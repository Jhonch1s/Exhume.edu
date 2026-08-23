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
@onready var trayectoria_lanzamiento: Line2D = $TrayectoriaLanzamiento
@onready var gestor_vision: FOVManager = $GestorVision
@onready var capa_oscuridad: TileMapLayer = $Zona1/CapaOscuridad

const ESCENA_FICHA = preload("res://scenes/ficha/ficha.tscn")
const DEFINICION_PIEDRA = preload("res://assets/items/piedra/piedra.tres")
const DEFINICION_LLAVE_PRUEBA = preload("res://assets/items/llave_prueba/llave_prueba.tres")
const DEFINICION_BOMBA_HUMO = preload("res://assets/items/bomba_humo/bomba_humo.tres")
const RUTA_GUARDADO := "user://partida.json"
@export var catalogo_mensajes: CatalogoMensajesInteraccion
@export_range(0.02, 0.5, 0.01) var duracion_paso_lanzamiento: float = 0.08

var tablero: TableroGrid = TableroGrid.new()
var pathfinding: PathFindingManager = PathFindingManager.new()
var gestor_acciones: GestorAcciones = GestorAcciones.new()
var validador_espacial: ValidadorEspacialTablero
var consultor_reacciones: ConsultorReaccionesCelda = ConsultorReaccionesCelda.new()
var resolver_reacciones: ResolverReaccionesCelda
var servicio_turnos: ServicioTurnos
var procesador_superficies: ProcesadorSuperficies
var registro_conocimiento: RegistroConocimiento = RegistroConocimiento.new()
var servicio_examen: ServicioExamen
var ficha_jugador: Ficha = null
var transferidor_items: TransferidorItems
var selector_objetivos: SelectorObjetivosInteraccion = SelectorObjetivosInteraccion.new()
var adaptador_menu_contextual: AdaptadorMenuContextual = AdaptadorMenuContextual.new()
var constructor_contexto_accion: ConstructorContextoAccion = ConstructorContextoAccion.new()
var ultima_coordenada_hover: Vector2i = Vector2i(-999, -999)
var objetivos_hover: Array[Object] = []
var objetivo_hover: Object = null
var objetivo_resaltado: Object = null
var ultima_opcion_contextual_seleccionada: OpcionAccion = null
var opcion_uso_item_pendiente: OpcionAccion = null
var seleccionando_item_lanzamiento: bool = false
var item_lanzamiento_pendiente: ItemInstancia = null
var celda_lanzamiento_pendiente: Variant = null
var secuencia_items_lanzados: int = 0
var lanzamiento_en_vuelo: bool = false
var representacion_lanzamiento: Node2D = null
var ultimo_contexto_contextual: ContextoAccion = null
var ultimo_resultado_contextual: ResultadoAccion = null
var interaccion_modal_activa: bool = false
var estado_seleccion_objetivos: EstadoSeleccionObjetivos = EstadoSeleccionObjetivos.new()
var objetivos_pendientes_seleccion: Array[Object]:
	get:
		return estado_seleccion_objetivos.objetivos_pendientes.duplicate()
var objetivo_seleccionado: Object:
	get:
		return estado_seleccion_objetivos.objetivo_seleccionado
var celda_seleccionada: Variant:
	get:
		return estado_seleccion_objetivos.celda_seleccionada
var camino_actual_tentativo: Array[Vector2i] = []
var ultimo_resultado_salir: ResultadoReacciones
var ultimo_resultado_entrar: ResultadoReacciones
var en_combate: bool = false
var persistencia_partida := PersistenciaPartida.new()

