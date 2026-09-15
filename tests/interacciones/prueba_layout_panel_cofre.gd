extends SceneTree

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	var panel = load("res://scenes/ui/inventario/panel_inventario_cofre.tscn").instantiate()
	root.add_child(panel)
	var fondo = panel.get_node("Fondo")
	for tamano in [Vector2(300, 300), Vector2(600, 600), Vector2(900, 700), Vector2(900, 200)]:
		fondo.size = tamano
		await process_frame
		await process_frame
		var area = fondo.get_node("AreaItems")
		assert(area.position.is_equal_approx(tamano * Vector2(0.21, 0.225)))
		assert(area.size.is_equal_approx(tamano * Vector2(0.585, 0.395)))
		for nombre in ["RecogerTodos", "Cerrar"]:
			var boton = fondo.get_node("Botones/" + nombre)
			assert(Rect2(Vector2.ZERO, tamano).encloses(boton.get_rect()))
		var grid = area.get_node("Proporcion/Contenido")
		assert(grid.get_global_rect().get_center().distance_to(area.get_global_rect().get_center()) < 2.0)
		for casilla in grid.get_children():
			assert(absf(casilla.size.x - casilla.size.y) <= 1.0)
			assert(area.get_global_rect().encloses(casilla.get_global_rect()))
	var cofre := CofreInteractuable.new()
	cofre.definicion = load("res://scenes/interactuables/cofres/cofre_pequeno.tres")
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	cofre.obtener_inventario().agregar(ItemInstancia.new(&"detalle:piedra", piedra, 3))
	panel.mostrar(cofre, Inventario.new())
	var casilla_item := panel.contenido.get_child(0) as CasillaInventario
	casilla_item.mouse_entered.emit()
	assert(panel.detalle_item.visible)
	assert(panel.detalle_nombre.text == "Piedra")
	assert(panel.detalle_cantidad.text == "Cantidad: 3")
	assert(panel.detalle_descripcion.text == piedra.descripcion_base)
	casilla_item.mouse_exited.emit()
	assert(not panel.detalle_item.visible)
	var inicio := panel.position
	var pulsacion := InputEventMouseButton.new()
	pulsacion.button_index = MOUSE_BUTTON_LEFT
	pulsacion.pressed = true
	panel._gui_input(pulsacion)
	var movimiento := InputEventMouseMotion.new()
	movimiento.relative = Vector2(40, 30)
	panel._input(movimiento)
	assert(panel.position == inicio + Vector2(40, 30))
	pulsacion.pressed = false
	panel._input(pulsacion)
	cofre.free()
	panel.free()
	print("Panel cofre: layout y detalle de item correctos.")
	quit()
