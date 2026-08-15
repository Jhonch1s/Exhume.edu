extends SceneTree

const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)

class ReceptorContratoInvalido extends RefCounted:
	func validar_accion(_contexto: ContextoAccion) -> bool:
		return true

	func resolver_accion(_contexto: ContextoAccion) -> ResultadoAccion:
		return ResultadoAccion.crear_exito()


class ReceptorResultadoInvalido extends RefCounted:
	func validar_accion(_contexto: ContextoAccion) -> StringName:
		return &""

	func resolver_accion(_contexto: ContextoAccion) -> Variant:
		return null


var _fallos: Array[String] = []
var _eventos: Array[StringName] = []
var _gestor: GestorAcciones


func _init() -> void:
	_gestor = GestorAcciones.new()
	root.add_child(_gestor)
	_gestor.accion_iniciada.connect(_on_accion_iniciada)
	_gestor.accion_resuelta.connect(_on_accion_resuelta)
	_gestor.accion_finalizada.connect(_on_accion_finalizada)

	_probar_examen_exitoso()
	_probar_contexto_y_actor_invalidos()
	_probar_alcance()
	_probar_objetivo_sin_protocolo()
	_probar_rechazo_del_receptor()
	_probar_contratos_invalidos()

	if _fallos.is_empty():
		print("GestorAcciones: 6 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_examen_exitoso() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var contexto := _crear_contexto(receptor)
	_eventos.clear()

	var resultado := _gestor.procesar_accion(contexto)

	_comprobar(resultado.exitosa, "EXAMINAR un receptor válido debe tener éxito.")
	_comprobar(receptor.fue_examinado, "Una resolución válida debe alcanzar al receptor.")
	_comprobar_ciclo_completo("éxito")


func _probar_contexto_y_actor_invalidos() -> void:
	_eventos.clear()
	var sin_contexto := _gestor.procesar_accion(null)
	_comprobar(
		sin_contexto.motivo == &"contexto_invalido",
		"Un contexto nulo debe bloquearse con un motivo comprensible."
	)
	_comprobar(
		_eventos.is_empty(),
		"No puede iniciarse un ciclo de señales sin un contexto."
	)

	var receptor := ReceptorAccionesPrueba.new()
	var sin_actor := ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		null,
		Vector2i.ZERO,
		Vector2i(1, 0),
		receptor,
		null,
		&"",
		[],
		{},
		1.0
	)
	_eventos.clear()
	var resultado := _gestor.procesar_accion(sin_actor)
	_comprobar(resultado.motivo == &"actor_invalido", "Debe validar el actor.")
	_comprobar(not receptor.fue_examinado, "Un actor inválido no debe alcanzar al receptor.")
	_comprobar_ciclo_completo("actor inválido")


func _probar_alcance() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var contexto := _crear_contexto(
		receptor,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(2, 0),
		1.0
	)
	_eventos.clear()
	var resultado := _gestor.procesar_accion(contexto)

	_comprobar(resultado.motivo == &"fuera_de_alcance", "Debe validar el alcance.")
	_comprobar(not receptor.fue_examinado, "Estar fuera de alcance no debe resolver.")
	_comprobar_ciclo_completo("fuera de alcance")


func _probar_objetivo_sin_protocolo() -> void:
	var objetivo := RefCounted.new()
	var contexto := _crear_contexto(objetivo)
	_eventos.clear()
	var resultado := _gestor.procesar_accion(contexto)

	_comprobar(
		resultado.motivo == &"objetivo_no_es_receptor",
		"Debe rechazar un objetivo que no implemente el protocolo."
	)
	_comprobar_ciclo_completo("objetivo sin protocolo")


func _probar_rechazo_del_receptor() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(1, 0),
		receptor,
		null,
		&"accionar",
		[],
		{},
		1.0
	)
	_eventos.clear()
	var resultado := _gestor.procesar_accion(contexto)

	_comprobar(
		resultado.motivo == &"accion_no_admitida",
		"Debe conservar el motivo devuelto por el receptor."
	)
	_comprobar(not receptor.fue_examinado, "Un rechazo no debe resolver la acción.")
	_comprobar_ciclo_completo("rechazo del receptor")


func _probar_contratos_invalidos() -> void:
	var receptor_validacion := ReceptorContratoInvalido.new()
	_eventos.clear()
	var resultado_validacion := _gestor.procesar_accion(_crear_contexto(receptor_validacion))
	_comprobar(
		resultado_validacion.motivo == &"contrato_receptor_invalido",
		"Debe detectar un retorno inválido de validar_accion()."
	)
	_comprobar_ciclo_completo("contrato de validación inválido")

	var receptor_resultado := ReceptorResultadoInvalido.new()
	_eventos.clear()
	var resultado_resolucion := _gestor.procesar_accion(_crear_contexto(receptor_resultado))
	_comprobar(
		resultado_resolucion.motivo == &"resultado_receptor_invalido",
		"Debe detectar un retorno inválido de resolver_accion()."
	)
	_comprobar(
		resultado_resolucion.estado == TiposInteraccion.EstadoResolucion.FALLO,
		"Un contrato roto durante la resolución debe producir FALLO."
	)
	_comprobar_ciclo_completo("resultado de receptor inválido")


func _crear_contexto(
	objetivo: Object,
	actor: Object = null,
	origen: Vector2i = Vector2i.ZERO,
	destino: Vector2i = Vector2i(1, 0),
	alcance: float = 1.0
) -> ContextoAccion:
	var actor_contexto: Object = actor if actor != null else RefCounted.new()
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		actor_contexto,
		origen,
		destino,
		objetivo,
		null,
		&"",
		[],
		{},
		alcance
	)


func _comprobar_ciclo_completo(caso: String) -> void:
	_comprobar(
		_eventos == [&"iniciada", &"resuelta", &"finalizada"],
		"El ciclo de señales debe ser único y ordenado para: %s." % caso
	)


func _on_accion_iniciada(_contexto: ContextoAccion) -> void:
	_eventos.append(&"iniciada")


func _on_accion_resuelta(
	_contexto: ContextoAccion,
	_resultado: ResultadoAccion
) -> void:
	_eventos.append(&"resuelta")


func _on_accion_finalizada(
	_contexto: ContextoAccion,
	_resultado: ResultadoAccion
) -> void:
	_eventos.append(&"finalizada")


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