func _ready() -> void:
	menu_contextual.opcion_accion_elegida.connect(_on_opcion_contextual_elegida)
	menu_contextual.objetivo_elegido.connect(_on_objetivo_contextual_elegido)
	menu_contextual.item_elegido.connect(_on_item_contextual_elegido)
	menu_contextual.impacto_elegido.connect(_on_impacto_contextual_elegido)
	menu_contextual.cancelado.connect(_on_menu_contextual_cancelado)
	panel_resultado_accion.resultado_presentado.connect(_on_resultado_accion_presentado)
	panel_resultado_accion.cerrado.connect(_on_panel_resultado_cerrado)
	add_child(gestor_acciones)
	resolver_reacciones = ResolverReaccionesCelda.new(gestor_acciones)
	servicio_turnos = ServicioTurnos.new(gestor_acciones)
	procesador_superficies = ProcesadorSuperficies.new(tablero)
	tablero.generar_desde_zona(zona_actual)
	validador_espacial = ValidadorEspacialTablero.new(tablero)
	transferidor_items = TransferidorItems.new(tablero, gestor_acciones)
	tablero.item_suelo_registrado.connect(_on_item_suelo_registrado)
	tablero.item_suelo_retirado.connect(_on_item_suelo_retirado)
	servicio_examen = ServicioExamen.new(tablero, registro_conocimiento)
	tablero.configurar_servicio_examen(servicio_examen)
	gestor_acciones.configurar_validador_espacial(validador_espacial)
	gestor_acciones.configurar_proveedor_costes(ProveedorCostesFicha.new())
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo:
		var errores_contenido := ValidadorContenidoZona.new().validar(
			zona_actual, tablero, capa_suelo
		)
		if errores_contenido.is_empty():
			tablero.registrar_interactuables_desde_zona(zona_actual, capa_suelo)
			tablero.registrar_efectos_superficie_desde_zona(zona_actual, capa_suelo)
		else:
			for error in errores_contenido:
				push_error("Contenido de zona invalido: %s" % error)
	pathfinding.inicializar(tablero.datos)
	gestor_vision.inicializar(capa_oscuridad, tablero)
	spawnear_ficha_inicial()
	if ficha_jugador:
		_colocar_piedra_prueba()
		_colocar_llave_prueba()
		_colocar_bomba_humo_prueba()
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)

func _process(_delta: float) -> void:
	centrar_camara_en_ficha()
	if ficha_jugador and ficha_jugador.esta_moviendose:
		trayectoria_lanzamiento.clear_points()
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
	if item_lanzamiento_pendiente != null:
		if coord_actual != ultima_coordenada_hover:
			_actualizar_previsualizacion_lanzamiento(coord_actual)
			ultima_coordenada_hover = coord_actual
		return
	if coord_actual == ultima_coordenada_hover:
		return
	_actualizar_hover_interaccion(coord_actual)
	capa_selector.clear()
	if tablero.es_celda_valida(coord_actual):
		capa_selector.set_cell(coord_actual, 0, Vector2i(1, 1))
		camino_actual_tentativo = pathfinding.calcular_camino(
			ficha_jugador.coordenada_mapa,
			coord_actual,
			tablero.datos,
			ficha_jugador
		)
		if en_combate:
			camino_actual_tentativo = pathfinding.limitar_camino_por_movimiento(
				camino_actual_tentativo,
				tablero.datos,
				ficha_jugador,
				ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
			)
		pathfinding.dibujar_trayectoria(camino_actual_tentativo, capa_camino)
	else:
		camino_actual_tentativo.clear()
		capa_camino.clear()
	ultima_coordenada_hover = coord_actual

func _unhandled_input(event: InputEvent) -> void:
	if item_lanzamiento_pendiente != null and event.is_action_pressed(&"ui_cancel"):
		_cancelar_lanzamiento()
		get_viewport().set_input_as_handled()
		return
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_imprimir_celda_bajo_cursor()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
		_abrir_selector_item_lanzamiento()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		_soltar_unico_item_prueba()
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


func _imprimir_celda_bajo_cursor() -> void:
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo != null:
		var coordenada := capa_suelo.local_to_map(get_global_mouse_position())
		print(InspectorCeldaDesarrollo.new().describir(tablero, coordenada))

func _manejar_clic_izquierdo(coord: Vector2i) -> void:
	if (
		ficha_jugador == null
		or ficha_jugador.esta_moviendose
		or interaccion_modal_activa
	):
		return
	if item_lanzamiento_pendiente != null:
		_seleccionar_celda_lanzamiento(coord)
		return
	if not _solicitar_interaccion_en_celda(coord):
		_cerrar_menu_contextual()
		return
	_abrir_menu_contextual(get_viewport().get_mouse_position())

