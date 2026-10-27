extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/ui/interacciones/vista_dado_3d.tscn")
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(360, 180)
	dado.size = Vector2(360, 180)
	dado.tamano_pixel = 2
	root.add_child(dado)
	await process_frame
	
	var cam: Camera3D = dado.get_node("SubViewport/Camera3D")
	cam.position = Vector3(0, 0.65, 2.0)
	cam.rotation_degrees = Vector3(-20, 0, 0)
	cam.size = 0.75
	
	var pivote: Node3D = dado.get_node("SubViewport/PivoteDado")
	
	# Probar qué ángulo en X (con Z=90) muestra cada cara claramente
	for i in range(6):
		var angulo := 30.0 + i * 60.0
		pivote.rotation_degrees = Vector3(angulo, 0, 90)
		for f in range(3):
			await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png("res://scratch/dado_h_cara_%d.png" % (i + 1))
		print("Cara %d probada con angulo %f" % [i + 1, angulo])
		
	quit(0)
