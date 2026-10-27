extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/ui/interacciones/vista_dado_3d.tscn")
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(400, 200)
	dado.size = Vector2(400, 200)
	dado.tamano_pixel = 2
	root.add_child(dado)
	await process_frame
	
	# Probar rotación horizontal del dado:
	# El modelo del dado está dentro de SubViewport/PivoteDado/Dado
	# Si rotamos el Dado dentro del pivote a Z = 90°:
	var modelo: Node3D = dado.get_node("SubViewport/PivoteDado/Dado")
	modelo.rotation_degrees = Vector3(0, 0, 90)
	
	# Ajustar cámara para que encuadre bien en horizontal (proyección ortogonal)
	var cam: Camera3D = dado.get_node("SubViewport/Camera3D")
	cam.size = 1.3
	
	dado.mostrar_valor(4)
	for i in range(5):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png("res://scratch/test_dado_horizontal.png")
	print("Captura del dado horizontal guardada en res://scratch/test_dado_horizontal.png")
	quit(0)
