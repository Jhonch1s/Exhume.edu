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
		var posicion_libre := trampa.position + Vector2(7.0, 3.0)
		var centro_esperado := capa_suelo.map_to_local(capa_suelo.local_to_map(posicion_libre))
		trampa.position = posicion_libre
		trampa._ajustar_al_centro_celda()
		_comprobar(
			trampa.position.is_equal_approx(centro_esperado),
			"La placa debe ajustarse al centro de la celda más cercana."
		)
		_comprobar(
			trampa.coordenada_mapa == Vector2i(4, 3),
			"Debe colocarse en la celda prevista; fue %s." % trampa.coordenada_mapa
		)
		_comprobar(
			trampa_vecina.coordenada_mapa == Vector2i(5, 3),
			"La segunda trampa debe ser cardinalmente adyacente."
		)
		_comprobar(trampa.obtener_opciones_accion().is_empty(), "La trampa oculta no debe ofrecer acciones.")
		var sprite := trampa.get_node("Sprite2D") as Sprite2D
		_comprobar(sprite.texture != null, "La trampa debe usar el atlas configurado.")
		_comprobar(sprite.modulate.a == 0.0, "La trampa oculta debe ser transparente.")
		_comprobar(sprite.region_rect.position.x == 0.0, "La placa armada debe usar la primera columna.")
		trampa.fila_atlas = 1
		trampa._actualizar_presentacion()
		_comprobar(sprite.region_rect.position.y == 32.0, "La segunda fila debe representar fuego.")
		trampa.fila_atlas = 0
		trampa._actualizar_presentacion()
		var ficha := Ficha.new()
		root.add_child(ficha)
		ficha.velocidad_paso = 0.001
		ficha.energia_actual = 5
		var origen := trampa.coordenada_mapa + Vector2i.LEFT
		ficha.inicializar(origen, capa_suelo)
		tablero.ocupar_celda(origen, ficha)
		var celda := tablero.obtener_celda(trampa.coordenada_mapa)
		celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
		tablero.obtener_celda(trampa_vecina.coordenada_mapa).visibilidad = Celda.EstadoVisibilidad.VISIBLE
		var percepciones := ServicioPercepcionTrampas.new(
			tablero,
			RegistroConocimiento.new(),
			ValidadorEspacialTablero.new(tablero),
			_motor_con_exito(ficha.obtener_voluntad())
		).evaluar(ficha)
		_comprobar(
			not percepciones.is_empty()
			and percepciones.all(func(resultado):
				return resultado.tirada.atributo == ficha.obtener_voluntad()
			),
			"La percepción secreta de trampas debe usar VOL."
		)
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
		_comprobar(trampa.estado == TrampaSuperficie.Estado.ACTIVADA, "La trampa de un uso debe quedar activada.")
		_comprobar(trampa_vecina.estado == TrampaSuperficie.Estado.ACTIVADA, "La trampa adyacente debe activarse por cadena.")
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
		trampa.estado = TrampaSuperficie.Estado.OCULTA
		trampa._actualizar_presentacion()
		_comprobar(sprite.modulate.a == 0.0, "Una trampa oculta debe ser totalmente transparente.")
		ficha.queue_free()
		gestor.queue_free()

	_probar_reaccion_en_cadena(tablero)
	await _probar_descubrimiento_y_desarme()

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
	trampas[0].estado = TrampaSuperficie.Estado.OCULTA
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
	_comprobar(trampas.all(func(trampa): return trampa.estado == TrampaSuperficie.Estado.ACTIVADA), "Toda la cadena cardinal debe activarse.")
	_comprobar(diagonal.estado != TrampaSuperficie.Estado.ACTIVADA, "Una trampa solamente diagonal no debe encadenarse.")

	gestor.queue_free()
	for trampa in trampas:
		trampa.queue_free()
	diagonal.queue_free()


func _probar_descubrimiento_y_desarme() -> void:
	var trampa := (load(
		"res://scenes/interactuables/trampas/TrampaSuperficie.tscn"
	) as PackedScene).instantiate() as TrampaSuperficie
	root.add_child(trampa)
	trampa.id_instancia = &"trampa_desarme"
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	trampa.configurar_registro(tablero, Vector2i.ZERO)
	_comprobar(trampa.descubrir(), "Una trampa oculta debe poder descubrirse.")
	_comprobar(
		trampa.estado == TrampaSuperficie.Estado.DESCUBIERTA
		and trampa.obtener_opciones_accion().size() == 3,
		"La trampa descubierta debe ofrecer FUE, DES y VOL para desarmar."
	)
	await create_timer(trampa.pulsos_descubrimiento * trampa.duracion_pulso * 2.0 + 0.05).timeout
	_comprobar(
		trampa.get_node("Sprite2D").modulate.a == 0.0,
		"El indicador debe desaparecer tras los pulsos de descubrimiento."
	)
	var guerrero := Ficha.new()
	root.add_child(guerrero)
	guerrero.clase = "Guerrero"
	trampa.motor_dados = _motor_con_exito(guerrero.obtener_fuerza())
	var opcion := trampa.obtener_opciones_accion().filter(
		func(candidata): return candidata.id == &"desarmar_fue"
	)[0] as OpcionAccion
	var contexto := trampa.construir_contexto_accion(
		opcion, guerrero, Vector2i.ZERO, trampa.coordenada_mapa
	)
	var resultado := trampa.resolver_accion(contexto)
	_comprobar(
		resultado.exitosa
		and resultado.tirada is ResultadoPrueba
		and resultado.tirada.modo == ResultadoPrueba.Modo.NORMAL
		and trampa.estado == TrampaSuperficie.Estado.DESACTIVADA,
		"El Guerrero debe desarmar sin desventaja y dejar la trampa inerte."
	)
	_comprobar(
		not trampa.reacciona_automaticamente(TiposInteraccion.TipoAccion.ENTRAR),
		"Una trampa desactivada no debe volver a reaccionar."
	)
	guerrero.queue_free()
	trampa.queue_free()
	tablero.queue_free()


func _motor_con_exito(atributo: int) -> MotorDados:
	for semilla in 1000:
		var prueba := RandomNumberGenerator.new()
		prueba.seed = semilla
		if MotorDados.new(prueba).resolver_prueba(atributo).exitosa:
			var generador := RandomNumberGenerator.new()
			generador.seed = semilla
			return MotorDados.new(generador)
	return MotorDados.new()