func _manejar_clic_derecho(coord: Vector2i) -> void:
	if not ficha_jugador:
		return
	if item_lanzamiento_pendiente != null:
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
		tablero.datos,
		ficha_jugador
	)
	if en_combate:
		camino_confirmado = pathfinding.limitar_camino_por_movimiento(
			camino_confirmado,
			tablero.datos,
			ficha_jugador,
			ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
		)
	if camino_confirmado.size() <= 1:
		print("No te puedes mover ahi")
		return

	capa_camino.clear()
	ficha_jugador.mover_por_camino(
		camino_confirmado,
		_preparar_paso_ficha,
		_confirmar_paso_ficha,
		_cancelar_paso_ficha,
		_procesar_salida_paso_ficha,
		_procesar_entrada_paso_ficha,
		_calcular_coste_paso_ficha,
		_avanzar_turno_exploracion,
		en_combate
	)

func _avanzar_turno_exploracion(ficha: Ficha) -> bool:
	var resultado := servicio_turnos.avanzar_turno(ficha)
	if not resultado.exitosa:
		return false
	var resultado_superficies := procesador_superficies.procesar_fin_ronda()
	if not resultado_superficies.exitosa or ficha.pv_actual <= 0:
		return false
	ficha.iniciar_turno()
	return true


func guardar_partida(ruta: String = RUTA_GUARDADO) -> StringName:
	if ficha_jugador == null or ficha_jugador.esta_moviendose or interaccion_modal_activa:
		return &"partida_no_disponible_para_guardar"
	return persistencia_partida.guardar_archivo(
		ruta, tablero, &"zona1", ficha_jugador, registro_conocimiento
	)


func cargar_partida(ruta: String = RUTA_GUARDADO) -> StringName:
	if ficha_jugador == null or ficha_jugador.esta_moviendose or interaccion_modal_activa:
		return &"partida_no_disponible_para_cargar"
	var motivo := persistencia_partida.cargar_archivo(
		ruta, tablero, &"zona1", ficha_jugador, registro_conocimiento
	)
	if motivo != &"":
		return motivo
	pathfinding.inicializar(tablero.datos)
	_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)
	camino_actual_tentativo.clear()
	capa_camino.clear()
	return &""

func _preparar_paso_ficha(_origen: Vector2i, destino: Vector2i, ficha: Ficha) -> bool:
	return tablero.reservar_celda(destino, ficha)

func _confirmar_paso_ficha(origen: Vector2i, destino: Vector2i, ficha: Ficha) -> bool:
	return tablero.confirmar_movimiento(origen, destino, ficha)

func _cancelar_paso_ficha(destino: Vector2i, ficha: Ficha) -> void:
	tablero.cancelar_reserva(destino, ficha)

func _calcular_coste_paso_ficha(
	_origen: Vector2i,
	destino: Vector2i,
	ficha: Ficha
) -> int:
	var celda := tablero.obtener_celda(destino)
	return celda.calcular_coste_movimiento(ficha) if celda != null else -1

func _procesar_salida_paso_ficha(
	origen: Vector2i,
	destino: Vector2i,
	ficha: Ficha
) -> void:
	ultimo_resultado_salir = _resolver_reacciones_movimiento(
		TiposInteraccion.TipoAccion.SALIR,
		origen,
		destino,
		ficha
	)

func _procesar_entrada_paso_ficha(
	origen: Vector2i,
	destino: Vector2i,
	ficha: Ficha
) -> void:
	ultimo_resultado_entrar = _resolver_reacciones_movimiento(
		TiposInteraccion.TipoAccion.ENTRAR,
		origen,
		destino,
		ficha
	)

func _resolver_reacciones_movimiento(
	tipo: TiposInteraccion.TipoAccion,
	origen: Vector2i,
	destino: Vector2i,
	ficha: Ficha
) -> ResultadoReacciones:
	var coord_consulta := origen if tipo == TiposInteraccion.TipoAccion.SALIR else destino
	var celda := tablero.obtener_celda(coord_consulta)
	var reacciones := consultor_reacciones.obtener_reacciones(celda, tipo, ficha)
	var resultado := resolver_reacciones.resolver(
		tipo,
		ficha,
		origen,
		destino,
		reacciones
	)
	if resultado.interrumpe_movimiento:
		ficha.solicitar_interrupcion()
	return resultado

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


