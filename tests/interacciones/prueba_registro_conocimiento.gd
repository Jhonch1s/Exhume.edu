extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_registro_y_estado_transitorio()
	_probar_idempotencia()
	_probar_separacion_por_observador_y_objetivo()
	_probar_rechazo_atomico()
	_probar_copias_defensivas()

	if _fallos.is_empty():
		print("RegistroConocimiento: 5 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_registro_y_estado_transitorio() -> void:
	var registro := RegistroConocimiento.new()
	var identidad := _crear_fragmento(&"identidad", true)
	var construccion := _crear_fragmento(&"construccion", true)
	var estado_visible := _crear_fragmento(&"estado_visible", false)
	var fragmentos: Array[FragmentoInformacion] = [
		estado_visible,
		identidad,
		construccion,
	]
	var resultado := registro.registrar_descubrimientos(
		&"jugador_principal",
		&"zona1_antorcha_pie_02_01",
		fragmentos
	)

	_comprobar(resultado.exitosa, "Un registro válido debe completarse.")
	_comprobar(
		resultado.ids_fragmentos_nuevos == [&"identidad", &"construccion"],
		"Solo los fragmentos recordables deben informarse como nuevos."
	)
	_comprobar(
		not registro.conoce_fragmento(
			&"jugador_principal",
			&"zona1_antorcha_pie_02_01",
			&"estado_visible"
		),
		"Un estado transitorio no debe incorporarse al conocimiento."
	)


func _probar_idempotencia() -> void:
	var registro := RegistroConocimiento.new()
	var fragmentos: Array[FragmentoInformacion] = [_crear_fragmento(&"identidad", true)]
	var primero := registro.registrar_descubrimientos(&"observador", &"objetivo", fragmentos)
	var segundo := registro.registrar_descubrimientos(&"observador", &"objetivo", fragmentos)

	_comprobar(primero.exitosa, "El primer descubrimiento debe registrarse.")
	_comprobar(
		primero.ids_fragmentos_nuevos == [&"identidad"],
		"El primer registro debe informar la novedad."
	)
	_comprobar(segundo.exitosa, "Repetir conocimiento válido no debe fallar.")
	_comprobar(
		segundo.ids_fragmentos_nuevos.is_empty(),
		"Repetir un descubrimiento no debe producir una novedad duplicada."
	)


func _probar_separacion_por_observador_y_objetivo() -> void:
	var registro := RegistroConocimiento.new()
	var fragmentos: Array[FragmentoInformacion] = [_crear_fragmento(&"identidad", true)]
	registro.registrar_descubrimientos(&"observador_a", &"antorcha_a", fragmentos)

	_comprobar(
		registro.conoce_fragmento(&"observador_a", &"antorcha_a", &"identidad"),
		"El observador original debe conocer el fragmento de esa instancia."
	)
	_comprobar(
		not registro.conoce_fragmento(&"observador_b", &"antorcha_a", &"identidad"),
		"Otro observador no debe heredar el descubrimiento."
	)
	_comprobar(
		not registro.conoce_fragmento(&"observador_a", &"antorcha_b", &"identidad"),
		"Otra instancia de la misma definición no debe heredar el descubrimiento."
	)


func _probar_rechazo_atomico() -> void:
	var registro := RegistroConocimiento.new()
	var valido := _crear_fragmento(&"identidad", true)
	var invalido := _crear_fragmento(&"", true)
	var mezclados: Array[FragmentoInformacion] = [valido, invalido]
	var resultado := registro.registrar_descubrimientos(&"observador", &"objetivo", mezclados)

	_comprobar(not resultado.exitosa, "Una colección inválida debe rechazarse.")
	_comprobar(
		resultado.motivo == &"fragmentos_descubrimiento_invalidos",
		"El rechazo debe conservar un motivo estable."
	)
	_comprobar(
		not registro.conoce_fragmento(&"observador", &"objetivo", &"identidad"),
		"El rechazo debe ocurrir antes de cualquier mutación parcial."
	)

	var duplicados: Array[FragmentoInformacion] = [valido, valido]
	_comprobar(
		registro.registrar_descubrimientos(
			&"observador",
			&"objetivo",
			duplicados
		).motivo == &"fragmentos_descubrimiento_duplicados",
		"Una misma solicitud no debe admitir IDs repetidos."
	)


func _probar_copias_defensivas() -> void:
	var registro := RegistroConocimiento.new()
	var fragmentos: Array[FragmentoInformacion] = [
		_crear_fragmento(&"identidad", true),
		_crear_fragmento(&"construccion", true),
	]
	var resultado := registro.registrar_descubrimientos(&"observador", &"objetivo", fragmentos)
	var novedades := resultado.ids_fragmentos_nuevos
	novedades.clear()
	var conocidos := registro.obtener_ids_conocidos(&"observador", &"objetivo")
	conocidos.clear()

	_comprobar(
		resultado.ids_fragmentos_nuevos.size() == 2,
		"El resultado debe proteger su colección de novedades."
	)
	_comprobar(
		registro.obtener_ids_conocidos(&"observador", &"objetivo")
		== [&"construccion", &"identidad"],
		"El registro debe devolver una copia ordenada de sus IDs conocidos."
	)


func _crear_fragmento(
	id_fragmento: StringName,
	se_recuerda: bool
) -> FragmentoInformacion:
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = id_fragmento
	fragmento.nivel = TiposInteraccion.NivelInformacion.BASICO
	fragmento.id_mensaje = &"examen.prueba"
	fragmento.se_recuerda = se_recuerda
	return fragmento


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
