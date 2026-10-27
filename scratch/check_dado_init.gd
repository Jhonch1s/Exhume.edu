extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var escena: PackedScene = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	var dado: VistaDado3D = escena.instantiate()
	root.add_child(dado)
	await process_frame
	
	var pivote: Node3D = dado.get_node('SubViewport/PivoteDado')
	var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
	print('Pivote rot: ', pivote.rotation_degrees)
	print('Cam pos: ', cam.position, ' rot: ', cam.rotation_degrees, ' size: ', cam.size)
	quit(0)