func seleccionar_objetivo_interaccion(objetivo: Object) -> bool:
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
		if objetivo_resaltado.has_method(&"establecer_resaltado"):
			objetivo_resaltado.call(&"establecer_resaltado", false)
	objetivo_resaltado = siguiente if is_instance_valid(siguiente) else null
	if objetivo_resaltado != null:
		if objetivo_resaltado.has_method(&"establecer_resaltado"):
			objetivo_resaltado.call(&"establecer_resaltado", true)


func _abrir_menu_contextual(posicion_pantalla: Vector2) -> void:
	if objetivo_seleccionado != null:
		var opciones: Array[OpcionAccion] = objetivo_seleccionado.call(
			&"obtener_opciones_accion", ficha_jugador
		)
		menu_contextual.mostrar(
			objetivo_seleccionado.call(&"obtener_nombre_interaccion"),
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


func _on_objetivo_contextual_elegido(objetivo: Object) -> void:
	if seleccionar_objetivo_interaccion(objetivo):
		_abrir_menu_contextual(menu_contextual.position)


func _on_opcion_contextual_elegida(opcion: OpcionAccion) -> void:
	ultima_opcion_contextual_seleccionada = opcion
	opcion_contextual_seleccionada.emit(opcion)
	if opcion != null and opcion.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		opcion_uso_item_pendiente = opcion
		menu_contextual.mostrar(
			catalogo_mensajes.resolver(&"interaccion.seleccionar_item"),
			adaptador_menu_contextual.construir_entradas_items(
				ficha_jugador.inventario.obtener_contenido(),
				catalogo_mensajes
			),
			menu_contextual.position
		)
		return
	_ejecutar_opcion_contextual(opcion)


func _on_item_contextual_elegido(item: ItemInstancia) -> void:
	if seleccionando_item_lanzamiento:
		seleccionando_item_lanzamiento = false
		item_lanzamiento_pendiente = item
		ultima_coordenada_hover = Vector2i(-999, -999)
		menu_contextual.ocultar()
		_actualizar_estado_modal_interaccion()
		return
	_ejecutar_opcion_contextual(opcion_uso_item_pendiente, item)


func _on_impacto_contextual_elegido(objetivo: Object) -> void:
	_ejecutar_lanzamiento(objetivo)


func _ejecutar_opcion_contextual(
	opcion: OpcionAccion,
	item_seleccionado: ItemInstancia = null
) -> void:
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
			coordenada_objetivo,
			item_seleccionado
		)
		if construccion is ContextoAccion:
			contexto = construccion
			resultado = gestor_acciones.procesar_accion(contexto)
		else:
			var motivo_construccion: StringName = construccion
			resultado = ResultadoAccion.crear_bloqueo(motivo_construccion)

	ultimo_contexto_contextual = contexto
	ultimo_resultado_contextual = resultado
	opcion_uso_item_pendiente = null
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
	opcion_uso_item_pendiente = null
	seleccionando_item_lanzamiento = false
	item_lanzamiento_pendiente = null
	celda_lanzamiento_pendiente = null
	trayectoria_lanzamiento.clear_points()
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
		and is_instance_valid(opcion.objetivo)
		and opcion.objetivo.has_method(&"obtener_nombre_interaccion")
	):
		return opcion.objetivo.call(&"obtener_nombre_interaccion")
	return "Interacción"


func _colocar_piedra_prueba() -> void:
	var direcciones: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for direccion in direcciones:
		var coord := ficha_jugador.coordenada_mapa + direccion
		if tablero.validar_colocacion_item_suelo(coord, ficha_jugador) != &"":
			continue
		var piedra := ItemSuelo.new(ItemInstancia.new(&"zona1_piedra_prueba", DEFINICION_PIEDRA, 1))
		piedra.configurar_transferidor_items(transferidor_items)
		tablero.registrar_item_suelo(coord, piedra)
		return


