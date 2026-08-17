extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_fragmento_basico()
	_probar_secreto_con_pista_explicita()
	_probar_condiciones_observacion()
	_probar_fragmentos_en_definicion()
	_probar_solicitud_examen()

	if _fallos.is_empty():
		print("ContratosExamen: 5 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_fragmento_basico() -> void:
	var fragmento := _crear_fragmento(
		&"identidad",
		TiposInteraccion.NivelInformacion.BASICO,
		&"examen.antorcha.identidad"
	)
	_comprobar(fragmento.es_valido(), "Un fragmento básico completo debe ser válido.")
	_comprobar(fragmento.se_recuerda, "La información estable debe recordarse por defecto.")

	fragmento.id_mensaje = &""
	_comprobar(
		not fragmento.es_valido(),
		"Un fragmento sin ID de mensaje no debe ser válido."
	)


func _probar_secreto_con_pista_explicita() -> void:
	var secreto := _crear_fragmento(
		&"marca_oculta",
		TiposInteraccion.NivelInformacion.SECRETO,
		&"examen.antorcha.marca_oculta"
	)
	_comprobar(
		not secreto.es_valido(),
		"Un secreto sin pista explícita no debe ser válido."
	)

	secreto.pistas_requeridas = [&"marca_oculta_revelable"]
	_comprobar(secreto.es_valido(), "Una pista explícita debe habilitar el contrato secreto.")

	secreto.pistas_requeridas = [
		&"marca_oculta_revelable",
		&"marca_oculta_revelable",
	]
	_comprobar(
		not secreto.es_valido(),
		"Las pistas requeridas duplicadas deben rechazarse."
	)


func _probar_condiciones_observacion() -> void:
	var observador := RefCounted.new()
	var pistas_originales: Array[StringName] = [&"marca_oculta_revelable"]
	var condiciones := CondicionesObservacion.new(
		observador,
		1.0,
		true,
		true,
		pistas_originales
	)

	_comprobar(condiciones.es_valida(), "Las condiciones completas deben ser válidas.")
	_comprobar(condiciones.observador == observador, "Deben conservar el observador.")
	_comprobar(condiciones.distancia == 1.0, "Deben conservar la distancia calculada.")
	_comprobar(condiciones.objetivo_visible, "Deben conservar la visibilidad actual.")
	_comprobar(condiciones.linea_visual_valida, "Deben conservar la línea visual.")
	_comprobar(
		condiciones.tiene_pista(&"marca_oculta_revelable"),
		"Deben permitir consultar una pista semántica."
	)

	pistas_originales.append(&"añadida_desde_fuera")
	var pistas_obtenidas := condiciones.pistas
	pistas_obtenidas.append(&"añadida_desde_getter")
	_comprobar(
		condiciones.pistas.size() == 1,
		"Las pistas deben copiarse al construir y al consultar."
	)

	_comprobar(
		not CondicionesObservacion.new(null, 1.0, true, true).es_valida(),
		"Una observación sin observador no debe ser válida."
	)
	_comprobar(
		not CondicionesObservacion.new(observador, -1.0, true, true).es_valida(),
		"Una distancia negativa no debe ser válida."
	)


func _probar_fragmentos_en_definicion() -> void:
	var definicion := DefinicionInteractuable.new()
	definicion.id_definicion = &"antorcha_prueba"
	definicion.nombre = "Antorcha de prueba"
	var identidad := _crear_fragmento(
		&"identidad",
		TiposInteraccion.NivelInformacion.BASICO,
		&"examen.antorcha.identidad"
	)
	definicion.fragmentos_informacion.append(identidad)

	_comprobar(
		definicion.es_valida(),
		"Una definición debe aceptar fragmentos examinables válidos."
	)

	var id_repetido := _crear_fragmento(
		&"identidad",
		TiposInteraccion.NivelInformacion.DETALLADO,
		&"examen.antorcha.identidad_detallada"
	)
	definicion.fragmentos_informacion.append(id_repetido)
	_comprobar(
		not definicion.es_valida(),
		"Una definición no debe aceptar IDs de fragmento duplicados."
	)


func _probar_solicitud_examen() -> void:
	var actor := Ficha.new()
	var pistas_originales: Array[StringName] = [&"marca_oculta_revelable"]
	var solicitud := SolicitudExamen.new(&"jugador_principal", pistas_originales)
	_comprobar(solicitud.es_valida(actor), "Una solicitud completa debe ser válida.")

	pistas_originales.append(&"añadida_desde_fuera")
	var pistas_obtenidas := solicitud.pistas
	pistas_obtenidas.clear()
	_comprobar(
		solicitud.pistas == [&"marca_oculta_revelable"],
		"La solicitud debe copiar sus pistas al construir y consultar."
	)
	_comprobar(
		not SolicitudExamen.new(&"", []).es_valida(actor),
		"Una solicitud sin ID de observador debe ser inválida."
	)
	_comprobar(
		not SolicitudExamen.new(&"otro_observador", []).es_valida(actor),
		"La solicitud no debe atribuir conocimiento a otro observador."
	)
	_comprobar(
		not SolicitudExamen.new(
			&"jugador_principal",
			[&"pista_repetida", &"pista_repetida"]
		).es_valida(actor),
		"Una solicitud no debe aceptar pistas duplicadas."
	)
	actor.free()


func _crear_fragmento(
	id_fragmento: StringName,
	nivel: TiposInteraccion.NivelInformacion,
	id_mensaje: StringName
) -> FragmentoInformacion:
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = id_fragmento
	fragmento.nivel = nivel
	fragmento.id_mensaje = id_mensaje
	return fragmento


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
