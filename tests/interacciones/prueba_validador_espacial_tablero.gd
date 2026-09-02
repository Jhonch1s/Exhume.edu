extends SceneTree

const ReceptorAccionesPrueba = preload(
	"res://tests/interacciones/dobles/receptor_acciones_prueba.gd"
)

var _fallos: Array[String] = []


func _init() -> void:
	_probar_geometria_compartida()
	_probar_linea_visual_despejada()
	_probar_obstaculo_intermedio()
	_probar_esquina_visual()
	_probar_destino_opaco()
	_probar_hueco_y_extremos_invalidos()
	_probar_configuracion_y_linea_fisica()
	_probar_integracion_con_gestor()

	if _fallos.is_empty():
		print("ValidadorEspacialTablero: 8 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_geometria_compartida() -> void:
	_comprobar(
		GeometriaGrid.trazar_linea(Vector2i.ZERO, Vector2i(3, 0))
		== [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"Bresenham debe conservar una línea horizontal completa."
	)
	_comprobar(
		GeometriaGrid.trazar_linea(Vector2i.ZERO, Vector2i(2, 2))
		== [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)],
		"Bresenham debe conservar una diagonal completa."
	)
	_comprobar(
		GeometriaGrid.trazar_linea(Vector2i(2, 1), Vector2i(2, 1))
		== [Vector2i(2, 1)],
		"Una línea sin desplazamiento debe contener una sola celda."
	)
	_comprobar(
		GeometriaGrid.flancos_paso_diagonal(Vector2i.ZERO, Vector2i.ONE)
		== [Vector2i.RIGHT, Vector2i.DOWN],
		"Un paso diagonal debe exponer sus dos flancos ortogonales."
	)


func _probar_linea_visual_despejada() -> void:
	var tablero := _crear_tablero_lineal(4)
	var validador := ValidadorEspacialTablero.new(tablero)
	var motivo := validador.validar_linea_efecto(
		_crear_contexto_visual(RefCounted.new(), Vector2i.ZERO, Vector2i(3, 0))
	)

	_comprobar(motivo == &"", "Una línea visual despejada debe aceptarse.")
	tablero.free()


func _probar_obstaculo_intermedio() -> void:
	var tablero := _crear_tablero_lineal(4)
	tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision = true
	var validador := ValidadorEspacialTablero.new(tablero)
	var motivo := validador.validar_linea_efecto(
		_crear_contexto_visual(RefCounted.new(), Vector2i.ZERO, Vector2i(3, 0))
	)

	_comprobar(
		motivo == &"linea_de_efecto_bloqueada",
		"Una celda intermedia opaca debe bloquear la línea visual."
	)
	tablero.free()


func _probar_esquina_visual() -> void:
	var tablero := TableroGrid.new()
	for coord in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
		tablero.datos[coord] = Celda.new()
	tablero.obtener_celda(Vector2i.RIGHT).bloquea_vision = true
	tablero.obtener_celda(Vector2i.DOWN).bloquea_vision = true
	var validador := ValidadorEspacialTablero.new(tablero)
	var contexto := _crear_contexto_visual(
		RefCounted.new(), Vector2i.ZERO, Vector2i.ONE
	)

	_comprobar(
		validador.validar_linea_efecto(contexto) == &"linea_de_efecto_bloqueada",
		"Dos paredes contiguas deben cerrar la visión en su esquina diagonal."
	)
	tablero.obtener_celda(Vector2i.DOWN).bloquea_vision = false
	_comprobar(
		validador.validar_linea_efecto(contexto) == &"",
		"Una sola pared debe permitir la visión diagonal por el lado abierto."
	)
	tablero.free()


func _probar_destino_opaco() -> void:
	var tablero := _crear_tablero_lineal(3)
	tablero.obtener_celda(Vector2i(2, 0)).bloquea_vision = true
	var validador := ValidadorEspacialTablero.new(tablero)
	var motivo := validador.validar_linea_efecto(
		_crear_contexto_visual(RefCounted.new(), Vector2i.ZERO, Vector2i(2, 0))
	)

	_comprobar(
		motivo == &"",
		"El destino debe poder examinarse aunque bloquee la visión detrás de él."
	)
	tablero.free()


func _probar_hueco_y_extremos_invalidos() -> void:
	var tablero_con_hueco := _crear_tablero_lineal(4)
	tablero_con_hueco.datos.erase(Vector2i(1, 0))
	var validador_hueco := ValidadorEspacialTablero.new(tablero_con_hueco)
	var motivo_hueco := validador_hueco.validar_linea_efecto(
		_crear_contexto_visual(RefCounted.new(), Vector2i.ZERO, Vector2i(3, 0))
	)
	_comprobar(
		motivo_hueco == &"linea_fuera_del_tablero",
		"Un hueco intermedio debe bloquear la validación espacial."
	)
	tablero_con_hueco.free()

	var tablero := _crear_tablero_lineal(2)
	var validador := ValidadorEspacialTablero.new(tablero)
	var motivo_extremo := validador.validar_linea_efecto(
		_crear_contexto_visual(RefCounted.new(), Vector2i.ZERO, Vector2i(4, 0))
	)
	_comprobar(
		motivo_extremo == &"celda_espacial_invalida",
		"Origen y destino deben pertenecer al tablero."
	)
	tablero.free()


func _probar_configuracion_y_linea_fisica() -> void:
	var contexto_visual := _crear_contexto_visual(
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(1, 0)
	)
	var sin_tablero := ValidadorEspacialTablero.new()
	_comprobar(
		sin_tablero.validar_linea_efecto(contexto_visual) == &"tablero_espacial_no_configurado",
		"El adaptador debe explicar cuando no tiene tablero."
	)

	var contexto_fisico := ContextoAccion.new(
		TiposInteraccion.TipoAccion.IMPACTAR,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(2, 0),
		RefCounted.new(),
		null,
		&"",
		[],
		{},
		3.0,
		{},
		TiposInteraccion.TipoLineaEfecto.FISICA
	)
	_comprobar(
		sin_tablero.validar_linea_efecto(contexto_fisico) == &"tablero_espacial_no_configurado",
		"La línea física también debe exigir un tablero."
	)
	var tablero := _crear_tablero_lineal(3)
	tablero.obtener_celda(Vector2i.RIGHT).altura = 2
	var validador := ValidadorEspacialTablero.new(tablero)
	var trayectoria := validador.resolver_trayectoria_lanzamiento(
		Vector2i.ZERO, Vector2i(2, 0), 3.0
	)
	_comprobar(
		validador.validar_linea_efecto(contexto_fisico) == &"linea_de_efecto_bloqueada",
		"El obstáculo intermedio debe bloquear la línea física."
	)
	_comprobar(
		trayectoria[&"hubo_colision"]
		and trayectoria[&"celda_impacto"] == Vector2i.RIGHT,
		"El primer obstáculo físico debe recibir el impacto."
	)
	_comprobar(
		trayectoria[&"celda_caida"] == Vector2i.ZERO,
		"La unidad debe caer en la celda anterior al obstáculo."
	)
	tablero.obtener_celda(Vector2i.RIGHT).altura = 0
	_comprobar(
		validador.validar_linea_efecto(contexto_fisico) == &"",
		"Una línea física despejada debe aceptarse."
	)
	tablero.free()


func _probar_integracion_con_gestor() -> void:
	var tablero := _crear_tablero_lineal(3)
	tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision = true
	var receptor_bloqueado := ReceptorAccionesPrueba.new()
	var gestor_bloqueado := GestorAcciones.new()
	root.add_child(gestor_bloqueado)
	gestor_bloqueado.configurar_validador_espacial(
		ValidadorEspacialTablero.new(tablero)
	)
	var resultado_bloqueado := gestor_bloqueado.procesar_accion(
		_crear_contexto_visual(receptor_bloqueado, Vector2i.ZERO, Vector2i(2, 0))
	)
	_comprobar(
		resultado_bloqueado.motivo == &"linea_de_efecto_bloqueada",
		"El gestor debe respetar el adaptador real del tablero."
	)
	_comprobar(
		not receptor_bloqueado.fue_examinado,
		"Una línea real bloqueada no debe resolver el receptor."
	)
	gestor_bloqueado.free()

	tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision = false
	var receptor_despejado := ReceptorAccionesPrueba.new()
	var gestor_despejado := GestorAcciones.new()
	root.add_child(gestor_despejado)
	gestor_despejado.configurar_validador_espacial(
		ValidadorEspacialTablero.new(tablero)
	)
	var resultado_despejado := gestor_despejado.procesar_accion(
		_crear_contexto_visual(receptor_despejado, Vector2i.ZERO, Vector2i(2, 0))
	)
	_comprobar(resultado_despejado.exitosa, "La línea real despejada debe resolver.")
	gestor_despejado.free()
	tablero.free()


func _crear_tablero_lineal(cantidad: int) -> TableroGrid:
	var tablero := TableroGrid.new()
	for x in range(cantidad):
		tablero.datos[Vector2i(x, 0)] = Celda.new()
	return tablero


func _crear_contexto_visual(
	objetivo: Object,
	origen: Vector2i,
	destino: Vector2i
) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		origen,
		destino,
		objetivo,
		null,
		&"",
		[],
		{},
		10.0,
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
