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
	
	var viewport = dado.get_node('SubViewport')
	var pivote = dado.get_node('SubViewport/PivoteDado')
	var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
	cam.position = Vector3(0, 0.45, 2.2)
	cam.rotation_degrees = Vector3(-18.0, 0, 0)
	cam.size = 0.82
	
	# Creamos un SoporteOrientacion intermediario
	var soporte := Node3D.new()
	soporte.name = 'SoporteOrientacion'
	viewport.add_child(soporte)
	soporte.rotation_degrees = Vector3(0, 0, -90)
	
	# Movemos pivote_dado dentro de soporte
	pivote.reparent(soporte)
	
	# Ahora probamos animar a valor 4
	dado.mostrar_valor(1)
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/soporte_val1.png')
	
	# Animamos a 4
	dado.animar_a_valor(4)
	await dado.animacion_finalizada
	for f in range(5): await process_frame
	root.get_texture().get_image().save_png('res://scratch/soporte_val4.png')
	
	print('Animacion con SoporteOrientacion probada exitosamente!')
	quit(0)
