extends Control



@export_group("Animación de entrada")
@export_range(0.2, 2.0, 0.05) var duracion_caida: float = 0.70
@export_range(0.0, 50.0, 1.0) var sobrepaso: float = 22.0
@export_range(0.0, 30.0, 1.0) var rebote: float = 10.0
@export_range(0.0, 8.0, 0.1) var inclinacion_inicial: float = 2.5

@export_group("Reaccion secundaria")
@export_range(0.0, 2.0, 0.05) var intensidad_reaccion: float = 1.0
@export_range(0.0, 0.15, 0.01) var retraso_entre_niveles: float = 0.04

@export_group("Balanceo ambiental")
@export_range(0.0, 3.0, 0.05) var amplitud_balanceo_colas: float = 0.75
@export_range(1.0, 6.0, 0.1) var duracion_balanceo_colas: float = 3.2

@onready var rig_colgante: Control = $MenuPausa/RigColgante
@onready var piezas_colgantes: Array[Control] = [
	$MenuPausa/RigColgante/Carteles/CartelLogo,
	$MenuPausa/RigColgante/Carteles/Resumir,
	$MenuPausa/RigColgante/Carteles/Opciones,
	$MenuPausa/RigColgante/Carteles/Guardar,
	$MenuPausa/RigColgante/Carteles/Salir,
]
@onready var cola_izquierda: Control = $MenuPausa/RigColgante/Cadenas/ColaIzquierdaRig
@onready var cola_derecha: Control = $MenuPausa/RigColgante/Cadenas/ColaDerechaRig
@onready var resumir: TablaMenuOpcion = $MenuPausa/RigColgante/Carteles/Resumir
@onready var opciones: TablaMenuOpcion = $MenuPausa/RigColgante/Carteles/Opciones
@onready var guardar: TablaMenuOpcion = $MenuPausa/RigColgante/Carteles/Guardar
@onready var estado_guardado: Label = $MenuPausa/EstadoGuardado
@onready var salir: TablaMenuOpcion = $MenuPausa/RigColgante/Carteles/Salir

const CURSOR_PERSONALIZADO = preload("res://assets/ui/cursors/cursor_default.png")
const SONIDO_CADENAS_MENU: AudioStream = preload("res://assets/sonidos/varios/editados/cadenas menu.wav")


var posicion_final_y: float
var posicion_inicial_y: float
var rotaciones_base: Dictionary[Control, float] = {}
var balanceo_colas_activo: bool = false
var tiempo_balanceo_colas: float = 0.0

var transicion_activa_opciones := false
var mostrando_opciones := false

@onready var menu_colgante: Control = $MenuPausa
#@onready var nueva_partida: Control = $NuevaPartida
@onready var opciones_partida: Control = $OpcionesPartida



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# menu se movera desde el punto superior entre las cadenas.
	posicion_final_y = rig_colgante.position.y
	rig_colgante.pivot_offset = Vector2(rig_colgante.size.x * 0.5, 0.0)

	for pieza in piezas_colgantes:
		pieza.pivot_offset = pieza.size * 0.5
		rotaciones_base[pieza] = pieza.rotation_degrees

	resumir.presionado.connect(_on_resumir_pressed)
	opciones.presionado.connect(_on_opciones_pressed)
	guardar.presionado.connect(_on_guardar_pressed)
	salir.presionado.connect(_on_salir_pressed)
	
	if opciones_partida.has_signal("volver_solicitado_opciones"):
		opciones_partida.volver_solicitado_opciones.connect(_on_volver_desde_opciones)

	if visible:
		call_deferred("reproducir_entrada")
	
	print("--- PRUEBA DE OPCIONES PARTIDA ---")
	print("Nodo existe: ", is_instance_valid(opciones_partida))
	print("Posición global: ", opciones_partida.global_position)
	print("Tamaño actual: ", opciones_partida.size)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not balanceo_colas_activo:
		return

	tiempo_balanceo_colas += delta
	var fase_izquierda := TAU * tiempo_balanceo_colas / duracion_balanceo_colas
	var fase_derecha := TAU * tiempo_balanceo_colas / (duracion_balanceo_colas * 1.13)
	cola_izquierda.rotation_degrees = sin(fase_izquierda) * amplitud_balanceo_colas
	cola_derecha.rotation_degrees = -sin(fase_derecha) * amplitud_balanceo_colas * 0.85
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Por defecto la tecla Escape
		get_viewport().set_input_as_handled()
		print("presionaron escape wtfff")
		if mostrando_opciones:
			print("volver opciones")
			_on_volver_desde_opciones()
		elif visible:
			print("resumir juego")
			resumir_juego()
		else:
			print("juego pausado")
			pausar_juego()
			
