extends SceneTree

const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)

var _fallos: Array[String] = []


func _init() -> void:
	_probar_actor_incompatible()
	_probar_coste_no_soportado()
	_probar_energia_fraccionaria()
	_probar_energia_insuficiente()
	_probar_integracion_y_cobro_exacto()

	if _fallos.is_empty():
		print("ProveedorCostesFicha: 5 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_actor_incompatible() -> void:
	var proveedor := ProveedorCostesFicha.new()
	var contexto := _crear_contexto(
		RefCounted.new(),
		ReceptorAccionesPrueba.new(),
		{&"energia": 1.0}
	)
	_comprobar(
		proveedor.validar_costes(contexto) == &"actor_no_es_ficha",
		"El adaptador debe rechazar actores que no sean Ficha."
	)


func _probar_coste_no_soportado() -> void:
	var ficha := Ficha.new()
	var proveedor := ProveedorCostesFicha.new()
	var contexto := _crear_contexto(
		ficha,
		ReceptorAccionesPrueba.new(),
		{&"turno": 1.0}
	)
	_comprobar(
		proveedor.validar_costes(contexto) == &"coste_no_soportado",
		"El adaptador no debe ignorar claves que todavía no soporta."
	)
	_comprobar(ficha.energia_actual == 200, "Validar otra clave no debe consumir energía.")
	ficha.free()


func _probar_energia_fraccionaria() -> void:
	var ficha := Ficha.new()
	var proveedor := ProveedorCostesFicha.new()
	var contexto := _crear_contexto(
		ficha,
		ReceptorAccionesPrueba.new(),
		{&"energia": 0.5}
	)
	_comprobar(
		proveedor.validar_costes(contexto) == &"coste_energia_no_entero",
		"La energía entera de Ficha debe rechazar costes fraccionarios."
	)
	_comprobar(ficha.energia_actual == 200, "Validar una fracción no debe consumir.")
	ficha.free()


func _probar_energia_insuficiente() -> void:
	var ficha := Ficha.new()
	ficha.energia_actual = 1
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := _crear_gestor()
	var resultado := gestor.procesar_accion(
		_crear_contexto(ficha, receptor, {&"energia": 2.0})
	)

	_comprobar(resultado.motivo == &"costes_insuficientes", "Debe bloquear sin energía.")
	_comprobar(ficha.energia_actual == 1, "Un bloqueo no debe consumir energía.")
	_comprobar(not receptor.fue_examinado, "Un coste insuficiente no debe resolver.")
	gestor.free()
	ficha.free()


func _probar_integracion_y_cobro_exacto() -> void:
	var ficha := Ficha.new()
	ficha.energia_actual = 3
	var receptor := ReceptorAccionesPrueba.new()
	var gestor := _crear_gestor()
	var resultado := gestor.procesar_accion(
		_crear_contexto(ficha, receptor, {&"energia": 2.0})
	)

	_comprobar(resultado.exitosa, "La energía suficiente debe permitir resolver.")
	_comprobar(receptor.fue_examinado, "El receptor debe resolverse con energía suficiente.")
	_comprobar(ficha.energia_actual == 1, "Debe descontar exactamente dos unidades.")
	_comprobar(
		resultado.costes_consumidos[&"energia"] == 2.0,
		"El resultado final debe registrar la energía cobrada."
	)
	gestor.free()
	ficha.free()


func _crear_gestor() -> GestorAcciones:
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	return gestor


func _crear_contexto(
	actor: Object,
	objetivo: Object,
	costes: Dictionary[StringName, float]
) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		actor,
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
		costes
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
