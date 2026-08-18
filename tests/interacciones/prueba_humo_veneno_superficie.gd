extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var escena := load("res://scenes/Zona1/zona_1.tscn") as PackedScene
	var zona := escena.instantiate() as Node2D
	root.add_child(zona)
	var capa_suelo := zona.get_node("CapaSuelo") as TileMapLayer
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	_comprobar(
		tablero.registrar_efectos_superficie_desde_zona(zona, capa_suelo),
		"El humo de Zona1 debe registrarse correctamente."
	)

	var humo := tablero.efectos_superficie_por_id.get(
		&"zona1_humo_veneno_00_00"
	) as HumoVeneno
	_comprobar(humo != null, "Debe poder recuperarse por su ID estable.")
	if humo != null:
		var celda := tablero.obtener_celda(humo.coordenada_mapa)
		_comprobar(humo in celda.efectos_superficie, "Debe registrarse como superficie.")
		_comprobar(
			celda.calcular_coste_movimiento() == 2,
			"El humo debe sumar uno al coste base del paso."
		)
		var humo_superpuesto := HumoVeneno.new()
		humo_superpuesto.configurar_id_instancia(&"humo_superpuesto")
		root.add_child(humo_superpuesto)
		_comprobar(
			tablero.registrar_efecto_superficie(humo.coordenada_mapa, humo_superpuesto),
			"La superficie superpuesta debe registrarse como instancia independiente."
		)
		_comprobar(
			celda.calcular_coste_movimiento() == 2,
			"Dos nubes de la misma familia no deben duplicar el coste."
		)
		var ficha := Ficha.new()
		root.add_child(ficha)
		var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
			celda,
			TiposInteraccion.TipoAccion.ENTRAR,
			ficha
		)
		_comprobar(reacciones.size() == 2, "Ambas superficies deben publicar ENTRAR.")
		if reacciones.size() == 2:
			var gestor := GestorAcciones.new()
			root.add_child(gestor)
			var resolver := ResolverReaccionesCelda.new(gestor)
			var vida_inicial := ficha.pv_actual
			var resultado := resolver.resolver(
				TiposInteraccion.TipoAccion.ENTRAR,
				ficha,
				Vector2i(-1, 0),
				humo.coordenada_mapa,
				reacciones
			)
			_comprobar(
				resultado.mensajes == [&"estado.envenenado"],
				"Las superficies superpuestas deben producir un único mensaje confirmado."
			)
			_comprobar(resultado.interrumpe_movimiento, "Debe interrumpir tras entrar.")
			_comprobar(
				resultado.efectos_aplicados.size() == 1,
				"Debe aplicar una sola instancia lógica de veneno."
			)
			_comprobar(ficha.pv_actual == vida_inicial - 1, "El primer tick debe causar un daño.")
			var estado := ficha.obtener_estado(&"veneno")
			_comprobar(
				estado != null
				and estado.duracion_total == 2
				and estado.ticks_pendientes == 1,
				"Veneno debe conservar dos ticks totales con uno pendiente."
			)
			var renovacion := resolver.resolver(
				TiposInteraccion.TipoAccion.ENTRAR,
				ficha,
				Vector2i(-1, 0),
				humo.coordenada_mapa,
				reacciones
			)
			_comprobar(ficha.pv_actual == vida_inicial - 1, "Renovar no debe repetir el daño inmediato.")
			_comprobar(
				renovacion.mensajes == [&"estado.veneno_renovado"],
				"La renovación debe producir un solo mensaje."
			)
			gestor.queue_free()
		_comprobar(
			tablero.retirar_efecto_superficie(humo_superpuesto),
			"Debe poder retirar una contribución concreta."
		)
		_comprobar(
			celda.calcular_coste_movimiento() == 2,
			"Retirar una nube no debe eliminar el aporte de la nube restante."
		)
		ficha.queue_free()
		humo_superpuesto.queue_free()

	tablero.queue_free()
	zona.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("HumoVenenoSuperficie: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