func _conectar_boton(nodo: Node, metodo: Callable) -> void:
	if nodo.has_signal("presionado"):
		nodo.connect("presionado", metodo)
	elif nodo.has_signal("pressed"):
		nodo.connect("pressed", metodo)
		
func pausar_juego() -> void:
	estado_guardado.text = ""
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	#Input.set_custom_mouse_cursor(CURSOR_PERSONALIZADO, Input.CURSOR_ARROW, Vector2(0, 0))
	CursorJuego.establecer_cursor(0)
	
	transicion_activa_opciones = false
	mostrando_opciones = false
	opciones_partida.hide()
	show()
	reproducir_entrada()


func resumir_juego() -> void:
	if transicion_activa_opciones:
		return
	print("estoy hideando o lo que sea")
	transicion_activa_opciones = true
	await reproducir_salida()
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().paused = false
	transicion_activa_opciones = false


func _on_resumir_pressed() -> void:
	resumir_juego()


func _on_guardar_pressed() -> void:
	if transicion_activa_opciones:
		return
	var escenario := get_parent().get_parent()
	if escenario.get("es_escenario_de_descanso"):
		var campamento: Variant = escenario.get("control_descanso")
		if is_instance_valid(campamento):
			escenario = campamento.escenario
	if not is_instance_valid(escenario) or not escenario.has_method(&"guardar_partida"):
		estado_guardado.text = "No se pudo guardar la partida."
		return
	var motivo: StringName = escenario._motivo_bloqueo_persistencia(true, false)
	if motivo != &"":
		estado_guardado.text = "No se pudo guardar. Termina la acción en curso."
		return
	motivo = escenario.guardar_partida()
	estado_guardado.text = "Partida guardada." if motivo == &"" else "No se pudo guardar la partida: %s" % motivo

func _reproducir_sonido_cadenas() -> void:
	if not is_inside_tree():
		return
	var rep := get_node_or_null("AudioCadenasMenu") as AudioStreamPlayer
	if rep == null:
		rep = AudioStreamPlayer.new()
		rep.name = "AudioCadenasMenu"
		rep.stream = SONIDO_CADENAS_MENU
		rep.volume_db = -4.0
		add_child(rep)
	rep.pitch_scale = randf_range(0.97, 1.03)
	rep.play()