func _colocar_llave_prueba() -> void:
	var direcciones: Array[Vector2i] = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]
	for direccion in direcciones:
		var coord := ficha_jugador.coordenada_mapa + direccion
		if tablero.validar_colocacion_item_suelo(coord, ficha_jugador) != &"":
			continue
		if not tablero.obtener_celda(coord).items_suelo.is_empty():
			continue
		var llave := ItemSuelo.new(ItemInstancia.new(
			&"zona1_llave_prueba",
			DEFINICION_LLAVE_PRUEBA,
			1
		))
		llave.configurar_transferidor_items(transferidor_items)
		tablero.registrar_item_suelo(coord, llave)
		return


func _colocar_bomba_humo_prueba() -> void:
	var direcciones: Array[Vector2i] = [Vector2i.ZERO, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]
	for direccion in direcciones:
		var coord := ficha_jugador.coordenada_mapa + direccion
		if tablero.validar_colocacion_item_suelo(coord, ficha_jugador) != &"":
			continue
		if not tablero.obtener_celda(coord).items_suelo.is_empty():
			continue
		var bomba := ItemSuelo.new(ItemInstancia.new(
			&"zona1_bomba_humo",
			DEFINICION_BOMBA_HUMO,
			1
		))
		bomba.configurar_transferidor_items(transferidor_items)
		tablero.registrar_item_suelo(coord, bomba)
		return


func _on_item_suelo_registrado(coord: Vector2i, item_suelo: ItemSuelo) -> void:
	if item_suelo.item.definicion.escena_mundo == null:
		return
	var representacion := item_suelo.item.definicion.escena_mundo.instantiate() as Node2D
	if representacion == null:
		return
	zona_actual.add_child(representacion)
	representacion.global_position = zona_actual.get_node("CapaSuelo").map_to_local(coord)
	item_suelo.vincular_representacion(representacion)


func _on_item_suelo_retirado(_coord: Vector2i, item_suelo: ItemSuelo) -> void:
	var representacion := item_suelo.obtener_representacion()
	if representacion != null:
		representacion.queue_free()


func _soltar_unico_item_prueba() -> void:
	if (
		ficha_jugador == null
		or interaccion_modal_activa
		or item_lanzamiento_pendiente != null
	):
		return
	var contenido := ficha_jugador.inventario.obtener_contenido()
	if contenido.size() != 1:
		return
	var contexto := transferidor_items.construir_contexto_soltar(
		ficha_jugador,
		contenido[0],
		ficha_jugador.coordenada_mapa,
		ficha_jugador.coordenada_mapa
	)
	gestor_acciones.procesar_accion(contexto)


func _abrir_selector_item_lanzamiento() -> void:
	if (
		ficha_jugador == null
		or ficha_jugador.esta_moviendose
		or interaccion_modal_activa
		or item_lanzamiento_pendiente != null
	):
		return
	var arrojables: Array[ItemInstancia] = []
	for item in ficha_jugador.inventario.obtener_contenido():
		if &"arrojable" in item.definicion.etiquetas:
			arrojables.append(item)
	if arrojables.is_empty():
		return
	seleccionando_item_lanzamiento = true
	menu_contextual.mostrar(
		catalogo_mensajes.resolver(&"interaccion.lanzar_item"),
		adaptador_menu_contextual.construir_entradas_items(
			arrojables,
			catalogo_mensajes
		),
		get_viewport().get_mouse_position()
	)
	_actualizar_estado_modal_interaccion()


func _seleccionar_celda_lanzamiento(coordenada: Vector2i) -> void:
	if not _es_celda_lanzamiento_valida(coordenada):
		return
	celda_lanzamiento_pendiente = coordenada
	var trayectoria := validador_espacial.resolver_trayectoria_lanzamiento(
		ficha_jugador.coordenada_mapa,
		coordenada,
		_obtener_alcance_lanzamiento_actual()
	)
	if trayectoria.is_empty() or trayectoria[&"celda_impacto"] != coordenada:
		_ejecutar_lanzamiento(null)
		return
	var objetivos := _obtener_objetivos_impacto(coordenada)
	if objetivos.is_empty():
		_ejecutar_lanzamiento(null)
		return
	menu_contextual.mostrar(
		catalogo_mensajes.resolver(&"interaccion.seleccionar_impacto"),
		adaptador_menu_contextual.construir_entradas_impacto(
			objetivos,
			catalogo_mensajes
		),
		get_viewport().get_mouse_position()
	)
	_actualizar_estado_modal_interaccion()


