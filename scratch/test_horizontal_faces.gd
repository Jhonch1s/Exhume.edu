extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var escena: PackedScene = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	
	# Probemos valores 1 a 6
	# En vertical original:
	# 1: 270, 2: 30, 3: 150, 4: 90, 5: 330, 6: 210
	# La cara activa mira hacia +Z (la camara).
	# Si acostamos el dado: queremos que el cilindro este horizontal (eje X)
	# y la cara activa mire hacia la camara (+Z), o ligeramente hacia arriba si la camara mira desde arriba.
	
	var angulos_orig = {
		1: 270.0,
		2: 30.0,
		3: 150.0,
		4: 90.0,
		5: 330.0,
		6: 210.0,
	}
	
	var contenedor := Control.new()
	contenedor.size = Vector2(440, 215)
	root.add_child(contenedor)
	
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(440, 215)
	dado.size = Vector2(440, 215)
	dado.tamano_pixel = 2
	contenedor.add_child(dado)
	await process_frame
	
	var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
	cam.position = Vector3(0, 0.45, 2.2)
	cam.rotation_degrees = Vector3(-18.0, 0, 0)
	cam.size = 0.82
	
	var pivote: Node3D = dado.get_node('SubViewport/PivoteDado')
	var modelo: Node3D = dado.get_node('SubViewport/PivoteDado/Dado')
	
	# Si modelo tiene rotation_degrees = Vector3(0, 0, 90) o Vector3(0, 0, -90)
	# Veamos como gira el modelo o pivote
	# Si dejamos a Pivote rotar en X, o rotamos el modelo en Z = 90
	modelo.rotation_degrees = Vector3(0, 0, 90)
	
	for v in range(1, 7):
		# Veamos cual rotacion en X del pivote muestra el numero v
		# En el glb, si giramos en Z por 90 grados:
		# el eje Y original pasa a ser eje X o -X
		# Por tanto, la rotacion que antes era en Y ahora se transfiere.
		# Vamos a probar varios angulos para ver que valor aparece
		pivote.rotation_degrees = Vector3(angulos_orig[v], 0, 0)
		for f in range(4):
			await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png('res://scratch/dado_h_v%d.png' % v)
		print('Guardado v=%d con rot X=%f' % [v, angulos_orig[v]])
		
	quit(0)
