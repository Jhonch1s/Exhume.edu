extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_contexto_dirigido()
	_probar_coordenadas_opcionales()

	if _fallos.is_empty():
		print("ContextoAccion: 2 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_contexto_dirigido() -> void:
	var actor_prueba := RefCounted.new()
	var objetivo_prueba := RefCounted.new()
	var item_prueba := RefCounted.new()
	var etiquetas_originales: Array[StringName] = [&"visible", &"mecanismo"]
	var magnitudes_originales: Dictionary[StringName, float] = {&"distancia": 1.0}
	var costes_originales: Dictionary[StringName, float] = {&"energia": 2.0}
	var metadatos_originales: Dictionary = {
		&"linea_efecto": {&"requerida": true},
	}
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		actor_prueba,
		Vector2i(3, 4),
		Vector2i(4, 4),
		objetivo_prueba,
		item_prueba,
		&"examinar_objetivo",
		etiquetas_originales,
		magnitudes_originales,
		1.0,
		metadatos_originales,
		TiposInteraccion.TipoLineaEfecto.VISUAL,
		costes_originales,
		TiposInteraccion.PoliticaCobro.AL_INTENTAR
	)

	_comprobar(
		contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR,
		"El contexto debe conservar el tipo de acción."
	)
	_comprobar(contexto.actor == actor_prueba, "El contexto debe conservar el actor.")
	_comprobar(contexto.objetivo == objetivo_prueba, "Debe conservar el objetivo.")
	_comprobar(contexto.item == item_prueba, "Debe conservar el item opcional.")
	_comprobar(contexto.origen == Vector2i(3, 4), "Debe conservar la celda de origen.")
	_comprobar(
		contexto.celda_objetivo == Vector2i(4, 4),
		"Debe conservar la celda objetivo."
	)
	_comprobar(contexto.tiene_origen(), "Debe reconocer un origen Vector2i.")
	_comprobar(
		contexto.tiene_celda_objetivo(),
		"Debe reconocer una celda objetivo Vector2i."
	)
	_comprobar(contexto.alcance_maximo == 1.0, "Debe conservar el alcance máximo.")
	_comprobar(
		contexto.tipo_linea_efecto == TiposInteraccion.TipoLineaEfecto.VISUAL,
		"Debe conservar el tipo de línea de efecto."
	)
	_comprobar(
		contexto.politica_cobro == TiposInteraccion.PoliticaCobro.AL_INTENTAR,
		"Debe conservar la política de cobro."
	)

	etiquetas_originales.append(&"añadida_desde_fuera")
	magnitudes_originales[&"distancia"] = 99.0
	costes_originales[&"energia"] = 99.0
	metadatos_originales[&"linea_efecto"][&"requerida"] = false
	var etiquetas_obtenidas := contexto.etiquetas
	var metadatos_obtenidos := contexto.metadatos
	etiquetas_obtenidas.append(&"añadida_desde_getter")
	metadatos_obtenidos[&"linea_efecto"][&"requerida"] = false

	_comprobar(contexto.etiquetas.size() == 2, "Las etiquetas deben copiarse.")
	_comprobar(
		contexto.magnitudes[&"distancia"] == 1.0,
		"Las magnitudes deben copiarse."
	)
	_comprobar(
		contexto.metadatos[&"linea_efecto"][&"requerida"] == true,
		"Los metadatos deben copiarse en profundidad."
	)
	_comprobar(
		contexto.costes_solicitados[&"energia"] == 2.0,
		"Los costes solicitados deben copiarse."
	)


func _probar_coordenadas_opcionales() -> void:
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.FIN_TURNO)

	_comprobar(contexto.origen == null, "El origen debe ser opcional.")
	_comprobar(contexto.celda_objetivo == null, "La celda objetivo debe ser opcional.")
	_comprobar(not contexto.tiene_origen(), "Un contexto global no debe declarar origen.")
	_comprobar(
		not contexto.tiene_celda_objetivo(),
		"Un contexto global no debe declarar celda objetivo."
	)
	_comprobar(
		contexto.alcance_maximo == -1.0,
		"El alcance negativo debe representar que no corresponde validarlo."
	)
	_comprobar(
		contexto.tipo_linea_efecto == TiposInteraccion.TipoLineaEfecto.NINGUNA,
		"Una acción global no debe requerir línea de efecto por defecto."
	)
	_comprobar(
		contexto.politica_cobro == TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		"SOLO_EXITO debe ser la política predeterminada."
	)
	_comprobar(
		contexto.solicitud_examen == null,
		"Las acciones que no examinan no deben requerir una solicitud de examen."
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
