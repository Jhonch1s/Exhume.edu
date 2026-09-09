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
	panel.free()
	print("Panel cofre: celdas cuadradas y centradas en cuatro tamaños, incluido 900x200.")
	quit()