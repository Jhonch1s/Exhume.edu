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
		humo.motor_dados = _motor_con_fallos(2, 2)
		var celda := tablero.obtener_celda(humo.coordenada_mapa)
		_comprobar(humo in celda.efectos_superficie, "Debe registrarse como superficie.")
		_comprobar(
			celda.calcular_coste_movimiento() == 2,
			"El humo debe sumar uno al coste base del paso."
		)
		var humo_superpuesto := HumoVeneno.new()
		humo_superpuesto.motor_dados = _motor_con_fallos(2, 2)
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
			_comprobar(ficha.pv_actual == vida_inicial, "El veneno no debe causar daño inmediato.")
			var estado := ficha.obtener_estado(&"veneno")
			_comprobar(
				estado != null
				and estado.duracion_total == 2
				and estado.ticks_pendientes == 2
				and estado.terminos_dano_tick == [{
					&"cantidad": 1, &"caras": 2, &"signo": 1
				}],
				"Veneno debe conservar sus dos ticks pendientes."
			)
			var renovacion := resolver.resolver(
				TiposInteraccion.TipoAccion.ENTRAR,
				ficha,
				Vector2i(-1, 0),
				humo.coordenada_mapa,
				reacciones
			)
			_comprobar(ficha.pv_actual == vida_inicial, "Renovar no debe aplicar daño inmediato.")
			_comprobar(
				renovacion.mensajes == [&"estado.veneno_renovado"],
				"La renovación debe producir un solo mensaje."
			)
			var ficha_resistente := Ficha.new()
			root.add_child(ficha_resistente)
			humo.motor_dados = _motor_con_exitos(ficha_resistente.obtener_voluntad(), 1)
			var resistencia := gestor.procesar_accion(ContextoAccion.new(
				TiposInteraccion.TipoAccion.ENTRAR,
				ficha_resistente,
				Vector2i(-1, 0),
				humo.coordenada_mapa,
				humo,
				null,
				&"",
				[],
				{},
				-1.0,
				{},
				TiposInteraccion.TipoLineaEfecto.NINGUNA,
				{},
				TiposInteraccion.PoliticaCobro.SOLO_EXITO,
				null,
				&"salvacion_veneno"
			))
			_comprobar(
				resistencia.exitosa
				and resistencia.tirada is ResultadoPrueba
				and resistencia.tirada.exitosa
				and resistencia.tirada.presentacion == TiposTirada.Presentacion.SOLO_LOG
				and ficha_resistente.obtener_estado(&"veneno") == null,
				"Superar Voluntad debe evitar por completo el estado de veneno."
			)
			ficha_resistente.queue_free()
			var servicio := ServicioTurnos.new(gestor, null, MotorDados.new())
			var vida_antes_tick := ficha.pv_actual
			var tick := servicio.avanzar_turno(ficha)
			_comprobar(
				tick.exitosa
				and tick.tirada is ResultadoTirada
				and tick.tirada.origen == TiposTirada.Origen.AUTOMATICA
				and tick.tirada.presentacion == TiposTirada.Presentacion.SOLO_LOG
				and vida_antes_tick - ficha.pv_actual in [1, 2]
				and ficha.obtener_estado(&"veneno").ticks_pendientes == 1,
				"Cada tick debe resolver y aplicar un d2 automático visible sólo en el log."
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


func _motor_con_fallos(atributo: int, cantidad: int) -> MotorDados:
	for semilla in 1000:
		var prueba := RandomNumberGenerator.new()
		prueba.seed = semilla
		var sirve := true
		for _indice in cantidad:
			if MotorDados.new(prueba).resolver_prueba(atributo).exitosa:
				sirve = false
				break
		if sirve:
			var generador := RandomNumberGenerator.new()
			generador.seed = semilla
			return MotorDados.new(generador)
	return MotorDados.new()


func _motor_con_exitos(atributo: int, cantidad: int) -> MotorDados:
	for semilla in 1000:
		var prueba := RandomNumberGenerator.new()
		prueba.seed = semilla
		var sirve := true
		for _indice in cantidad:
			if not MotorDados.new(prueba).resolver_prueba(atributo).exitosa:
				sirve = false
				break
		if sirve:
			var generador := RandomNumberGenerator.new()
			generador.seed = semilla
			return MotorDados.new(generador)
	return MotorDados.new()
