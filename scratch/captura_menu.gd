extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/menu/menu_principal.tscn")
	var nodo: Control = escena.instantiate()
	root.add_child(nodo)
	
	# Esperar a que la animación de entrada de menu_colgante termine (unos 1.5s)
	for i in range(90):
		await process_frame
	
	var img: Image = root.get_texture().get_image()
	img.save_png("res://scratch/captura_menu_principal.png")
	print("Captura guardada en res://scratch/captura_menu_principal.png")
	quit(0)
