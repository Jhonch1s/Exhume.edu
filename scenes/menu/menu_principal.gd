extends Control

@onready var musica_menu: AudioStreamPlayer = $MusicaMenu
@onready var menu_colgante: Control = $MenuColgante
@onready var nueva_partida: Control = $NuevaPartida

var transicion_activa := false
var mostrando_nueva_partida := false


func _ready() -> void:
	if musica_menu.stream is AudioStreamMP3:
		musica_menu.stream.loop = true

func _on_jugar_pressed() -> void:
	if transicion_activa:
		return

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


func _on_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/personajes.tscn")


func _on_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/opciones.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
