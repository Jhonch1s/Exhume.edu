extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/ui/interacciones/vista_dado_3d.tscn")
	var contenedor := Control.new()
	contenedor.size = Vector2(800, 400)
	root.add_child(contenedor)
	
	# Probar varias rotaciones de cámara y dado:
	# Config 1: Dado horizontal a lo largo de X (rotación Z = 90 o Z = -90)
	# Y cámara con un poco de inclinación hacia abajo (X = -25°) para ver la cara superior con la runa
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(400, 200)
	dado.size = Vector2(400, 200)
	dado.position = Vector2(200, 50)
	dado.tamano_pixel = 2
	contenedor.add_child(dado)
	await process_frame
	
	var cam: Camera3D = dado.get_node("SubViewport/Camera3D")
	# Inclinamos la cámara un poco hacia abajo (pitch -25°) y subimos Y
	cam.position = Vector3(0, 1.0, 2.2)
	cam.rotation_degrees = Vector3(-24, 0, 0)
	cam.size = 0.9
	
	var pivote: Node3D = dado.get_node("SubViewport/PivoteDado")
	# Ponemos el dado horizontal a lo largo del eje X (rotación Z = 90°)
	# Y para cambiar de cara, rotamos en su propio eje largo (X)
	pivote.rotation_degrees = Vector3(0, 0, 90)
	
	for i in range(10):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png("res://scratch/test_dado_horizontal_inclinado.png")
	print("Captura guardada en res://scratch/test_dado_horizontal_inclinado.png")
	quit(0)
