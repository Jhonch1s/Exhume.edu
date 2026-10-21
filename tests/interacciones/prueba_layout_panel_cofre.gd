extends SceneTree

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	var panel := (load("res://scenes/ui/inventario/panel_inventario_cofre.tscn") as PackedScene).instantiate() as PanelInventarioCofre
	root.add_child(panel)
	var cofre := (load("res://scenes/interactuables/cofres/cofre_interactuable.tscn") as PackedScene).instantiate() as CofreInteractuable
	root.add_child(cofre)
	cofre.coordenada_mapa = Vector2i(1, 0)
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	assert(cofre.obtener_inventario().agregar(ItemInstancia.new(&"detalle:piedra", piedra, 3)).exitosa)
	assert(cofre.obtener_inventario().agregar(ItemInstancia.new(&"detalle:segunda", piedra, 1)).exitosa)
	var ficha := Ficha.new()
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		ficha,
		Vector2i.ZERO,
		cofre.coordenada_mapa,
		cofre,
		null,
		&"abrir_cofre"
	)
	assert(cofre.resolver_accion(contexto).exitosa and cofre.abierto)
	var destino := ficha.obtener_inventario()
	destino.capacidad = 1
	panel.mostrar(cofre, destino)
	var capacidad := (cofre.definicion as DefinicionCofre).columnas * (cofre.definicion as DefinicionCofre).filas
	assert(panel.visible)
	assert(panel.contenido.get_child_count() == capacidad)
	assert(not (panel.contenido.get_child(0) as CasillaInventario).disabled)
	assert(not (panel.contenido.get_child(1) as CasillaInventario).disabled)
	var fondo = panel.get_node("Fondo")
	for solicitado in [Vector2(300, 300), Vector2(600, 600), Vector2(900, 700), Vector2(900, 200)]:
		fondo.size = solicitado
		var tamano: Vector2 = fondo.size
		assert(tamano == solicitado.max(Vector2(300, 300)))
		await process_frame
		await process_frame
		var area = fondo.get_node("AreaItems")
		assert(area.position.is_equal_approx(tamano * Vector2(0.21, 0.225)))
		assert(area.size.is_equal_approx(tamano * Vector2(0.585, 0.395)))
		for nombre in ["RecogerTodos", "Cerrar"]:
			var boton = fondo.get_node("Botones/" + nombre)
			if not Rect2(Vector2.ZERO, tamano).encloses(boton.get_rect()):
				push_error("Botón %s fuera del fondo %s: %s" % [nombre, tamano, boton.get_rect()])
				quit(1)
				return
		var grid = area.get_node("Proporcion/Contenido")
		assert(grid.get_child_count() == capacidad)
		assert(grid.get_global_rect().get_center().distance_to(area.get_global_rect().get_center()) < 2.0)
		for casilla in grid.get_children():
			assert(absf(casilla.size.x - casilla.size.y) <= 1.0)
			assert(area.get_global_rect().encloses(casilla.get_global_rect()))
	var casilla_item := panel.contenido.get_child(0) as CasillaInventario
	casilla_item.mouse_entered.emit()
	assert(panel.detalle_item.visible)
	assert(panel.detalle_nombre.text == "Piedra")
	assert(panel.detalle_cantidad.text == "Cantidad: 3")
	assert(panel.detalle_descripcion.text == piedra.descripcion_base)
	casilla_item.mouse_exited.emit()
	assert(not panel.detalle_item.visible)
	var recoger_todos := fondo.get_node("Botones/RecogerTodos") as Button
	recoger_todos.pressed.emit()
	assert(destino.obtener_contenido().size() == 1)
	assert(cofre.obtener_inventario().obtener_contenido().size() == 1)
	assert(panel.visible and panel.contenido.get_child_count() == capacidad)
	assert(not recoger_todos.disabled)
	destino.capacidad = 2
	var casilla_restante := panel.contenido.get_child(0) as CasillaInventario
	assert(casilla_restante.item != null)
	casilla_restante.pressed.emit()
	assert(cofre.obtener_inventario().obtener_contenido().is_empty())
	assert(destino.obtener_contenido().size() == 2)
	assert(recoger_todos.disabled)
	assert((panel.contenido.get_child(0) as CasillaInventario).disabled)
	assert(cofre.abierto)
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
	(fondo.get_node("Botones/Cerrar") as Button).pressed.emit()
	assert(not panel.visible and panel.cofre == null and panel.inventario_destino == null)
	ficha.free()
	cofre.queue_free()
	panel.free()
	print("Panel cofre: apertura, casillas, recogida parcial y total, cierre y layout correctos.")
	quit()