func reproducir_entrada() -> Signal:
	_detener_balanceo_colas()
	_reproducir_sonido_cadenas()
	rig_colgante.show()
	#posicion_final_y = rig_colgante.position.y

	# Comienza afuera de la pantalla.
	rig_colgante.position.y = -rig_colgante.size.y - 80.0
	rig_colgante.rotation_degrees = -inclinacion_inicial

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Primero: caída acelerada y como rebote sobrepaso.
	tween.tween_property(
		rig_colgante,
		"position:y",
		posicion_final_y + sobrepaso,
		duracion_caida
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(
		rig_colgante,
		"rotation_degrees",
		1.8,
		duracion_caida
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# El impacto activa la reaccion de cada cartel mientras el rig rebota.
	tween.tween_callback(_reproducir_reaccion_secundaria)

	# Segundo: rebote hacia arriba.
	tween.tween_property(
		rig_colgante,
		"position:y",
		posicion_final_y - rebote,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		rig_colgante,
		"rotation_degrees",
		-0.9,
		0.12
	)

	# Tercero: asentamiento.
	tween.tween_property(
		rig_colgante,
		"position:y",
		posicion_final_y,
		0.20
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		rig_colgante,
		"rotation_degrees",
		0.0,
		0.26
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween.finished

func reproducir_salida() -> Signal:
	_detener_balanceo_colas()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(
		rig_colgante,
		"position:y",
		-rig_colgante.size.y - 100.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween.finished

func _reproducir_reaccion_secundaria() -> void:
	for indice in piezas_colgantes.size():
		var pieza := piezas_colgantes[indice]
		var rotacion_base := rotaciones_base[pieza]
		# Cada nivel pierde un 18 % de fuerza y alterna direccion.
		var magnitud := 1.2 * pow(0.82, indice)
		var direccion := 1.0 if indice % 2 == 0 else -1.0
		var amplitud := magnitud * direccion * intensidad_reaccion
		var tween_pieza := create_tween()
		tween_pieza.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_pieza.tween_interval(indice * retraso_entre_niveles)
		tween_pieza.tween_property(
			pieza,
			"rotation_degrees",
			rotacion_base + amplitud,
			0.09
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_pieza.tween_property(
			pieza,
			"rotation_degrees",
			rotacion_base - amplitud * 0.45,
			0.13
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_pieza.tween_property(
			pieza,
			"rotation_degrees",
			rotacion_base,
			0.20
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_sacudir_colas()


func _sacudir_colas() -> void:
	_detener_balanceo_colas()

	var tween_izquierda := create_tween()
	tween_izquierda.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_izquierda.tween_interval(0.08)
	tween_izquierda.tween_property(
		cola_izquierda,
		"rotation_degrees",
		-3.2 * intensidad_reaccion,
		0.11
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_izquierda.tween_property(
		cola_izquierda,
		"rotation_degrees",
		1.4 * intensidad_reaccion,
		0.16
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_izquierda.tween_property(
		cola_izquierda,
		"rotation_degrees",
		0.0,
		0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var tween_derecha := create_tween()
	tween_derecha.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_derecha.tween_interval(0.12)
	tween_derecha.tween_property(
		cola_derecha,
		"rotation_degrees",
		4.2 * intensidad_reaccion,
		0.13
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_derecha.tween_property(
		cola_derecha,
		"rotation_degrees",
		-1.8 * intensidad_reaccion,
		0.19
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_derecha.tween_property(
		cola_derecha,
		"rotation_degrees",
		0.0,
		0.30
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_derecha.finished.connect(_iniciar_balanceo_colas)


func _iniciar_balanceo_colas() -> void:
	tiempo_balanceo_colas = 0.0
	balanceo_colas_activo = amplitud_balanceo_colas > 0.0
	set_process(balanceo_colas_activo)


func _detener_balanceo_colas() -> void:
	balanceo_colas_activo = false
	tiempo_balanceo_colas = 0.0
	set_process(false)
	cola_izquierda.rotation_degrees = 0.0
	cola_derecha.rotation_degrees = 0.0
	
func _on_opciones_pressed() -> void:
	if transicion_activa_opciones:
		return
	transicion_activa_opciones = true
	if(opciones_partida):
		print("xddd")
	
	print("estoy mostrando opciones")

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(
		menu_colgante,
		"position:y",
		menu_colgante.position.y - menu_colgante.size.y - 80.0,
		0.55
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	menu_colgante.hide()
	opciones_partida.show()
	if opciones_partida.has_method("reproducir_entrada"):
		await opciones_partida.reproducir_entrada()
	
	mostrando_opciones = true
	transicion_activa_opciones = false
	
	
func _on_volver_desde_opciones() -> void:
	if transicion_activa_opciones or not mostrando_opciones:
		return
	print("estoy volviendo estoy volviendo")
	transicion_activa_opciones = true
	await opciones_partida.reproducir_salida()
	print("tras await")
	opciones_partida.hide()
	menu_colgante.position.y = 0.0
	menu_colgante.show()
	menu_colgante.process_mode = Node.PROCESS_MODE_INHERIT
	await reproducir_entrada()
	print("reproducir entrada")
	mostrando_opciones = false
	transicion_activa_opciones = false


func _on_salir_pressed() -> void:
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://scenes/menu/menu_principal.tscn")
	
