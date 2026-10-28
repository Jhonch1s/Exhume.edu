extends Node2D

signal opcion_contextual_seleccionada(opcion: OpcionAccion)
signal accion_contextual_finalizada(
	opcion: OpcionAccion,
	contexto: ContextoAccion,
	resultado: ResultadoAccion
)
signal estado_modal_interaccion_cambiado(activo: bool)

@onready var zona_actual: Node2D = $Zona
@onready var capa_selector: TileMapLayer = $CapaSelector
@onready var capa_vision_npc: CapaVisionNPC = $CapaVisionNPC
@onready var panel_resultado_accion: PanelResultadoAccion = (
	$CanvasLayerModalDados/PanelResultadoAccion
)
@onready var panel_examen_ilustrado: PanelExamenIlustrado = (
	$CanvasLayer/PanelExamenIlustrado
)
@onready var menu_contextual: MenuContextualInteracciones = (
	$CanvasLayer/MenuContextualInteracciones
)
@onready var capa_paredes_oclusivas: CapaParedesOclusivas = (
	zona_actual.get_node("CapaParedes") as CapaParedesOclusivas
)
@onready var camera_2d: CamaraEscenario = $Camera2D
@onready var capa_camino: TileMapLayer = $CapaCamino
@onready var trayectoria_lanzamiento: Line2D = $TrayectoriaLanzamiento
@onready var gestor_vision: FOVManager = $GestorVision
@onready var capa_oscuridad: TileMapLayer = $Zona/CapaOscuridad
@onready var hud: HUD = $CanvasLayer/HUD
@onready var panel_info_npc: PanelInfoNPC = $CanvasLayer/PanelInfoNPC
@onready var panel_ficha_npc: PanelFichaNPC = $CanvasLayer/PanelFichaNPC
@onready var panel_orden_combate: PanelOrdenCombate = $CanvasLayer/PanelOrdenCombate
@onready var panel_registro_narrativo: PanelRegistroNarrativo = (
	$CanvasLayer/HUD/HUDRoot/LogAcontecimientos
)

@onready var viewportKnight: SubViewportContainer = $KnightViewPort
@onready var subviewportKnight: SubViewport = $KnightViewPort/KnightSubViewport
@onready var camaraCaballero: Camera3D = $KnightViewPort/KnightSubViewport/Camera3D
@onready var caballeroModelo: Node3D = $KnightViewPort/KnightSubViewport/cavallerov2

@onready var viewportWizar: SubViewportContainer = $WizardViewPort
@onready var subviewportWizard: SubViewport = $WizardViewPort/WizardSubViewport
@onready var camaraMago: Camera3D = $WizardViewPort/WizardSubViewport/Camera3D
@onready var magoModelo:Node3D = $WizardViewPort/WizardSubViewport/magov2

@onready var viewportThief: SubViewportContainer = $ThiefViewPort
@onready var subviewportThief: SubViewport = $ThiefViewPort/ThiefSubViewport
@onready var camaraThief: Camera3D = $ThiefViewPort/ThiefSubViewport/Camera3D
@onready var ladronModelo: Node3D = $ThiefViewPort/ThiefSubViewport/ladronmodelo
@onready var panel_inventario_cofre: PanelInventarioCofre = (
	$CanvasLayer/PanelInventarioCofre
)
@onready var panel_inventario_equipo: PanelInventarioEquipo = (
	$CanvasLayer/PanelInventarioEquipo
)

const modeloCaballero = preload("res://assets/characters/knight3d/cavallerov2.glb")
const modeloMago = preload("res://assets/characters/knight3d/magov2.glb")
const modeloLadron = preload("res://assets/characters/knight3d/modeloladron2.glb")

const ESCENA_FICHA = preload("res://scenes/ficha/ficha.tscn")
const DEFINICION_PIEDRA = preload("res://assets/items/piedra/piedra.tres")
const DEFINICION_ANTORCHA = preload("res://assets/items/antorcha/antorcha.tres")
const DEFINICION_ESPADA_INICIAL = preload("res://assets/items/forja/espada_inicial/espada_inicial.tres")
const DEFINICION_ESCUDO_INICIAL = preload("res://assets/items/forja/escudo_inicial/escudo_inicial.tres")
const DEFINICION_CASCO_INICIAL = preload("res://assets/items/forja/casco_inicial/casco_inicial.tres")
const DEFINICION_PECHERA_INICIAL = preload("res://assets/items/forja/pechera_inicial/pechera_inicial.tres")
const DEFINICION_DAGA_INICIAL = preload("res://assets/items/forja/daga_inicial/daga_inicial.tres")
const DEFINICION_CAPUCHA_INICIAL = preload("res://assets/items/forja/capucha_inicial/capucha_inicial.tres")
const DEFINICION_BOTAS_LADRON = preload("res://assets/items/forja/botas_ladron_inicial/botas_ladron_inicial.tres")
const DEFINICION_BASTON_INICIAL = preload("res://assets/items/forja/baston_inicial/baston_inicial.tres")
const DEFINICION_TUNICA_MAGO = preload("res://assets/items/forja/tunica_mago_inicial/tunica_mago_inicial.tres")
const DEFINICION_BOTAS_MAGO = preload("res://assets/items/forja/botas_mago_iniciales/botas_mago_iniciales.tres")
const SONIDO_PASO_1 = preload("res://assets/sonidos/sonidos finales/sonido pasos/Light Armor Running 1_05.wav")
const SONIDO_PASO_2 = preload("res://assets/sonidos/sonidos finales/sonido pasos/Light Armor Running 1_06.wav")
const SONIDO_MONSTRUO_CADENAS = preload("res://assets/sonidos/enemigo/munstro con cadenas.wav")
const SONIDO_LAVA = preload("res://assets/sonidos/ambiente/lava 2.wav")

const SONIDOS_AMBIENTE_TENEBROSO: Array[AudioStream] = [
	preload("res://assets/sonidos/sonidos finales/sonido ambiente/Dark Transition.wav"),
	preload("res://assets/sonidos/sonidos finales/sonido ambiente/Dungeon Atmosphere - Dark.wav"),
]
const SONIDO_CREEPY: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/Creepy Noise 1.wav")
const SONIDO_AMBIENTE_ENTRADA_ZONA: AudioStream = preload("res://assets/sonidos/sonidos ambiente dungeon/Ambient 29.wav")
const SONIDO_AMBIENTE_FONDO_30: AudioStream = preload("res://assets/sonidos/sonidos ambiente dungeon/Ambient 30.wav")
const SONIDO_BREATH_1: AudioStream = preload("res://assets/sonidos/tension/Breath 1.wav")
const SONIDO_BREATH_2: AudioStream = preload("res://assets/sonidos/tension/Breath 2.wav")
const SONIDO_CAMPANAS_ESTATUA: AudioStream = preload("res://assets/sonidos/campana/campanas.wav")
const SONIDO_DADO_EXITO: AudioStream = preload("res://assets/sonidos/narrador/la fortuna te perdona.mp3")
const SONIDO_DADO_FRACASO: AudioStream = preload("res://assets/sonidos/narrador/tu suerte se agota.mp3")
const SONIDO_NARRADOR_TEMPLO_TRAMPAS: AudioStream = preload("res://assets/sonidos/narrador/templo de las trampas.mp3")
const SONIDO_LATIDO_CORAZON: AudioStream = preload("res://assets/sonidos/corazon/332819__loudernoises__heartbeat-80bpm-limited.wav")

const ESCENA_PANTALLA_MUERTE = preload("res://scenes/ui/pantalla_muerte.tscn")
const ESCENA_PRESENTACION_ZONA = preload("res://scenes/ui/presentacion_zona.tscn")
const SHADER_CERCA_MUERTE = preload("res://assets/ui/shaders/cerca_muerte.gdshader")

const SONIDO_MAGIA_FUEGO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido magia/Magic Element Fire 03.wav")

const PLAYLIST_EXPLORACION: Array[AudioStream] = [
	preload("res://assets/sonidos/sonidos finales/musica buena/Fire Dungeon.ogg"),
	preload("res://assets/sonidos/sonidos finales/musica buena/Mines.ogg"),
	preload("res://assets/sonidos/sonidos finales/musica buena/Necropolis.ogg"),
]

const PLAYLIST_COMBATE: Array[AudioStream] = [
	preload("res://assets/sonidos/sonidos finales/musica buena/pelea/Ancient Battle Full Version.wav"),
	preload("res://assets/sonidos/sonidos finales/musica buena/pelea/Fighting The Boss Full Version.wav"),
	preload("res://assets/sonidos/sonidos finales/musica buena/pelea/Intruder Detected Loop.wav"),
	preload("res://assets/sonidos/sonidos finales/musica buena/pelea/Loop 3.wav"),
]
const RUTA_GUARDADO := "user://partida.json"
const ESCENA_CAMPAMENTO = preload("res://scenes/campamento/campamento.tscn")
var campamento: CanvasLayer
var _modo_proceso_antes_campamento: ProcessMode
var _audio_antes_campamento: Dictionary = {}
var _acciones_en_resolucion := 0
var boton_campamento: Button
var panel_empuje: ConfirmationDialog
var habilidades_nivel_dos = preload("res://scripts/interacciones/habilidades_nivel_dos.gd").new(self)
var panel_progresion: ConfirmationDialog
var boton_progresion: Button
var habilidad_en_seleccion := ""
var fuente_trasvase: Variant = null
var es_escenario_de_descanso := false
var control_descanso: Node
@export var catalogo_mensajes: CatalogoMensajesInteraccion
@export_category("Ilustraciones de diálogo del jugador")
@export var ilustracion_dialogo_guerrero: Texture2D
@export var ilustracion_dialogo_ladron: Texture2D
@export var ilustracion_dialogo_mago: Texture2D
@export_range(0.02, 0.5, 0.01) var duracion_paso_lanzamiento: float = 0.08
@export_range(1, 12, 1) var radio_audio_lava: int = 3
@export_range(1, 12, 1) var radio_audio_fuego: int = 6
@export_range(0.2, 60.0, 0.1) var intervalo_exploracion_npc: float = 1.0

var tablero: TableroGrid = TableroGrid.new()
var pathfinding: PathFindingManager = PathFindingManager.new()
var gestor_acciones: GestorAcciones = GestorAcciones.new()
var historial_tiradas: HistorialTiradas = HistorialTiradas.new()
var registro_narrativo: RegistroNarrativoSesion = RegistroNarrativoSesion.new()
var validador_espacial: ValidadorEspacialTablero
var consultor_reacciones: ConsultorReaccionesCelda = ConsultorReaccionesCelda.new()
var resolver_reacciones: ResolverReaccionesCelda
var servicio_turnos: ServicioTurnos
var procesador_superficies: ProcesadorSuperficies
var registro_conocimiento: RegistroConocimiento = RegistroConocimiento.new()
var servicio_examen: ServicioExamen
var servicio_percepcion_trampas: ServicioPercepcionTrampas
var accion_destrabarse: AccionDestrabarse = AccionDestrabarse.new()
var ficha_jugador: Ficha = null
var seleccionando_ataque_doble := false
var seleccionando_bola_fuego := false
var transferidor_items: TransferidorItems
var selector_objetivos: SelectorObjetivosInteraccion = SelectorObjetivosInteraccion.new()
var adaptador_menu_contextual: AdaptadorMenuContextual = AdaptadorMenuContextual.new()
var constructor_contexto_accion: ConstructorContextoAccion = ConstructorContextoAccion.new()
var ultima_coordenada_hover: Vector2i = Vector2i(-999, -999)
var objetivos_hover: Array[Object] = []
var objetivos_resaltados: Array[Object] = []
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
var dialogo_npc_activo: bool = false
var recurso_dialogo_npc_activo: DialogueResource
var tema_dialogo_npc_activo: DialogoNPC
var npc_dialogo_activo: PersonajeNPC
var motor_dados_dialogo := MotorDados.new()
var ultima_prueba_dialogo: ResultadoPrueba
var prueba_dialogo_resuelta := false
var _exito_prueba_dialogo := false
var prueba_dialogo_exitosa: bool:
	get:
		return prueba_dialogo_resuelta and _exito_prueba_dialogo
var _prueba_dialogo_en_curso := false
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
var gestor_rondas: GestorRondas
var _restaurando_partida: bool = false
var _secuencia_turno_npc: int = 0
var _turno_exploracion_en_curso := false
var _turnos_exploracion_pendientes := 0
var _secuencia_exploracion_npc := 0
var _tiempo_exploracion_npc := 0.0
var persistencia_partida := PersistenciaPartida.new()
@onready var reproductor_musica: AudioStreamPlayer = $AudioStreamPlayer
var reproductor_pasos: AudioStreamPlayer2D
var reproductor_lava: AudioStreamPlayer2D
var reproductor_fuego: AudioStreamPlayer
var reproductor_monstruo: AudioStreamPlayer
var reproductor_ambiente_tenebroso: AudioStreamPlayer
var reproductor_creepy: AudioStreamPlayer
var reproductor_examen: AudioStreamPlayer
var reproductor_recoleccion: AudioStreamPlayer
var reproductor_impacto: AudioStreamPlayer2D
var reproductor_campana_estatua: AudioStreamPlayer
var reproductor_narrador_dados: AudioStreamPlayer
var reproductor_latido: AudioStreamPlayer
var reproductor_magia_fuego: AudioStreamPlayer
var reproductor_ocultarse: AudioStreamPlayer
var guardado_en_fogata_realizado: bool = false
var pantalla_muerte: PantallaMuerte
var presentacion_zona: PresentacionZona
var capa_cerca_muerte: CanvasLayer
var rect_cerca_muerte: ColorRect
var material_cerca_muerte: ShaderMaterial
var _estado_cerca_muerte_activo: bool = false
var temporizador_monstruo: Timer
var temporizador_ambiente_tenebroso: Timer
var indice_musica_exploracion: int = 0
var indice_musica_combate: int = 0
var tween_musica: Tween
var _transicionando_musica: bool = false
var generador_azar_audio := RandomNumberGenerator.new()
var siguiente_paso_usa_variante_uno: bool = true
var pasos_movimiento_actual: int = 0
var longitud_movimiento_actual: int = 0
var nombreClase: String = "Guerrero"
var _firma_secuencia_combate := ""
var _actor_turno_camara: Object
var _centrado_camara_pendiente := false
var _dialogos_camara: Array[DialogueResource] = []
var _puntero_en_ventana := true

func _ready() -> void:
	# Las capas se guardan ocultas para poder editar el mapa sin la interfaz encima.
	$FiltroCRT.visible = true
	$CanvasLayer.visible = true
	$CanvasLayerModalDados.visible = true
	CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)
	guardado_en_fogata_realizado = EstadoPartida.guardado_en_fogata_realizado
	if not guardado_en_fogata_realizado and FileAccess.file_exists(RUTA_GUARDADO):
		DirAccess.remove_absolute(RUTA_GUARDADO)
	nombreClase = EstadoPartida.aventurero_pendiente.get("clase", nombreClase)
	var limite_hud := hud.get_node("HUDRoot/SeccionesHUD/SeccionJugador/Retrato") as Control
	menu_contextual.hud_inferior = limite_hud
	panel_inventario_equipo.hud_inferior = limite_hud
	panel_examen_ilustrado.hud_inferior = limite_hud
	panel_examen_ilustrado._ajustar_al_viewport()

	panel_registro_narrativo.observar(registro_narrativo)
	gestor_acciones.accion_finalizada.connect(_on_agresion_resuelta)
	gestor_acciones.accion_iniciada.connect(func(_contexto): _acciones_en_resolucion += 1)
	gestor_acciones.accion_finalizada.connect(func(_contexto, _resultado): _acciones_en_resolucion = maxi(0, _acciones_en_resolucion - 1))
	if not es_escenario_de_descanso:
		_crear_acceso_campamento()
		_crear_acceso_progresion()
	hud.pasar_turno_solicitado.connect(_on_pasar_turno_hud)
	hud.ataque_doble_solicitado.connect(_on_ataque_doble_hud)
	hud.ocultarse_solicitado.connect(_on_ocultarse_hud)
	hud.bola_fuego_solicitada.connect(_on_bola_fuego_hud)
	hud.habilidad_aprendida_solicitada.connect(_on_habilidad_aprendida_hud)
	hud.item_rapido_solicitado.connect(_on_item_rapido_hud_solicitado)
	panel_orden_combate.retrato_pulsado.connect(_on_retrato_combate_pulsado)
	menu_contextual.opcion_accion_elegida.connect(_on_opcion_contextual_elegida)
	menu_contextual.objetivo_elegido.connect(_on_objetivo_contextual_elegido)
	menu_contextual.item_elegido.connect(_on_item_contextual_elegido)
	menu_contextual.impacto_elegido.connect(_on_impacto_contextual_elegido)
	menu_contextual.cancelado.connect(_on_menu_contextual_cancelado)
	panel_resultado_accion.resultado_presentado.connect(_on_resultado_accion_presentado)
	panel_resultado_accion.tirada_presentada.connect(_on_tirada_presentada)
	panel_resultado_accion.veredicto_revelado.connect(_reproducir_narrador_tirada)
	panel_resultado_accion.cerrado.connect(_on_panel_resultado_cerrado)
	panel_examen_ilustrado.cerrado.connect(_on_panel_resultado_cerrado)
	panel_ficha_npc.cerrado.connect(_on_panel_resultado_cerrado)
	panel_inventario_cofre.visibility_changed.connect(_actualizar_estado_modal_interaccion)
	panel_inventario_equipo.visibility_changed.connect(_actualizar_estado_modal_interaccion)
	panel_inventario_equipo.item_soltado_al_suelo.connect(_on_item_inventario_soltado_al_suelo)
	panel_inventario_equipo.item_uso_solicitado.connect(_on_item_inventario_uso_solicitado)
	DialogueManager.dialogue_started.connect(_on_dialogo_camara_iniciado)
	DialogueManager.dialogue_ended.connect(_on_dialogo_camara_finalizado)
	add_child(gestor_acciones)
	resolver_reacciones = ResolverReaccionesCelda.new(gestor_acciones)
	servicio_turnos = ServicioTurnos.new(gestor_acciones)
	procesador_superficies = ProcesadorSuperficies.new(tablero)
	tablero.generar_desde_zona(zona_actual)
	camera_2d.configurar_limites(zona_actual)
	validador_espacial = ValidadorEspacialTablero.new(tablero)
	servicio_percepcion_trampas = ServicioPercepcionTrampas.new(
		tablero, registro_conocimiento, validador_espacial
	)
	transferidor_items = TransferidorItems.new(tablero, gestor_acciones)
	tablero.configurar_transferidor_items(transferidor_items)
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
			tablero.registrar_items_suelo_desde_zona(zona_actual, capa_suelo)
		else:
			for error in errores_contenido:
				push_error("Contenido de zona invalido: %s" % error)
	pathfinding.inicializar(tablero.datos)
	gestor_vision.inicializar(capa_oscuridad, tablero)
	_inicializar_audio_ambiente()
	if not es_escenario_de_descanso:
		_inicializar_musica()
		_presentar_entrada_nueva_zona()
	await spawnear_ficha_inicial()
	if ficha_jugador:
		hud.configurar_ficha(ficha_jugador)
		if not ficha_jugador.puntos_vida_cambiados.is_connected(_on_vida_jugador_cambiada):
			ficha_jugador.puntos_vida_cambiados.connect(_on_vida_jugador_cambiada)
		_on_vida_jugador_cambiada(ficha_jugador.pv_actual, ficha_jugador.pv_max)
		capa_vision_npc.configurar(tablero, validador_espacial, ficha_jugador, gestor_vision)
		_colocar_piedra_prueba()
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)
		_actualizar_audio_proximidad()
		centrar_camara_en_ficha()

