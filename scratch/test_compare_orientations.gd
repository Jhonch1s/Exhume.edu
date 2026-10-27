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
	dado.tamano_pixel = 2
	contenedor.add_child(dado)
	await process_frame
	
	var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
	cam.position = Vector3(0, 0.45, 2.2)
	cam.rotation_degrees = Vector3(-18.0, 0, 0)
	cam.size = 0.82
	
	var pivote: Node3D = dado.get_node('SubViewport/PivoteDado')
	var modelo: Node3D = dado.get_node('SubViewport/PivoteDado/Dado')
	
	# Caso A: pivote Z = -90
	pivote.rotation_degrees = Vector3(0, 0, -90)
	modelo.rotation_degrees = Vector3(0, 270, 0) # Cara 1
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_z_neg90_c1.png')
	
	# Caso B: pivote Z = +90
	pivote.rotation_degrees = Vector3(0, 0, 90)
	modelo.rotation_degrees = Vector3(0, 270, 0) # Cara 1
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_z_pos90_c1.png')
	
	# Cara 4 (que tiene una runa muy clara)
	pivote.rotation_degrees = Vector3(0, 0, -90)
	modelo.rotation_degrees = Vector3(0, 90, 0) # Cara 4
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_z_neg90_c4.png')
	
	pivote.rotation_degrees = Vector3(0, 0, 90)
	modelo.rotation_degrees = Vector3(0, 90, 0) # Cara 4
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_z_pos90_c4.png')
	
	print('Capturas guardadas')
	quit(0)
