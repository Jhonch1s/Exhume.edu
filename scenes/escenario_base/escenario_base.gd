extends Node2D

signal opcion_contextual_seleccionada(opcion: OpcionAccion)
signal accion_contextual_finalizada(
	opcion: OpcionAccion,
	contexto: ContextoAccion,
	resultado: ResultadoAccion
)
signal estado_modal_interaccion_cambiado(activo: bool)

@onready var zona_actual: Node2D = $Zona1
@onready var capa_selector: TileMapLayer = $CapaSelector
@onready var panel_resultado_accion: PanelResultadoAccion = (
	$CanvasLayer/PanelResultadoAccion
)
@onready var menu_contextual: MenuContextualInteracciones = (
	$CanvasLayer/MenuContextualInteracciones
)
@onready var camera_2d: Camera2D = $Camera2D
@onready var capa_camino: TileMapLayer = $CapaCamino
@onready var gestor_vision: FOVManager = $GestorVision
@onready var capa_oscuridad: TileMapLayer = $Zona1/CapaOscuridad

const ESCENA_FICHA = preload("res://scenes/ficha/ficha.tscn")

@export var catalogo_mensajes: CatalogoMensajesInteraccion

var tablero: TableroGrid = TableroGrid.new()
var pathfinding: PathFindingManager = PathFindingManager.new()
var gestor_acciones: GestorAcciones = GestorAcciones.new()
var registro_conocimiento: RegistroConocimiento = RegistroConocimiento.new()
var servicio_examen: ServicioExamen
var ficha_jugador: Ficha = null
var selector_objetivos: SelectorObjetivosInteraccion = SelectorObjetivosInteraccion.new()
var adaptador_menu_contextual: AdaptadorMenuContextual = AdaptadorMenuContextual.new()
var constructor_contexto_accion: ConstructorContextoAccion = ConstructorContextoAccion.new()
var ultima_coordenada_hover: Vector2i = Vector2i(-999, -999)
var objetivos_hover: Array[Interactuable] = []
var objetivo_hover: Interactuable = null
var objetivo_resaltado: Interactuable = null
var ultima_opcion_contextual_seleccionada: OpcionAccion = null
var ultimo_contexto_contextual: ContextoAccion = null
var ultimo_resultado_contextual: ResultadoAccion = null
var interaccion_modal_activa: bool = false
var estado_seleccion_objetivos: EstadoSeleccionObjetivos = EstadoSeleccionObjetivos.new()
var objetivos_pendientes_seleccion: Array[Interactuable]:
	get:
		return estado_seleccion_objetivos.objetivos_pendientes.duplicate()
var objetivo_seleccionado: Interactuable:
	get:
		return estado_seleccion_objetivos.objetivo_seleccionado
var celda_seleccionada: Variant:
	get:
		return estado_seleccion_objetivos.celda_seleccionada
var camino_actual_tentativo: Array[Vector2i] = []

func _ready() -> void:
	menu_contextual.opcion_accion_elegida.connect(_on_opcion_contextual_elegida)
	menu_contextual.objetivo_elegido.connect(_on_objetivo_contextual_elegido)
	menu_contextual.cancelado.connect(_on_menu_contextual_cancelado)
	panel_resultado_accion.resultado_presentado.connect(_on_resultado_accion_presentado)
	panel_resultado_accion.cerrado.connect(_on_panel_resultado_cerrado)
	add_child(gestor_acciones)
	tablero.generar_desde_zona(zona_actual)
	servicio_examen = ServicioExamen.new(tablero, registro_conocimiento)
	tablero.configurar_servicio_examen(servicio_examen)
	gestor_acciones.configurar_validador_espacial(ValidadorEspacialTablero.new(tablero))
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo:
		tablero.registrar_interactuables_desde_zona(zona_actual, capa_suelo)
	pathfinding.inicializar(tablero.datos)
	gestor_vision.inicializar(capa_oscuridad, tablero)
	spawnear_ficha_inicial()
	if ficha_jugador:
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)