func _process(delta: float) -> void:
	_actualizar_decision_empuje()
	if is_instance_valid(campamento):
		CursorJuego.ocultar_probabilidad_ataque()
		return
	if ficha_jugador != null:
		habilidades_nivel_dos.limpiar_agarre()
	if is_instance_valid(boton_progresion):
		boton_progresion.text = "Nivel 2 · Elegir recompensa [P]" if ficha_jugador != null and ficha_jugador.nivel_recompensa_pendiente == 2 else "Progresión [P]"
		boton_progresion.disabled = motivo_bloqueo_campamento() != &""
	if is_instance_valid(boton_campamento):
		var motivo_campamento := motivo_bloqueo_campamento()
		boton_campamento.disabled = motivo_campamento != &""
		boton_campamento.tooltip_text = mensaje_bloqueo_campamento(motivo_campamento)
	if capa_vision_npc.visible:
		capa_vision_npc.actualizar(gestor_rondas)
	if ficha_jugador and capa_paredes_oclusivas:
		capa_paredes_oclusivas.actualizar_occlusion(ficha_jugador.global_position)
	_actualizar_audio_proximidad()
	if en_combate and not _restaurando_partida and _acciones_en_resolucion == 0 and habilidades_nivel_dos.empuje_pendiente == null and not _esperar_escapista():
		_resolver_perdida_agro()
		_actualizar_ui_combate()
	_actualizar_disponibilidad_turno()
	_actualizar_reloj_exploracion_npc(delta)
	_actualizar_fade_fin_musica()
	_actualizar_camara(delta)
	if ficha_jugador and ficha_jugador.esta_moviendose:
		trayectoria_lanzamiento.clear_points()
		capa_selector.clear()
		capa_camino.clear()
		_limpiar_hover_interaccion()
		ultima_coordenada_hover = Vector2i(-999, -999)
		return
	if interaccion_modal_activa:
		CursorJuego.ocultar_probabilidad_ataque()
		trayectoria_lanzamiento.clear_points()
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
		return
	_evaluar_agro_npc()
	if en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso):
		trayectoria_lanzamiento.clear_points()
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
		_limpiar_hover_interaccion()
		return

	if camera_2d.desplazando or not _dialogos_camara.is_empty() or _puntero_sobre_interfaz():
		trayectoria_lanzamiento.clear_points()
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
		_limpiar_hover_interaccion()
		ultima_coordenada_hover = Vector2i(-999, -999)
		return

	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if not capa_suelo or not ficha_jugador:
		return
	var coord_actual := capa_suelo.local_to_map(capa_suelo.to_local(get_global_mouse_position()))
	if item_lanzamiento_pendiente != null:
		CursorJuego.ocultar_probabilidad_ataque()
		CursorJuego.establecer_cursor(CursorJuego.Tipo.LANZAR)
		if coord_actual != ultima_coordenada_hover:
			_actualizar_previsualizacion_lanzamiento(coord_actual)
			ultima_coordenada_hover = coord_actual
		return
	if habilidad_en_seleccion != "":
		_previsualizar_habilidad_nueva(coord_actual)
		return
	if seleccionando_bola_fuego:
		_actualizar_previsualizacion_bola_fuego(coord_actual, get_global_mouse_position())
		return
	if not _celda_conocida_para_movimiento(coord_actual):
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
		_limpiar_hover_interaccion()
		ultima_coordenada_hover = coord_actual
		return
	_actualizar_hover_interaccion(coord_actual, get_global_mouse_position())
	if coord_actual == ultima_coordenada_hover:
		_actualizar_cursor_movimiento(coord_actual)
		return
	capa_selector.clear()
	if tablero.es_celda_valida(coord_actual):
		capa_selector.set_cell(coord_actual, 0, Vector2i(1, 1))
		camino_actual_tentativo = pathfinding.calcular_camino_conocido(
			ficha_jugador.coordenada_mapa,
			coord_actual,
			tablero.datos,
			ficha_jugador
		)
		if en_combate:
			camino_actual_tentativo = _limitar_camino_jugador(camino_actual_tentativo)
		pathfinding.dibujar_trayectoria(camino_actual_tentativo, capa_camino)
	else:
		camino_actual_tentativo.clear()
		capa_camino.clear()
	_actualizar_cursor_movimiento(coord_actual)
	ultima_coordenada_hover = coord_actual

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.keycode != KEY_SPACE or _camara_bloqueada():
		return
	# Espacio no debe activar un botón del HUD que conserve el foco.
	get_viewport().set_input_as_handled()
	if event.pressed and not event.echo:
		centrar_camara_en_ficha()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		abrir_progresion()
		get_viewport().set_input_as_handled()
		return
	if habilidad_en_seleccion != "" and event.is_action_pressed(&"ui_cancel"):
		_cancelar_habilidad_nueva()
		get_viewport().set_input_as_handled()
		return
	if not es_escenario_de_descanso and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		if is_instance_valid(campamento):
			salir_campamento()
		else:
			entrar_campamento()
		get_viewport().set_input_as_handled()
		return
	if not _dialogos_camara.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and not _camara_bloqueada():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if Rect2(Vector2.ZERO, get_viewport_rect().size).has_point(event.position) and not _puntero_sobre_panel_desplazable():
				var pasos: float = event.factor if event.factor > 0.0 else 1.0
				camera_2d.cambiar_zoom(pasos if event.button_index == MOUSE_BUTTON_WHEEL_UP else -pasos, ficha_jugador.global_position)
				get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V and not interaccion_modal_activa and item_lanzamiento_pendiente == null and ficha_jugador != null:
		capa_vision_npc.alternar(gestor_rondas)
		get_viewport().set_input_as_handled()
		return
	if en_combate and _turno_exploracion_en_curso:
		get_viewport().set_input_as_handled()
		return
	if item_lanzamiento_pendiente != null and event.is_action_pressed(&"ui_cancel"):
		_cancelar_lanzamiento()
		get_viewport().set_input_as_handled()
		return
	if seleccionando_ataque_doble and event.is_action_pressed(&"ui_cancel"):
		seleccionando_ataque_doble = false
		get_viewport().set_input_as_handled()
		return
	if seleccionando_bola_fuego and event.is_action_pressed(&"ui_cancel"):
		_cancelar_bola_fuego()
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
			elif (
				is_instance_valid(panel_inventario_equipo)
				and panel_inventario_equipo.visible
			):
				panel_inventario_equipo.cerrar()
		get_viewport().set_input_as_handled()
		return
	if en_combate and not _es_turno_jugador():
		get_viewport().set_input_as_handled()
		return
	if _activar_atajo_numerico(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_imprimir_celda_bajo_cursor()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I and not dialogo_npc_activo:
		if is_instance_valid(panel_inventario_equipo):
			if panel_inventario_equipo.visible:
				panel_inventario_equipo.cerrar()
			else:
				panel_inventario_equipo.abrir(ficha_jugador)
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
	if camera_2d.desplazando or _puntero_sobre_interfaz():
		return
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if not capa_suelo:
		return
	var coord_clic := capa_suelo.local_to_map(capa_suelo.to_local(get_global_mouse_position()))
	if event.button_index == MOUSE_BUTTON_LEFT:
		_manejar_clic_izquierdo(coord_clic, get_global_mouse_position())
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_manejar_clic_derecho(coord_clic)


func _activar_atajo_numerico(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:
		return false
	var indice := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8].find(event.keycode)
	if indice < 0:
		indice = [KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8].find(event.keycode)
	if indice < 0:
		return false
	var boton: Button = hud.habilidades[indice] if indice < hud.habilidades.size() else hud.items_rapidos[indice - hud.habilidades.size()]
	if not boton.disabled:
		boton.pressed.emit()
	return true


func _imprimir_celda_bajo_cursor() -> void:
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo != null:
		var coordenada := capa_suelo.local_to_map(capa_suelo.to_local(get_global_mouse_position()))
		print(InspectorCeldaDesarrollo.new().describir(tablero, coordenada))

func _manejar_clic_izquierdo(coord: Vector2i, punto_global: Variant = null) -> void:
	if (
		ficha_jugador == null
		or not ficha_jugador.puede_actuar()
		or ficha_jugador.esta_moviendose
		or interaccion_modal_activa
		or (en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso))
	):
		return
	if item_lanzamiento_pendiente != null:
		_seleccionar_celda_lanzamiento(coord)
		return
	if habilidad_en_seleccion != "":
		_seleccionar_habilidad_nueva(coord)
		return
	if seleccionando_ataque_doble:
		_seleccionar_objetivo_ataque_doble(coord, punto_global)
		return
	if seleccionando_bola_fuego:
		_seleccionar_objetivo_bola_fuego(coord, punto_global)
		return
	if not _solicitar_interaccion_en_celda(coord, punto_global):
		_cerrar_menu_contextual()
		return
	_abrir_menu_contextual(get_viewport().get_mouse_position())

func _manejar_clic_derecho(coord: Vector2i) -> void:
	if habilidad_en_seleccion != "":
		_cancelar_habilidad_nueva()
		return
	if not ficha_jugador:
		return
	if not ficha_jugador.puede_actuar():
		return
	if en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso):
		return
	if item_lanzamiento_pendiente != null:
		return
	if interaccion_modal_activa:
		return
	if ficha_jugador.obtener_estado(&"enredado") != null:
		_intentar_destrabarse()
		return
	if ficha_jugador.esta_moviendose:
		# Se interrumpe al terminar el paso en curso, nunca entre dos celdas.
		ficha_jugador.solicitar_interrupcion()
		return
	if not _celda_conocida_para_movimiento(coord):
		return
	if not tablero.puede_entrar(coord, ficha_jugador):
		return
	_cerrar_menu_contextual()

	# La linea dibujada es tentativa: al confirmar se calcula una ruta nueva.
	var camino_confirmado := pathfinding.calcular_camino_conocido(
		ficha_jugador.coordenada_mapa,
		coord,
		tablero.datos,
		ficha_jugador
	)
	if en_combate:
		camino_confirmado = _limitar_camino_jugador(camino_confirmado)
	if camino_confirmado.size() <= 1:
		print("No te puedes mover ahi")
		return

	capa_camino.clear()
	longitud_movimiento_actual = camino_confirmado.size() - 1
	pasos_movimiento_actual = 0
	ficha_jugador.mover_por_camino(
		camino_confirmado,
		_preparar_paso_actor,
		_confirmar_paso_actor,
		_cancelar_paso_actor,
		_procesar_salida_paso_actor,
		_procesar_entrada_paso_actor,
		_calcular_coste_paso_actor,
		_avanzar_turno_exploracion,
		en_combate
	)


func _intentar_destrabarse() -> void:
	var resultado := gestor_acciones.procesar_accion(
		accion_destrabarse.construir_contexto(ficha_jugador)
	)
	ultimo_resultado_contextual = resultado
	_registrar_resultado_narrativo(
		"Telaraña", resultado, EntradaRegistroNarrativo.Categoria.ESTADO
	)
	_presentar_resultado_contextual("Telaraña", resultado)

func _avanzar_turno_exploracion(ficha: Ficha) -> bool:
	if en_combate:
		return false
	var resultado := servicio_turnos.avanzar_turno(ficha)
	if not resultado.exitosa:
		return false
	ficha.avanzar_ocultamiento()
	if resultado.tirada != null:
		historial_tiradas.registrar(resultado.tirada)
	if not resultado.mensajes.is_empty() or not resultado.efectos_aplicados.is_empty():
		var titulo := "Estados"
		if resultado.mensajes.any(func(id): return "quemado" in String(id)):
			titulo = "Quemado"
		if resultado.mensajes.any(func(id): return "veneno" in String(id)):
			titulo = "Veneno" if titulo == "Estados" else "Quemado y veneno"
		_registrar_resultado_narrativo(titulo, resultado, EntradaRegistroNarrativo.Categoria.ESTADO)
	if ficha.pv_actual <= 0:
		return false
	var resultado_superficies := procesador_superficies.procesar_fin_ronda()
	if not resultado_superficies.exitosa or ficha.pv_actual <= 0:
		return false
	_registrar_transformaciones_superficies(resultado_superficies)
	_evaluar_agro_npc()
	if en_combate:
		return false
	ficha.iniciar_turno()
	return true


func _actualizar_reloj_exploracion_npc(delta: float) -> void:
	if not _exploracion_npc_vigente(_secuencia_exploracion_npc) or interaccion_modal_activa:
		_tiempo_exploracion_npc = 0.0
		return
	_tiempo_exploracion_npc += delta
	if _tiempo_exploracion_npc < maxf(0.2, intervalo_exploracion_npc):
		return
	_tiempo_exploracion_npc = 0.0
	_turnos_exploracion_pendientes = 1
	_programar_exploracion_npc()


func _programar_exploracion_npc() -> void:
	if _turno_exploracion_en_curso or _turnos_exploracion_pendientes == 0 or en_combate:
		return
	_turno_exploracion_en_curso = true
	call_deferred("_procesar_cola_exploracion_npc", _secuencia_exploracion_npc)


func _procesar_cola_exploracion_npc(secuencia: int) -> void:
	while _exploracion_npc_vigente(secuencia) and _turnos_exploracion_pendientes > 0:
		_turnos_exploracion_pendientes -= 1
		if not await _procesar_turnos_npc_exploracion(secuencia):
			break
	if secuencia == _secuencia_exploracion_npc:
		_turnos_exploracion_pendientes = 0
	_turno_exploracion_en_curso = false
	_programar_exploracion_npc()


func _exploracion_npc_vigente(secuencia: int) -> bool:
	return (
		secuencia == _secuencia_exploracion_npc and is_inside_tree()
		and not en_combate and not _restaurando_partida
		and ficha_jugador != null and ficha_jugador.puede_actuar()
	)


func _cancelar_exploracion_npc() -> void:
	_secuencia_exploracion_npc += 1
	_turnos_exploracion_pendientes = 0
	_tiempo_exploracion_npc = 0.0
	for entidad in tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC:
			entidad.solicitar_interrupcion()


func _obtener_decisor_npc(npc: PersonajeNPC) -> DecisorCombateNPC:
	var decisor := npc.get_node_or_null("DecisorCombate") as DecisorCombateNPC
	if decisor == null:
		decisor = DecisorCombateNPC.new()
		decisor.name = "DecisorCombate"
		decisor.set_scene_root_hint(self)
		npc.add_child(decisor)
	return decisor


func _liberar_npc(npc: PersonajeNPC) -> bool:
	if npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) <= 0:
		return false
	var resultado := gestor_acciones.procesar_accion(accion_destrabarse.construir_contexto(npc))
	if resultado.tirada != null:
		historial_tiradas.registrar(resultado.tirada)
	_registrar_resultado_narrativo(
		"Liberarse", resultado, EntradaRegistroNarrativo.Categoria.ESTADO, "DES", npc
	)
	return resultado.exitosa


func _procesar_turnos_npc_exploracion(secuencia: int) -> bool:
	# Se lanzan por ID para resolver de forma estable la primera reserva disputada.
	var ids := tablero.interactuables_por_id.keys()
	ids.sort()
	var lote := {"pendientes": 0, "exitoso": true}
	for id in ids:
		if not _exploracion_npc_vigente(secuencia):
			break
		var npc := tablero.obtener_interactuable(id) as PersonajeNPC
		if npc == null or not npc.puede_actuar() or npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) < 0:
			continue
		lote["pendientes"] += 1
		_ejecutar_avance_npc_exploracion(npc, secuencia, lote)
	while lote["pendientes"] > 0:
		await get_tree().process_frame
	return lote["exitoso"] and _exploracion_npc_vigente(secuencia)


func _ejecutar_avance_npc_exploracion(npc: PersonajeNPC, secuencia: int, lote: Dictionary) -> void:
	var exitoso := await _procesar_turno_npc_exploracion(npc, secuencia)
	if not exitoso:
		lote["exitoso"] = false
		if _exploracion_npc_vigente(secuencia):
			_cancelar_exploracion_npc()
	lote["pendientes"] -= 1


func _recalcular_ruta_npc(origen: Vector2i, destino: Vector2i, actor: Node2D) -> Array[Vector2i]:
	return pathfinding.calcular_camino(origen, destino, tablero.datos, actor)


func _procesar_turno_npc_exploracion(npc: PersonajeNPC, secuencia: int) -> bool:
	if npc.esta_moviendose:
		await npc.movimiento.movimiento_terminado
	if not _exploracion_npc_vigente(secuencia) or not is_instance_valid(npc) or not npc.is_inside_tree():
		return false
	if not npc.puede_actuar():
		return true
	_evaluar_agro_npc()
	if not _exploracion_npc_vigente(secuencia):
		return false
	npc.iniciar_turno()
	var decisor := _obtener_decisor_npc(npc)
	while _exploracion_npc_vigente(secuencia) and npc.puede_actuar() and npc.obtener_estado(&"caido") == null:
		var plan: Dictionary = habilidades_nivel_dos.plan_senuelo(npc)
		if plan.is_empty():
			plan = decisor.elegir(npc, tablero, pathfinding)
		var decision: StringName = plan["decision"]
		if decision == &"liberarse":
			if not _liberar_npc(npc):
				break
		elif decision == &"terminar_busqueda":
			npc.olvidar_posicion_jugador()
		elif decision == &"esperar_patrulla":
			npc.obtener_patrulla().consumir_turno_espera()
			break
		elif decision == &"avanzar_patrulla":
			var patrulla := npc.obtener_patrulla()
			patrulla.avanzar_punto()
			if patrulla.esta_esperando():
				break
		elif decision in [&"buscar", &"regresar", &"patrullar"]:
			var camino: Array[Vector2i] = plan["camino"]
			var procesar_entrada := func(desde: Vector2i, hasta: Vector2i, actor: Node2D) -> void:
				_procesar_entrada_paso_actor(desde, hasta, actor)
				if _exploracion_npc_vigente(secuencia):
					_evaluar_agro_npc()
			var completo := await npc.mover_por_camino(
				camino, _preparar_paso_actor, _confirmar_paso_actor,
				_cancelar_paso_actor, _procesar_salida_paso_actor,
				procesar_entrada, _calcular_coste_paso_actor,
				_recalcular_ruta_npc, plan["destino"]
			)
			if not _exploracion_npc_vigente(secuencia):
				return false
			if npc.movimiento.pasos_completados > 0:
				var titulo := "Patrulla de %s"
				if decision == &"buscar":
					titulo = "Búsqueda de %s"
				elif decision == &"regresar":
					titulo = "Regreso de %s"
				registro_narrativo.registrar(
					EntradaRegistroNarrativo.Categoria.MOVIMIENTO,
					titulo % npc.obtener_nombre_interaccion(),
					"Avanza %d casillas." % npc.movimiento.pasos_completados
				)
			if not completo and npc.obtener_estado(&"enredado") == null:
				break
		else:
			break
	if not _exploracion_npc_vigente(secuencia):
		return false
	if not npc.puede_actuar():
		return true
	ficha_jugador.senuelos.erase(String(npc.id_instancia))
	var resultado := servicio_turnos.avanzar_turno(npc)
	if not resultado.exitosa:
		push_warning("No se pudo cerrar el turno de exploración de %s: %s" % [npc.id_instancia, resultado.motivo])
		return false
	if resultado.tirada != null:
		historial_tiradas.registrar(resultado.tirada)
	if not resultado.mensajes.is_empty() or not resultado.efectos_aplicados.is_empty():
		_registrar_resultado_narrativo(
			"Estados", resultado, EntradaRegistroNarrativo.Categoria.ESTADO, "DES", npc
		)
	_evaluar_agro_npc()
	return _exploracion_npc_vigente(secuencia)


func _motivo_bloqueo_persistencia(exigir_reposo: bool, registrar_diagnostico: bool = true) -> StringName:
	if habilidades_nivel_dos != null and (habilidades_nivel_dos.desplazando or habilidades_nivel_dos.empuje_pendiente != null):
		return &"partida_accion_en_curso"
	if is_instance_valid(campamento) and campamento.descanso_pendiente:
		return &"partida_interaccion_activa"
	_actualizar_estado_modal_interaccion()
	if ficha_jugador == null:
		return &"partida_sin_jugador"
	if interaccion_modal_activa:
		return &"partida_interaccion_activa"
	if not exigir_reposo:
		return &""
	if ficha_jugador.esta_moviendose:
		return &"partida_jugador_en_movimiento"
	for entidad in tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC and entidad.esta_moviendose:
			if registrar_diagnostico:
				print("Persistencia: movimiento de %s (%s)." % [entidad.obtener_nombre_interaccion(), entidad.id_instancia])
			return &"partida_npc_en_movimiento"
	if _turno_exploracion_en_curso:
		return &"partida_exploracion_en_curso"
	return &""


func guardar_partida(ruta: String = RUTA_GUARDADO) -> StringName:
	# El snapshot usa casillas confirmadas; no guarda tweens ni reservas de pasos.
	var bloqueo := _motivo_bloqueo_persistencia(false)
	if bloqueo != &"":
		return bloqueo
	var snapshot := persistencia_partida.crear_snapshot(
		tablero, obtener_id_zona(), ficha_jugador, registro_conocimiento, gestor_rondas
	)
	if snapshot.is_empty():
		return &"guardado_invalido"
	snapshot["escena_zona"] = zona_actual.scene_file_path
	snapshot["guardado_en_fogata"] = true
	snapshot["en_campamento"] = false
	var resultado: StringName = persistencia_partida.archivos.guardar(ruta, snapshot)
	if resultado == &"":
		guardado_en_fogata_realizado = true
		EstadoPartida.guardado_en_fogata_realizado = true
	return resultado


func cargar_partida(ruta: String = RUTA_GUARDADO) -> StringName:
	var muerto: bool = ficha_jugador != null and ficha_jugador.pv_actual <= 0
	if not muerto:
		var bloqueo := _motivo_bloqueo_persistencia(true)
		if bloqueo != &"":
			return bloqueo
	var snapshot: Variant = persistencia_partida.archivos.cargar(ruta)
	if snapshot is StringName:
		return snapshot
	if snapshot.has("escena_zona") and snapshot["escena_zona"] != zona_actual.scene_file_path:
		return &"zona_guardado_no_coincide"
	# Antes se llamaba zona1 a todos los mapas; aún se valida su contenido completo.
	if not snapshot.has("escena_zona") and snapshot.get("zona_id") == "zona1":
		snapshot["zona_id"] = String(obtener_id_zona())
	var gestor_guardado: GestorRondas = null
	if snapshot.get("rondas") != null:
		var preparacion: Variant = _preparar_gestor_guardado(snapshot["rondas"])
		if preparacion is StringName:
			return preparacion
		gestor_guardado = preparacion as GestorRondas
	_restaurando_partida = true
	var tenia_vision := gestor_vision.tiene_vision_calculada
	# Las señales de restauración no deben explorar desde la posición anterior.
	gestor_vision.tiene_vision_calculada = false
	var motivo := persistencia_partida.restaurar(
		snapshot, tablero, obtener_id_zona(), ficha_jugador, registro_conocimiento,
		gestor_guardado
	)
	_restaurando_partida = false
	gestor_vision.tiene_vision_calculada = tenia_vision
	if motivo != &"":
		return motivo
	_cancelar_habilidad_nueva()
	if snapshot.has("celdas_exploradas"):
		gestor_vision.reconstruir_niebla_restaurada()
	_actualizar_luz_al_cargar()
	_cancelar_exploracion_npc()
	_secuencia_turno_npc += 1
	for entidad in tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC:
			entidad.en_oposicion_encuentro = false
	# El encuentro anterior no debe limpiar la memoria recién restaurada.
	gestor_rondas = gestor_guardado
	if gestor_guardado == null:
		_terminar_combate(false)
	else:
		en_combate = true
		_reproducir_siguiente_musica_combate(true)
		for id_actor in gestor_rondas.obtener_ids_ordenados():
			var npc := tablero.obtener_interactuable(id_actor) as PersonajeNPC
			if npc != null:
				npc.bando_encuentro = gestor_rondas.obtener_bando(npc)
		_conectar_derrota_combate()
		if not _resolver_fin_combate(false):
			_actualizar_ui_combate()
			_programar_turno_npc()
	pathfinding.inicializar(tablero.datos)
	hud.actualizar_desde_ficha()
	camino_actual_tentativo.clear()
	capa_camino.clear()
	centrar_camara_en_ficha()
	if is_instance_valid(campamento):
		if snapshot.get("en_campamento", false):
			campamento.actualizar()
		else:
			salir_campamento()
	return &""


func obtener_id_zona() -> StringName:
	var ruta := zona_actual.scene_file_path
	return &"zona1" if ruta == "res://scenes/Zona1/zona_1.tscn" else StringName(ruta)


func _crear_acceso_progresion() -> void:
	panel_progresion = preload("res://scenes/ui/personajes/panel_progresion.gd").new()
	add_child(panel_progresion)
	panel_progresion.visibility_changed.connect(_actualizar_estado_modal_interaccion)
	panel_progresion.recompensa_elegida.connect(_aprender_recompensa)
	boton_progresion = Button.new()
	boton_progresion.name = "AccesoProgresion"
	boton_progresion.position = Vector2(24, 124)
	boton_progresion.custom_minimum_size = Vector2(270, 44)
	boton_progresion.text = "Progresión [P]"
	boton_progresion.tooltip_text = "Consulta tu nivel y aprende una de las cuatro recompensas de tu clase al llegar a 100 XP. Fuera de combate."
	boton_progresion.pressed.connect(abrir_progresion)
	$CanvasLayer.add_child(boton_progresion)


