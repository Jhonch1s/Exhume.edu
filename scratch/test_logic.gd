extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var escena = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	
	# 1. Probar modo vertical por defecto
	var dado_vert: VistaDado3D = escena.instantiate()
	root.add_child(dado_vert)
	await process_frame
	dado_vert.mostrar_valor(1)
	assert(is_equal_approx(dado_vert.get_node('SubViewport/PivoteDado').rotation_degrees.y, 270.0))
	print('Vertical test: OK')
	dado_vert.queue_free()
	await process_frame
	
	# 2. Probar animacion en horizontal
	var dado_horiz: VistaDado3D = escena.instantiate()
	root.add_child(dado_horiz)
	await process_frame
	
	var cam: Camera3D = dado_horiz.get_node('SubViewport/Camera3D')
	cam.position = Vector3(0, 0.45, 2.2)
	cam.rotation_degrees = Vector3(-18.0, 0, 0)
	cam.size = 0.82
	var piv = dado_horiz.get_node('SubViewport/PivoteDado')
	var mod = dado_horiz.get_node('SubViewport/PivoteDado/Dado')
	piv.rotation_degrees = Vector3(0, 0, -90)
	
	# animar modelo_dado en Y
	var angulo_actual = mod.rotation_degrees.y
	var destino = 90.0 # valor 4
	var diferencia = fposmod(destino - fposmod(angulo_actual, 360.0), 360.0)
	var tw = dado_horiz.create_tween()
	tw.tween_property(mod, 'rotation_degrees:y', angulo_actual + 1440.0 + diferencia, 0.5)
	await tw.finished
	assert(is_equal_approx(fposmod(mod.rotation_degrees.y, 360.0), 90.0))
	print('Horizontal animation test: OK')
	quit(0)