func _process(_delta: float) -> void:
	centrar_camara_en_ficha()
	if ficha_jugador and ficha_jugador.esta_moviendose:
		capa_selector.clear()
		capa_camino.clear()
		_limpiar_hover_interaccion()
		ultima_coordenada_hover = Vector2i(-999, -999)
		return
	if interaccion_modal_activa:
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
		return

	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if not capa_suelo or not ficha_jugador:
		return
	var coord_actual := capa_suelo.local_to_map(get_global_mouse_position())
	if coord_actual == ultima_coordenada_hover:
		return
	_actualizar_hover_interaccion(coord_actual)
	capa_selector.clear()
	if tablero.es_celda_valida(coord_actual):
		capa_selector.set_cell(coord_actual, 0, Vector2i(1, 1))
		camino_actual_tentativo = pathfinding.calcular_camino(
			ficha_jugador.coordenada_mapa,
			coord_actual,
			tablero.datos
		)
		pathfinding.dibujar_trayectoria(camino_actual_tentativo, capa_camino)
	else:
		camino_actual_tentativo.clear()
		capa_camino.clear()
	ultima_coordenada_hover = coord_actual

func _unhandled_input(event: InputEvent) -> void:
	if interaccion_modal_activa:
		if event.is_action_pressed(&"ui_cancel"):
			if is_instance_valid(menu_contextual) and menu_contextual.visible:
				_cerrar_menu_contextual()
			elif (
				is_instance_valid(panel_resultado_accion)
				and panel_resultado_accion.visible
			):
				panel_resultado_accion.ocultar()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton or not event.pressed:
		return
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if not capa_suelo:
		return
	var coord_clic := capa_suelo.local_to_map(get_global_mouse_position())
	if event.button_index == MOUSE_BUTTON_LEFT:
		_manejar_clic_izquierdo(coord_clic)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_manejar_clic_derecho(coord_clic)

func _manejar_clic_izquierdo(coord: Vector2i) -> void:
	if (
		ficha_jugador == null
		or ficha_jugador.esta_moviendose
		or interaccion_modal_activa
	):
		return
	if not _solicitar_interaccion_en_celda(coord):
		_cerrar_menu_contextual()
		return
	_abrir_menu_contextual(get_viewport().get_mouse_position())

func _manejar_clic_derecho(coord: Vector2i) -> void:
	if not ficha_jugador:
		return
	if interaccion_modal_activa:
		return
	if ficha_jugador.esta_moviendose:
		# Se interrumpe al terminar el paso en curso, nunca entre dos celdas.
		ficha_jugador.solicitar_interrupcion()
		return
	if not tablero.puede_entrar(coord, ficha_jugador):
		return
	_cerrar_menu_contextual()

	# La linea dibujada es tentativa: al confirmar se calcula una ruta nueva.
	var camino_confirmado := pathfinding.calcular_camino(
		ficha_jugador.coordenada_mapa,
		coord,
		tablero.datos
	)
	if camino_confirmado.size() <= 1:
		print("No te puedes mover ahi")
		return

	capa_camino.clear()
	ficha_jugador.mover_por_camino(
		camino_confirmado,
		_preparar_paso_ficha,
		_confirmar_paso_ficha,
		_cancelar_paso_ficha
	)

func _preparar_paso_ficha(_origen: Vector2i, destino: Vector2i, ficha: Ficha) -> bool:
	return tablero.reservar_celda(destino, ficha)

func _confirmar_paso_ficha(origen: Vector2i, destino: Vector2i, ficha: Ficha) -> bool:
	return tablero.confirmar_movimiento(origen, destino, ficha)

func _cancelar_paso_ficha(destino: Vector2i, ficha: Ficha) -> void:
	tablero.cancelar_reserva(destino, ficha)