func abrir_progresion() -> StringName:
	var motivo := motivo_bloqueo_campamento()
	if motivo != &"" or not is_instance_valid(panel_progresion):
		return motivo if motivo != &"" else &"progresion_no_disponible"
	_cancelar_habilidad_nueva()
	_cancelar_bola_fuego()
	seleccionando_ataque_doble = false
	var opciones: Array[Dictionary] = []
	var resumen := "Nivel %d · %d XP acumulados.\n\n" % [ficha_jugador.nivel, ficha_jugador.experiencia_acumulada]
	if ficha_jugador.nivel_recompensa_pendiente == 2:
		opciones = CatalogoHabilidades.opciones(ficha_jugador.clase)
	elif ficha_jugador.nivel < 2:
		resumen += "Tu próxima recompensa llega a 100 XP: eliges UNA entre dos activas y dos pasivas de tu clase. Conservas tu habilidad inicial."
	else:
		for id in ficha_jugador.activas_aprendidas + ficha_jugador.pasivas_aprendidas:
			var opcion := CatalogoHabilidades.obtener(id)
			resumen += "%s · %s\n%s\n%s\n" % [opcion["nombre"], opcion["tipo"], opcion["descripcion"], opcion["coste"]]
		resumen += "\nConservas tu habilidad inicial. El corte actual llega al nivel 2; la XP sobrante se guarda."
	panel_progresion.mostrar(ficha_jugador.nivel, opciones, resumen)
	_actualizar_estado_modal_interaccion()
	return &""


func _aprender_recompensa(id: String) -> void:
	panel_progresion.hide()
	_actualizar_estado_modal_interaccion()
	if motivo_bloqueo_campamento() != &"" or not ficha_jugador.aprender_recompensa(id):
		return
	hud.actualizar_desde_ficha()
	habilidades_nivel_dos.registrar("Recompensa aprendida", CatalogoHabilidades.obtener(id)["nombre"] + ". Conservas tu habilidad inicial. Consulta la ranura 2.")


func _actualizar_decision_empuje() -> void:
	if habilidades_nivel_dos == null or habilidades_nivel_dos.empuje_pendiente == null or _acciones_en_resolucion > 0:
		return
	# El resultado del ataque básico se lee antes de abrir otra ventana exclusiva.
	if is_instance_valid(panel_resultado_accion) and panel_resultado_accion.visible:
		return
	if not is_instance_valid(panel_empuje):
		panel_empuje = ConfirmationDialog.new()
		panel_empuje.title = "Golpe desplazante · ¡Has acertado!"
		panel_empuje.dialog_text = "Has causado daño. ¿Empujar al enemigo una casilla?\nEs opcional y solo puedes empujar una vez por turno.\nSi lo alejas tras el primer golpe de Ataque doble, el segundo pierde alcance."
		panel_empuje.get_ok_button().text = "Empujar"
		panel_empuje.get_cancel_button().text = "No empujar"
		panel_empuje.exclusive = true
		add_child(panel_empuje)
		panel_empuje.confirmed.connect(func(): _resolver_decision_empuje(true))
		panel_empuje.canceled.connect(func(): _resolver_decision_empuje(false))
	if not panel_empuje.visible:
		panel_empuje.popup_centered()
		panel_empuje.get_cancel_button().grab_focus()


func _resolver_decision_empuje(aceptar: bool) -> void:
	if _acciones_en_resolucion > 0:
		return
	if is_instance_valid(panel_empuje):
		panel_empuje.hide()
	await habilidades_nivel_dos.resolver_empuje(aceptar)


func _on_habilidad_aprendida_hud() -> void:
	if not hud.aprendida_disponible or ficha_jugador == null or _acciones_en_resolucion > 0:
		return
	if ficha_jugador.conoce_habilidad("golpe_desplazante"):
		return # La decisión se ofrece después de causar daño.
	elif ficha_jugador.conoce_habilidad("contagio_arcano"):
		var estados := ["", "veneno", "quemado"]
		ficha_jugador.contagio_elegido = estados[(estados.find(ficha_jugador.contagio_elegido) + 1) % estados.size()]
	elif not ficha_jugador.activas_aprendidas.is_empty():
		var id: String = ficha_jugador.activas_aprendidas[0]
		if ficha_jugador.usos_activas.get(id, 0) < 1:
			return
		var anterior := habilidad_en_seleccion
		_cancelar_habilidad_nueva()
		_cancelar_bola_fuego()
		seleccionando_ataque_doble = false
		if anterior != id:
			habilidad_en_seleccion = id
	ficha_jugador.usos_habilidades_cambiados.emit()


func _cancelar_habilidad_nueva() -> void:
	habilidad_en_seleccion = ""
	fuente_trasvase = null
	if is_instance_valid(trayectoria_lanzamiento):
		trayectoria_lanzamiento.clear_points()
	if is_instance_valid(capa_selector):
		capa_selector.clear()
	CursorJuego.ocultar_probabilidad_ataque()


func _seleccionar_habilidad_nueva(coord: Vector2i) -> void:
	if habilidad_en_seleccion == "trasvase" and fuente_trasvase == null:
		if habilidades_nivel_dos.validar(habilidad_en_seleccion, coord) == &"":
			fuente_trasvase = coord
		return
	var resultado: ResultadoAccion = await habilidades_nivel_dos.ejecutar(habilidad_en_seleccion, coord, fuente_trasvase)
	if resultado.exitosa:
		_cancelar_habilidad_nueva()
	else:
		CursorJuego.mostrar_probabilidad_ataque("OBJETIVO INVÁLIDO · NO SE GASTÓ EL USO · ESC CANCELA")


func _previsualizar_habilidad_nueva(coord: Vector2i) -> void:
	capa_selector.clear()
	capa_camino.clear()
	trayectoria_lanzamiento.clear_points()
	camino_actual_tentativo.clear()
	CursorJuego.establecer_cursor(CursorJuego.Tipo.LANZAR)
	var motivo: StringName = habilidades_nivel_dos.validar(habilidad_en_seleccion, coord, fuente_trasvase)
	var opcion := CatalogoHabilidades.obtener(habilidad_en_seleccion)
	var texto: String = opcion["nombre"].to_upper()
	if motivo != &"":
		if habilidad_en_seleccion == "paso_sombra" and ficha_jugador.turnos_oculto < 1:
			texto += " · REQUIERE ESTAR OCULTO"
		elif motivo == &"recursos_turno_insuficientes":
			texto += " · SIN ACCIÓN DISPONIBLE · OCULTARSE TAMBIÉN GASTA LA ADICIONAL" if habilidad_en_seleccion == "paso_sombra" else " · SIN ACCIÓN DISPONIBLE"
		else:
			texto += " · ELIGE UN OBJETIVO VÁLIDO CON ALCANCE Y PASO LIBRES"
	elif habilidad_en_seleccion == "trasvase":
		texto += " · " + ("CLIC: SUPERFICIE DE ORIGEN" if fuente_trasvase == null else "CLIC: SUELO LIBRE DE DESTINO")
	else:
		texto += " · CLIC PARA USAR · EL DESTINO ACTIVA PELIGROS"
	CursorJuego.mostrar_probabilidad_ataque(texto + " · ESC CANCELA")
	var celda := tablero.obtener_celda(coord)
	if celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE:
		capa_selector.set_cell(coord, 0, Vector2i(1, 1))
		if habilidad_en_seleccion == "ariete" and motivo == &"":
			var dir := coord - ficha_jugador.coordenada_mapa
			for paso in range(1, 3):
				var siguiente := coord + dir * paso
				if not habilidades_nivel_dos.libre(siguiente):
					break
				capa_selector.set_cell(siguiente, 0, Vector2i(1, 1))
	if fuente_trasvase is Vector2i:
		capa_selector.set_cell(fuente_trasvase, 0, Vector2i(1, 1))


func _esperar_escapista() -> bool:
	return ficha_jugador != null and ficha_jugador.esta_moviendose and ficha_jugador.conoce_habilidad("escapista") and "escapista" not in ficha_jugador.pasivas_usadas_turno


func _limitar_camino_jugador(camino: Array[Vector2i]) -> Array[Vector2i]:
	if ficha_jugador.pasos_inercia == 0:
		return pathfinding.limitar_camino_por_movimiento(camino, tablero.datos, ficha_jugador, ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO))
	var resultado: Array[Vector2i] = [ficha_jugador.coordenada_mapa]
	var libres := ficha_jugador.pasos_inercia
	var restante := ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
	for coord in camino:
		if coord == ficha_jugador.coordenada_mapa:
			continue
		if libres > 0:
			libres -= 1
		else:
			restante -= tablero.obtener_celda(coord).calcular_coste_movimiento(ficha_jugador)
			if restante < 0:
				break
		resultado.append(coord)
	return resultado


func _crear_ficha() -> Ficha:
	return ESCENA_FICHA.instantiate() as Ficha


func _crear_acceso_campamento() -> void:
	boton_campamento = Button.new()
	boton_campamento.name = "AccesoCampamento"
	boton_campamento.text = "Campamento [B]"
	boton_campamento.position = Vector2(24, 72)
	boton_campamento.custom_minimum_size = Vector2(210, 44)
	boton_campamento.pressed.connect(entrar_campamento)
	$CanvasLayer.add_child(boton_campamento)


func motivo_bloqueo_campamento() -> StringName:
	if is_instance_valid(campamento):
		return &"campamento_ya_abierto"
	if en_combate or gestor_rondas != null:
		return &"campamento_en_combate"
	if _restaurando_partida or _acciones_en_resolucion > 0:
		return &"campamento_accion_en_curso"
	if not _dialogos_camara.is_empty() or item_lanzamiento_pendiente != null or seleccionando_item_lanzamiento or opcion_uso_item_pendiente != null:
		return &"partida_interaccion_activa"
	var bloqueo := _motivo_bloqueo_persistencia(true, false)
	if bloqueo != &"":
		return bloqueo
	if not ficha_jugador.puede_actuar():
		return &"descanso_jugador_sin_vida"
	return &""


func mensaje_bloqueo_campamento(motivo: StringName) -> String:
	match motivo:
		&"": return "Visitar sin gastar provisiones. Regresas al mismo punto."
		&"campamento_en_combate": return "Termina el combate para ir al campamento."
		&"partida_jugador_en_movimiento", &"partida_npc_en_movimiento", &"partida_exploracion_en_curso", &"campamento_accion_en_curso":
			return "Espera a que termine el movimiento o la acción."
		&"descanso_jugador_sin_vida": return "La ficha sin vida no puede ir al campamento."
		_: return "Cierra el diálogo o menú antes de ir al campamento."


func entrar_campamento() -> StringName:
	var motivo := motivo_bloqueo_campamento()
	if motivo != &"":
		return motivo
	_mostrar_campamento()
	return &""


func _mostrar_campamento() -> void:
	if is_instance_valid(campamento):
		return
	CursorJuego.ocultar_probabilidad_ataque()
	if is_instance_valid(presentacion_zona):
		presentacion_zona.queue_free()
		presentacion_zona = null
	_modo_proceso_antes_campamento = Node.PROCESS_MODE_INHERIT
	campamento = ESCENA_CAMPAMENTO.instantiate()
	campamento.escenario = self
	# Conserva el árbol y todos sus nodos; el campamento procesa en su propia capa.
	process_mode = Node.PROCESS_MODE_DISABLED
	_audio_antes_campamento.clear()
	for nodo in find_children("*", "", true, false):
		if nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D:
			_audio_antes_campamento[nodo] = nodo.stream_paused
			nodo.stream_paused = true
	add_child(campamento)
	CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)


func salir_campamento() -> StringName:
	if not is_instance_valid(campamento):
		return &"campamento_no_abierto"
	if campamento.descanso_pendiente:
		return &"partida_interaccion_activa"
	campamento.queue_free()
	campamento = null
	process_mode = Node.PROCESS_MODE_INHERIT
	for nodo in _audio_antes_campamento:
		if is_instance_valid(nodo):
			nodo.stream_paused = _audio_antes_campamento[nodo]
	_audio_antes_campamento.clear()
	hud.actualizar_desde_ficha()
	_limpiar_seleccion_interaccion()
	interaccion_modal_activa = false
	_actualizar_estado_modal_interaccion()
	return &""


func _preparar_gestor_guardado(estado_rondas: Variant) -> Variant:
	if not estado_rondas is Dictionary:
		return &"estado_rondas_guardado_invalido"
	var orden: Variant = estado_rondas.get("orden_actores")
	if not orden is Array or orden.size() < 2:
		return &"estado_rondas_guardado_invalido"
	var actores: Array[Object] = []
	var incluye_jugador := false
	for id_guardado in orden:
		if not id_guardado is String:
			return &"estado_rondas_guardado_invalido"
		if id_guardado == String(ficha_jugador.obtener_id_actor()):
			actores.append(ficha_jugador)
			incluye_jugador = true
			continue
		var npc := tablero.obtener_interactuable(StringName(id_guardado)) as PersonajeNPC
		if npc == null or npc.obtener_definicion_personaje() == null:
			return &"actores_ronda_guardados_no_coinciden"
		actores.append(npc)
	if not incluye_jugador:
		return &"actores_ronda_guardados_no_coinciden"
	var nuevo_gestor := GestorRondas.new(servicio_turnos, procesador_superficies, MotorDados.new())
	var motivo := nuevo_gestor.preparar_restauracion(actores)
	for actor in actores:
		nuevo_gestor.bandos[actor.obtener_id_actor()] = (
			GestorRondas.Bando.JUGADOR if actor == ficha_jugador else GestorRondas.Bando.OPONENTE
		)
	return motivo if motivo != &"" else nuevo_gestor


func _preparar_paso_actor(_origen: Vector2i, destino: Vector2i, actor: Node2D) -> bool:
	return tablero.reservar_celda(destino, actor)

func _confirmar_paso_actor(origen: Vector2i, destino: Vector2i, actor: Node2D) -> bool:
	return tablero.confirmar_movimiento(origen, destino, actor)

func _cancelar_paso_actor(destino: Vector2i, actor: Node2D) -> void:
	tablero.cancelar_reserva(destino, actor)

func _calcular_coste_paso_actor(
	_origen: Vector2i,
	destino: Vector2i,
	actor: Node2D
) -> int:
	var celda := tablero.obtener_celda(destino)
	return celda.calcular_coste_movimiento(actor) if celda != null else -1

func _procesar_salida_paso_actor(
	origen: Vector2i,
	destino: Vector2i,
	actor: Node2D
) -> void:
	ultimo_resultado_salir = _resolver_reacciones_movimiento(
		TiposInteraccion.TipoAccion.SALIR,
		origen,
		destino,
		actor
	)

func _procesar_entrada_paso_actor(
	origen: Vector2i,
	destino: Vector2i,
	actor: Node2D
) -> void:
	ultimo_resultado_entrar = _resolver_reacciones_movimiento(
		TiposInteraccion.TipoAccion.ENTRAR,
		origen,
		destino,
		actor
	)
	habilidades_nivel_dos.al_paso(origen, destino, actor)

func _resolver_reacciones_movimiento(
	tipo: TiposInteraccion.TipoAccion,
	origen: Vector2i,
	destino: Vector2i,
	actor: Node2D
) -> ResultadoReacciones:
	var coord_consulta := origen if tipo == TiposInteraccion.TipoAccion.SALIR else destino
	var celda := tablero.obtener_celda(coord_consulta)
	var reacciones := consultor_reacciones.obtener_reacciones(celda, tipo, actor)
	var resultado := resolver_reacciones.resolver(
		tipo,
		actor,
		origen,
		destino,
		reacciones
	)
	for resultado_individual in resultado.resultados:
		if resultado_individual.tirada != null:
			historial_tiradas.registrar(resultado_individual.tirada)
	_registrar_reaccion_narrativa(tipo, reacciones, resultado, actor)
	if resultado.interrumpe_movimiento:
		actor.solicitar_interrupcion()
	if actor.has_method(&"obtener_estado") and actor.obtener_estado(&"caido") != null:
		actor.solicitar_interrupcion()
		actor.agotar_recursos_turno()
		if en_combate:
			if gestor_rondas != null and gestor_rondas.actor_activo == actor:
				_finalizar_turno_combate()
		elif actor is Ficha:
			_avanzar_turno_exploracion(actor)
	return resultado


func _registrar_reaccion_narrativa(
	tipo: TiposInteraccion.TipoAccion,
	reacciones: Array[ReaccionCelda],
	resultado: ResultadoReacciones,
	actor: Node2D
) -> void:
	if tipo != TiposInteraccion.TipoAccion.ENTRAR or resultado == null:
		return
	var titulo := ""
	for reaccion in reacciones:
		var receptor := reaccion.receptor
		if receptor is Telarana:
			titulo = "Telaraña"
		elif receptor is Lodo:
			titulo = "Hielo" if receptor.obtener_familia_superficie() == &"hielo" else "Lodo"
		elif receptor is Fuego:
			titulo = "Fuego"
		elif receptor is HumoVeneno:
			titulo = "Humo venenoso"
		elif receptor is TrampaSuperficie:
			titulo = "Trampa"
		elif receptor is TerrenoDanino:
			titulo = "Pinchos" if receptor.id_reaccion == &"pinchos" else "Lava"
		if titulo != "":
			break
	if titulo == "":
		return
	var combinado := ResultadoAccion.crear_exito(
		resultado.mensajes, resultado.efectos_aplicados, resultado.cambios_estado
	)
	for accion in resultado.resultados:
		if accion.tirada != null:
			combinado = combinado.con_tirada(accion.tirada)
			break
	_registrar_resultado_narrativo(
		titulo,
		combinado,
		EntradaRegistroNarrativo.Categoria.MOVIMIENTO,
		"VOL" if titulo == "Humo venenoso" else "DES", actor
	)


func _registrar_resultado_narrativo(
	titulo: String,
	resultado: ResultadoAccion,
	categoria: EntradaRegistroNarrativo.Categoria,
	etiqueta_atributo: String = "DES",
	actor: Node2D = null
) -> void:
	if resultado == null:
		return
	var detalles: Array[String] = []
	if resultado.tirada is ResultadoPrueba:
		var bono: int = resultado.tirada.bono_total
		var ajuste := ""
		if bono != 0:
			ajuste = " %s %d = %d" % [
				"+" if bono > 0 else "−", absi(bono), resultado.tirada.atributo_efectivo
			]
		detalles.append("%s %d%s → dado %d, %s" % [
			etiqueta_atributo,
			resultado.tirada.atributo,
			ajuste,
			resultado.tirada.dado_seleccionado,
			"éxito" if resultado.tirada.exitosa else "fallo",
		])
	elif resultado.tirada is ResultadoTirada:
		detalles.append("Tirada → %d" % resultado.tirada.total_efectivo)
	if resultado.tirada_defensa != null:
		var defensa := resultado.tirada_defensa
		detalles.append("Esquiva DES %d → dado %d, %s" % [
			defensa.atributo_efectivo, defensa.dado_seleccionado,
			"éxito" if defensa.exitosa else "fallo",
		])
	if resultado.tirada_dano != null:
		var atacante: Node2D = actor if actor != null else ficha_jugador
		detalles.append("Daño: %s + %d FUE + %d equipo" % [
			_formatear_pista_tirada(resultado.tirada_dano),
			EfectosEquipo.bono_fuerza_dano(atacante),
			EfectosEquipo.bono_dano(atacante, true),
		])
		for efecto_dano in resultado.efectos_aplicados:
			if efecto_dano.tipo == &"dano":
				var dano_bruto := resultado.tirada_dano.total_efectivo + EfectosEquipo.bono_fuerza_dano(atacante) + EfectosEquipo.bono_dano(atacante, true)
				var reducido := mini(EfectosEquipo.bono_armadura(efecto_dano.objetivo), maxi(0, dano_bruto - 1))
				if reducido > 0:
					detalles.append("Protección: −%d de daño físico" % reducido)
				break
	var mensajes: Array[String] = []
	for id_mensaje in resultado.mensajes:
		if actor is PersonajeNPC and String(id_mensaje).begins_with("estado."):
			id_mensaje = StringName(String(id_mensaje).replace("estado.", "estado.npc_"))
		mensajes.append(
			catalogo_mensajes.resolver(id_mensaje)
			if catalogo_mensajes != null else String(id_mensaje)
		)
	for efecto in resultado.efectos_aplicados:
		if efecto.tipo == &"dano":
			var sujeto := "Recibes" if efecto.objetivo == ficha_jugador else "Infliges"
			if categoria in [EntradaRegistroNarrativo.Categoria.MOVIMIENTO, EntradaRegistroNarrativo.Categoria.ESTADO] and efecto.objetivo is PersonajeNPC:
				sujeto = "%s recibe" % efecto.objetivo.obtener_nombre_interaccion()
			mensajes.append("%s [hint=\"%s\"]%d de daño[/hint]." % [
				sujeto,
				_formatear_pista_tirada(resultado.tirada_dano if resultado.tirada_dano != null else resultado.tirada), int(efecto.magnitud)
			])
	if mensajes.is_empty() and resultado.motivo != &"":
		mensajes.append(
			catalogo_mensajes.resolver(resultado.motivo)
			if catalogo_mensajes != null else String(resultado.motivo)
		)
	if actor is PersonajeNPC:
		titulo = "%s — %s" % [actor.obtener_nombre_interaccion(), titulo]
	registro_narrativo.registrar(categoria, titulo, "\n".join(mensajes), detalles)


func _formatear_pista_tirada(tirada: Variant) -> String:
	if tirada is ResultadoTirada and not tirada.terminos.is_empty():
		var terminos: Array[String] = []
		for termino in tirada.terminos:
			terminos.append("%dd%d → %s" % [termino[&"cantidad"], termino[&"caras"], str(termino[&"resultados"])])
		return ", ".join(terminos)
	return "Resultado de la tirada"


func capturar_textura(angulo:float,jugador: String) -> ImageTexture:
	if DisplayServer.get_name() == "headless":
		return ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))
	var textura: ImageTexture
	
	if jugador == "Guerrero":
		ficha_jugador.sprite_render.position = Vector2(0,-24)
		camaraCaballero.position = Vector3(-10,13.9,10) 
		camaraCaballero.rotation.x = deg_to_rad(-45)
		camaraCaballero.rotation.y = deg_to_rad(-45)
		camaraCaballero.size = 1.5
		caballeroModelo.rotation.y = deg_to_rad(angulo)
		await get_tree().process_frame
		await get_tree().process_frame
		var imagen: Image = subviewportKnight.get_texture().get_image()
		textura = ImageTexture.create_from_image(imagen)
		
	
	if jugador == "Mago":
		ficha_jugador.sprite_render.position = Vector2(0,-24)
		camaraMago.position = Vector3(0,14,10)
		camaraMago.rotation.x = deg_to_rad(-45)
		camaraMago.rotation.y = deg_to_rad(-45)
		magoModelo.rotation.y = deg_to_rad(angulo)
		await get_tree().process_frame
		await get_tree().process_frame
		var imagen: Image = subviewportWizard.get_texture().get_image()
		textura = ImageTexture.create_from_image(imagen)
		
	
	if jugador == "Ladrón":
		ficha_jugador.sprite_render.position = Vector2(0,-16)
		if angulo == 0:
			camaraThief.position = Vector3(10,13.8,10)
		if angulo == 90:
			camaraThief.position = Vector3(10,14,10)
		if angulo == 180:
			camaraThief.position = Vector3(10,14,10)
		if angulo == 270:
			camaraThief.position = Vector3(10,13.9,10)
		#camaraThief.position = Vector3(10,14,10)
		camaraThief.rotation.x = deg_to_rad(-45)
		camaraThief.rotation.y = deg_to_rad(-45)
		ladronModelo.rotation.y = deg_to_rad(angulo)
		await get_tree().process_frame
		await get_tree().process_frame
		var imagen: Image = subviewportThief.get_texture().get_image()
		textura = ImageTexture.create_from_image(imagen)


	return textura


