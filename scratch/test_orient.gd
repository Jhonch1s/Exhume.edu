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
	var modelo: Node3D = dado.get_node('SubViewport/PivoteDado/Dado')
	
	# Probemos:
	# Si pivote tiene rotation_degrees = Vector3(0, 0, -90)
	# y modelo.rotation_degrees = Vector3(0, angulo_y, 0)
	# o viceversa:
	pivote.rotation_degrees = Vector3(0, 0, -90)
	
	var angulos_orig = {
		1: 270.0,
		2: 30.0,
		3: 150.0,
		4: 90.0,
		5: 330.0,
		6: 210.0,
	}
	
	for v in range(1, 7):
		modelo.rotation_degrees = Vector3(0, angulos_orig[v], 0)
		for f in range(5):
			await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png('res://scratch/orient_test_v%d.png' % v)
		print('v=%d con modelo.rot_y=%f' % [v, angulos_orig[v]])
		
	quit(0)
