extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(zona)
	var capa_suelo := zona.get_node("CapaSuelo") as TileMapLayer
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	tablero.registrar_interactuables_desde_zona(zona, capa_suelo)
	tablero.registrar_efectos_superficie_desde_zona(zona, capa_suelo)

	var trampa := tablero.obtener_interactuable(&"zona1_trampa_humo_04_03") as TrampaSuperficie
	var trampa_vecina := tablero.obtener_interactuable(&"zona1_trampa_humo_05_03") as TrampaSuperficie
	_comprobar(trampa != null, "La trampa debe registrarse como interactuable automatico.")
	_comprobar(trampa_vecina != null, "La segunda trampa debe registrarse.")
	if trampa != null and trampa_vecina != null:
		_comprobar(
			trampa.coordenada_mapa == Vector2i(4, 3),
			"Debe colocarse en la celda prevista; fue %s." % trampa.coordenada_mapa
		)
		_comprobar(
			trampa_vecina.coordenada_mapa == Vector2i(5, 3),
			"La segunda trampa debe ser cardinalmente adyacente."
		)
		_comprobar(trampa.obtener_opciones_accion().is_empty(), "La trampa no debe ser examinable a distancia.")
		var sprite := trampa.get_node("Sprite2D") as Sprite2D
		_comprobar(sprite.texture != null, "La trampa debe usar el atlas configurado.")
		_comprobar(is_equal_approx(sprite.modulate.a, 0.7), "El indicio debe usar alpha 0.7.")
		_comprobar(sprite.region_rect.position.x == 0.0, "La placa armada debe usar la primera columna.")
		var ficha := Ficha.new()
		root.add_child(ficha)
		ficha.velocidad_paso = 0.001
		ficha.energia_actual = 5
		var origen := trampa.coordenada_mapa + Vector2i.LEFT
		ficha.inicializar(origen, capa_suelo)
		tablero.ocupar_celda(origen, ficha)
		var celda := tablero.obtener_celda(trampa.coordenada_mapa)
		var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
			celda,
			TiposInteraccion.TipoAccion.ENTRAR,
			ficha
		)
		_comprobar(reacciones.size() == 2, "Debe incluir la trampa pisada y su vecina.")
		var gestor := GestorAcciones.new()
		root.add_child(gestor)
		var resolver := ResolverReaccionesCelda.new(gestor)
		var resultados_entrada: Array[ResultadoReacciones] = []
		ficha.mover_por_camino(
			[origen, trampa.coordenada_mapa],
			func(_desde, hasta, actor): return tablero.reservar_celda(hasta, actor),
			func(desde, hasta, actor): return tablero.confirmar_movimiento(desde, hasta, actor),
			func(hasta, actor): tablero.cancelar_reserva(hasta, actor),
			Callable(),
			func(desde, hasta, actor):
				var resultado_entrada := resolver.resolver(
					TiposInteraccion.TipoAccion.ENTRAR,
					actor,
					desde,
					hasta,
					ConsultorReaccionesCelda.new().obtener_reacciones(
						tablero.obtener_celda(hasta),
						TiposInteraccion.TipoAccion.ENTRAR,
						actor
					)
				)
				resultados_entrada.append(resultado_entrada)
				if resultado_entrada.interrumpe_movimiento:
					actor.solicitar_interrupcion(),
			func(_desde, hasta, actor):
				return tablero.obtener_celda(hasta).calcular_coste_movimiento(actor)
		)
		var interrumpida: bool = await ficha.movimiento_terminado
		var resultado := resultados_entrada[0]
		_comprobar(interrumpida, "La ficha debe finalizar la ruta como interrumpida.")
		_comprobar(ficha.coordenada_mapa == trampa.coordenada_mapa, "Debe detenerse sobre la trampa.")
		_comprobar(ficha in celda.ocupantes, "La ocupacion debe estar confirmada antes de activar.")
		_comprobar(resultado.resultados.size() == 2, "Cada trampa colocada debe resolverse una sola vez.")
		_comprobar(resultado.interrumpe_movimiento, "Debe detener la ruta despues del paso.")
		_comprobar(trampa.activada, "La trampa de un uso debe quedar activada.")
		_comprobar(trampa_vecina.activada, "La trampa adyacente debe activarse por cadena.")
		_comprobar(sprite.region_rect.position.x == 64.0, "La placa presionada debe usar la segunda columna.")
		var sprite_vecina := trampa_vecina.get_node("Sprite2D") as Sprite2D
		_comprobar(sprite_vecina.region_rect.position.x == 64.0, "La vecina debe mostrarse presionada.")
		_comprobar(
			resultado.resultados.all(func(item): return not item.cambios_estado.is_empty()),
			"Cada trampa colocada debe desplegar superficies."
		)
		for cambio in resultado.cambios_estado:
			var coord: Vector2i = cambio["coordenada"]
			var distancia_primera: int = absi(coord.x - trampa.coordenada_mapa.x) + absi(coord.y - trampa.coordenada_mapa.y)
			var distancia_vecina: int = absi(coord.x - trampa_vecina.coordenada_mapa.x) + absi(coord.y - trampa_vecina.coordenada_mapa.y)
			_comprobar(
				mini(distancia_primera, distancia_vecina) <= trampa.radio,
				"Toda superficie debe quedar dentro del radio Manhattan."
			)
			_comprobar(
				not tablero.obtener_celda(coord).efectos_superficie.is_empty(),
				"Cada celda informada debe contener la superficie."
			)
		var reacciones_posteriores := ConsultorReaccionesCelda.new().obtener_reacciones(
			celda,
			TiposInteraccion.TipoAccion.ENTRAR,
			ficha
		)
		_comprobar(
			reacciones_posteriores.all(
				func(reaccion): return reaccion.receptor != trampa and reaccion.receptor != trampa_vecina
			),
			"Las trampas activadas no deben volver a reaccionar."
		)
		trampa.presentacion = TrampaSuperficie.Presentacion.OCULTA
		trampa._actualizar_presentacion()
		_comprobar(sprite.modulate.a == 0.0, "Una trampa oculta debe ser totalmente transparente.")
		ficha.queue_free()
		gestor.queue_free()

	_probar_reaccion_en_cadena(tablero)

	tablero.queue_free()
	zona.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("TrampaSuperficie: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _probar_reaccion_en_cadena(tablero: TableroGrid) -> void:
	var trampas: Array[TrampaSuperficie] = []
	for indice in range(3):
		var trampa := TrampaSuperficie.new()
		trampa.id_instancia = StringName("trampa_cadena_%d" % indice)
		root.add_child(trampa)
		tablero.registrar_interactuable(Vector2i(8 + indice, 0), trampa)
		trampas.append(trampa)
	var diagonal := TrampaSuperficie.new()
	diagonal.id_instancia = &"trampa_diagonal"
	root.add_child(diagonal)
	tablero.registrar_interactuable(Vector2i(7, 1), diagonal)

	var actor := RefCounted.new()
	trampas[0].presentacion = TrampaSuperficie.Presentacion.OCULTA
	var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
		tablero.obtener_celda(Vector2i(8, 0)),
		TiposInteraccion.TipoAccion.IMPACTAR,
		actor
	)
	_comprobar(
		reacciones.size() == 3,
		"Un impacto en una trampa oculta debe encadenar las tres trampas cardinales."
	)
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var definicion_item := DefinicionItem.new()
	definicion_item.id_definicion = &"piedra_prueba_impacto"
	definicion_item.nombre = "Piedra"
	var item := ItemInstancia.new(&"piedra_prueba_impacto", definicion_item)
	var resultado := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.IMPACTAR,
		actor,
		Vector2i(7, 0),
		Vector2i(8, 0),
		reacciones,
		item,
		[&"impacto"],
		{},
		1,
		null
	)
	_comprobar(
		resultado.resultados.size() == 3,
		"Cada trampa encadenada por el impacto debe resolverse una vez."
	)
	_comprobar(
		resultado.resultados.all(func(item): return not item.cambios_estado.is_empty()),
		"Cada trampa encadenada debe desplegar al menos una superficie caminable."
	)
	_comprobar(trampas.all(func(trampa): return trampa.activada), "Toda la cadena cardinal debe activarse.")
	_comprobar(not diagonal.activada, "Una trampa solamente diagonal no debe encadenarse.")

	gestor.queue_free()
	for trampa in trampas:
		trampa.queue_free()
	diagonal.queue_free()
