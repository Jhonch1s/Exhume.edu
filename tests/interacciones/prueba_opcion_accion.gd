extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_opcion_habilitada()
	_probar_opcion_bloqueada()
	_probar_opcion_secreta()

	if _fallos.is_empty():
		print("OpcionAccion: 3 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_opcion_habilitada() -> void:
	var objetivo_prueba := RefCounted.new()
	var costes_originales: Dictionary[StringName, float] = {&"accion": 1.0}
	var metadatos_originales: Dictionary = {
		&"presentacion": {&"icono": &"examinar"},
	}
	var opcion := OpcionAccion.crear_habilitada(
		&"examinar",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"accion.examinar",
		objetivo_prueba,
		costes_originales,
		10,
		false,
		metadatos_originales,
		TiposInteraccion.TipoLineaEfecto.VISUAL,
		TiposInteraccion.PoliticaCobro.AL_INTENTAR
	)

	_comprobar(opcion.id == &"examinar", "Debe conservar el ID de la opción.")
	_comprobar(
		opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR,
		"Debe conservar el tipo de acción."
	)
	_comprobar(opcion.texto == &"accion.examinar", "Debe conservar el ID de texto.")
	_comprobar(opcion.objetivo == objetivo_prueba, "Debe conservar el objetivo.")
	_comprobar(opcion.habilitada, "La fábrica habilitada debe habilitar la opción.")
	_comprobar(
		opcion.motivo_bloqueo == &"",
		"Una opción habilitada no debe tener motivo de bloqueo."
	)
	_comprobar(opcion.prioridad == 10, "Debe conservar la prioridad.")
	_comprobar(
		opcion.tipo_linea_efecto == TiposInteraccion.TipoLineaEfecto.VISUAL,
		"Debe conservar el requisito espacial previsto."
	)
	_comprobar(
		opcion.politica_cobro == TiposInteraccion.PoliticaCobro.AL_INTENTAR,
		"Debe conservar la política de cobro prevista."
	)

	costes_originales[&"accion"] = 99.0
	metadatos_originales[&"presentacion"][&"icono"] = &"otro"
	var costes_obtenidos := opcion.costes_previstos
	var metadatos_obtenidos := opcion.metadatos
	costes_obtenidos[&"accion"] = 50.0
	metadatos_obtenidos[&"presentacion"][&"icono"] = &"otro_getter"

	_comprobar(
		opcion.costes_previstos[&"accion"] == 1.0,
		"Los costes previstos deben copiarse."
	)
	_comprobar(
		opcion.metadatos[&"presentacion"][&"icono"] == &"examinar",
		"Los metadatos deben copiarse en profundidad."
	)


func _probar_opcion_bloqueada() -> void:
	var objetivo_prueba := RefCounted.new()
	var opcion := OpcionAccion.crear_bloqueada(
		&"examinar",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"accion.examinar",
		objetivo_prueba,
		&"fuera_de_alcance"
	)

	_comprobar(not opcion.habilitada, "La fábrica bloqueada debe deshabilitar la opción.")
	_comprobar(
		opcion.motivo_bloqueo == &"fuera_de_alcance",
		"Una opción bloqueada debe conservar su motivo."
	)

	var sin_motivo := OpcionAccion.crear_bloqueada(
		&"examinar",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"accion.examinar",
		objetivo_prueba,
		&""
	)
	_comprobar(
		sin_motivo.motivo_bloqueo == &"motivo_no_especificado",
		"Una opción bloqueada sin motivo debe recibir el motivo de respaldo."
	)


func _probar_opcion_secreta() -> void:
	var opcion := OpcionAccion.crear_habilitada(
		&"examinar_mecanismo_oculto",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"accion.examinar_mecanismo_oculto",
		null,
		{},
		20,
		true
	)

	_comprobar(opcion.secreta, "La opción debe conservar su condición secreta.")
	_comprobar(
		opcion.habilitada,
		"Ser secreta y estar habilitada son estados independientes."
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
