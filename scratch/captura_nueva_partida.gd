extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/menu/menu_principal.tscn")
	var menu: Control = escena.instantiate()
	root.add_child(menu)
	await process_frame
	
	# Llamar a entrar a nueva partida
	menu.call("_on_jugar_pressed")
	
	# Esperar a que la transición termine
	while menu.transicion_activa:
		await process_frame
		
	# Esperar 30 frames adicionales para estabilización visual completa
	for i in range(30):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png("res://scratch/captura_nueva_partida.png")
	print("Captura guardada en res://scratch/captura_nueva_partida.png")
	quit(0)
