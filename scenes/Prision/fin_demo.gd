extends Control


func _ready() -> void:
	$Contenido.modulate.a = 0.0
	create_tween().tween_property($Contenido, "modulate:a", 1.0, 1.2)


func _on_ver_creditos_pressed() -> void:
	$Contenido.hide()
	$Creditos.show()
	var elementos := $Creditos/Columna.get_children()
	var animacion := create_tween()
	for elemento in elementos:
		elemento.modulate.a = 0.0
		animacion.tween_property(elemento, "modulate:a", 1.0, 0.45)


func _on_juego_original_pressed() -> void:
	OS.shell_open("https://rolepersecond.itch.io/exhume-esp-micro-fantasy-rpg")


func _on_volver_al_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/menu_principal.tscn")
