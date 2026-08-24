extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_exito_y_copias_defensivas()
	_probar_fallo()
	_probar_bloqueo()

	if _fallos.is_empty():
		print("ResultadoAccion: 3 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_exito_y_copias_defensivas() -> void:
	var objetivo_efecto := RefCounted.new()
	var solicitud := SolicitudEfecto.new(
		&"veneno", &"estado", objetivo_efecto, &"evento_prueba"
	)
	var mensajes_originales: Array[StringName] = [&"examinar.objetivo_observado"]
	var cambios_originales: Array[Dictionary] = [{
		&"propiedad": &"informacion_descubierta",
		&"valor": true,
	}]
	var costes_originales: Dictionary[StringName, float] = {
		&"accion": 1.0,
		&"turno": 1.0,
	}
	var resultado := ResultadoAccion.crear_exito(
		mensajes_originales,
		[],
		cambios_originales,
		costes_originales,
		false,
		false,
		[solicitud]
	)

	_comprobar(resultado.exitosa, "Un éxito debe informar exitosa = true.")
	_comprobar(resultado.motivo == &"", "Un éxito no debe conservar un motivo.")
	_comprobar(resultado.consumio_accion(), "Debe registrar el coste de acción.")
	_comprobar(resultado.consumio_turno(), "Debe registrar el coste de turno.")
	_comprobar(
		resultado.solicitudes_efecto == [solicitud],
		"Debe separar solicitudes de efectos confirmados."
	)

	mensajes_originales.append(&"mensaje_añadido_desde_fuera")
	cambios_originales[0][&"valor"] = false
	costes_originales[&"accion"] = 99.0
	var cambios_obtenidos := resultado.cambios_estado
	cambios_obtenidos[0][&"valor"] = false

	_comprobar(resultado.mensajes.size() == 1, "Los mensajes deben copiarse al construir.")
	_comprobar(
		resultado.cambios_estado[0][&"valor"] == true,
		"Los cambios de estado deben copiarse en profundidad."
	)
	_comprobar(
		resultado.costes_consumidos[&"accion"] == 1.0,
		"Los costes deben copiarse al construir."
	)

	var terminal := ResultadoAccion.crear_exito([], [], [], {}, true, true)
	var terminal_con_coste := terminal.con_costes_consumidos({&"energia": 1.0})
	_comprobar(terminal.interrumpe_movimiento, "Debe conservar la interrupción.")
	_comprobar(terminal.terminal, "Debe exponer la terminalidad.")
	_comprobar(
		terminal_con_coste.terminal,
		"Confirmar costes no debe perder la terminalidad."
	)
	var generador := RandomNumberGenerator.new()
	generador.seed = 145
	var tirada := MotorDados.new(generador).resolver_prueba(3)
	var con_tirada := resultado.con_tirada(tirada)
	_comprobar(
		con_tirada.tirada == tirada
		and con_tirada.con_costes_consumidos({&"energia": 1.0}).tirada == tirada,
		"Una tirada resuelta debe conservarse al confirmar costes."
	)


func _probar_fallo() -> void:
	var resultado := ResultadoAccion.crear_fallo(
		&"inspeccion_inconclusa",
		[&"examinar.no_descubre_nada"]
	)

	_comprobar(not resultado.exitosa, "Un fallo no debe informar exitosa = true.")
	_comprobar(
		resultado.estado == TiposInteraccion.EstadoResolucion.FALLO,
		"La fábrica de fallo debe conservar el estado FALLO."
	)
	_comprobar(
		resultado.motivo == &"inspeccion_inconclusa",
		"Un fallo debe conservar su motivo."
	)

	var sin_motivo := ResultadoAccion.crear_fallo(&"")
	_comprobar(
		sin_motivo.motivo == &"motivo_no_especificado",
		"Un fallo sin motivo debe recibir el motivo de respaldo."
	)


func _probar_bloqueo() -> void:
	var efectos_prohibidos: Array = [&"efecto_que_no_debe_aplicarse"]
	var cambios_prohibidos: Array[Dictionary] = [{&"propiedad": &"estado"}]
	var costes_prohibidos: Dictionary[StringName, float] = {&"accion": 1.0}
	var resultado := ResultadoAccion.new(
		TiposInteraccion.EstadoResolucion.BLOQUEO,
		&"fuera_de_alcance",
		[&"accion.objetivo_fuera_de_alcance"],
		efectos_prohibidos,
		cambios_prohibidos,
		costes_prohibidos,
		true
	)

	_comprobar(
		resultado.estado == TiposInteraccion.EstadoResolucion.BLOQUEO,
		"El resultado debe conservar el estado BLOQUEO."
	)
	_comprobar(resultado.efectos_aplicados.is_empty(), "Un bloqueo no admite efectos.")
	_comprobar(resultado.cambios_estado.is_empty(), "Un bloqueo no admite cambios.")
	_comprobar(resultado.costes_consumidos.is_empty(), "Un bloqueo no admite costes.")
	_comprobar(not resultado.interrumpe_movimiento, "Un bloqueo no debe interrumpir.")
	_comprobar(not resultado.terminal, "Un bloqueo no debe ser terminal.")


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
