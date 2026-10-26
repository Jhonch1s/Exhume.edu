extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var fondo_tex = load('res://assets/ui/panels/new_game/dice/dice_area_frame.png')
	var escena_dado = load('res://scenes/ui/interacciones/vista_dado_3d.tscn')
	
	var root_ctrl := Control.new()
	root_ctrl.size = Vector2(1000, 600)
	root.add_child(root_ctrl)
	
	# Bandeja A: Camara recta (perspectiva frontal limpia)
	var panel_a := PanelContainer.new()
	panel_a.position = Vector2(40, 50)
	panel_a.size = Vector2(440, 215)
	root_ctrl.add_child(panel_a)
	
	var rect_a := TextureRect.new()
	rect_a.texture = fondo_tex
	rect_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_a.stretch_mode = TextureRect.STRETCH_SCALE
	rect_a.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_a.add_child(rect_a)
	
	var dado_a: VistaDado3D = escena_dado.instantiate()
	dado_a.size = Vector2(440, 215)
	dado_a.tamano_pixel = 2
	panel_a.add_child(dado_a)
	
	# Bandeja B: Camara inclinada (-18 deg)
	var panel_b := PanelContainer.new()
	panel_b.position = Vector2(520, 50)
	panel_b.size = Vector2(440, 215)
	root_ctrl.add_child(panel_b)
	
	var rect_b := TextureRect.new()
	rect_b.texture = fondo_tex
	rect_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_b.stretch_mode = TextureRect.STRETCH_SCALE
	rect_b.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_b.add_child(rect_b)
	
	var dado_b: VistaDado3D = escena_dado.instantiate()
	dado_b.size = Vector2(440, 215)
	dado_b.tamano_pixel = 2
	panel_b.add_child(dado_b)
	
	await process_frame
	
	# Config A: frontal
	var vp_a = dado_a.get_node('SubViewport')
	var piv_a = dado_a.get_node('SubViewport/PivoteDado')
	var cam_a = dado_a.get_node('SubViewport/Camera3D')
	cam_a.position = Vector3(0, 0, 2.5)
	cam_a.rotation_degrees = Vector3.ZERO
	cam_a.size = 0.85
	var sop_a = Node3D.new()
	vp_a.add_child(sop_a)
	sop_a.rotation_degrees = Vector3(0, 0, -90)
	piv_a.reparent(sop_a)
	dado_a.mostrar_valor(4)
	
	# Config B: inclinada
	var vp_b = dado_b.get_node('SubViewport')
	var piv_b = dado_b.get_node('SubViewport/PivoteDado')
	var cam_b = dado_b.get_node('SubViewport/Camera3D')
	cam_b.position = Vector3(0, 0.45, 2.2)
	cam_b.rotation_degrees = Vector3(-18, 0, 0)
	cam_b.size = 0.82
	var sop_b = Node3D.new()
	vp_b.add_child(sop_b)
	sop_b.rotation_degrees = Vector3(0, 0, -90)
	piv_b.reparent(sop_b)
	dado_b.mostrar_valor(4)
	
	for f in range(10): await process_frame
	
	root.get_texture().get_image().save_png('res://scratch/comparativa_bandejas.png')
	print('Comparativa guardada en scratch/comparativa_bandejas.png')
	quit(0)