func spawnear_ficha_inicial(id_spawn: StringName = &"entrada") -> void:
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if not capa_suelo:
		return
	var coord_inicio := _obtener_coordenada_spawn(id_spawn, capa_suelo)
	if coord_inicio == Vector2i(-999, -999):
		return
	ficha_jugador = _crear_ficha()
	ficha_jugador.sprite_render = Sprite2D.new()
	subviewportKnight.size = Vector2i(512,512)
	subviewportWizard.size = Vector2i(512, 512)
	subviewportKnight.set_update_mode(SubViewport.UPDATE_ALWAYS)
	subviewportWizard.set_update_mode(SubViewport.UPDATE_ALWAYS)
	subviewportThief.set_update_mode(SubViewport.UPDATE_ALWAYS)

	ficha_jugador.texturas_por_direccion[0]   = await capturar_textura(90,nombreClase)   # Mirando al frente (o derecha)
	ficha_jugador.texturas_por_direccion[90]  = await capturar_textura(0,nombreClase)  # Mirando hacia abajo (si usas Y como eje vertical)
	ficha_jugador.texturas_por_direccion[180] = await capturar_textura(270,nombreClase) # Mirando hacia atrás
	ficha_jugador.texturas_por_direccion[270] = await capturar_textura(180,nombreClase) # Mirando hacia arriba
	ficha_jugador.sprite_render.texture = ficha_jugador.texturas_por_direccion[0]
	ficha_jugador.sprite_render.scale = Vector2(
		0.12,0.12
	)

	ficha_jugador.get_node("Sprite2D").visible = false

	ficha_jugador._aplicar_visual_clase()

	var datos_aventurero := EstadoPartida.consumir_aventurero()
	if not datos_aventurero.is_empty() and not ficha_jugador.configurar_creacion(datos_aventurero):
		push_error("La ficha se creó con valores por defecto: datos de aventurero inválidos.")
	_equipar_carga_inicial(ficha_jugador)
	ficha_jugador.inventario.agregar(ItemInstancia.new(
		&"jugador_antorchas_iniciales", DEFINICION_ANTORCHA, 3
	))
	ficha_jugador.activar_antorcha_si_necesario()
	zona_actual.add_child(ficha_jugador)
	ficha_jugador.inicializar(coord_inicio, capa_suelo)
	ficha_jugador.paso_dado.connect(_on_ficha_paso_dado)
	ficha_jugador.golpe_conectado.connect(habilidades_nivel_dos.al_golpe)
	ficha_jugador.movimiento_terminado.connect(func(_interrumpido):
		habilidades_nivel_dos.al_terminar_movimiento()
		if en_combate:
			_resolver_perdida_agro()
	)
	ficha_jugador.progresion_cambiada.connect(hud.actualizar_desde_ficha)
	tablero.ocupar_celda(coord_inicio, ficha_jugador)


func _equipar_carga_inicial(ficha: Ficha) -> void:
	var piezas: Array[Dictionary] = []
	match ficha.clase:
		"Guerrero":
			piezas = [
				{"id": &"jugador_espada_inicial", "definicion": DEFINICION_ESPADA_INICIAL, "ranura": 3},
				{"id": &"jugador_escudo_inicial", "definicion": DEFINICION_ESCUDO_INICIAL, "ranura": 4},
				{"id": &"jugador_casco_inicial", "definicion": DEFINICION_CASCO_INICIAL, "ranura": 0},
				{"id": &"jugador_pechera_inicial", "definicion": DEFINICION_PECHERA_INICIAL, "ranura": 2},
			]
		"Ladrón":
			piezas = [
				{"id": &"jugador_daga_principal", "definicion": DEFINICION_DAGA_INICIAL, "ranura": 3},
				{"id": &"jugador_daga_secundaria", "definicion": DEFINICION_DAGA_INICIAL, "ranura": 4},
				{"id": &"jugador_capucha_inicial", "definicion": DEFINICION_CAPUCHA_INICIAL, "ranura": 0},
				{"id": &"jugador_botas_ladron", "definicion": DEFINICION_BOTAS_LADRON, "ranura": 6},
			]
		"Mago":
			piezas = [
				{"id": &"jugador_baston_inicial", "definicion": DEFINICION_BASTON_INICIAL, "ranura": 3},
				{"id": &"jugador_tunica_inicial", "definicion": DEFINICION_TUNICA_MAGO, "ranura": 2},
				{"id": &"jugador_botas_mago", "definicion": DEFINICION_BOTAS_MAGO, "ranura": 6},
			]
	for pieza in piezas:
		var item := ItemInstancia.new(pieza.id, pieza.definicion)
		var agregado := ficha.inventario.agregar(item)
		if not agregado.exitosa:
			push_error("No se pudo añadir el equipo inicial %s: %s" % [pieza.id, agregado.motivo])
			continue
		var motivo := ficha.equipo.equipar(ficha.inventario, item.id_instancia, pieza.ranura)
		if motivo != &"":
			push_error("No se pudo equipar %s: %s" % [pieza.id, motivo])


func _obtener_coordenada_spawn(
	id_spawn: StringName,
	capa_suelo: TileMapLayer
) -> Vector2i:
	var puntos: Array[PuntoSpawnZona] = []
	for nodo in zona_actual.find_children("*", "", true, false):
		if nodo is PuntoSpawnZona:
			puntos.append(nodo)
	puntos.sort_custom(func(a, b): return String(a.id_spawn) < String(b.id_spawn))
	var coincidencias: Array[PuntoSpawnZona] = []
	for punto in puntos:
		if punto.id_spawn == id_spawn:
			coincidencias.append(punto)
	if coincidencias.size() > 1:
		push_error("Punto de spawn duplicado: %s" % id_spawn)
		return Vector2i(-999, -999)
	if coincidencias.size() == 1:
		var coordenada := coincidencias[0].obtener_coordenada(capa_suelo)
		if tablero.puede_entrar(coordenada):
			return coordenada
		push_error("Punto de spawn fuera de una celda caminable: %s" % id_spawn)
		return Vector2i(-999, -999)
	if not puntos.is_empty():
		push_error("La zona no contiene el punto de spawn solicitado: %s" % id_spawn)
		return Vector2i(-999, -999)
	# Compatibilidad con zonas anteriores al marcador explícito.
	for coordenada in tablero.datos:
		if tablero.puede_entrar(coordenada):
			return coordenada
	return Vector2i(-999, -999)

func _on_ficha_paso_dado(nueva_coord: Vector2i) -> void:
	_reproducir_sonido_paso()
	if not es_escenario_de_descanso and not ficha_jugador.consumir_paso_antorcha():
		print("El jugador se ha quedado completamente a oscuras.")
	hud.actualizar_desde_ficha()
	_actualizar_luz_jugador(nueva_coord)
	if en_combate and gestor_rondas != null and not _esperar_escapista():
		_resolver_perdida_agro()
	_evaluar_agro_npc()


func _actores_combate() -> Array[Object]:
	var actores: Array[Object] = []
	for id_actor in gestor_rondas.obtener_ids_ordenados():
		var actor: Object = ficha_jugador if id_actor == ficha_jugador.obtener_id_actor() else tablero.obtener_interactuable(id_actor)
		if actor != null and actor.puede_actuar():
			actores.append(actor)
	actores.sort_custom(func(a: Object, b: Object) -> bool: return String(a.obtener_id_actor()) < String(b.obtener_id_actor()))
	return actores


func _objetivo_recordado(npc: PersonajeNPC) -> Object:
	var id := npc.obtener_id_objetivo_recordado()
	var objetivo: Object = ficha_jugador if id == &"" else tablero.obtener_interactuable(id)
	return objetivo if objetivo != null and objetivo.puede_actuar() and gestor_rondas.son_oponentes(npc, objetivo) else null


func _actualizar_memoria_combate() -> bool:
	var actores := _actores_combate()
	var observados := {GestorRondas.Bando.JUGADOR: {}, GestorRondas.Bando.OPONENTE: {}}
	for actor in actores:
		if not actor is PersonajeNPC:
			continue
		for objetivo in actores:
			if gestor_rondas.son_oponentes(actor, objetivo) and actor.puede_ver_actor(objetivo, validador_espacial):
				observados[gestor_rondas.obtener_bando(actor)][objetivo.obtener_id_actor()] = objetivo.coordenada_mapa
	for actor in actores:
		if not actor is PersonajeNPC:
			continue
		var vistos: Dictionary = observados[gestor_rondas.obtener_bando(actor)]
		var elegido: Object = null
		var menor_distancia := INF
		for objetivo in actores:
			if not vistos.has(objetivo.obtener_id_actor()):
				continue
			var distancia := Vector2(actor.coordenada_mapa - vistos[objetivo.obtener_id_actor()]).length_squared()
			if elegido == null or distancia < menor_distancia or (distancia == menor_distancia and String(objetivo.obtener_id_actor()) < String(elegido.obtener_id_actor())):
				elegido = objetivo
				menor_distancia = distancia
		if elegido != null:
			actor.recordar_objetivo(elegido, vistos[elegido.obtener_id_actor()])
		elif _objetivo_recordado(actor) == null:
			actor.olvidar_posicion_jugador()
	return not observados[GestorRondas.Bando.JUGADOR].is_empty() or not observados[GestorRondas.Bando.OPONENTE].is_empty()


func _resolver_perdida_agro() -> bool:
	if not en_combate or gestor_rondas == null or not ficha_jugador.puede_actuar():
		return false
	if _resolver_fin_combate():
		return true
	_incorporar_npc_al_combate()
	if _actualizar_memoria_combate():
		return false
	ficha_jugador.solicitar_interrupcion()
	registro_narrativo.registrar(
		EntradaRegistroNarrativo.Categoria.SISTEMA, "Has escapado",
		"Ya no te detectan. Termina el combate y vuelves a explorar."
	)
	_terminar_combate(true, true)
	return true


func _asignar_bando(npc: PersonajeNPC, bando: int) -> void:
	gestor_rondas.bandos[npc.obtener_id_actor()] = bando
	if npc.bando_encuentro != bando:
		npc.bando_encuentro = bando
		npc.solicitar_interrupcion()
		npc.olvidar_posicion_jugador()


func _incorporar_con_bando(npc: PersonajeNPC, bando: int) -> void:
	if npc.obtener_id_actor() not in gestor_rondas.obtener_ids_ordenados():
		var motivo := gestor_rondas.incorporar_actor(npc)
		if motivo != &"":
			push_warning("No se pudo incorporar NPC: %s" % motivo)
			return
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA, "Se une %s" % npc.obtener_nombre_interaccion(),
			"Ha visto el encuentro. Actuará al final de esta ronda."
		)
	_asignar_bando(npc, bando)


func _bando_auxilio(npc: PersonajeNPC, actores: Array[Object]) -> int:
	# La defensa de un compañero precede a la relación individual con el jugador.
	for actor in actores:
		if (
			actor is PersonajeNPC and actor.obtener_id_actor() in gestor_rondas.defendidos
			and npc.comparte_faccion(actor)
			and npc.puede_ver_actor(actor, validador_espacial, 7)
		):
			return gestor_rondas.obtener_bando(actor)
	var actitud := npc.obtener_actitud_hacia_jugador()
	for actor in actores:
		if not npc.puede_ver_actor(actor, validador_espacial, 7):
			continue
		if actitud == DefinicionPersonaje.ActitudInicialJugador.HOSTIL:
			return GestorRondas.Bando.OPONENTE
		if actitud == DefinicionPersonaje.ActitudInicialJugador.AMISTOSA and ficha_jugador.obtener_id_actor() in gestor_rondas.defendidos:
			if gestor_rondas.obtener_bando(actor) == GestorRondas.Bando.JUGADOR or (actor is PersonajeNPC and actor.obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.HOSTIL):
				return GestorRondas.Bando.JUGADOR
	return GestorRondas.Bando.NEUTRAL


func _incorporar_npc_al_combate() -> void:
	var ids := gestor_rondas.obtener_ids_ordenados()
	var actores := _actores_combate()
	var candidatos: Array[PersonajeNPC] = []
	var bandos := {}
	for entidad in tablero.interactuables_por_id.values():
		if not entidad is PersonajeNPC or entidad.obtener_id_actor() in ids:
			continue
		var perfil: DefinicionPersonaje = entidad.obtener_definicion_personaje()
		if perfil == null or not perfil.puede_combatir or not entidad.puede_actuar():
			continue
		var bando := _bando_auxilio(entidad, actores)
		if bando != GestorRondas.Bando.NEUTRAL:
			candidatos.append(entidad)
			bandos[entidad.obtener_id_actor()] = bando
	candidatos.sort_custom(func(a: PersonajeNPC, b: PersonajeNPC) -> bool: return String(a.obtener_id_actor()) < String(b.obtener_id_actor()))
	for npc in candidatos:
		_incorporar_con_bando(npc, bandos[npc.obtener_id_actor()])
	if not candidatos.is_empty():
		_conectar_derrota_combate()
		_actualizar_ui_combate()


func _on_agresion_resuelta(contexto: ContextoAccion, resultado: ResultadoAccion) -> void:
	if contexto.actor == ficha_jugador and contexto.id_accion == &"ataque_basico" and resultado.tirada != null:
		ficha_jugador.romper_ocultamiento()
	if not en_combate or resultado.tirada == null:
		return
	var victima: Object = null
	if contexto.id_accion == &"ataque_basico" and contexto.objetivo is PersonajeNPC:
		victima = contexto.objetivo
	elif contexto.id_accion == &"ataque_basico_npc" and contexto.objetivo is AccionAtaqueNPC:
		victima = contexto.objetivo.objetivo
	if victima == null:
		return
	if victima.obtener_id_actor() not in gestor_rondas.defendidos:
		gestor_rondas.defendidos.append(victima.obtener_id_actor())
	if victima == ficha_jugador and resultado != null:
		var es_acierto := false
		for msg in resultado.mensajes:
			if String(msg).ends_with("ataque_acertado"):
				es_acierto = true
				break
		if es_acierto and ficha_jugador != null and ficha_jugador.get_parent() != null:
			EfectoCorteSangre.instanciar_en(ficha_jugador.get_parent(), ficha_jugador.global_position)
	var testigos: Array[PersonajeNPC] = []
	for entidad in tablero.interactuables_por_id.values():
		if not entidad is PersonajeNPC or entidad == victima or entidad == contexto.actor:
			continue
		var perfil: DefinicionPersonaje = entidad.obtener_definicion_personaje()
		if perfil == null or not perfil.puede_combatir or not entidad.puede_actuar():
			continue
		if entidad.puede_ver_coordenada(contexto.origen, validador_espacial) and entidad.puede_ver_coordenada(contexto.celda_objetivo, validador_espacial):
			if (victima is PersonajeNPC and entidad.comparte_faccion(victima)) or (
				victima == ficha_jugador
				and entidad.obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.AMISTOSA
				and contexto.actor.obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.HOSTIL
			):
				testigos.append(entidad)
	testigos.sort_custom(func(a: PersonajeNPC, b: PersonajeNPC) -> bool: return String(a.obtener_id_actor()) < String(b.obtener_id_actor()))
	for npc in testigos:
		# La defensa propia ya establecida no se sustituye por auxilio a otro actor.
		if npc.obtener_id_actor() not in gestor_rondas.defendidos:
			_incorporar_con_bando(npc, gestor_rondas.obtener_bando(victima))
	if not testigos.is_empty():
		_conectar_derrota_combate()
		_actualizar_ui_combate()


func _evaluar_agro_npc() -> void:
	if (
		en_combate or _restaurando_partida or interaccion_modal_activa
		or lanzamiento_en_vuelo or ficha_jugador == null or not ficha_jugador.puede_actuar()
		or not gestor_vision.tiene_vision_calculada
	):
		return
	var objetivo: PersonajeNPC = null
	var menor_distancia := INF
	for entidad in tablero.interactuables_por_id.values():
		if not entidad is PersonajeNPC or not entidad.puede_detectar_jugador(ficha_jugador, validador_espacial):
			continue
		var distancia := Vector2(entidad.coordenada_mapa - ficha_jugador.coordenada_mapa).length_squared()
		if (
			objetivo == null or distancia < menor_distancia
			or (distancia == menor_distancia and String(entidad.id_instancia) < String(objetivo.id_instancia))
		):
			objetivo = entidad
			menor_distancia = distancia
	if objetivo != null and _iniciar_combate(objetivo, false):
		ficha_jugador.solicitar_interrupcion()
		camino_actual_tentativo.clear()
		capa_camino.clear()
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA,
			"Detectado por %s" % objetivo.obtener_nombre_interaccion(),
			"Te ha visto. Comienza el combate."
		)


func _on_pasar_turno_hud() -> void:
	_cancelar_habilidad_nueva()
	seleccionando_ataque_doble = false
	_cancelar_bola_fuego()
	if ficha_jugador == null or not ficha_jugador.puede_actuar() or ficha_jugador.esta_moviendose or interaccion_modal_activa:
		return
	if en_combate:
		if _es_turno_jugador() and not _turno_exploracion_en_curso:
			_finalizar_turno_combate()
		return
	_avanzar_turno_exploracion(ficha_jugador)


func _on_ataque_doble_hud() -> void:
	_cancelar_habilidad_nueva()
	if (
		ficha_jugador == null or ficha_jugador.clase != "Guerrero"
		or not ficha_jugador.puede_actuar() or ficha_jugador.usos_ataque_doble < 1
		or ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) < 1
		or not en_combate or not _es_turno_jugador() or _turno_exploracion_en_curso
		or ficha_jugador.esta_moviendose or interaccion_modal_activa
	):
		return
	seleccionando_ataque_doble = not seleccionando_ataque_doble
	hud.habilidades[0].tooltip_text = (
		"Atajo 1 · Haz clic en un enemigo adyacente. Esc cancela."
		if seleccionando_ataque_doble else "Atajo 1 · Ataque doble: selecciona un enemigo adyacente."
	)


func _on_ocultarse_hud() -> void:
	_cancelar_habilidad_nueva()
	if (
		ficha_jugador == null or ficha_jugador.clase != "Ladrón"
		or not ficha_jugador.puede_actuar() or ficha_jugador.usos_ocultarse < 1
		or (en_combate and not _es_turno_jugador()) or _turno_exploracion_en_curso
		or ficha_jugador.esta_moviendose or interaccion_modal_activa
		or not ficha_jugador.consumir_recurso_turno(RecursosTurnoActor.ACCION_ADICIONAL, 1)
	):
		return
	ficha_jugador.ocultarse()
	_reproducir_sonido_ocultarse()
	registro_narrativo.registrar(
		EntradaRegistroNarrativo.Categoria.SISTEMA, "Ocultarse",
		"El Ladrón desaparece de la vista durante dos turnos. Atacar o recibir daño rompe el sigilo."
	)
	_resolver_perdida_agro()


func _on_bola_fuego_hud() -> void:
	_cancelar_habilidad_nueva()
	if (
		ficha_jugador == null or ficha_jugador.clase != "Mago"
		or not ficha_jugador.puede_actuar() or ficha_jugador.usos_bola_fuego < 1
		or ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) < 1
		or (en_combate and not _es_turno_jugador()) or _turno_exploracion_en_curso
		or ficha_jugador.esta_moviendose or interaccion_modal_activa
		or item_lanzamiento_pendiente != null
	):
		return
	seleccionando_bola_fuego = not seleccionando_bola_fuego
	if not seleccionando_bola_fuego:
		_cancelar_bola_fuego()
	else:
		_limpiar_hover_interaccion()


func _on_item_rapido_hud_solicitado(indice: int) -> void:
	if indice < 0 or indice >= hud.items_rapidos_asignados.size():
		return
	_usar_item_inventario(hud.items_rapidos_asignados[indice])


func _on_item_inventario_uso_solicitado(item: ItemInstancia) -> void:
	panel_inventario_equipo.cerrar()
	_actualizar_estado_modal_interaccion()
	_usar_item_inventario(item)


func _usar_item_inventario(item: ItemInstancia) -> void:
	if (
		ficha_jugador == null
		or not ficha_jugador.puede_actuar()
		or ficha_jugador.esta_moviendose
		or interaccion_modal_activa
		or item_lanzamiento_pendiente != null
	):
		return
	if en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso):
		return
	if item == null:
		return
	var item_en_inv := ficha_jugador.inventario.obtener_por_id(item.id_instancia)
	if item_en_inv == null or item_en_inv.cantidad <= 0:
		for indice in hud.items_rapidos_asignados.size():
			if hud.items_rapidos_asignados[indice] == item:
				hud.items_rapidos_asignados[indice] = null
		hud.actualizar_desde_ficha()
		return

	if &"arrojable" in item_en_inv.definicion.etiquetas:
		_cancelar_bola_fuego()
		seleccionando_item_lanzamiento = true
		_on_item_contextual_elegido(item_en_inv)
		return
	if item_en_inv.definicion.id_definicion == &"antorcha":
		var activa := ficha_jugador.obtener_pila_antorcha_activa()
		if activa == null:
			return
		var duracion := int(activa.definicion.magnitudes.get(&"duracion", float(Ficha.PASOS_MAX_ANTORCHA)))
		if ficha_jugador.pasos_antorcha_actual > 0:
			if ficha_jugador.pasos_antorcha_actual >= duracion or ficha_jugador.obtener_cantidad_antorchas() < 2:
				return
			# La antorcha encendida permanece en la mochila hasta agotarse o reemplazarse.
			ficha_jugador.inventario.consumir_unidad(activa.id_instancia)
		ficha_jugador.activar_antorcha_si_necesario()
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA,
			"Usar antorcha",
			"Enciendes una antorcha. Pasos al máximo (%d)." % ficha_jugador.pasos_antorcha_actual
		)
	elif (
		item_en_inv.definicion.id_definicion == &"racion"
		or item_en_inv.definicion.magnitudes.has(&"recuperacion_pv_dados")
		or item_en_inv.definicion.magnitudes.has(&"recuperacion_pv")
	):
		var es_racion := item_en_inv.definicion.id_definicion == &"racion"
		if ficha_jugador.pv_actual >= ficha_jugador.pv_max:
			registro_narrativo.registrar(EntradaRegistroNarrativo.Categoria.SISTEMA, item_en_inv.definicion.nombre, "Ya tienes la vida completa.")
			return
		var valor_defecto := 5 if es_racion else 0
		var formula := item_en_inv.definicion.obtener_formula_curacion(valor_defecto)
		var curacion := item_en_inv.definicion.resolver_curacion(null, valor_defecto)
		if curacion <= 0:
			return
		var pv_curados := ficha_jugador.curar(curacion)
		ficha_jugador.inventario.consumir_unidad(item_en_inv.id_instancia)
		if es_racion and ficha_jugador.raciones > 0:
			ficha_jugador.raciones -= 1
		var mensaje := "Tirada de curación: %s = %d. Recuperas %d PV." % [formula, curacion, pv_curados]
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA,
			item_en_inv.definicion.nombre,
			mensaje
		)
	else:
		return

	if panel_inventario_equipo != null and panel_inventario_equipo.visible:
		panel_inventario_equipo.refrescar_mochila()
		panel_inventario_equipo.refrescar_peso()
	hud.actualizar_desde_ficha()


