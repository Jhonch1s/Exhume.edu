extends SceneTree

const RegistroAccionesDesarrolloScript = preload(
	"res://scripts/interacciones/debug/registro_acciones_desarrollo.gd"
)
const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)
const ProveedorCostesPrueba = preload(
	"res://tests/interacciones/dobles/proveedor_costes_prueba.gd"
)

var _fallos: Array[String] = []


func _init() -> void:
	_probar_registro_de_accion_exitosa()
	_probar_desconexion_y_limpieza()

	if _fallos.is_empty():
		print("RegistroAccionesDesarrollo: 2 pruebas correctas.")
		quit()
		return

	for fallo: String in _fallos:
		push_error(fallo)
	quit(1)


func _probar_registro_de_accion_exitosa() -> void:
	var gestor := GestorAcciones.new()
	var registro := RegistroAccionesDesarrolloScript.new()
	registro.imprimir_en_consola = false
	root.add_child(gestor)
	root.add_child(registro)
	gestor.configurar_proveedor_costes(
		ProveedorCostesPrueba.new({&"energia": 3.0})
	)
	registro.observar_gestor(gestor)

	gestor.procesar_accion(_crear_contexto(ReceptorAccionesPrueba.new()))

	_comprobar(registro.entradas.size() == 3, "Debe registrar las tres etapas.")
	if registro.entradas.size() == 3:
		_comprobar(
			registro.entradas[0]
			== "[ACCION][INICIO] tipo=EXAMINAR origen=(0,0) destino=(1,0)",
			"La entrada de inicio debe describir el contexto."
		)
		_comprobar(
			registro.entradas[1]
			== "[ACCION][RESUELTA] estado=EXITO motivo=-",
			"La entrada resuelta debe describir el resultado del receptor."
		)
		_comprobar(
			registro.entradas[2]
			== "[ACCION][FIN] estado=EXITO costes={energia:1} interrupcion=false",
			"La entrada final debe incluir el coste confirmado."
		)

	registro.free()
	gestor.free()


func _probar_desconexion_y_limpieza() -> void:
	var gestor := GestorAcciones.new()
	var registro := RegistroAccionesDesarrolloScript.new()
	registro.imprimir_en_consola = false
	root.add_child(gestor)
	root.add_child(registro)
	registro.observar_gestor(gestor)
	registro.observar_gestor(null)

	gestor.procesar_accion(
		ContextoAccion.new(
			TiposInteraccion.TipoAccion.EXAMINAR,
			null,
			Vector2i.ZERO,
			Vector2i(1, 0),
			ReceptorAccionesPrueba.new()
		)
	)
	_comprobar(registro.entradas.is_empty(), "Desconectar debe detener el registro.")

	registro.entradas.append("temporal")
	registro.limpiar()
	_comprobar(registro.entradas.is_empty(), "Limpiar debe vaciar el historial.")

	registro.free()
	gestor.free()


func _crear_contexto(objetivo: Object) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(1, 0),
		objetivo,
		null,
		&"examinar_prueba",
		[],
		{},
		1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{&"energia": 1.0}
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