func _obtener_objetivos_impacto(coordenada: Vector2i) -> Array[Object]:
	var objetivos: Array[Object] = []
	var celda := tablero.obtener_celda(coordenada)
	for reaccion in consultor_reacciones.obtener_reacciones(
		celda,
		TiposInteraccion.TipoAccion.IMPACTAR,
		ficha_jugador,
		null,
		true
	):
		var receptor := reaccion.receptor
		var perceptible := true
		var pertenece_a_celda := true
		if receptor.has_method(&"es_objetivo_impacto_perceptible"):
			var valor: Variant = receptor.call(&"es_objetivo_impacto_perceptible")
			perceptible = valor is bool and valor
		if receptor.has_method(&"obtener_coordenada_reaccion"):
			pertenece_a_celda = receptor.call(&"obtener_coordenada_reaccion") == coordenada
		if (
			reaccion.categoria != TiposInteraccion.CategoriaReaccion.TERRENO
			and receptor not in objetivos
			and receptor.has_method(&"obtener_nombre_interaccion")
			and perceptible
			and pertenece_a_celda
		):
			objetivos.append(receptor)
	return objetivos


func _es_celda_lanzamiento_valida(coordenada: Vector2i) -> bool:
	if ficha_jugador == null or not tablero.es_celda_valida(coordenada):
		return false
	var celda := tablero.obtener_celda(coordenada)
	return (
		celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE
		and float(maxi(
			abs(coordenada.x - ficha_jugador.coordenada_mapa.x),
			abs(coordenada.y - ficha_jugador.coordenada_mapa.y)
		)) <= _obtener_alcance_lanzamiento_actual()
	)


func _obtener_alcance_lanzamiento_actual() -> float:
	if transferidor_items == null or ficha_jugador == null:
		return -1.0
	return transferidor_items.calcular_alcance_lanzamiento(ficha_jugador)


func _actualizar_previsualizacion_lanzamiento(coordenada: Vector2i) -> void:
	trayectoria_lanzamiento.clear_points()
	capa_selector.clear()
	capa_camino.clear()
	camino_actual_tentativo.clear()
	if ficha_jugador == null or not tablero.es_celda_valida(coordenada):
		return
	var celda := tablero.obtener_celda(coordenada)
	if celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return
	var trayectoria := validador_espacial.resolver_trayectoria_lanzamiento(
		ficha_jugador.coordenada_mapa,
		coordenada,
		_obtener_alcance_lanzamiento_actual()
	)
	if trayectoria.is_empty():
		return
	var coordenada_impacto: Vector2i = trayectoria[&"celda_impacto"]
	capa_selector.set_cell(coordenada_impacto, 0, Vector2i(1, 1))
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo == null:
		return
	trayectoria_lanzamiento.points = PackedVector2Array([
		trayectoria_lanzamiento.to_local(
			capa_suelo.to_global(capa_suelo.map_to_local(ficha_jugador.coordenada_mapa))
		),
		trayectoria_lanzamiento.to_local(
			capa_suelo.to_global(capa_suelo.map_to_local(coordenada_impacto))
		),
	])
	trayectoria_lanzamiento.default_color = (
		Color(0.3, 1.0, 0.4, 0.9)
		if trayectoria[&"destino_alcanzado"] and not trayectoria[&"hubo_colision"]
		else Color(1.0, 0.35, 0.15, 0.9)
	)


