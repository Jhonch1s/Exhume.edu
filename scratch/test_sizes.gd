extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var frame_tex = load('res://assets/ui/panels/new_game/dice/dice_area_frame.png')
	var escena = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	
	var ctrl := Control.new()
	ctrl.size = Vector2(950, 500)
	root.add_child(ctrl)
	
	for idx in range(3):
		var sz = [0.95, 0.75, 0.60][idx]
		var pan := PanelContainer.new()
		pan.position = Vector2(20 + idx * 310, 50)
		pan.size = Vector2(300, 150)
		ctrl.add_child(pan)
		
		var rect := TextureRect.new()
		rect.texture = frame_tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		pan.add_child(rect)
		
		var dado: VistaDado3D = escena.instantiate()
		dado.size = Vector2(300, 150)
		dado.tamano_pixel = 2
		pan.add_child(dado)
		await process_frame
		
		var cam: Camera3D = dado.get_node('SubViewport/Camera3D')
		cam.rotation_degrees = Vector3(0, 0, -90)
		cam.size = sz
		dado.mostrar_valor(4)
	
	for f in range(10): await process_frame
	root.get_texture().get_image().save_png('res://scratch/test_sizes.png')
	print('Sizes tested')
	quit(0)