func _seleccionar_objetivo_bola_fuego(coord: Vector2i, punto_global: Variant) -> void:
	var objetivo := _obtener_objetivo_bola_fuego(coord, punto_global)
	if objetivo != null:
		var resultado := ejecutar_bola_fuego(objetivo)
		if resultado.exitosa:
			_cancelar_bola_fuego()
		_registrar_resultado_narrativo("Bola de fuego", resultado, EntradaRegistroNarrativo.Categoria.OBJETO)
		_presentar_resultado_contextual("Bola de fuego", resultado)
		return
	if ficha_jugador.conoce_habilidad("piromancia_libre"):
		var resultado: ResultadoAccion = habilidades_nivel_dos.lanzar_al_suelo(coord)
		if resultado.exitosa:
			_cancelar_bola_fuego()
		else:
			CursorJuego.mostrar_probabilidad_ataque("ELIGE SUELO VACÍO VISIBLE A 4 CASILLAS")
		return
	_presentar_resultado_contextual("Bola de fuego", ResultadoAccion.crear_bloqueo(&"objetivo_no_combatiente"))


func _obtener_objetivo_bola_fuego(coord: Vector2i, punto_global: Variant) -> PersonajeNPC:
	# El hechizo apunta a una casilla, incluso si el clic no cae sobre el sprite.
	var celda := tablero.obtener_celda(coord)
	if celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE:
		for interactuable in celda.interactuables:
			if interactuable is PersonajeNPC and interactuable.puede_actuar():
				return interactuable
	# Un sprite alto también se puede seleccionar por su silueta.
	for interactuable in selector_objetivos.obtener_objetivos_perceptibles(tablero, coord, ficha_jugador, punto_global):
		if interactuable is PersonajeNPC and interactuable.puede_actuar():
			return interactuable
	return null


func _actualizar_previsualizacion_bola_fuego(coord: Vector2i, punto_global: Vector2) -> void:
	CursorJuego.establecer_cursor(CursorJuego.Tipo.LANZAR)
	capa_camino.clear()
	camino_actual_tentativo.clear()
	trayectoria_lanzamiento.clear_points()
	capa_selector.clear()
	var objetivo := _obtener_objetivo_bola_fuego(coord, punto_global)
	var destino: Vector2i = objetivo.coordenada_mapa if objetivo != null else coord
	var celda := tablero.obtener_celda(destino)
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		CursorJuego.mostrar_probabilidad_ataque("BOLA DE FUEGO · SIN VISIÓN")
		return
	capa_selector.set_cell(destino, 0, Vector2i(1, 1))
	var en_alcance := _distancia_cuadricula(ficha_jugador.coordenada_mapa, destino) <= 4
	var linea_libre := validador_espacial.validar_linea_visual(ficha_jugador.coordenada_mapa, destino) == &""
	var mensaje := "BOLA DE FUEGO · "
	if not en_alcance:
		mensaje += "FUERA DE ALCANCE (4)"
	elif not linea_libre:
		mensaje += "SIN LÍNEA DE VISIÓN"
	elif objetivo == null:
		mensaje += "CLIC: CREAR FUEGO (3 TURNOS)" if ficha_jugador.conoce_habilidad("piromancia_libre") else "ELIGE UN ENEMIGO"
	else:
		mensaje += "CLIC PARA LANZAR"
	CursorJuego.mostrar_probabilidad_ataque(mensaje)
	var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo == null:
		return
	trayectoria_lanzamiento.points = PackedVector2Array([
		trayectoria_lanzamiento.to_local(capa_suelo.to_global(capa_suelo.map_to_local(ficha_jugador.coordenada_mapa))),
		trayectoria_lanzamiento.to_local(capa_suelo.to_global(capa_suelo.map_to_local(destino))),
	])
	trayectoria_lanzamiento.default_color = (
		Color(0.3, 1.0, 0.4, 0.9) if objetivo != null and en_alcance and linea_libre
		else Color(1.0, 0.35, 0.15, 0.9)
	)


func _cancelar_bola_fuego() -> void:
	seleccionando_bola_fuego = false
	trayectoria_lanzamiento.clear_points()
	capa_selector.clear()
	CursorJuego.ocultar_probabilidad_ataque()
	CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)


func ejecutar_bola_fuego(objetivo: PersonajeNPC) -> ResultadoAccion:
	if (
		ficha_jugador == null or ficha_jugador.clase != "Mago"
		or not ficha_jugador.puede_actuar() or ficha_jugador.usos_bola_fuego < 1
		or (en_combate and not _es_turno_jugador()) or _turno_exploracion_en_curso
		or objetivo == null or not is_instance_valid(objetivo) or not objetivo.puede_actuar()
		or ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) < 1
	):
		return ResultadoAccion.crear_bloqueo(&"bola_fuego_no_disponible")
	if en_combate and not gestor_rondas.son_oponentes(ficha_jugador, objetivo):
		return ResultadoAccion.crear_bloqueo(&"objetivo_no_oponente")
	var celda_objetivo := tablero.obtener_celda(objetivo.coordenada_mapa)
	if celda_objetivo == null or celda_objetivo.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return ResultadoAccion.crear_bloqueo(&"objetivo_no_visible")
	if _distancia_cuadricula(ficha_jugador.coordenada_mapa, objetivo.coordenada_mapa) > 4:
		return ResultadoAccion.crear_bloqueo(&"fuera_de_alcance")
	var motivo := validador_espacial.validar_linea_visual(ficha_jugador.coordenada_mapa, objetivo.coordenada_mapa)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var aplicador := AplicadorEfectos.new()
	var dano := SolicitudEfecto.new(&"bola_fuego", &"dano", objetivo, &"bola_fuego", 1.0, 0, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, ficha_jugador)
	var quemado := SolicitudEfecto.new(&"quemado", &"estado", objetivo, &"bola_fuego", 0.0, 3, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, ficha_jugador, [{&"cantidad": 1, &"caras": 2, &"signo": 1}])
	for solicitud in [dano, quemado]:
		motivo = aplicador.validar(solicitud)
		if motivo != &"":
			return ResultadoAccion.crear_bloqueo(motivo)
	if not en_combate and not _iniciar_combate(objetivo):
		return ResultadoAccion.crear_bloqueo(&"npc_no_combatiente")
	if not ficha_jugador.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1):
		return ResultadoAccion.crear_bloqueo(&"recursos_turno_insuficientes")
	ficha_jugador.consumir_bola_fuego()
	reproducir_sonido_magia_fuego()
	var celda_impacto := objetivo.coordenada_mapa
	var aplica_quemado := randf() < 0.5
	var efecto: Variant = aplicador.aplicar(dano)
	if efecto is StringName:
		return ResultadoAccion.crear_fallo(efecto)
	var efectos: Array = [efecto]
	habilidades_nivel_dos.encender_celda(celda_impacto)
	if efecto.magnitud > 0:
		habilidades_nivel_dos.al_golpe(objetivo)
	if objetivo.puede_actuar() and aplica_quemado:
		var estado: Variant = aplicador.aplicar(quemado)
		if estado is StringName:
			return ResultadoAccion.crear_fallo(estado)
		efectos.append(estado)
	return ResultadoAccion.crear_exito([], efectos)


func _seleccionar_objetivo_ataque_doble(coord: Vector2i, punto_global: Variant) -> void:
	for objetivo in selector_objetivos.obtener_objetivos_perceptibles(tablero, coord, ficha_jugador, punto_global):
		if objetivo is PersonajeNPC and objetivo.puede_actuar():
			var golpes := await ejecutar_ataque_doble(objetivo)
			if golpes.is_empty():
				return
			if golpes[0].tirada != null:
				seleccionando_ataque_doble = false
			_mostrar_resultados_ataque_doble(golpes)
			return
	_presentar_resultado_contextual("Ataque doble", ResultadoAccion.crear_bloqueo(&"objetivo_no_combatiente"))


func ejecutar_ataque_doble(objetivo: PersonajeNPC) -> Array[ResultadoAccion]:
	var golpes: Array[ResultadoAccion] = []
	if (
		ficha_jugador == null or ficha_jugador.clase != "Guerrero"
		or not ficha_jugador.puede_actuar() or ficha_jugador.usos_ataque_doble < 1
		or not en_combate or not _es_turno_jugador() or _turno_exploracion_en_curso
		or objetivo == null or not is_instance_valid(objetivo)
	):
		golpes.append(ResultadoAccion.crear_bloqueo(&"ataque_doble_no_disponible"))
		return golpes
	if gestor_rondas.obtener_bando(objetivo) != GestorRondas.Bando.OPONENTE:
		golpes.append(ResultadoAccion.crear_bloqueo(&"objetivo_no_oponente"))
		return golpes
	var opcion: OpcionAccion = null
	for candidata in objetivo.obtener_opciones_accion(ficha_jugador):
		if candidata.id == &"ataque_basico":
			opcion = candidata
			break
	if opcion == null:
		golpes.append(ResultadoAccion.crear_bloqueo(&"npc_no_combatiente"))
		return golpes
	var construccion: Variant = constructor_contexto_accion.construir_desde_opcion(
		opcion, ficha_jugador, ficha_jugador.coordenada_mapa, objetivo.coordenada_mapa
	)
	if not construccion is ContextoAccion:
		golpes.append(ResultadoAccion.crear_bloqueo(construccion))
		return golpes
	var contexto := construccion as ContextoAccion
	if not gestor_acciones.esta_en_alcance(contexto):
		golpes.append(ResultadoAccion.crear_bloqueo(&"fuera_de_alcance"))
		return golpes
	var primero := gestor_acciones.procesar_accion(contexto)
	golpes.append(primero)
	if primero.tirada == null:
		return golpes
	ficha_jugador.consumir_ataque_doble()
	if habilidades_nivel_dos.empuje_pendiente != null:
		await habilidades_nivel_dos.empuje_resuelto
	if objetivo.puede_actuar() and habilidades_nivel_dos._distancia(ficha_jugador.coordenada_mapa, objetivo.coordenada_mapa) == 1:
		golpes.append(objetivo.resolver_golpe_extra_ataque_doble(contexto))
		if habilidades_nivel_dos.empuje_pendiente != null:
			await habilidades_nivel_dos.empuje_resuelto
	return golpes


func _mostrar_resultados_ataque_doble(golpes: Array[ResultadoAccion]) -> void:
	for indice in golpes.size():
		var resultado := golpes[indice]
		var titulo := "Ataque doble · golpe %d" % (indice + 1)
		_registrar_resultado_narrativo(
			titulo, resultado, EntradaRegistroNarrativo.Categoria.OBJETO, "FUE"
		)
		if indice < golpes.size() - 1:
			if resultado.tirada != null:
				historial_tiradas.registrar(resultado.tirada)
			if resultado.tirada_defensa != null:
				historial_tiradas.registrar(resultado.tirada_defensa)
			if resultado.tirada_dano != null:
				historial_tiradas.registrar(resultado.tirada_dano)
		else:
			_presentar_resultado_contextual(titulo, resultado)


func _es_turno_jugador() -> bool:
	return gestor_rondas != null and gestor_rondas.actor_activo == ficha_jugador


func _iniciar_combate(objetivo: PersonajeNPC, agresion_jugador: bool = true) -> bool:
	if objetivo == null or objetivo.esta_derrotado() or ficha_jugador == null:
		return false
	var perfil := objetivo.obtener_definicion_personaje()
	if perfil == null or not perfil.puede_combatir:
		return false
	if en_combate:
		_incorporar_con_bando(objetivo, GestorRondas.Bando.OPONENTE)
		_conectar_derrota_combate()
		_actualizar_ui_combate()
		return true
	var nuevo_gestor := GestorRondas.new(servicio_turnos, procesador_superficies, MotorDados.new())
	var actores: Array[Object] = [ficha_jugador, objetivo]
	for entidad in tablero.interactuables_por_id.values():
		if (
			entidad is PersonajeNPC and entidad != objetivo
			and entidad.puede_detectar_jugador(ficha_jugador, validador_espacial)
		):
			actores.append(entidad)
	var inicio := nuevo_gestor.iniciar(actores)
	if not inicio.exitoso:
		push_warning("No se pudo iniciar combate: %s" % inicio.motivo)
		return false
	gestor_rondas = nuevo_gestor
	en_combate = true
	_reproducir_siguiente_musica_combate(true)
	gestor_rondas.bandos[ficha_jugador.obtener_id_actor()] = GestorRondas.Bando.JUGADOR
	if not agresion_jugador:
		gestor_rondas.defendidos.append(ficha_jugador.obtener_id_actor())
	_cancelar_exploracion_npc()
	ficha_jugador.solicitar_interrupcion()
	for actor in actores:
		if actor is PersonajeNPC:
			_asignar_bando(actor, GestorRondas.Bando.OPONENTE)
			actor.solicitar_interrupcion()
			actor.olvidar_posicion_jugador()
	_incorporar_npc_al_combate()
	_actualizar_memoria_combate()
	_conectar_derrota_combate()
	_registrar_iniciativa_combate()
	_actualizar_ui_combate()
	_programar_turno_npc()
	return true


func _finalizar_turno_combate() -> void:
	if not en_combate or gestor_rondas == null:
		return
	var actor_finalizado := gestor_rondas.actor_activo as Node2D
	if actor_finalizado is PersonajeNPC:
		ficha_jugador.senuelos.erase(String(actor_finalizado.id_instancia))
	var avance := gestor_rondas.finalizar_turno_activo()
	if not avance.exitoso:
		push_warning("No se pudo avanzar turno de combate: %s" % avance.motivo)
		return
	if actor_finalizado == ficha_jugador:
		ficha_jugador.avanzar_ocultamiento()
	if avance.resultado_turno != null:
		var resultado: ResultadoAccion = avance.resultado_turno
		if resultado.tirada != null:
			historial_tiradas.registrar(resultado.tirada)
		if not resultado.mensajes.is_empty() or not resultado.efectos_aplicados.is_empty():
			_registrar_resultado_narrativo(
				"Estados", resultado, EntradaRegistroNarrativo.Categoria.ESTADO,
				"DES", actor_finalizado
			)
	if avance.resultado_superficies != null:
		_registrar_transformaciones_superficies(avance.resultado_superficies)
	if avance.nueva_ronda:
		_registrar_iniciativa_combate()
	if _resolver_fin_combate():
		return
	if _resolver_perdida_agro():
		return
	_actualizar_ui_combate()
	_programar_turno_npc()


func _plan_combate_npc(npc: PersonajeNPC) -> Dictionary:
	var senuelo: Dictionary = habilidades_nivel_dos.plan_senuelo(npc)
	if not senuelo.is_empty():
		return senuelo
	var visibles: Array[Object] = []
	for actor in _actores_combate():
		if gestor_rondas.son_oponentes(npc, actor) and npc.puede_ver_actor(actor, validador_espacial):
			visibles.append(actor)
	var decisor := _obtener_decisor_npc(npc)
	return decisor.elegir(npc, tablero, pathfinding, visibles, true)


func _programar_turno_npc() -> void:
	_secuencia_turno_npc += 1
	if not en_combate or _es_turno_jugador() or gestor_rondas.actor_activo == null:
		return
	var secuencia := _secuencia_turno_npc
	await get_tree().create_timer(0.6).timeout
	if not _turno_npc_vigente(secuencia) or _resolver_fin_combate():
		return
	if ficha_jugador.esta_moviendose:
		await ficha_jugador.movimiento_terminado
		if not _turno_npc_vigente(secuencia):
			return
	for entidad in tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC and entidad.esta_moviendose:
			await entidad.movimiento.movimiento_terminado
			if not _turno_npc_vigente(secuencia):
				return
	var npc := gestor_rondas.actor_activo as PersonajeNPC
	if npc == null:
		_finalizar_turno_combate()
		return
	while _turno_npc_vigente(secuencia) and npc.puede_actuar():
		if _resolver_perdida_agro():
			return
		if npc.obtener_estado(&"caido") != null:
			npc.agotar_recursos_turno()
			break
		var plan := _plan_combate_npc(npc)
		var objetivo: Object = plan["objetivo"]
		var decision: StringName = plan["decision"]
		if decision == &"liberarse":
			if not _liberar_npc(npc):
				break
			await get_tree().create_timer(0.6).timeout
		elif decision == &"atacar":
			var ataque := AccionAtaqueNPC.new(objetivo, gestor_rondas)
			var resultado := gestor_acciones.procesar_accion(ataque.construir_contexto(npc))
			if resultado.tirada != null:
				historial_tiradas.registrar(resultado.tirada)
			if resultado.tirada_defensa != null:
				historial_tiradas.registrar(resultado.tirada_defensa)
			if resultado.tirada_dano != null:
				historial_tiradas.registrar(resultado.tirada_dano)
			_registrar_resultado_narrativo(
				"Ataque de %s" % npc.obtener_nombre_interaccion(),
				resultado, EntradaRegistroNarrativo.Categoria.DANO, "FUE", npc
			)
			if _resolver_fin_combate():
				return
			if not resultado.exitosa:
				break
			await get_tree().create_timer(0.6).timeout
		elif decision == &"acercarse":
			var origen := npc.coordenada_mapa
			var camino: Array[Vector2i] = plan["camino"]
			var procesar_entrada := func(desde: Vector2i, hasta: Vector2i, actor: Node2D) -> void:
				_procesar_entrada_paso_actor(desde, hasta, actor)
				if _turno_npc_vigente(secuencia):
					_resolver_perdida_agro()
			var completo := await npc.mover_por_camino(
				camino, _preparar_paso_actor, _confirmar_paso_actor,
				_cancelar_paso_actor, _procesar_salida_paso_actor,
				procesar_entrada, _calcular_coste_paso_actor
			)
			if npc.coordenada_mapa != origen:
				registro_narrativo.registrar(
					EntradaRegistroNarrativo.Categoria.MOVIMIENTO,
					"Movimiento de %s" % npc.obtener_nombre_interaccion(),
					"Avanza %d casillas. Le quedan %d puntos de movimiento." % [
						camino.find(npc.coordenada_mapa),
						npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
					]
				)
			if not _turno_npc_vigente(secuencia) or _resolver_fin_combate():
				return
			if npc.coordenada_mapa == origen:
				break
			if (
				not completo and npc.obtener_estado(&"enredado") == null
				and (
					(ultimo_resultado_entrar != null and ultimo_resultado_entrar.interrumpe_movimiento)
					or (objetivo != null and npc.puede_ver_actor(objetivo, validador_espacial)) == plan["objetivo_visible"]
				)
			):
				break
		else:
			break
	if _turno_npc_vigente(secuencia):
		_finalizar_turno_combate()


func _turno_npc_vigente(secuencia: int) -> bool:
	return (
		secuencia == _secuencia_turno_npc and is_inside_tree() and en_combate
		and gestor_rondas != null and not _es_turno_jugador()
	)


func _hay_actor_moviendose() -> bool:
	if ficha_jugador != null and ficha_jugador.esta_moviendose:
		return true
	for entidad in tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC and entidad.esta_moviendose:
			return true
	return false


func _conectar_derrota_combate() -> void:
	if gestor_rondas == null:
		return
	for id_actor in gestor_rondas.obtener_ids_ordenados():
		var npc := tablero.obtener_interactuable(id_actor) as PersonajeNPC
		if npc != null and not npc.derrota_cambiada.is_connected(_on_derrota_npc_combate):
			npc.derrota_cambiada.connect(_on_derrota_npc_combate)
		if npc != null and not npc.muerte_por_danio.is_connected(_on_muerte_npc_con_xp.bind(npc)):
			npc.muerte_por_danio.connect(_on_muerte_npc_con_xp.bind(npc))


func _on_muerte_npc_con_xp(_fuente: Object, victima: PersonajeNPC) -> void:
	if _restaurando_partida or not en_combate or gestor_rondas == null or ficha_jugador == null:
		return
	if gestor_rondas.obtener_bando(victima) != GestorRondas.Bando.OPONENTE:
		return
	habilidades_nivel_dos.al_derrotar(_fuente, victima)
	# El bando de la víctima determina la recompensa; no exige autor ni daño previo.
	var recompensa: int = victima.obtener_definicion_personaje().experiencia_recompensa_derrota
	if recompensa <= 0:
		return
	var nivel_anterior := ficha_jugador.nivel
	ficha_jugador.ganar_experiencia(recompensa)
	hud.actualizar_desde_ficha()
	registro_narrativo.registrar(
		EntradaRegistroNarrativo.Categoria.SISTEMA,
		"Experiencia",
		"Ganas %d XP por derrotar a %s." % [recompensa, victima.obtener_nombre_interaccion()]
	)
	if ficha_jugador.nivel > nivel_anterior:
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA, "Nuevo nivel",
			"Alcanzas el nivel 2. Tienes una recompensa pendiente para elegir fuera de combate."
		)


func _on_derrota_npc_combate(_derrotado: bool) -> void:
	if not _restaurando_partida:
		call_deferred("_resolver_fin_combate")


func _resolver_fin_combate(reponer_recursos: bool = true) -> bool:
	if not en_combate or gestor_rondas == null:
		return false
	var queda_oponente := false
	for id_actor in gestor_rondas.obtener_ids_ordenados():
		var npc := tablero.obtener_interactuable(id_actor) as PersonajeNPC
		if npc != null and npc.puede_actuar() and gestor_rondas.son_oponentes(ficha_jugador, npc):
			queda_oponente = true
			break
	if queda_oponente and ficha_jugador.puede_actuar():
		return false
	_terminar_combate(reponer_recursos)
	return true


