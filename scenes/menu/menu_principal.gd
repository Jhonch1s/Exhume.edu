extends Control

@onready var musica_menu: AudioStreamPlayer = $MusicaMenu


func _ready() -> void:
	if musica_menu.stream is AudioStreamMP3:
		musica_menu.stream.loop = true

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/nueva_partida.tscn")


func _on_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/personajes.tscn")


func _on_opciones_pressed() -> void:
	pass # Replace with function body.


func _on_salir_pressed() -> void:
	get_tree().quit()
