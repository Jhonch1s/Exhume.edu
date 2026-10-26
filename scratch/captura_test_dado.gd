extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/ui/interacciones/vista_dado_3d.tscn")
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(220, 200)
	dado.size = Vector2(220, 200)
	dado.tamano_pixel = 2
	root.add_child(dado)
	await process_frame
	
	dado.mostrar_valor(4)
	for i in range(5):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png("res://scratch/test_dado_render.png")
	print("Captura del dado guardada en res://scratch/test_dado_render.png")
	quit(0)