func _terminar_combate(reponer_recursos: bool = true, conservar_memoria: bool = false) -> void:
	if ficha_jugador != null:
		ficha_jugador.romper_agarre()
	_cancelar_habilidad_nueva()
	CursorJuego.ocultar_probabilidad_ataque()
	seleccionando_ataque_doble = false
	seleccionando_bola_fuego = false
	_secuencia_turno_npc += 1
	if gestor_rondas != null:
		for id_actor in gestor_rondas.obtener_ids_ordenados():
			var npc := tablero.obtener_interactuable(id_actor) as PersonajeNPC
			if npc != null:
				npc.solicitar_interrupcion()
				npc.en_oposicion_encuentro = false
				if not conservar_memoria or gestor_rondas.obtener_bando(npc) == GestorRondas.Bando.JUGADOR or npc.obtener_actitud_hacia_jugador() != DefinicionPersonaje.ActitudInicialJugador.HOSTIL:
					npc.olvidar_posicion_jugador()
	en_combate = false
	_reproducir_siguiente_musica_exploracion(true)
	gestor_rondas = null
	_actor_turno_camara = null
	_centrado_camara_pendiente = false
	panel_orden_combate.ocultar()
	_firma_secuencia_combate = ""
	panel_info_npc.offset_top = 18.0
	panel_info_npc.offset_bottom = 94.0
	hud.pasar_turno.disabled = ficha_jugador == null or not ficha_jugador.puede_actuar()
	if reponer_recursos and ficha_jugador != null and ficha_jugador.puede_actuar():
		ficha_jugador.iniciar_turno()


func _actualizar_ui_combate() -> void:
	if not en_combate or gestor_rondas == null:
		return
	if gestor_rondas.actor_activo != _actor_turno_camara:
		_actor_turno_camara = gestor_rondas.actor_activo
		_centrado_camara_pendiente = _actor_turno_camara == ficha_jugador
		if _centrado_camara_pendiente and not _camara_bloqueada():
			centrar_camara_en_ficha()
	var entradas: Array[Dictionary] = []
	var ids_actuales := gestor_rondas.obtener_ids_pendientes_ronda()
	var ids_siguientes := gestor_rondas.obtener_ids_siguiente_ronda()
	var todos_los_ids := ids_actuales + ids_siguientes
	for indice in todos_los_ids.size():
		if entradas.size() >= PanelOrdenCombate.MAXIMO_VISIBLE:
			break
		var id_actor: StringName = todos_los_ids[indice]
		var siguiente := indice >= ids_actuales.size()
		var actor: Object = (
			ficha_jugador if id_actor == ficha_jugador.obtener_id_actor()
			else tablero.obtener_interactuable(id_actor)
		)
		if actor == null:
			continue
		var es_jugador := actor == ficha_jugador
		var npc := actor as PersonajeNPC
		var visible_para_jugador := es_jugador or (
			npc != null and tablero.obtener_celda(npc.coordenada_mapa) != null
			and tablero.obtener_celda(npc.coordenada_mapa).visibilidad == Celda.EstadoVisibilidad.VISIBLE
		)
		var retrato: Texture2D = (
			HUD.RETRATOS_POR_CLASE.get(ficha_jugador.clase) if es_jugador else (
				npc.obtener_definicion_personaje().retrato_turno if visible_para_jugador else null
			)
		)
		entradas.append({
			"id": id_actor,
			"nombre": ficha_jugador.nombre if es_jugador else (
				npc.obtener_nombre_interaccion() if visible_para_jugador else "Combatiente oculto"
			),
			"salud": "%d / %d PV" % [ficha_jugador.pv_actual, ficha_jugador.pv_max]
				if es_jugador else (
					"%d / %d PV" % [npc.vida_actual, npc.obtener_definicion_personaje().vida_maxima]
					if visible_para_jugador else "Salud desconocida"
				),
			"retrato": retrato,
			"jugador": es_jugador,
			"activo": not siguiente and gestor_rondas.actor_activo == actor,
			"siguiente": siguiente,
			"iniciativa": (
				gestor_rondas.obtener_iniciativa_siguiente(id_actor)
				if siguiente else gestor_rondas.obtener_iniciativa_ronda(id_actor)
			) if visible_para_jugador else {},
			"bando": "Aliado" if gestor_rondas.obtener_bando(actor) == GestorRondas.Bando.JUGADOR else "Oponente",
		})
	var firma := "%d:%s" % [gestor_rondas.ronda_actual, str(entradas)]
	if _firma_secuencia_combate != firma:
		_firma_secuencia_combate = firma
		panel_orden_combate.mostrar(
			gestor_rondas.ronda_actual, entradas,
			gestor_rondas.actor_activo.call(&"obtener_id_actor")
			if gestor_rondas.actor_activo != null else &""
		)
	panel_info_npc.offset_top = panel_orden_combate.offset_top + panel_orden_combate.size.y + 12.0
	panel_info_npc.offset_bottom = panel_info_npc.offset_top + 76.0
	_actualizar_disponibilidad_turno()


func _actualizar_disponibilidad_turno() -> void:
	hud.aprendida_disponible = not es_escenario_de_descanso and ficha_jugador != null and ficha_jugador.puede_actuar() and not ficha_jugador.esta_moviendose and not interaccion_modal_activa and not _turno_exploracion_en_curso and (not en_combate or _es_turno_jugador()) and item_lanzamiento_pendiente == null and _dialogos_camara.is_empty()
	var motivo := ""
	if ficha_jugador == null or not ficha_jugador.puede_actuar():
		motivo = "No puedes actuar"
	elif interaccion_modal_activa:
		motivo = "Cierra el panel actual para continuar"
	elif ficha_jugador.esta_moviendose:
		motivo = "Espera a terminar el movimiento"
	elif en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso):
		motivo = "Espera tu turno"
	hud.pasar_turno.disabled = not motivo.is_empty()
	hud.configurar_ataque_doble_en_turno(
		motivo.is_empty() and (
			(en_combate and _es_turno_jugador())
			or (not en_combate and ficha_jugador != null and ficha_jugador.clase in ["Ladrón", "Mago"])
		)
	)
	hud.pasar_turno.text = "FINALIZAR\nTURNO" if en_combate else "PASAR\nTURNO"
	hud.pasar_turno.tooltip_text = motivo if not motivo.is_empty() else (
		"Finalizar turno y procesar estados" if en_combate else "Pasar turno de exploración"
	)


func _on_retrato_combate_pulsado(id_actor: StringName) -> void:
	if not en_combate or interaccion_modal_activa or ficha_jugador == null or not _es_turno_jugador():
		return
	var npc := tablero.obtener_interactuable(id_actor) as PersonajeNPC
	if npc == null:
		return
	var celda := tablero.obtener_celda(npc.coordenada_mapa)
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		panel_resultado_accion.mostrar_resultado("Examinar", ResultadoAccion.crear_bloqueo(&"objetivo_no_visible"), catalogo_mensajes)
		_actualizar_estado_modal_interaccion()
		return
	var opcion_examen: OpcionAccion
	for opcion in npc.obtener_opciones_accion(ficha_jugador):
		if opcion.id == &"examinar":
			opcion_examen = opcion
			break
	if opcion_examen == null:
		return
	var contexto: Variant = constructor_contexto_accion.construir_desde_opcion(
		opcion_examen, ficha_jugador, ficha_jugador.coordenada_mapa, npc.coordenada_mapa
	)
	if not contexto is ContextoAccion:
		return
	var resultado := (
		gestor_acciones.procesar_accion(contexto) if gestor_acciones.esta_en_alcance(contexto)
		else ResultadoAccion.crear_bloqueo(&"fuera_de_alcance")
	)
	_presentar_resultado_contextual("Examinar", resultado, contexto)
	_actualizar_estado_modal_interaccion()


func _registrar_iniciativa_combate() -> void:
	for tirada in gestor_rondas.obtener_tiradas_iniciativa():
		historial_tiradas.registrar(tirada)
	var detalles: Array[String] = []
	for id_actor in gestor_rondas.obtener_ids_ordenados():
		var iniciativa := gestor_rondas.obtener_iniciativa_ronda(id_actor)
		if iniciativa.is_empty():
			continue
		var nombre := ficha_jugador.nombre
		if id_actor != ficha_jugador.obtener_id_actor():
			var npc := tablero.obtener_interactuable(id_actor) as PersonajeNPC
			nombre = npc.obtener_nombre_interaccion()
		detalles.append("%s: 1d6 (%d) + DES %d = %d" % [
			nombre, iniciativa["dado"], iniciativa["destreza"], iniciativa["total"],
		])
	if detalles.is_empty():
		return
	registro_narrativo.registrar(
		EntradaRegistroNarrativo.Categoria.SISTEMA,
		"Iniciativa de ronda %d" % gestor_rondas.ronda_actual,
		"Mayor total primero; empate por DES y luego por ID.", detalles
	)


func _actualizar_luz_jugador(coordenada: Vector2i) -> void:
	var antorcha := ficha_jugador.obtener_antorcha_activa()
	if antorcha == null:
		gestor_vision.actualizar_vision(coordenada, 1)
	else:
		var radio_actual := float(antorcha.radio_vision)
		if antorcha.pasos_atenuacion > 0 and ficha_jugador.pasos_antorcha_actual <= antorcha.pasos_atenuacion:
			var porcentaje_final := float(ficha_jugador.pasos_antorcha_actual) / antorcha.pasos_atenuacion
			radio_actual = maxf(1.0, porcentaje_final * antorcha.radio_vision)
		gestor_vision.actualizar_vision(coordenada, int(radio_actual))
	_evaluar_percepcion_trampas()


func _actualizar_luz_al_cargar() -> void:
	if ficha_jugador != null:
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)


func _evaluar_percepcion_trampas() -> void:
	if servicio_percepcion_trampas == null or ficha_jugador == null:
		return
	for resultado in servicio_percepcion_trampas.evaluar(ficha_jugador):
		if resultado.tirada != null:
			historial_tiradas.registrar(resultado.tirada)
		if &"trampa.detectada" in resultado.mensajes:
			_registrar_resultado_narrativo(
				"Trampa descubierta",
				resultado,
				EntradaRegistroNarrativo.Categoria.SISTEMA,
				"VOL"
			)


func _registrar_transformaciones_superficies(resultado: ResultadoAccion) -> void:
	for cambio in resultado.cambios_estado:
		if not cambio.get(&"expirada", false):
			continue
		var coordenada: Variant = cambio.get(&"coordenada")
		var celda := tablero.obtener_celda(coordenada) if coordenada is Vector2i else null
		if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
			continue
		var transformada := cambio.has(&"id_superficie_resultante")
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA,
			"Superficie",
			"El fuego se consume y deja humo." if transformada else "La superficie se disipa."
		)

func _inicializar_audio_ambiente() -> void:
	generador_azar_audio.randomize()
	_preparar_loop_audio(SONIDO_LAVA)

	reproductor_pasos = _crear_reproductor_2d(&"AudioPasos", -18.0, 360.0)
	reproductor_lava = _crear_reproductor_2d(&"AudioLava", -18.0, 220.0)
	reproductor_lava.attenuation = 2.0
	reproductor_lava.stream = SONIDO_LAVA
	reproductor_fuego = _crear_reproductor_global(&"AudioFuegoCercano", -30.0)
	reproductor_fuego.bus = &"Master"
	reproductor_fuego.finished.connect(_on_fuego_finished)

	reproductor_monstruo = _crear_reproductor_global(&"AudioMonstruoCadenas", -28.0)
	reproductor_monstruo.stream = SONIDO_MONSTRUO_CADENAS

	reproductor_ambiente_tenebroso = _crear_reproductor_global(&"AudioAmbienteTenebroso", -26.0)
	reproductor_creepy = _crear_reproductor_global(&"AudioCreepy", -28.0)
	reproductor_creepy.stream = SONIDO_CREEPY
	reproductor_examen = _crear_reproductor_global(&"AudioExamen", -16.0)
	reproductor_recoleccion = _crear_reproductor_global(&"AudioRecoleccion", -15.0)
	reproductor_impacto = _crear_reproductor_2d(&"AudioImpacto", -8.0, 800.0)
	reproductor_magia_fuego = _crear_reproductor_global(&"AudioMagiaFuego", -6.0)
	reproductor_ocultarse = _crear_reproductor_global(&"AudioOcultarse", -10.0)

	temporizador_monstruo = _crear_temporizador_audio(&"_on_temporizador_monstruo_timeout")
	temporizador_ambiente_tenebroso = _crear_temporizador_audio(&"_on_temporizador_ambiente_tenebroso_timeout")
	_programar_monstruo_ambiente()
	_programar_ambiente_tenebroso()


func _inicializar_musica() -> void:
	if not is_instance_valid(reproductor_musica):
		return
	if not reproductor_musica.finished.is_connected(_on_musica_terminada):
		reproductor_musica.finished.connect(_on_musica_terminada)
	_reproducir_siguiente_musica_exploracion(false)


func _actualizar_fade_fin_musica() -> void:
	if not is_instance_valid(reproductor_musica):
		return
	if not reproductor_musica.playing:
		if not _transicionando_musica and not es_escenario_de_descanso and not is_instance_valid(campamento):
			if pantalla_muerte == null or not pantalla_muerte.visible:
				_reproducir_siguiente_musica_exploracion(true)
		return
	if _transicionando_musica:
		return
	if tween_musica != null and tween_musica.is_running():
		return
	var stream := reproductor_musica.stream
	if stream == null:
		return
	var duracion := stream.get_length()
	if duracion <= 6.0:
		return
	var pos := reproductor_musica.get_playback_position()
	if pos >= duracion - 3.8:
		_transicionando_musica = true
		if en_combate:
			_reproducir_siguiente_musica_combate(true)
		else:
			_reproducir_siguiente_musica_exploracion(true)


func _on_musica_terminada() -> void:
	_transicionando_musica = false
	if en_combate:
		_reproducir_siguiente_musica_combate(true)
	else:
		_reproducir_siguiente_musica_exploracion(true)


func _reproducir_siguiente_musica_exploracion(con_fade: bool = true) -> void:
	if PLAYLIST_EXPLORACION.is_empty() or not is_instance_valid(reproductor_musica):
		return
	var stream: AudioStream = PLAYLIST_EXPLORACION[indice_musica_exploracion % PLAYLIST_EXPLORACION.size()]
	indice_musica_exploracion = (indice_musica_exploracion + 1) % PLAYLIST_EXPLORACION.size()
	_cambiar_pista_musica(stream, -7.5, con_fade)


func _reproducir_siguiente_musica_combate(con_fade: bool = true) -> void:
	if PLAYLIST_COMBATE.is_empty() or not is_instance_valid(reproductor_musica):
		return
	var stream: AudioStream = PLAYLIST_COMBATE[indice_musica_combate % PLAYLIST_COMBATE.size()]
	indice_musica_combate = (indice_musica_combate + 1) % PLAYLIST_COMBATE.size()
	_cambiar_pista_musica(stream, -7.0, con_fade)


