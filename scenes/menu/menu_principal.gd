extends Control

const SONIDO_NARRADOR_CONTINUAR: AudioStream = preload("res://assets/sonidos/narrador/vuelve a la oscuridad.mp3")
const SONIDO_NARRADOR_NUEVA_EXPLORACION: AudioStream = preload("res://assets/sonidos/narrador/lograras sobrevivir.mp3")

@onready var musica_menu: AudioStreamPlayer = $MusicaMenu
@onready var menu_colgante: Control = $MenuColgante
@onready var nueva_partida: Control = $NuevaPartida
@onready var opciones_partida: Control = $OpcionesPartida
@onready var personajes: Control = $Personajes


var transicion_activa := false
var mostrando_nueva_partida := false
var transicion_activa_opciones := false
var mostrando_opciones := false


func _ready() -> void:
	if musica_menu.stream is AudioStreamMP3:
		musica_menu.stream.loop = true
	if EstadoPartida.error_carga != &"":
		_on_continuar_pressed()


func _reproducir_narrador_global(stream: AudioStream, vol_db: float = 2.5) -> void:
	if stream == null or not is_inside_tree():
		return
	var anterior := get_tree().root.get_node_or_null("AudioNarradorGlobal") as AudioStreamPlayer
	if is_instance_valid(anterior):
		anterior.stop()
		anterior.queue_free()
	var rep := AudioStreamPlayer.new()
	rep.name = "AudioNarradorGlobal"
	rep.stream = stream
	rep.volume_db = vol_db
	rep.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(rep)
	rep.play()
	rep.finished.connect(rep.queue_free)


func _on_jugar_pressed() -> void:
	if transicion_activa:
		return

	_reproducir_narrador_global(SONIDO_NARRADOR_NUEVA_EXPLORACION)
	transicion_activa = true
	menu_colgante.process_mode = Node.PROCESS_MODE_DISABLED

	var tween := create_tween()
	tween.tween_property(
		menu_colgante,
		"position:y",
		menu_colgante.position.y - menu_colgante.size.y - 80.0,
		0.55
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	menu_colgante.hide()
	await nueva_partida.reproducir_entrada()
	mostrando_nueva_partida = true
	transicion_activa = false


func _on_volver_nueva_partida() -> void:
	if transicion_activa or not mostrando_nueva_partida:
		return

	transicion_activa = true
	await nueva_partida.reproducir_salida()
	nueva_partida.hide()
	menu_colgante.position.y = 0.0
	menu_colgante.show()
	menu_colgante.process_mode = Node.PROCESS_MODE_INHERIT
	await menu_colgante.reproducir_entrada()
	mostrando_nueva_partida = false
	transicion_activa = false


func _on_excursion_solicitada(datos: Dictionary) -> void:
	if not EstadoPartida.establecer_aventurero(datos):
		push_error("No se puede iniciar la excursión: datos de aventurero inválidos.")
		return
	musica_menu.stop()
	var narrador := get_tree().root.get_node_or_null("AudioNarradorGlobal")
	if narrador != null:
		narrador.queue_free()
	var capa := CanvasLayer.new()
	capa.layer = 4
	add_child(capa)
	var cinematica := preload("res://scenes/cinematicas/cinematica_imagenes.tscn").instantiate()
	capa.add_child(cinematica)
	await cinematica.terminada
	get_tree().change_scene_to_file("res://scenes/Prision/prision.tscn")


func _on_continuar_pressed() -> void:
	if transicion_activa:
		return
	_reproducir_narrador_global(SONIDO_NARRADOR_CONTINUAR)
	transicion_activa = true
	menu_colgante.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(menu_colgante, "position:y", menu_colgante.position.y - menu_colgante.size.y - 80.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	menu_colgante.hide()
	personajes.actualizar()
	personajes.show()
	transicion_activa = false


func _on_volver_personajes() -> void:
	if transicion_activa:
		return
	personajes.hide()
	menu_colgante.position.y = 0.0
	menu_colgante.show()
	menu_colgante.process_mode = Node.PROCESS_MODE_INHERIT
	transicion_activa = true
	await menu_colgante.reproducir_entrada()
	transicion_activa = false


func _on_opciones_pressed() -> void:
	if transicion_activa_opciones:
		return
	transicion_activa_opciones = true
	
	menu_colgante.process_mode = Node.PROCESS_MODE_DISABLED

	var tween := create_tween()
	tween.tween_property(
		menu_colgante,
		"position:y",
		menu_colgante.position.y - menu_colgante.size.y - 80.0,
		0.55
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	menu_colgante.hide()
	
	await opciones_partida.reproducir_entrada()
	
	mostrando_opciones = true
	transicion_activa_opciones = false
	
	


func _on_salir_pressed() -> void:
	get_tree().quit()
	
	
func _on_volver_opciones() -> void:
	if transicion_activa_opciones or not mostrando_opciones:
		return

	transicion_activa_opciones = true
	await opciones_partida.reproducir_salida()
	opciones_partida.hide()
	menu_colgante.position.y = 0.0
	menu_colgante.show()
	menu_colgante.process_mode = Node.PROCESS_MODE_INHERIT
	await menu_colgante.reproducir_entrada()
	mostrando_opciones = false
	transicion_activa_opciones = false