func spawnear_ficha_inicial() -> void:
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if not capa_suelo:
		return
	var coord_inicio := Vector2i(-999, -999)
	for coord in tablero.datos:
		if tablero.puede_entrar(coord):
			coord_inicio = coord
			break
	if coord_inicio == Vector2i(-999, -999):
		return
	ficha_jugador = ESCENA_FICHA.instantiate()
	zona_actual.add_child(ficha_jugador)
	ficha_jugador.inicializar(coord_inicio, capa_suelo)
	ficha_jugador.paso_dado.connect(_on_ficha_paso_dado)
	tablero.ocupar_celda(coord_inicio, ficha_jugador)

func _on_ficha_paso_dado(nueva_coord: Vector2i) -> void:
	ficha_jugador.pasos_antorcha_actual -= 1
	if ficha_jugador.pasos_antorcha_actual <= 0:
		var tiene_luz := ficha_jugador.consumir_o_recargar_antorcha()
		if not tiene_luz:
			print("El jugador se ha quedado completamente a oscuras.")
	_actualizar_luz_jugador(nueva_coord)

func _actualizar_luz_jugador(coordenada: Vector2i) -> void:
	if ficha_jugador.pasos_antorcha_actual <= 0 and ficha_jugador.antorchas <= 0:
		gestor_vision.actualizar_vision(coordenada, 1)
		return
	var radio_actual: float = 5.0
	if ficha_jugador.pasos_antorcha_actual <= 10:
		var porcentaje_final := float(max(0, ficha_jugador.pasos_antorcha_actual)) / 10.0
		radio_actual = max(1.0, porcentaje_final * 5.0)
	gestor_vision.actualizar_vision(coordenada, int(radio_actual))

func centrar_camara_en_ficha() -> void:
	if ficha_jugador and camera_2d:
		camera_2d.global_position = ficha_jugador.global_position

func _actualizar_hover_interaccion(coord: Vector2i) -> void:
	objetivos_hover = selector_objetivos.obtener_objetivos_perceptibles(
		tablero,
		coord,
		ficha_jugador
	)
	objetivo_hover = objetivos_hover[0] if objetivos_hover.size() == 1 else null
	_actualizar_resaltado_interaccion()


func _limpiar_hover_interaccion() -> void:
	objetivos_hover.clear()
	objetivo_hover = null
	_actualizar_resaltado_interaccion()


func _solicitar_interaccion_en_celda(coord: Vector2i) -> bool:
	var objetivos := selector_objetivos.obtener_objetivos_perceptibles(
		tablero,
		coord,
		ficha_jugador
	)
	var iniciada := estado_seleccion_objetivos.iniciar(coord, objetivos)
	_actualizar_resaltado_interaccion()
	return iniciada


func seleccionar_objetivo_interaccion(objetivo: Interactuable) -> bool:
	var seleccion_valida := estado_seleccion_objetivos.seleccionar(objetivo)
	_actualizar_resaltado_interaccion()
	return seleccion_valida


func _limpiar_seleccion_interaccion() -> void:
	estado_seleccion_objetivos.limpiar()
	_actualizar_resaltado_interaccion()


func _actualizar_resaltado_interaccion() -> void:
	var siguiente := objetivo_seleccionado if objetivo_seleccionado != null else objetivo_hover
	if objetivo_resaltado == siguiente:
		return
	if is_instance_valid(objetivo_resaltado):
		objetivo_resaltado.establecer_resaltado(false)
	objetivo_resaltado = siguiente if is_instance_valid(siguiente) else null
	if objetivo_resaltado != null:
		objetivo_resaltado.establecer_resaltado(true)


func _abrir_menu_contextual(posicion_pantalla: Vector2) -> void:
	if objetivo_seleccionado != null:
		var opciones := objetivo_seleccionado.obtener_opciones_accion(ficha_jugador)
		menu_contextual.mostrar(
			objetivo_seleccionado.definicion.nombre,
			adaptador_menu_contextual.construir_entradas_acciones(
				opciones,
				catalogo_mensajes
			),
			posicion_pantalla
		)
		_actualizar_estado_modal_interaccion()
		return
	if not objetivos_pendientes_seleccion.is_empty():
		menu_contextual.mostrar(
			catalogo_mensajes.resolver(&"interaccion.seleccionar_objetivo"),
			adaptador_menu_contextual.construir_entradas_objetivos(
				objetivos_pendientes_seleccion,
				catalogo_mensajes
			),
			posicion_pantalla
		)
		_actualizar_estado_modal_interaccion()


