extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var escena := load(
		"res://scenes/interactuables/fuentes_luz/fuente_luz_interactuable.tscn"
	) as PackedScene
	var fuente := escena.instantiate() as FuenteLuzInteractuable
	fuente.definicion = load(
		"res://assets/interactuables/luces/antorcha_pie.tres"
	) as DefinicionFuenteLuz
	fuente.id_instancia = &"fuente_constructor_prueba"
	fuente.coordenada_mapa = Vector2i(2, 2)
	root.add_child(fuente)
	var actor := Ficha.new()
	actor.id_observador = &"observador_constructor"
	root.add_child(actor)
	var constructor := ConstructorContextoAccion.new()
	var opciones := fuente.obtener_opciones_accion(actor)

	var examen: OpcionAccion = opciones[0]
	var contexto_examen: Variant = constructor.construir_desde_opcion(
		examen,
		actor,
		Vector2i(0, 2),
		fuente.coordenada_mapa
	)
	_comprobar(contexto_examen is ContextoAccion, "Examinar debe construir un contexto.")
	if contexto_examen is ContextoAccion:
		_comprobar(
			contexto_examen.tipo == TiposInteraccion.TipoAccion.EXAMINAR
			and contexto_examen.id_accion == &""
			and contexto_examen.alcance_maximo == 5.0
			and contexto_examen.tipo_linea_efecto == TiposInteraccion.TipoLineaEfecto.VISUAL,
			"El contexto de examen debe conservar alcance y línea visual."
		)
		_comprobar(
			contexto_examen.solicitud_examen != null
			and contexto_examen.solicitud_examen.id_observador == &"observador_constructor",
			"Examinar debe construir su SolicitudExamen tipada."
		)

	var interaccion: OpcionAccion = opciones[1]
	var contexto_interaccion: Variant = constructor.construir_desde_opcion(
		interaccion,
		actor,
		Vector2i(2, 1),
		fuente.coordenada_mapa
	)
	_comprobar(
		contexto_interaccion is ContextoAccion
		and contexto_interaccion.id_accion == interaccion.id
		and contexto_interaccion.alcance_maximo == 1.0
		and contexto_interaccion.solicitud_examen == null,
		"Encender o Apagar debe construir INTERACTUAR con adyacencia."
	)

	var celda_incorrecta: Variant = constructor.construir_desde_opcion(
		interaccion,
		actor,
		Vector2i(2, 1),
		Vector2i(3, 3)
	)
	_comprobar(
		celda_incorrecta == &"contrato_constructor_contexto_invalido",
		"El adaptador debe rechazar un contexto que el objetivo no pueda construir."
	)
	var opcion_nula: Variant = constructor.construir_desde_opcion(
		null,
		actor,
		Vector2i.ZERO,
		fuente.coordenada_mapa
	)
	_comprobar(
		opcion_nula == &"opcion_accion_invalida",
		"Una opción nula debe producir un motivo estable sin ejecutar."
	)

	actor.free()
	fuente.free()
	_finalizar()


func _finalizar() -> void:
	if _fallos.is_empty():
		print("ConstructorContextoAccion: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
