extends SceneTree

const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)
const ProveedorCostesPrueba = preload(
	"res://tests/interacciones/dobles/proveedor_costes_prueba.gd"
)

class ReceptorFalloPrueba extends RefCounted:
	func validar_accion(_contexto: ContextoAccion) -> StringName:
		return &""

	func resolver_accion(_contexto: ContextoAccion) -> ResultadoAccion:
		return ResultadoAccion.crear_fallo(&"inspeccion_inconclusa")


class ProveedorConsumoInvalido extends RefCounted:
	func validar_costes(_contexto: ContextoAccion) -> StringName:
		return &""

	func consumir_costes(_contexto: ContextoAccion) -> Variant:
		return null


var _fallos: Array[String] = []
var _costes_al_resolver: Dictionary[StringName, float] = {}
var _costes_al_finalizar: Dictionary[StringName, float] = {}


func _init() -> void:
	_probar_servicio_no_requerido()
	_probar_servicio_ausente()
	_probar_costes_invalidos()
	_probar_costes_insuficientes()
	_probar_cobro_exitoso_y_señales()
	_probar_politicas_ante_fallo()
	_probar_consumo_invalido()

	if _fallos.is_empty():
		print("ServicioCostesAcciones: 7 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_servicio_no_requerido() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := _crear_gestor()
	var resultado := gestor.procesar_accion(_crear_contexto(receptor))

	_comprobar(resultado.exitosa, "Una acción sin costes no debe exigir proveedor.")
	gestor.queue_free()


func _probar_servicio_ausente() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := _crear_gestor()
	var resultado := gestor.procesar_accion(_crear_contexto_con_coste(receptor))

	_comprobar(
		resultado.motivo == &"proveedor_costes_no_configurado",
		"Debe explicar cuando falta un proveedor requerido."
	)
	_comprobar(not receptor.fue_examinado, "No debe resolver sin proveedor.")
	gestor.queue_free()


func _probar_costes_insuficientes() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var proveedor := ProveedorCostesPrueba.new({&"energia": 1.0})
	var gestor := _crear_gestor(proveedor)
	var resultado := gestor.procesar_accion(
		_crear_contexto_con_coste(receptor, 2.0)
	)

	_comprobar(resultado.motivo == &"costes_insuficientes", "Debe validar recursos.")
	_comprobar(proveedor.recursos[&"energia"] == 1.0, "Validar no debe consumir.")
	_comprobar(not receptor.fue_examinado, "Un coste insuficiente no debe resolver.")
	gestor.queue_free()


func _probar_costes_invalidos() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var proveedor := ProveedorCostesPrueba.new({&"energia": 3.0})
	var gestor := _crear_gestor(proveedor)
	var resultado := gestor.procesar_accion(
		_crear_contexto_con_coste(receptor, -1.0)
	)

	_comprobar(resultado.motivo == &"costes_invalidos", "Debe rechazar costes negativos.")
	_comprobar(proveedor.recursos[&"energia"] == 3.0, "Un coste inválido no debe mutar.")
	_comprobar(not receptor.fue_examinado, "Un coste inválido no debe resolver.")
	gestor.queue_free()


func _probar_cobro_exitoso_y_señales() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var proveedor := ProveedorCostesPrueba.new({&"energia": 3.0})
	var gestor := _crear_gestor(proveedor)
	_costes_al_resolver.clear()
	_costes_al_finalizar.clear()
	gestor.accion_resuelta.connect(_on_accion_resuelta)
	gestor.accion_finalizada.connect(_on_accion_finalizada)
	var resultado := gestor.procesar_accion(
		_crear_contexto_con_coste(receptor, 2.0)
	)

	_comprobar(resultado.exitosa, "Un coste disponible debe permitir el éxito.")
	_comprobar(proveedor.recursos[&"energia"] == 1.0, "Debe consumir el coste exacto.")
	_comprobar(
		resultado.costes_consumidos[&"energia"] == 2.0,
		"El resultado final debe registrar el coste real."
	)
	_comprobar(
		_costes_al_resolver.is_empty(),
		"accion_resuelta debe observar el resultado previo al cobro."
	)
	_comprobar(
		_costes_al_finalizar[&"energia"] == 2.0,
		"accion_finalizada debe observar los costes confirmados."
	)
	gestor.queue_free()


func _probar_politicas_ante_fallo() -> void:
	var receptor_solo_exito := ReceptorFalloPrueba.new()
	var proveedor_solo_exito := ProveedorCostesPrueba.new({&"energia": 3.0})
	var gestor_solo_exito := _crear_gestor(proveedor_solo_exito)
	var resultado_solo_exito := gestor_solo_exito.procesar_accion(
		_crear_contexto_con_coste(receptor_solo_exito, 2.0)
	)
	_comprobar(
		resultado_solo_exito.estado == TiposInteraccion.EstadoResolucion.FALLO,
		"El receptor debe poder producir FALLO."
	)
	_comprobar(
		proveedor_solo_exito.recursos[&"energia"] == 3.0,
		"SOLO_EXITO no debe cobrar un fallo."
	)
	gestor_solo_exito.queue_free()

	var receptor_al_intentar := ReceptorFalloPrueba.new()
	var proveedor_al_intentar := ProveedorCostesPrueba.new({&"energia": 3.0})
	var gestor_al_intentar := _crear_gestor(proveedor_al_intentar)
	var resultado_al_intentar := gestor_al_intentar.procesar_accion(
		_crear_contexto_con_coste(
			receptor_al_intentar,
			2.0,
			TiposInteraccion.PoliticaCobro.AL_INTENTAR
		)
	)
	_comprobar(
		proveedor_al_intentar.recursos[&"energia"] == 1.0,
		"AL_INTENTAR debe cobrar un fallo resuelto."
	)
	_comprobar(
		resultado_al_intentar.costes_consumidos[&"energia"] == 2.0,
		"El fallo final debe registrar el coste cobrado."
	)
	gestor_al_intentar.queue_free()


func _probar_consumo_invalido() -> void:
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := _crear_gestor(ProveedorConsumoInvalido.new())
	var resultado := gestor.procesar_accion(_crear_contexto_con_coste(receptor))

	_comprobar(
		resultado.motivo == &"consumo_costes_invalido",
		"Debe detectar un retorno inválido durante el consumo."
	)
	_comprobar(
		resultado.estado == TiposInteraccion.EstadoResolucion.FALLO,
		"Un contrato de consumo roto debe producir FALLO."
	)
	gestor.queue_free()


func _crear_gestor(proveedor: Object = null) -> GestorAcciones:
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	if proveedor != null:
		gestor.configurar_proveedor_costes(proveedor)
	return gestor


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


func _crear_contexto_con_coste(
	objetivo: Object,
	energia: float = 1.0,
	politica: TiposInteraccion.PoliticaCobro = TiposInteraccion.PoliticaCobro.SOLO_EXITO
) -> ContextoAccion:
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
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{&"energia": energia},
		politica
	)


func _on_accion_resuelta(
	_contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> void:
	_costes_al_resolver = resultado.costes_consumidos


func _on_accion_finalizada(
	_contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> void:
	_costes_al_finalizar = resultado.costes_consumidos


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