func _ejecutar_lanzamiento(objetivo_impacto: Object) -> void:
	if lanzamiento_en_vuelo:
		return
	var item := item_lanzamiento_pendiente
	if (
		item == null
		or not celda_lanzamiento_pendiente is Vector2i
	):
		_cancelar_lanzamiento()
		return
	var id_resultante := _crear_id_item_lanzado(item)
	var contexto := transferidor_items.construir_contexto_lanzar(
		ficha_jugador,
		item,
		ficha_jugador.coordenada_mapa,
		celda_lanzamiento_pendiente,
		id_resultante,
		objetivo_impacto
	)
	menu_contextual.ocultar()
	trayectoria_lanzamiento.clear_points()
	seleccionando_item_lanzamiento = false
	item_lanzamiento_pendiente = null
	celda_lanzamiento_pendiente = null
	lanzamiento_en_vuelo = true
	_actualizar_estado_modal_interaccion()
	_animar_lanzamiento(contexto, item)


func _animar_lanzamiento(contexto: ContextoAccion, item: ItemInstancia) -> void:
	var trayectoria := validador_espacial.resolver_trayectoria_lanzamiento(
		contexto.origen,
		contexto.celda_objetivo,
		contexto.alcance_maximo
	)
	if trayectoria.is_empty():
		_finalizar_lanzamiento(contexto, item)
		return
	representacion_lanzamiento = _crear_representacion_lanzamiento(item, contexto.origen)
	var recorrido: Array = trayectoria[&"recorrido"]
	if representacion_lanzamiento == null or recorrido.size() < 2:
		_finalizar_lanzamiento(contexto, item)
		return
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo == null:
		_finalizar_lanzamiento(contexto, item)
		return
	var tween := create_tween()
	for coordenada in recorrido.slice(1):
		tween.tween_property(
			representacion_lanzamiento,
			^"global_position",
			capa_suelo.to_global(capa_suelo.map_to_local(coordenada)),
			duracion_paso_lanzamiento
		).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(
		_finalizar_lanzamiento.bind(contexto, item),
		CONNECT_ONE_SHOT
	)


func _crear_representacion_lanzamiento(
	item: ItemInstancia,
	origen: Vector2i
) -> Node2D:
	if item.definicion.escena_mundo == null:
		return null
	var representacion := item.definicion.escena_mundo.instantiate() as Node2D
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if representacion == null or capa_suelo == null:
		if representacion != null:
			representacion.free()
		return null
	zona_actual.add_child(representacion)
	representacion.global_position = capa_suelo.to_global(
		capa_suelo.map_to_local(origen)
	)
	representacion.z_index = 100
	return representacion


func _finalizar_lanzamiento(contexto: ContextoAccion, item: ItemInstancia) -> void:
	if is_instance_valid(representacion_lanzamiento):
		representacion_lanzamiento.visible = false
		representacion_lanzamiento.queue_free()
	representacion_lanzamiento = null
	var resultado := gestor_acciones.procesar_accion(contexto)
	ultimo_contexto_contextual = contexto
	ultimo_resultado_contextual = resultado
	lanzamiento_en_vuelo = false
	panel_resultado_accion.mostrar_resultado(item.definicion.nombre, resultado, catalogo_mensajes)
	accion_contextual_finalizada.emit(null, contexto, resultado)


func _crear_id_item_lanzado(item: ItemInstancia) -> StringName:
	if item.cantidad == 1:
		return &""
	while true:
		secuencia_items_lanzados += 1
		var candidato := StringName("%s_lanzado_%d" % [
			item.id_instancia,
			secuencia_items_lanzados,
		])
		if (
			ficha_jugador.inventario.obtener_por_id(candidato) == null
			and not tablero.items_suelo_por_id.has(candidato)
		):
			return candidato
	return &""


func _cancelar_lanzamiento() -> void:
	seleccionando_item_lanzamiento = false
	item_lanzamiento_pendiente = null
	celda_lanzamiento_pendiente = null
	trayectoria_lanzamiento.clear_points()
	if is_instance_valid(menu_contextual):
		menu_contextual.ocultar()
	ultima_coordenada_hover = Vector2i(-999, -999)
	_actualizar_estado_modal_interaccion()


func _actualizar_estado_modal_interaccion() -> void:
	var siguiente := (
		lanzamiento_en_vuelo
		or (is_instance_valid(menu_contextual) and menu_contextual.visible)
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
