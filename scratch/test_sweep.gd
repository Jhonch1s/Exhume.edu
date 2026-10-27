extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var escena: PackedScene = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	var contenedor := Control.new()
	contenedor.size = Vector2(800, 400)
	root.add_child(contenedor)
	
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(440, 215)
	dado.size = Vector2(440, 215)
	dado.position = Vector2(180, 90)
	dado.tamano_pixel = 2
	contenedor.add_child(dado)
	await process_frame
	
	var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
	cam.position = Vector3(0, 0.45, 2.2)
	cam.rotation_degrees = Vector3(-18.0, 0, 0)
	cam.size = 0.82
	
	var pivote: Node3D = dado.get_node('SubViewport/PivoteDado')
	
	# Probemos con pivote.rotation_degrees:
	# En modo normal (vertical): pivote gira en Y.
	# Si queremos que este horizontal a lo largo de X:
	# Podriamos rotar el dado interior o el pivote.
	# Si rotamos el modelo interior: Dado.rotation_degrees = Vector3(0, 0, 90)
	# o pivote = Vector3(angulo, 0, 90)
	# Veamos que angulo en X muestra 1, 2, 3, 4, 5, 6
	for v in range(1, 7):
		# Los angulos originales en Y eran:
		# 1: 270, 2: 30, 3: 150, 4: 90, 5: 330, 6: 210
		# Si rotamos en Z = 90:
		# En coordenadas locales del cilindro:
		# Veamos qué angulo en X (o Y) muestra cada cara
		pass
	
	# Hagamos una prueba barriendo X de 0 a 360 en pasos de 30 grados
	for ang in [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]:
		pivote.rotation_degrees = Vector3(ang, 0, 90)
		for f in range(6):
			await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png('res://scratch/ang_%03d.png' % ang)
		
	print('Barrido completado')
	quit(0)
