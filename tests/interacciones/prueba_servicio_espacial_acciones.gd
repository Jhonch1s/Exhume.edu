extends SceneTree

const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)
const ValidadorEspacialPrueba = preload(
	"res://tests/interacciones/dobles/validador_espacial_prueba.gd"
)

class ValidadorEspacialInvalido extends RefCounted:
	func validar_linea_efecto(_contexto: ContextoAccion) -> bool:
		return true


var _fallos: Array[String] = []


func _init() -> void:
	_probar_servicio_no_requerido()
	_probar_servicio_ausente_o_invalido()
	_probar_linea_bloqueada()
	_probar_linea_despejada()

	if _fallos.is_empty():
		print("ServicioEspacialAcciones: 4 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_servicio_no_requerido() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var resultado := gestor.procesar_accion(_crear_contexto(receptor))

	_comprobar(
		resultado.exitosa,
		"Una acción sin línea de efecto no debe exigir el servicio espacial."
	)
	gestor.queue_free()


func _probar_servicio_ausente_o_invalido() -> void:
	var receptor_sin_servicio := ReceptorAccionesPrueba.new()
	var gestor_sin_servicio := GestorAcciones.new()
	root.add_child(gestor_sin_servicio)
	var sin_servicio := gestor_sin_servicio.procesar_accion(
		_crear_contexto_visual(receptor_sin_servicio)
	)
	_comprobar(
		sin_servicio.motivo == &"validador_espacial_no_configurado",
		"Debe explicar cuando falta un servicio espacial requerido."
	)
	_comprobar(
		not receptor_sin_servicio.fue_examinado,
		"La ausencia del servicio no debe alcanzar al receptor."
	)
	gestor_sin_servicio.queue_free()

	var receptor_invalido := ReceptorAccionesPrueba.new()
	var gestor_invalido := GestorAcciones.new()
	root.add_child(gestor_invalido)
	gestor_invalido.configurar_validador_espacial(ValidadorEspacialInvalido.new())
	var contrato_invalido := gestor_invalido.procesar_accion(
		_crear_contexto_visual(receptor_invalido)
	)
	_comprobar(
		contrato_invalido.motivo == &"contrato_validador_espacial_invalido",
		"Debe detectar un retorno inválido del servicio espacial."
	)
	gestor_invalido.queue_free()


func _probar_linea_bloqueada() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	gestor.configurar_validador_espacial(
		ValidadorEspacialPrueba.new(&"linea_de_efecto_bloqueada")
	)
	var resultado := gestor.procesar_accion(_crear_contexto_visual(receptor))

	_comprobar(
		resultado.motivo == &"linea_de_efecto_bloqueada",
		"Debe conservar el motivo producido por el servicio espacial."
	)
	_comprobar(not receptor.fue_examinado, "Una línea bloqueada no debe resolver.")
	gestor.queue_free()


func _probar_linea_despejada() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	gestor.configurar_validador_espacial(ValidadorEspacialPrueba.new())
	var resultado := gestor.procesar_accion(_crear_contexto_visual(receptor))

	_comprobar(resultado.exitosa, "Una línea despejada debe permitir resolver.")
	_comprobar(receptor.fue_examinado, "La línea despejada debe alcanzar al receptor.")
	gestor.queue_free()


func _crear_contexto(objetivo: Object) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(1, 0),
		objetivo,
		null,
		&"",
		[],
		{},
		1.0
	)


func _crear_contexto_visual(objetivo: Object) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(1, 0),
		objetivo,
		null,
		&"",
		[],
		{},
		1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