func _cambiar_pista_musica(nuevo_stream: AudioStream, volumen_objetivo_db: float, con_fade: bool = true) -> void:
	if not is_instance_valid(reproductor_musica) or nuevo_stream == null:
		_transicionando_musica = false
		return
	if tween_musica != null and tween_musica.is_running():
		tween_musica.kill()
	_desactivar_loop_audio(nuevo_stream)
	if not con_fade or not reproductor_musica.playing:
		reproductor_musica.stream = nuevo_stream
		reproductor_musica.volume_db = -32.0
		reproductor_musica.play()
		tween_musica = create_tween()
		tween_musica.tween_property(reproductor_musica, "volume_db", volumen_objetivo_db, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_musica.tween_callback(func():
			_transicionando_musica = false
		)
		return
	tween_musica = create_tween()
	# Transición de salida suave (fade out)
	tween_musica.tween_property(reproductor_musica, "volume_db", -48.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_musica.tween_callback(func():
		if is_instance_valid(reproductor_musica):
			reproductor_musica.stream = nuevo_stream
			reproductor_musica.volume_db = -32.0
			reproductor_musica.play()
	)
	# Transición de entrada suave (fade in)
	tween_musica.tween_property(reproductor_musica, "volume_db", volumen_objetivo_db, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_musica.tween_callback(func():
		_transicionando_musica = false
	)


func _programar_ambiente_tenebroso() -> void:
	if is_instance_valid(temporizador_ambiente_tenebroso):
		temporizador_ambiente_tenebroso.start(generador_azar_audio.randf_range(30.0, 65.0))


func _on_temporizador_ambiente_tenebroso_timeout() -> void:
	if generador_azar_audio.randf() < 0.15:
		if is_instance_valid(reproductor_creepy) and not reproductor_creepy.playing:
			reproductor_creepy.volume_db = -28.0
			reproductor_creepy.pitch_scale = randf_range(0.92, 1.05)
			reproductor_creepy.play()
	elif is_instance_valid(reproductor_ambiente_tenebroso):
		var sonido: AudioStream = null
		var volumen_ambiente: float = -26.0
		# Ocasionalmente reproduce Ambient 30 de fondo a menor volumen
		if generador_azar_audio.randf() < 0.35:
			sonido = SONIDO_AMBIENTE_FONDO_30
			volumen_ambiente = -32.0
		elif not SONIDOS_AMBIENTE_TENEBROSO.is_empty():
			sonido = SONIDOS_AMBIENTE_TENEBROSO.pick_random()
			volumen_ambiente = -26.0

		if sonido != null:
			_desactivar_loop_audio(sonido)
			reproductor_ambiente_tenebroso.stream = sonido
			reproductor_ambiente_tenebroso.volume_db = volumen_ambiente
			reproductor_ambiente_tenebroso.pitch_scale = randf_range(0.95, 1.05)
			reproductor_ambiente_tenebroso.play()
	_programar_ambiente_tenebroso()


func _reproducir_sonido_recoleccion(item_suelo: ItemSuelo) -> void:
	if not is_instance_valid(reproductor_recoleccion):
		reproductor_recoleccion = _crear_reproductor_global(&"AudioRecoleccion", -15.0)
	var stream: AudioStream = null
	if item_suelo != null and item_suelo.item != null and item_suelo.item.definicion != null:
		stream = item_suelo.item.definicion.obtener_sonido_recoger()
	if stream != null:
		reproductor_recoleccion.stream = stream
		reproductor_recoleccion.volume_db = -15.0
		reproductor_recoleccion.play()


func _reproducir_sonido_examen(sonido: AudioStream) -> void:
	if sonido == null:
		return
	if not is_instance_valid(reproductor_examen):
		reproductor_examen = _crear_reproductor_global(&"AudioExamen", -16.0)
	_desactivar_loop_audio(sonido)
	reproductor_examen.stream = sonido
	reproductor_examen.volume_db = -16.0
	reproductor_examen.play()


func _reproducir_campanas_estatua() -> void:
	if not is_instance_valid(reproductor_campana_estatua):
		reproductor_campana_estatua = _crear_reproductor_global(&"AudioCampanaEstatua", -26.0)
	_desactivar_loop_audio(SONIDO_CAMPANAS_ESTATUA)
	reproductor_campana_estatua.stream = SONIDO_CAMPANAS_ESTATUA
	reproductor_campana_estatua.volume_db = -26.0
	reproductor_campana_estatua.play()


func _desactivar_loop_audio(sonido: AudioStream) -> void:
	if sonido is AudioStreamWAV:
		(sonido as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif sonido is AudioStreamOggVorbis:
		(sonido as AudioStreamOggVorbis).loop = false


func reproducir_sonido_magia_fuego() -> void:
	if not is_instance_valid(reproductor_magia_fuego):
		reproductor_magia_fuego = _crear_reproductor_global(&"AudioMagiaFuego", -6.0)
	_desactivar_loop_audio(SONIDO_MAGIA_FUEGO)
	reproductor_magia_fuego.stream = SONIDO_MAGIA_FUEGO
	reproductor_magia_fuego.volume_db = -6.0
	reproductor_magia_fuego.play()


func _reproducir_sonido_ocultarse() -> void:
	if not is_instance_valid(reproductor_ocultarse):
		reproductor_ocultarse = _crear_reproductor_global(&"AudioOcultarse", -10.0)
	_desactivar_loop_audio(SONIDO_BREATH_2)
	reproductor_ocultarse.stream = SONIDO_BREATH_2
	reproductor_ocultarse.volume_db = -10.0
	reproductor_ocultarse.play()


func _reproducir_sonido_impacto(sonido: AudioStream, celda: Variant = null) -> void:
	if not is_instance_valid(reproductor_impacto):
		reproductor_impacto = _crear_reproductor_2d(&"AudioImpacto", -8.0, 800.0)
	if celda is Vector2i:
		var capa_suelo := zona_actual.get_node_or_null("CapaSuelo") as TileMapLayer
		if capa_suelo != null:
			reproductor_impacto.global_position = capa_suelo.to_global(capa_suelo.map_to_local(celda))
	elif ficha_jugador != null:
		reproductor_impacto.global_position = ficha_jugador.global_position
	reproductor_impacto.stream = sonido
	reproductor_impacto.play()


func _crear_reproductor_2d(
	nombre: StringName,
	volumen_db: float,
	distancia_maxima: float
) -> AudioStreamPlayer2D:
	var reproductor := AudioStreamPlayer2D.new()
	reproductor.name = String(nombre)
	reproductor.volume_db = volumen_db
	reproductor.max_distance = distancia_maxima
	add_child(reproductor)
	return reproductor


func _crear_reproductor_global(nombre: StringName, volumen_db: float) -> AudioStreamPlayer:
	var reproductor := AudioStreamPlayer.new()
	reproductor.name = String(nombre)
	reproductor.volume_db = volumen_db
	add_child(reproductor)
	return reproductor


func _crear_temporizador_audio(metodo_timeout: StringName) -> Timer:
	var temporizador := Timer.new()
	temporizador.one_shot = true
	temporizador.timeout.connect(Callable(self, metodo_timeout))
	add_child(temporizador)
	return temporizador


func _programar_monstruo_ambiente() -> void:
	if is_instance_valid(temporizador_monstruo):
		temporizador_monstruo.start(generador_azar_audio.randf_range(35.0, 75.0))


func _on_temporizador_monstruo_timeout() -> void:
	if is_instance_valid(reproductor_monstruo) and not reproductor_monstruo.playing:
		reproductor_monstruo.play()
	_programar_monstruo_ambiente()


func _reproducir_sonido_paso() -> void:
	if not is_instance_valid(reproductor_pasos) or ficha_jugador == null:
		return
	pasos_movimiento_actual += 1
	if longitud_movimiento_actual > 1 and pasos_movimiento_actual % 2 != 0:
		return
	reproductor_pasos.global_position = ficha_jugador.global_position
	reproductor_pasos.stream = (
		SONIDO_PASO_1 if siguiente_paso_usa_variante_uno else SONIDO_PASO_2
	)
	siguiente_paso_usa_variante_uno = not siguiente_paso_usa_variante_uno
	reproductor_pasos.play()


func _on_fuego_finished() -> void:
	if is_instance_valid(reproductor_fuego) and reproductor_fuego.stream != null:
		var fuente := _buscar_fuente_fuego_cercana()
		if not fuente.is_empty():
			reproductor_fuego.play()


func _actualizar_audio_proximidad() -> void:
	if ficha_jugador == null:
		return
	var fuente_lava := _buscar_fuente_lava_cercana()
	_actualizar_reproductor_proximidad(reproductor_lava, SONIDO_LAVA, fuente_lava)

	_actualizar_audio_fuego()


func _actualizar_audio_fuego() -> void:
	if not is_instance_valid(reproductor_fuego) or ficha_jugador == null:
		return
	var fuente_fuego := _buscar_fuente_fuego_cercana()
	if fuente_fuego.is_empty() or not fuente_fuego.has(&"sonido") or fuente_fuego[&"sonido"] == null:
		if reproductor_fuego.playing:
			reproductor_fuego.stop()
		return
	var sonido_fuego: AudioStream = fuente_fuego[&"sonido"]
	var dist_px: float = fuente_fuego.get(&"distancia", 999.0)
	var radio_max_px: float = float(maxi(radio_audio_fuego, 6)) * 64.0
	var factor := clampf(1.0 - (dist_px / radio_max_px), 0.0, 1.0)
	var volumen_calc := lerpf(-38.0, -12.0, factor * factor)
	
	_preparar_loop_audio(sonido_fuego)
	if reproductor_fuego.stream != sonido_fuego:
		reproductor_fuego.stream = sonido_fuego
	reproductor_fuego.volume_db = volumen_calc
	if not reproductor_fuego.playing:
		reproductor_fuego.play()


func _actualizar_reproductor_proximidad(
	reproductor: AudioStreamPlayer2D,
	sonido: AudioStream,
	fuente: Dictionary
) -> void:
	if not is_instance_valid(reproductor):
		return
	if fuente.is_empty() or sonido == null:
		if reproductor.playing:
			reproductor.stop()
		return
	var posicion: Vector2 = fuente[&"posicion"]
	reproductor.global_position = posicion
	if reproductor.stream != sonido:
		_preparar_loop_audio(sonido)
		reproductor.stream = sonido
	if not reproductor.playing:
		reproductor.play()


func _buscar_fuente_lava_cercana() -> Dictionary:
	var capa_suelo := zona_actual.get_node_or_null("CapaSuelo") as TileMapLayer
	if capa_suelo == null or ficha_jugador == null:
		return {}
	var mejor_distancia := INF
	var mejor_coord := Vector2i.ZERO
	for coord in tablero.datos:
		var celda := tablero.obtener_celda(coord)
		if celda == null or celda.zona != &"lava":
			continue
		var distancia := _distancia_cuadricula(ficha_jugador.coordenada_mapa, coord)
		if distancia > radio_audio_lava or distancia >= mejor_distancia:
			continue
		mejor_distancia = distancia
		mejor_coord = coord
	if mejor_distancia == INF:
		return {}
	return {
		&"posicion": capa_suelo.to_global(capa_suelo.map_to_local(mejor_coord)),
	}


func _buscar_fuente_fuego_cercana() -> Dictionary:
	if ficha_jugador == null:
		return {}
	var mejor_distancia := INF
	var mejor_fuente: FuenteLuzInteractuable = null
	var pos_jugador := ficha_jugador.global_position
	var radio_max_px: float = float(maxi(radio_audio_fuego, 6)) * 64.0

	var candidatas: Array[FuenteLuzInteractuable] = []
	if zona_actual != null:
		for nodo in zona_actual.find_children("*", "", true, false):
			if nodo is FuenteLuzInteractuable and nodo not in candidatas:
				candidatas.append(nodo)
	if tablero != null:
		for interactuable in tablero.interactuables_por_id.values():
			if interactuable is FuenteLuzInteractuable and interactuable not in candidatas:
				candidatas.append(interactuable)
		for celda_variant in tablero.datos.values():
			var celda := celda_variant as Celda
			if celda != null:
				for fuente in celda.iluminacion:
					if fuente is FuenteLuzInteractuable and fuente not in candidatas:
						candidatas.append(fuente)

	for fuente in candidatas:
		if not is_instance_valid(fuente) or not fuente.encendida:
			continue
		var sonido := fuente.obtener_sonido_ambiente()
		if sonido == null:
			continue
		var dist_px := pos_jugador.distance_to(fuente.global_position)
		if dist_px > radio_max_px or dist_px >= mejor_distancia:
			continue
		mejor_distancia = dist_px
		mejor_fuente = fuente

	if mejor_fuente == null:
		return {}
	return {
		&"posicion": mejor_fuente.global_position,
		&"sonido": mejor_fuente.obtener_sonido_ambiente(),
		&"distancia": mejor_distancia,
	}


func _distancia_cuadricula(a: Vector2i, b: Vector2i) -> int:
	return maxi(abs(a.x - b.x), abs(a.y - b.y))


func _preparar_loop_audio(sonido: AudioStream) -> void:
	if sonido is AudioStreamWAV:
		var wav := sonido as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if wav.loop_end <= wav.loop_begin:
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif sonido != null and "loop" in sonido:
		sonido.set("loop", true)
	elif sonido is AudioStreamOggVorbis:
		(sonido as AudioStreamOggVorbis).loop = true

func centrar_camara_en_ficha() -> void:
	if ficha_jugador and camera_2d:
		camera_2d.centrar(ficha_jugador.global_position)
		_centrado_camara_pendiente = false
		ultima_coordenada_hover = Vector2i(-999, -999)


func _camara_bloqueada() -> bool:
	return ficha_jugador == null or _restaurando_partida or interaccion_modal_activa or not _dialogos_camara.is_empty()


func _puntero_sobre_panel_desplazable() -> bool:
	var control := get_viewport().gui_get_hovered_control()
	while control != null:
		if control is ScrollContainer:
			return true
		control = control.get_parent_control()
	return false


func _puntero_sobre_interfaz() -> bool:
	if get_viewport().gui_get_hovered_control() != null:
		return true
	var base_hud: Control = hud.get_node("HUDRoot/HudBaseRoca")
	return base_hud.is_visible_in_tree() and base_hud.get_global_rect().has_point(get_viewport().get_mouse_position())


func _actualizar_camara(delta: float) -> void:
	var bloqueada := _camara_bloqueada()
	if _centrado_camara_pendiente and not bloqueada:
		centrar_camara_en_ficha()
	if ficha_jugador == null:
		return
	camera_2d.actualizar(delta, ficha_jugador.global_position, get_viewport_rect().size,
		get_viewport().get_mouse_position(), _puntero_en_ventana
		and get_window().has_focus()
		and Input.get_mouse_button_mask() == 0, bloqueada)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_puntero_en_ventana = false
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		_puntero_en_ventana = true


func _on_dialogo_camara_iniciado(recurso: DialogueResource) -> void:
	if recurso not in _dialogos_camara:
		_dialogos_camara.append(recurso)
	camera_2d.suspender_bordes()


func _on_dialogo_camara_finalizado(recurso: DialogueResource) -> void:
	_dialogos_camara.erase(recurso)
	camera_2d.suspender_bordes()

func _actualizar_hover_interaccion(coord: Vector2i, punto_global: Variant = null) -> void:
	objetivos_hover = selector_objetivos.obtener_objetivos_perceptibles(
		tablero,
		coord,
		ficha_jugador,
		punto_global
	)
	_actualizar_cursor_interaccion()
	_actualizar_resaltado_interaccion()
	_actualizar_panel_info_npc()
	_actualizar_probabilidad_ataque_basico()


func _actualizar_probabilidad_ataque_basico() -> void:
	if not en_combate or not _es_turno_jugador() or ficha_jugador == null:
		CursorJuego.ocultar_probabilidad_ataque()
		return
	for objetivo in objetivos_hover:
		if (
			objetivo is PersonajeNPC and objetivo.puede_actuar()
			and gestor_rondas.son_oponentes(ficha_jugador, objetivo)
		):
			var texto := "ATAQUE BÁSICO · 0%"
			var distancia: Vector2i = objetivo.coordenada_mapa - ficha_jugador.coordenada_mapa
			if absi(distancia.x) + absi(distancia.y) > 1:
				texto += "\nFuera de alcance"
			elif ficha_jugador.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) < 1:
				texto += "\nSin acción principal"
			else:
				var probabilidad := ResolverAtaqueBasico.probabilidad_de_dano(
					ficha_jugador.obtener_fuerza(), objetivo.obtener_destreza()
				)
				texto = "ATAQUE BÁSICO · %d%%" % roundi(probabilidad * 100.0)
			CursorJuego.mostrar_probabilidad_ataque(texto)
			return
	CursorJuego.ocultar_probabilidad_ataque()


func _actualizar_cursor_interaccion() -> void:
	var tiene_interaccion := false
	var tiene_examen := false
	for objetivo in objetivos_hover:
		if not is_instance_valid(objetivo):
			continue
		for opcion in objetivo.call(&"obtener_opciones_accion", ficha_jugador):
			if opcion.tipo in [
				TiposInteraccion.TipoAccion.INTERACTUAR,
				TiposInteraccion.TipoAccion.RECOGER,
				TiposInteraccion.TipoAccion.ENTRAR,
				TiposInteraccion.TipoAccion.SALIR,
				TiposInteraccion.TipoAccion.USAR_ITEM,
			]:
				tiene_interaccion = true
			elif opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
				tiene_examen = true
	if tiene_interaccion:
		CursorJuego.establecer_cursor(CursorJuego.Tipo.INTERACCION)
	elif tiene_examen:
		CursorJuego.establecer_cursor(CursorJuego.Tipo.EXAMINAR)
	elif not objetivos_hover.is_empty():
		CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)


func _celda_conocida_para_movimiento(coord: Vector2i) -> bool:
	var celda := tablero.obtener_celda(coord)
	return celda != null and celda.visibilidad != Celda.EstadoVisibilidad.OCULTO


func _actualizar_cursor_movimiento(coord: Vector2i) -> void:
	if not objetivos_hover.is_empty():
		return
	if (
		ficha_jugador != null
		and coord != ficha_jugador.coordenada_mapa
		and camino_actual_tentativo.size() > 1
		and camino_actual_tentativo.back() == coord
	):
		CursorJuego.establecer_cursor(CursorJuego.Tipo.MOVIMIENTO)
	else:
		CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)


func _actualizar_panel_info_npc() -> void:
	for objetivo in objetivos_hover:
		if objetivo is PersonajeNPC:
			panel_info_npc.mostrar_personaje(objetivo)
			return
	panel_info_npc.ocultar()


func _limpiar_hover_interaccion() -> void:
	objetivos_hover.clear()
	CursorJuego.ocultar_probabilidad_ataque()
	CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)
	_actualizar_resaltado_interaccion()
	panel_info_npc.ocultar()


func _solicitar_interaccion_en_celda(coord: Vector2i, punto_global: Variant = null) -> bool:
	var objetivos := selector_objetivos.obtener_objetivos_perceptibles(
		tablero,
		coord,
		ficha_jugador,
		punto_global
	)
	var coord_objetivo := coord
	if objetivos.size() == 1 and (objetivos[0] is ItemSuelo or objetivos[0] is PersonajeNPC):
		coord_objetivo = objetivos[0].coordenada_mapa
	var iniciada := estado_seleccion_objetivos.iniciar(coord_objetivo, objetivos)
	_actualizar_resaltado_interaccion()
	return iniciada


func seleccionar_objetivo_interaccion(objetivo: Object) -> bool:
	var seleccion_valida := estado_seleccion_objetivos.seleccionar(objetivo)
	if seleccion_valida and (objetivo is ItemSuelo or objetivo is PersonajeNPC):
		estado_seleccion_objetivos.celda_seleccionada = objetivo.coordenada_mapa
	_actualizar_resaltado_interaccion()
	return seleccion_valida


func _limpiar_seleccion_interaccion() -> void:
	estado_seleccion_objetivos.limpiar()
	_actualizar_resaltado_interaccion()


func _actualizar_resaltado_interaccion() -> void:
	var siguientes: Array[Object] = []
	if is_instance_valid(objetivo_seleccionado):
		siguientes.append(objetivo_seleccionado)
	else:
		siguientes.assign(objetivos_hover)
	if objetivos_resaltados == siguientes:
		return
	for objetivo in objetivos_resaltados:
		if (
			is_instance_valid(objetivo)
			and objetivo not in siguientes
			and objetivo.has_method(&"establecer_resaltado")
		):
			objetivo.call(&"establecer_resaltado", false)
	for objetivo in siguientes:
		if (
			is_instance_valid(objetivo)
			and objetivo not in objetivos_resaltados
			and objetivo.has_method(&"establecer_resaltado")
		):
			objetivo.call(&"establecer_resaltado", true)
	objetivos_resaltados.assign(siguientes)


func _abrir_menu_contextual(posicion_pantalla: Vector2) -> void:
	if objetivo_seleccionado != null:
		if es_escenario_de_descanso and is_instance_valid(control_descanso) and control_descanso.es_fogata(objetivo_seleccionado):
			menu_contextual.mostrar(
				objetivo_seleccionado.obtener_nombre_interaccion(),
				control_descanso.obtener_entradas_fogata(),
				posicion_pantalla
			)
			_actualizar_estado_modal_interaccion()
			return
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
	if es_escenario_de_descanso and is_instance_valid(control_descanso) and control_descanso.es_opcion_campamento(opcion):
		control_descanso.ejecutar_opcion_campamento(opcion)
		return
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
	if en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso):
		_cerrar_menu_contextual()
		return
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
			if gestor_acciones.esta_en_alcance(contexto):
				resultado = _procesar_accion_contextual(contexto)
			else:
				var camino := _buscar_camino_interaccion(
					opcion, item_seleccionado, coordenada_objetivo
				)
				menu_contextual.ocultar()
				_limpiar_seleccion_interaccion()
				_actualizar_estado_modal_interaccion()
				if camino.is_empty():
					resultado = ResultadoAccion.crear_bloqueo(
						&"ruta_interaccion_no_disponible"
					)
				elif not await _recorrer_camino_interaccion(camino):
					resultado = ResultadoAccion.crear_bloqueo(
						&"ruta_interaccion_interrumpida"
					)
				else:
					construccion = constructor_contexto_accion.construir_desde_opcion(
						opcion,
						ficha_jugador,
						ficha_jugador.coordenada_mapa,
						coordenada_objetivo,
						item_seleccionado
					)
					if construccion is ContextoAccion:
						contexto = construccion
						resultado = _procesar_accion_contextual(contexto)
					else:
						resultado = ResultadoAccion.crear_bloqueo(construccion)
		else:
			var motivo_construccion: StringName = construccion
			resultado = ResultadoAccion.crear_bloqueo(motivo_construccion)

	ultimo_contexto_contextual = contexto
	ultimo_resultado_contextual = resultado
	opcion_uso_item_pendiente = null
	var titulo_resultado := _obtener_titulo_resultado_contextual(opcion)
	menu_contextual.ocultar()
	if contexto != null and contexto.tipo in [
		TiposInteraccion.TipoAccion.INTERACTUAR,
		TiposInteraccion.TipoAccion.USAR_ITEM,
	] and not (
		contexto.objetivo is PersonajeNPC
		and String(contexto.id_accion).begins_with("hablar:")
		and resultado.exitosa
	):
		var etiqueta_atributo := "DES"
		if opcion.id in [&"desarmar_fue", &"desarmar_des", &"desarmar_vol"]:
			etiqueta_atributo = String(opcion.id).trim_prefix("desarmar_").to_upper()
		elif opcion.id == &"ataque_basico":
			etiqueta_atributo = "FUE"
		_registrar_resultado_narrativo(
			titulo_resultado,
			resultado,
			EntradaRegistroNarrativo.Categoria.OBJETO,
			etiqueta_atributo
		)
	_presentar_resultado_contextual(titulo_resultado, resultado, contexto)
	accion_contextual_finalizada.emit(opcion, contexto, resultado)