func _on_objetivo_contextual_elegido(objetivo: Interactuable) -> void:
	if seleccionar_objetivo_interaccion(objetivo):
		_abrir_menu_contextual(menu_contextual.position)


func _on_opcion_contextual_elegida(opcion: OpcionAccion) -> void:
	ultima_opcion_contextual_seleccionada = opcion
	opcion_contextual_seleccionada.emit(opcion)
	_ejecutar_opcion_contextual(opcion)


func _ejecutar_opcion_contextual(opcion: OpcionAccion) -> void:
	var contexto: ContextoAccion = null
	var resultado: ResultadoAccion
	if opcion == null or not opcion.habilitada:
		var motivo := (
			opcion.motivo_bloqueo if opcion != null
			else &"opcion_accion_invalida"
		)
		resultado = ResultadoAccion.crear_bloqueo(motivo)
	elif not celda_seleccionada is Vector2i:
		resultado = ResultadoAccion.crear_bloqueo(&"celda_objetivo_invalida")
	else:
		var coordenada_objetivo: Vector2i = celda_seleccionada
		var construccion: Variant = constructor_contexto_accion.construir_desde_opcion(
			opcion,
			ficha_jugador,
			ficha_jugador.coordenada_mapa,
			coordenada_objetivo
		)
		if construccion is ContextoAccion:
			contexto = construccion
			resultado = gestor_acciones.procesar_accion(contexto)
		else:
			var motivo_construccion: StringName = construccion
			resultado = ResultadoAccion.crear_bloqueo(motivo_construccion)

	ultimo_contexto_contextual = contexto
	ultimo_resultado_contextual = resultado
	var titulo_resultado := _obtener_titulo_resultado_contextual(opcion)
	menu_contextual.ocultar()
	panel_resultado_accion.mostrar_resultado(
		titulo_resultado,
		resultado,
		catalogo_mensajes
	)
	accion_contextual_finalizada.emit(opcion, contexto, resultado)


func _on_menu_contextual_cancelado() -> void:
	_cerrar_menu_contextual()


func _cerrar_menu_contextual() -> void:
	if is_instance_valid(menu_contextual):
		menu_contextual.ocultar()
	ultima_opcion_contextual_seleccionada = null
	_limpiar_seleccion_interaccion()
	ultima_coordenada_hover = Vector2i(-999, -999)
	_actualizar_estado_modal_interaccion()


func _on_resultado_accion_presentado(_resultado: ResultadoAccion) -> void:
	_actualizar_estado_modal_interaccion()


func _on_panel_resultado_cerrado() -> void:
	if not menu_contextual.visible:
		_limpiar_seleccion_interaccion()
	ultima_coordenada_hover = Vector2i(-999, -999)
	_actualizar_estado_modal_interaccion()


func _obtener_titulo_resultado_contextual(opcion: OpcionAccion) -> String:
	if (
		opcion != null
		and opcion.objetivo is Interactuable
		and is_instance_valid(opcion.objetivo)
		and opcion.objetivo.definicion != null
		and not opcion.objetivo.definicion.nombre.is_empty()
	):
		return opcion.objetivo.definicion.nombre
	return "Interacción"


func _actualizar_estado_modal_interaccion() -> void:
	var siguiente := (
		(is_instance_valid(menu_contextual) and menu_contextual.visible)
		or (
			is_instance_valid(panel_resultado_accion)
			and panel_resultado_accion.visible
		)
	)
	if interaccion_modal_activa == siguiente:
		return
	interaccion_modal_activa = siguiente
	if interaccion_modal_activa:
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
	estado_modal_interaccion_cambiado.emit(interaccion_modal_activa)
