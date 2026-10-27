extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var escena = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	var dado: VistaDado3D = escena.instantiate()
	dado.size = Vector2(440, 215)
	dado.tamano_pixel = 2
	root.add_child(dado)
	await process_frame
	
	var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
	print('Camara inicial: pos=', cam.position, ' rot=', cam.rotation_degrees, ' size=', cam.size)
	
	# Rotamos la camara en Z por 90 o -90
	cam.rotation_degrees = Vector3(0, 0, 90)
	
	dado.mostrar_valor(1)
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_cam_z90_v1.png')
	
	cam.rotation_degrees = Vector3(0, 0, -90)
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_cam_zneg90_v1.png')
	
	dado.animar_a_valor(4)
	await dado.animacion_finalizada
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_cam_anim_v4.png')
	
	print('Prueba con rotacion de camara completada!')
	quit(0)
