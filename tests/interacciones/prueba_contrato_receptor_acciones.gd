extends SceneTree

const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)

var _fallos: Array[String] = []


func _init() -> void:
	_probar_protocolo_y_examen()
	_probar_rechazo_sin_mutacion()

	if _fallos.is_empty():
		print("ContratoReceptorAcciones: 2 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_protocolo_y_examen() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		Vector2i(2, 2),
		Vector2i(3, 2),
		receptor,
		null,
		&"",
		[],
		{},
		1.0
	)

	_comprobar(
		receptor.has_method(&"validar_accion"),
		"Un receptor debe implementar validar_accion()."
	)
	_comprobar(
		receptor.has_method(&"resolver_accion"),
		"Un receptor debe implementar resolver_accion()."
	)
	_comprobar(
		receptor.validar_accion(contexto) == &"",
		"El receptor debe aceptar un contexto EXAMINAR dirigido a él."
	)
	_comprobar(
		receptor.validar_accion(contexto) == &"",
		"Validar varias veces debe producir el mismo resultado."
	)
	_comprobar(
		not receptor.fue_examinado,
		"La validación no debe modificar el estado del receptor."
	)

	var resultado: ResultadoAccion = receptor.resolver_accion(contexto)
	_comprobar(resultado.exitosa, "Resolver EXAMINAR debe devolver éxito.")
	_comprobar(receptor.fue_examinado, "Resolver debe modificar el estado de prueba.")
	_comprobar(
		resultado.mensajes == [&"examinar.objetivo_observado"],
		"La resolución debe devolver un mensaje estructurado."
	)
	_comprobar(
		resultado.cambios_estado.size() == 1,
		"La resolución debe registrar su cambio de estado."
	)


func _probar_rechazo_sin_mutacion() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var contexto_no_admitido := ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		RefCounted.new(),
		null,
		null,
		receptor
	)
	var contexto_otro_objetivo := ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		null,
		null,
		RefCounted.new()
	)

	_comprobar(
		receptor.validar_accion(contexto_no_admitido) == &"accion_no_admitida",
		"Debe explicar el rechazo de un tipo de acción no admitido."
	)
	_comprobar(
		receptor.validar_accion(contexto_otro_objetivo) == &"objetivo_no_coincide",
		"Debe explicar cuando el contexto apunta a otro objetivo."
	)
	_comprobar(
		not receptor.fue_examinado,
		"Rechazar contextos no debe modificar el estado del receptor."
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