func _procesar_accion_contextual(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto.id_accion == &"ataque_basico" and contexto.objetivo is PersonajeNPC:
		# Prevalidar antes de abrir un encuentro: un bloqueo no provoca defensa.
		var motivo: StringName = contexto.objetivo.validar_accion(contexto)
		if motivo == &"":
			motivo = gestor_acciones.proveedor_costes.validar_costes(contexto)
		if motivo != &"":
			return ResultadoAccion.crear_bloqueo(motivo)
		if not gestor_acciones.esta_en_alcance(contexto):
			return ResultadoAccion.crear_bloqueo(&"fuera_de_alcance")
		if not _iniciar_combate(contexto.objetivo):
			return ResultadoAccion.crear_bloqueo(&"npc_no_combatiente")
		# La orden abre combate; el golpe y su penalización esperan el turno propio.
		if not _es_turno_jugador() or _turno_exploracion_en_curso:
			return ResultadoAccion.crear_exito()
	return gestor_acciones.procesar_accion(contexto)


func _buscar_camino_interaccion(
	opcion: OpcionAccion,
	item_seleccionado: ItemInstancia,
	coordenada_objetivo: Vector2i
) -> Array[Vector2i]:
	var mejor_camino: Array[Vector2i] = []
	var mejor_coste := INF
	# ponytail: barrido simple; crear un índice espacial si los mapas grandes lo requieren.
	for destino: Vector2i in tablero.datos:
		if not _celda_conocida_para_movimiento(destino):
			continue
		if not tablero.puede_entrar(destino, ficha_jugador):
			continue
		var construccion: Variant = constructor_contexto_accion.construir_desde_opcion(
			opcion,
			ficha_jugador,
			destino,
			coordenada_objetivo,
			item_seleccionado
		)
		if not construccion is ContextoAccion:
			continue
		var contexto := construccion as ContextoAccion
		if not gestor_acciones.esta_en_alcance(contexto):
			continue
		if (
			contexto.tipo_linea_efecto != TiposInteraccion.TipoLineaEfecto.NINGUNA
			and validador_espacial.validar_linea_efecto(contexto) != &""
		):
			continue
		var camino := pathfinding.calcular_camino_conocido(
			ficha_jugador.coordenada_mapa,
			destino,
			tablero.datos,
			ficha_jugador
		)
		if camino.is_empty():
			continue
		if en_combate:
			var limitado := _limitar_camino_jugador(camino)
			if limitado.size() != camino.size():
				continue
		var coste := 0
		for indice in range(1, camino.size()):
			coste += tablero.obtener_celda(camino[indice]).calcular_coste_movimiento(
				ficha_jugador
			)
		if coste < mejor_coste:
			mejor_coste = coste
			mejor_camino = camino
	return mejor_camino


func _recorrer_camino_interaccion(camino: Array[Vector2i]) -> bool:
	capa_camino.clear()
	longitud_movimiento_actual = camino.size() - 1
	pasos_movimiento_actual = 0
	return await ficha_jugador.mover_por_camino(
		camino,
		_preparar_paso_actor,
		_confirmar_paso_actor,
		_cancelar_paso_actor,
		_procesar_salida_paso_actor,
		_procesar_entrada_paso_actor,
		_calcular_coste_paso_actor,
		_avanzar_turno_exploracion,
		en_combate
	)


func _presentar_resultado_contextual(
	titulo: String,
	resultado: ResultadoAccion,
	contexto: ContextoAccion = null
) -> void:
	if (
		contexto != null
		and contexto.objetivo is PersonajeNPC
		and String(contexto.id_accion).begins_with("hablar:")
		and resultado.exitosa
	):
		var dialogo := (contexto.objetivo as PersonajeNPC).obtener_dialogo_por_accion(
			contexto.id_accion
		)
		if dialogo == null:
			return
		ultima_prueba_dialogo = null
		prueba_dialogo_resuelta = false
		var globo := DisparadorDialogoArea.mostrar(
			dialogo.recurso,
			dialogo.punto_inicio,
			[contexto.objetivo, contexto.actor, self]
		)
		if globo != null:
			if globo.has_method(&"configurar_participantes"):
				globo.call(
					&"configurar_participantes",
					ficha_jugador.nombre,
					_obtener_ilustracion_dialogo_jugador(),
					(contexto.objetivo as PersonajeNPC).obtener_nombre_interaccion(),
					(contexto.objetivo as PersonajeNPC).obtener_definicion_personaje().ilustracion_dialogo
				)
			dialogo_npc_activo = true
			recurso_dialogo_npc_activo = dialogo.recurso
			tema_dialogo_npc_activo = dialogo
			npc_dialogo_activo = contexto.objetivo as PersonajeNPC
			var gestor_dialogos := get_tree().root.get_node_or_null(^"DialogueManager")
			var al_terminar := Callable(self, &"_on_dialogo_npc_finalizado")
			if gestor_dialogos != null and not gestor_dialogos.is_connected(
				&"dialogue_ended", al_terminar
			):
				gestor_dialogos.connect(&"dialogue_ended", al_terminar)
			_actualizar_estado_modal_interaccion()
			return
	if (
		contexto != null
		and contexto.tipo == TiposInteraccion.TipoAccion.INTERACTUAR
		and (
			(contexto.id_accion == &"abrir_cofre" and contexto.objetivo is CofreInteractuable)
			or (contexto.id_accion == &"recoger_botin" and contexto.objetivo is PersonajeNPC)
		)
		and resultado.exitosa
	):
		panel_inventario_cofre.mostrar(
			contexto.objetivo,
			ficha_jugador.obtener_inventario()
		)
		return
	if (
		contexto != null
		and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR
		and resultado.exitosa
		and contexto.objetivo is PersonajeNPC
	):
		var textos_npc: Array[String] = []
		for id_mensaje in resultado.mensajes:
			textos_npc.append(
				catalogo_mensajes.resolver(id_mensaje)
				if catalogo_mensajes != null else String(id_mensaje)
			)
		panel_ficha_npc.mostrar(contexto.objetivo as PersonajeNPC, textos_npc)
		_actualizar_estado_modal_interaccion()
		return
	if (
		contexto != null
		and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR
		and resultado.exitosa
		and contexto.objetivo is ItemSuelo
	):
		var definicion_item := (contexto.objetivo as ItemSuelo).item.definicion
		panel_examen_ilustrado.mostrar(
			definicion_item.nombre,
			definicion_item.ilustracion_examen if definicion_item.ilustracion_examen != null else definicion_item.icono,
			definicion_item.descripcion_base
		)
		_actualizar_estado_modal_interaccion()
		return
	if (
		contexto != null
		and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR
		and resultado.exitosa
		and contexto.objetivo is Interactuable
		and contexto.objetivo.definicion != null
	):
		var sonido_examen: AudioStream = contexto.objetivo.definicion.obtener_sonido_examen()
		if sonido_examen != null:
			_reproducir_sonido_examen(sonido_examen)
		if contexto.objetivo.definicion.id_definicion == &"trampero_sin_rostro":
			_reproducir_campanas_estatua()
		if contexto.objetivo.definicion.ilustracion_examen != null:
			var texto_final: String = ""
			if contexto.objetivo.has_method(&"obtener_texto_examen"):
				texto_final = String(contexto.objetivo.call(&"obtener_texto_examen"))
			elif "texto_examen" in contexto.objetivo and not (contexto.objetivo.texto_examen as String).is_empty():
				texto_final = String(contexto.objetivo.texto_examen)

			if texto_final.is_empty():
				var textos: Array[String] = []
				for id_mensaje in resultado.mensajes:
					textos.append(
						catalogo_mensajes.resolver(id_mensaje)
						if catalogo_mensajes != null
						else String(id_mensaje)
					)
				texto_final = "\n\n".join(textos)
			if texto_final.is_empty() and not contexto.objetivo.definicion.descripcion_base.is_empty():
				texto_final = contexto.objetivo.definicion.descripcion_base

			panel_examen_ilustrado.mostrar(
				titulo,
				contexto.objetivo.definicion.ilustracion_examen,
				texto_final
			)
			_actualizar_estado_modal_interaccion()
			return
	if resultado.tirada == null:
		panel_resultado_accion.mostrar_resultado(titulo, resultado, catalogo_mensajes)
		return
	historial_tiradas.registrar(resultado.tirada)
	if resultado.tirada_defensa != null:
		historial_tiradas.registrar(resultado.tirada_defensa)
	if resultado.tirada_dano != null:
		historial_tiradas.registrar(resultado.tirada_dano)
	var mensajes: Array[String] = []
	for id_mensaje in resultado.mensajes:
		mensajes.append(
			catalogo_mensajes.resolver(id_mensaje)
			if catalogo_mensajes != null
			else String(id_mensaje)
		)
	panel_resultado_accion.mostrar_tirada(titulo, resultado.tirada, mensajes)


## Mutation de Dialogue Manager: resuelve una vez y espera la presentación existente.
func realizar_prueba_dialogo(atributo: String, titulo: String) -> void:
	if not _puede_realizar_prueba_dialogo():
		return
	ultima_prueba_dialogo = null
	prueba_dialogo_resuelta = false
	if atributo not in ["fuerza", "destreza", "voluntad"]:
		return
	_prueba_dialogo_en_curso = true
	await _resolver_prueba_dialogo(atributo, titulo)
	_prueba_dialogo_en_curso = false


func _puede_realizar_prueba_dialogo() -> bool:
	return dialogo_npc_activo and not _prueba_dialogo_en_curso and ficha_jugador != null and ficha_jugador.puede_actuar()


func conoce_informacion_dialogo(id_fragmento: StringName) -> bool:
	return (
		dialogo_npc_activo and is_instance_valid(npc_dialogo_activo) and ficha_jugador != null
		and registro_conocimiento.conoce_fragmento(ficha_jugador.id_observador, npc_dialogo_activo.id_instancia, id_fragmento)
	)


## El diálogo sólo necesita conocer el ID configurado en su tema.
func realizar_prueba_dialogo_configurada(id_prueba: StringName) -> void:
	if not _puede_realizar_prueba_dialogo():
		return
	ultima_prueba_dialogo = null
	prueba_dialogo_resuelta = false
	if tema_dialogo_npc_activo == null or not is_instance_valid(npc_dialogo_activo) or npc_dialogo_activo.esta_muerto():
		return
	var prueba := tema_dialogo_npc_activo.obtener_prueba(id_prueba)
	if prueba == null:
		push_warning("Prueba de diálogo ausente, inválida o duplicada: %s." % id_prueba)
		return
	var coincidencias := 0
	for tema in npc_dialogo_activo.obtener_definicion_personaje().dialogos:
		if tema == null:
			continue
		for candidata in tema.pruebas:
			if candidata != null and candidata.id_prueba == id_prueba:
				coincidencias += 1
	if coincidencias != 1:
		push_warning("El ID de prueba debe ser único en el NPC: %s." % id_prueba)
		return
	var npc := npc_dialogo_activo
	var recordado: Variant = npc.obtener_resultado_prueba_dialogo(id_prueba)
	if prueba.una_sola_vez and recordado is bool:
		_exito_prueba_dialogo = recordado
		prueba_dialogo_resuelta = true
		return
	var motivo := prueba.validar_consecuencias(npc, ficha_jugador, registro_conocimiento)
	if motivo != &"":
		push_warning("Prueba de diálogo %s: %s." % [id_prueba, motivo])
		return
	_prueba_dialogo_en_curso = true
	await _resolver_prueba_dialogo(prueba.atributo, prueba.titulo)
	if prueba_dialogo_resuelta and dialogo_npc_activo and npc_dialogo_activo == npc:
		var consecuencias := prueba.consecuencias_exito if _exito_prueba_dialogo else prueba.consecuencias_fallo
		for consecuencia in consecuencias:
			var mensaje := consecuencia.aplicar(npc, ficha_jugador, registro_conocimiento, catalogo_mensajes)
			if not mensaje.is_empty():
				registro_narrativo.registrar(EntradaRegistroNarrativo.Categoria.SISTEMA, prueba.titulo, mensaje)
		if prueba.una_sola_vez:
			npc.recordar_resultado_prueba_dialogo(id_prueba, _exito_prueba_dialogo)
	_prueba_dialogo_en_curso = false


func _resolver_prueba_dialogo(atributo: String, titulo: String) -> void:
	var valor: int = ficha_jugador.call(StringName("obtener_" + atributo))
	ultima_prueba_dialogo = motor_dados_dialogo.resolver_prueba(valor)
	if not ultima_prueba_dialogo.valida:
		return
	prueba_dialogo_resuelta = true
	_exito_prueba_dialogo = ultima_prueba_dialogo.exitosa
	historial_tiradas.registrar(ultima_prueba_dialogo)
	_registrar_resultado_narrativo(
		titulo, ResultadoAccion.crear_exito().con_tirada(ultima_prueba_dialogo),
		EntradaRegistroNarrativo.Categoria.TIRADA, atributo.left(3).to_upper()
	)
	panel_resultado_accion.mostrar_tirada(titulo, ultima_prueba_dialogo)
	if panel_resultado_accion.visible:
		await panel_resultado_accion.cerrado


func _obtener_ilustracion_dialogo_jugador() -> Texture2D:
	if ficha_jugador == null:
		return null
	match ficha_jugador.clase:
		"Guerrero":
			return ilustracion_dialogo_guerrero
		"Ladrón":
			return ilustracion_dialogo_ladron
		"Mago":
			return ilustracion_dialogo_mago
	return null


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


func _on_tirada_presentada(_resultado: Variant) -> void:
	_actualizar_estado_modal_interaccion()


func _reproducir_narrador_tirada(resultado: Variant) -> void:
	if resultado == null:
		return
	var stream: AudioStream = null
	if "exitosa" in resultado:
		stream = SONIDO_DADO_EXITO if resultado.exitosa else SONIDO_DADO_FRACASO
	if stream == null:
		return
	if not is_instance_valid(reproductor_narrador_dados):
		reproductor_narrador_dados = _crear_reproductor_global(&"AudioNarradorDados", 2.5)
	_desactivar_loop_audio(stream)
	reproductor_narrador_dados.volume_db = 2.5
	reproductor_narrador_dados.stream = stream
	reproductor_narrador_dados.play()


func _presentar_entrada_nueva_zona() -> void:
	if es_escenario_de_descanso:
		return
	var rep_ambiente := _crear_reproductor_global(&"AudioAmbienteEntrada", -8.0)
	_desactivar_loop_audio(SONIDO_AMBIENTE_ENTRADA_ZONA)
	rep_ambiente.stream = SONIDO_AMBIENTE_ENTRADA_ZONA
	rep_ambiente.play()

	var rep_aliento := _crear_reproductor_global(&"AudioAlientoEntrada", -6.0)
	var stream_aliento := SONIDO_BREATH_1 if randf() < 0.5 else SONIDO_BREATH_2
	_desactivar_loop_audio(stream_aliento)
	rep_aliento.stream = stream_aliento
	rep_aliento.play()

	var nombre := "TEMPLO DE LAS TRAMPAS"
	if zona_actual != null:
		if zona_actual.has_method(&"obtener_nombre_zona"):
			nombre = String(zona_actual.call(&"obtener_nombre_zona"))
		elif "nombre_zona" in zona_actual and not (zona_actual.nombre_zona as String).is_empty():
			nombre = String(zona_actual.nombre_zona)
		elif zona_actual.scene_file_path.contains("Templo"):
			nombre = "TEMPLO DE LAS TRAMPAS"
		else:
			nombre = zona_actual.name.to_upper()

	if nombre.to_upper().contains("TEMPLO"):
		var rep_narrador := _crear_reproductor_global(&"AudioNarradorZona", 2.5)
		_desactivar_loop_audio(SONIDO_NARRADOR_TEMPLO_TRAMPAS)
		rep_narrador.stream = SONIDO_NARRADOR_TEMPLO_TRAMPAS
		rep_narrador.play()

	presentacion_zona = ESCENA_PRESENTACION_ZONA.instantiate() as PresentacionZona
	add_child(presentacion_zona)
	presentacion_zona.presentar(nombre)


func _on_vida_jugador_cambiada(actual: int, maximo: int) -> void:
	if maximo <= 0:
		return
	if actual <= 0:
		_desactivar_estado_cerca_muerte()
		_mostrar_pantalla_muerte()
		return
	var porcentaje := float(actual) / float(maximo)
	if porcentaje <= 0.50:
		_activar_estado_cerca_muerte(porcentaje)
	else:
		_desactivar_estado_cerca_muerte()


func _inicializar_overlay_cerca_muerte() -> void:
	if capa_cerca_muerte != null and is_instance_valid(capa_cerca_muerte):
		return
	capa_cerca_muerte = CanvasLayer.new()
	capa_cerca_muerte.name = "CapaCercaMuerte"
	capa_cerca_muerte.layer = 50

	rect_cerca_muerte = ColorRect.new()
	rect_cerca_muerte.name = "OverlayRojo"
	rect_cerca_muerte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect_cerca_muerte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect_cerca_muerte.visible = false

	material_cerca_muerte = ShaderMaterial.new()
	material_cerca_muerte.shader = SHADER_CERCA_MUERTE
	rect_cerca_muerte.material = material_cerca_muerte

	capa_cerca_muerte.add_child(rect_cerca_muerte)
	add_child(capa_cerca_muerte)

	reproductor_latido = _crear_reproductor_global(&"AudioLatidoCorazon", 5.0)
	reproductor_latido.bus = &"Master"
	_preparar_loop_audio(SONIDO_LATIDO_CORAZON)
	reproductor_latido.stream = SONIDO_LATIDO_CORAZON
	if not reproductor_latido.finished.is_connected(_on_latido_finished):
		reproductor_latido.finished.connect(_on_latido_finished)


func _on_latido_finished() -> void:
	if _estado_cerca_muerte_activo and is_instance_valid(reproductor_latido):
		reproductor_latido.play()


func _activar_estado_cerca_muerte(porcentaje: float) -> void:
	_inicializar_overlay_cerca_muerte()
	_estado_cerca_muerte_activo = true
	if rect_cerca_muerte != null:
		rect_cerca_muerte.visible = true
	var intensidad: float = clampf(remap(porcentaje, 0.50, 0.05, 0.30, 1.0), 0.30, 1.0)
	if material_cerca_muerte != null:
		material_cerca_muerte.set_shader_parameter("intensidad", intensidad)
	if is_instance_valid(reproductor_latido):
		reproductor_latido.volume_db = clampf(remap(porcentaje, 0.50, 0.05, 4.0, 8.5), 4.0, 8.5)
		if not reproductor_latido.playing:
			reproductor_latido.play()


func _desactivar_estado_cerca_muerte() -> void:
	_estado_cerca_muerte_activo = false
	if rect_cerca_muerte != null:
		rect_cerca_muerte.visible = false
	if material_cerca_muerte != null:
		material_cerca_muerte.set_shader_parameter("intensidad", 0.0)
	if is_instance_valid(reproductor_latido) and reproductor_latido.playing:
		reproductor_latido.stop()


func _mostrar_pantalla_muerte() -> void:
	if is_instance_valid(reproductor_musica) and reproductor_musica.playing:
		reproductor_musica.stop()
	if is_instance_valid(reproductor_fuego) and reproductor_fuego.playing:
		reproductor_fuego.stop()
	if is_instance_valid(reproductor_latido) and reproductor_latido.playing:
		reproductor_latido.stop()
	
	if pantalla_muerte == null or not is_instance_valid(pantalla_muerte):
		pantalla_muerte = ESCENA_PANTALLA_MUERTE.instantiate() as PantallaMuerte
		add_child(pantalla_muerte)
		pantalla_muerte.reiniciar_solicitado.connect(func():
			get_tree().reload_current_scene()
		)
		pantalla_muerte.cargar_solicitado.connect(_ejecutar_carga_tras_muerte)
	var se_puede_cargar: bool = (guardado_en_fogata_realizado or EstadoPartida.guardado_en_fogata_realizado) and FileAccess.file_exists(RUTA_GUARDADO)
	pantalla_muerte.mostrar_muerte(se_puede_cargar)


func _ejecutar_carga_tras_muerte() -> void:
	var snapshot: Variant = persistencia_partida.archivos.cargar(RUTA_GUARDADO)
	if snapshot is StringName or not snapshot is Dictionary:
		push_error("Error al leer archivo de guardado tras muerte: %s" % str(snapshot))
		return
	
	_desactivar_estado_cerca_muerte()
	en_combate = false
	_acciones_en_resolucion = 0
	_turno_exploracion_en_curso = false
	interaccion_modal_activa = false
	_dialogos_camara.clear()
	item_lanzamiento_pendiente = null
	seleccionando_item_lanzamiento = false
	opcion_uso_item_pendiente = null
	
	var escena_guardada: String = snapshot.get("escena_zona", "")
	if not escena_guardada.is_empty() and escena_guardada != zona_actual.scene_file_path:
		if is_instance_valid(pantalla_muerte):
			pantalla_muerte.queue_free()
			pantalla_muerte = null
		if is_instance_valid(campamento):
			campamento.queue_free()
			campamento = null
		get_tree().change_scene_to_file(escena_guardada)
		return
	
	var motivo := cargar_partida(RUTA_GUARDADO)
	if motivo == &"":
		if is_instance_valid(pantalla_muerte):
			pantalla_muerte.queue_free()
			pantalla_muerte = null
		if is_instance_valid(campamento):
			salir_campamento()
		_inicializar_musica()
		centrar_camara_en_ficha()
	else:
		push_error("No se pudo cargar la partida tras muerte: %s" % motivo)


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


func _on_item_suelo_registrado(coord: Vector2i, item_suelo: ItemSuelo) -> void:
	var representacion: Node2D = null
	if item_suelo.item.definicion.escena_mundo != null:
		representacion = item_suelo.item.definicion.escena_mundo.instantiate() as Node2D
	elif item_suelo.item.definicion.icono != null:
		var rep_fallback := RepresentacionItemSuelo.new()
		var spr := Sprite2D.new()
		spr.name = "Sprite2D"
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.texture = item_suelo.item.definicion.icono
		rep_fallback.add_child(spr)
		representacion = rep_fallback

	if representacion == null:
		return
	var capa_suelo := zona_actual.get_node("CapaSuelo") as TileMapLayer
	if representacion is RepresentacionItemSuelo:
		representacion.variante_visual = item_suelo.variante_visual
	zona_actual.add_child(representacion)
	representacion.global_position = capa_suelo.to_global(
		capa_suelo.map_to_local(coord) + item_suelo.desplazamiento_visual
	)
	item_suelo.vincular_representacion(representacion)


func _on_item_suelo_retirado(_coord: Vector2i, item_suelo: ItemSuelo) -> void:
	_reproducir_sonido_recoleccion(item_suelo)
	var representacion := item_suelo.obtener_representacion()
	if representacion != null:
		representacion.queue_free()
	if ficha_jugador == null:
		return
	var inventario := ficha_jugador.inventario
	var recogida := inventario.obtener_por_id(item_suelo.item.id_instancia)
	if recogida == item_suelo.item and recogida.definicion.apilable:
		for pila in inventario.obtener_por_definicion(recogida.definicion.id_definicion):
			if (
				pila != recogida
				and pila.definicion == recogida.definicion
				and pila.cantidad + recogida.cantidad <= pila.definicion.cantidad_maxima
			):
				if inventario.combinar(recogida.id_instancia, pila.id_instancia).exitosa:
					break
	if item_suelo.item.definicion.id_definicion == &"antorcha":
		ficha_jugador.activar_antorcha_si_necesario()
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)
	if recogida != null or item_suelo.item.definicion.id_definicion == &"antorcha":
		hud.actualizar_desde_ficha()
	if panel_inventario_equipo != null and panel_inventario_equipo.visible:
		panel_inventario_equipo.refrescar_mochila()
		panel_inventario_equipo.refrescar_peso()


func _on_item_inventario_soltado_al_suelo(
	item: ItemInstancia,
	origen_indice: int,
	es_equipo: bool,
	punto_pantalla: Vector2
) -> void:
	if (
		ficha_jugador == null
		or not ficha_jugador.puede_actuar()
		or ficha_jugador.esta_moviendose
		or item == null
	):
		return
	if en_combate and (not _es_turno_jugador() or _turno_exploracion_en_curso):
		return

	var capa_suelo := zona_actual.get_node("CapaSuelo") as TileMapLayer
	var pos_mundo: Vector2 = (
		get_canvas_transform().affine_inverse() * punto_pantalla
		if punto_pantalla != Vector2.ZERO
		else capa_suelo.get_global_mouse_position()
	)
	var coord_cursor: Vector2i = capa_suelo.local_to_map(capa_suelo.to_local(pos_mundo))
	var coord_origen := ficha_jugador.coordenada_mapa
	var coord_destino := coord_origen

	var distancia := absi(coord_cursor.x - coord_origen.x) + absi(coord_cursor.y - coord_origen.y)
	if distancia <= 1 and tablero.validar_colocacion_item_suelo(coord_cursor, ficha_jugador) == &"":
		coord_destino = coord_cursor
	elif tablero.validar_colocacion_item_suelo(coord_origen, ficha_jugador) == &"":
		coord_destino = coord_origen
	else:
		var candidatas: Array[Vector2i] = [
			Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP
		]
		candidatas.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return (coord_origen + a).distance_squared_to(coord_cursor) < (coord_origen + b).distance_squared_to(coord_cursor)
		)
		var encontrada := false
		for dir in candidatas:
			var c := coord_origen + dir
			if tablero.validar_colocacion_item_suelo(c, ficha_jugador) == &"":
				coord_destino = c
				encontrada = true
				break
		if not encontrada:
			return

	if es_equipo:
		if ficha_jugador.equipo == null or ficha_jugador.equipo.ranuras.get(origen_indice) != item:
			return

	var contexto := transferidor_items.construir_contexto_soltar(
		ficha_jugador,
		item,
		coord_origen,
		coord_destino,
		-1,
		&"",
		origen_indice if es_equipo else -1
	)
	var resultado := gestor_acciones.procesar_accion(contexto)
	if resultado.exitosa:
		registro_narrativo.registrar(
			EntradaRegistroNarrativo.Categoria.SISTEMA,
			"Soltar ítem",
			"Sueltas %s en el suelo." % item.definicion.nombre
		)
		if item.definicion.id_definicion == &"antorcha":
			_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)
		if panel_inventario_equipo != null and panel_inventario_equipo.visible:
			panel_inventario_equipo.refrescar_mochila()
			panel_inventario_equipo.refrescar_equipo()
			panel_inventario_equipo.refrescar_peso()
		if hud != null:
			hud.actualizar_desde_ficha()


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
	_cancelar_bola_fuego()
	seleccionando_item_lanzamiento = true
	menu_contextual.mostrar(
		catalogo_mensajes.resolver(&"interaccion.lanzar_item"),
		adaptador_menu_contextual.construir_entradas_items(
			arrojables,
			catalogo_mensajes,
			false
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
	if item != null and item.definicion != null:
		var sonido_impacto := item.definicion.obtener_sonido_impacto()
		if sonido_impacto != null:
			_reproducir_sonido_impacto(sonido_impacto, contexto.celda_objetivo)
	var resultado := gestor_acciones.procesar_accion(contexto)
	ultimo_contexto_contextual = contexto
	ultimo_resultado_contextual = resultado
	lanzamiento_en_vuelo = false
	_registrar_resultado_narrativo(
		item.definicion.nombre, resultado, EntradaRegistroNarrativo.Categoria.OBJETO
	)
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
		or (habilidades_nivel_dos != null and habilidades_nivel_dos.empuje_pendiente != null)
		or (is_instance_valid(panel_progresion) and panel_progresion.visible)
		or dialogo_npc_activo
		or (
			is_instance_valid(panel_inventario_cofre)
			and panel_inventario_cofre.visible
		)
		or (
			is_instance_valid(menu_contextual) 
			and menu_contextual.visible)
		or (
			is_instance_valid(panel_resultado_accion)
			and panel_resultado_accion.visible
		)
		or (
			is_instance_valid(panel_examen_ilustrado)
			and panel_examen_ilustrado.visible
		)
		or (
			is_instance_valid(panel_ficha_npc)
			and panel_ficha_npc.visible
		)
		or (
			is_instance_valid(panel_inventario_equipo)
			and panel_inventario_equipo.visible
		)
	)
	if interaccion_modal_activa == siguiente:
		return
	interaccion_modal_activa = siguiente
	if interaccion_modal_activa:
		camera_2d.suspender_bordes()
		CursorJuego.establecer_cursor(CursorJuego.Tipo.DEFAULT)
		capa_selector.clear()
		capa_camino.clear()
		camino_actual_tentativo.clear()
		panel_info_npc.ocultar()
	estado_modal_interaccion_cambiado.emit(interaccion_modal_activa)


func _on_dialogo_npc_finalizado(recurso: DialogueResource) -> void:
	if recurso != recurso_dialogo_npc_activo:
		return
	dialogo_npc_activo = false
	recurso_dialogo_npc_activo = null
	tema_dialogo_npc_activo = null
	npc_dialogo_activo = null
	ultima_prueba_dialogo = null
	prueba_dialogo_resuelta = false
	_actualizar_estado_modal_interaccion()
