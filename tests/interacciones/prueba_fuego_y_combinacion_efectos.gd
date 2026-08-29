extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	var coordenada := Vector2i.ZERO
	tablero.datos[coordenada] = Celda.new(&"piso_prueba", true)
	var superficies: Array[Node2D] = []
	for indice in 2:
		var humo := HumoVeneno.new()
		humo.motor_dados = _motor_con_fallos(2, 2)
		humo.configurar_id_instancia(StringName("humo_%d" % indice))
		root.add_child(humo)
		tablero.registrar_efecto_superficie(coordenada, humo)
		superficies.append(humo)
		var fuego := Fuego.new()
		fuego.configurar_id_instancia(StringName("fuego_%d" % indice))
		root.add_child(fuego)
		tablero.registrar_efecto_superficie(coordenada, fuego)
		superficies.append(fuego)

	var ficha := Ficha.new()
	root.add_child(ficha)
	var celda := tablero.obtener_celda(coordenada)
	_comprobar(celda.calcular_coste_movimiento(ficha) == 3, "Humo y fuego deben sumar una vez por familia.")
	var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
		celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
	)
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var resultado := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		ficha,
		Vector2i.LEFT,
		coordenada,
		reacciones
	)
	_comprobar(resultado.efectos_aplicados.size() == 2, "Cada familia debe aplicar una consecuencia.")
	_comprobar(ficha.pv_actual == ficha.pv_max, "Los estados no deben causar daño inmediato.")
	_comprobar(
		resultado.mensajes == [&"estado.quemado", &"estado.envenenado"],
		"Los mensajes deben conservar el orden determinista de las superficies."
	)
	var quemado := ficha.obtener_estado(&"quemado")
	var veneno := ficha.obtener_estado(&"veneno")
	_comprobar(
		quemado != null
		and quemado.duracion_total == 3
		and quemado.ticks_pendientes == 3
		and quemado.terminos_dano_tick[0][&"caras"] == 2,
		"Quemado debe conservar tres ticks de d2."
	)
	_comprobar(
		veneno != null and veneno.duracion_total == 2 and veneno.ticks_pendientes == 2,
		"Veneno debe reservar sus dos daños para fines de turno."
	)
	_comprobar((superficies[1] as Fuego).obtener_duracion_superficie() == 7, "El fuego debe declarar siete turnos de superficie.")
	var vida_tras_entrada := ficha.pv_actual
	var renovacion := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		ficha,
		Vector2i.LEFT,
		coordenada,
		reacciones
	)
	_comprobar(ficha.pv_actual == vida_tras_entrada, "Renovar estados no debe repetir daño inmediato.")
	_comprobar(
		renovacion.mensajes == [&"estado.quemado_renovado", &"estado.veneno_renovado"],
		"Cada estado debe publicar una única renovación."
	)

	for superficie in superficies:
		superficie.queue_free()
	gestor.queue_free()
	ficha.queue_free()
	tablero.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("FuegoYCombinacionEfectos: prueba correcta.")
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
