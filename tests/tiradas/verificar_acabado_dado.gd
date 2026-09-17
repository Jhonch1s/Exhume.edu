extends SceneTree

const OUTPUT := "res://tests/tiradas/capturas_dadico/"

func _initialize() -> void:
	call_deferred("_verificar")

func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + nombre + ".png")

func _verificar() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	FileAccess.open(OUTPUT + ".gdignore", FileAccess.WRITE).close()
	root.size = Vector2i(1920, 1080)
	var fondo := ColorRect.new()
	fondo.color = Color("171b20")
	fondo.size = Vector2(1920, 1080)
	root.add_child(fondo)
	var vistas: Array[Node] = []
	for valor in range(1, 7):
		var vista = load("res://scenes/ui/interacciones/vista_dado_3d.tscn").instantiate()
		vista.custom_minimum_size = Vector2(480, 480)
		vista.size = Vector2(480, 480)
		vista.position = Vector2(240 + ((valor - 1) % 3) * 480, ((valor - 1) / 3) * 520)
		root.add_child(vista)
		vista.mostrar_valor(valor)
		assert(vista.get_node("SubViewport").own_world_3d)
		vistas.append(vista)
		var label := Label.new()
		label.text = "Cara %d" % valor
		label.position = vista.position + Vector2(200, 450)
		fondo.add_child(label)
	await create_timer(1.0).timeout
	await _capturar("seis_caras")
	for vista in vistas: vista.grosor_contorno = 0
	await create_timer(0.15).timeout
	await _capturar("seis_caras_sin_contorno")
	for vista in vistas: vista.grosor_contorno = 1
	assert(vistas[0].material != vistas[1].material)
	await create_timer(0.15).timeout
	await _capturar("seis_caras_contorno")
	# Comparar ambos acabados con exactamente las mismas caras y encuadre.
	for vista in vistas: vista.tamano_pixel = 1
	await create_timer(0.15).timeout
	await _capturar("seis_caras_sin_filtro")
	for vista in vistas:
		vista.tamano_pixel = 3
		assert(vista.stretch_shrink == 3)
		assert(vista.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	await create_timer(0.15).timeout
	await _capturar("seis_caras_pixelado")
	for vista in vistas: vista.queue_free()
	fondo.queue_free()
	await process_frame
	var demo = load("res://tests/tiradas/demo_modal_dados.tscn").instantiate()
	root.add_child(demo)
	demo._lanzar_prueba()
	var a = demo.panel.vista_dado_1.get_node("SubViewport")
	var b = demo.panel.vista_dado_2.get_node("SubViewport")
	assert(a.own_world_3d and b.own_world_3d and a.find_world_3d() != b.find_world_3d())
	assert(demo.panel.vista_dado_2.visible)
	await create_timer(0.25).timeout
	await _capturar("dos_dados_giro")
	await create_timer(1.5).timeout
	await _capturar("dos_dados_resultado")
	print("DADICO_QA_OK: seis caras y dos mundos independientes; ", demo.panel.etiqueta_mensajes.text)
	var sin_modificadores: Array[StringName] = []
	var prueba_simple = demo.motor.resolver_prueba(3, sin_modificadores, sin_modificadores,
		TiposTirada.Origen.SOLICITADA, TiposTirada.Presentacion.PRIMER_PLANO)
	demo.panel.mostrar_tirada("Prueba de Percepción", prueba_simple)
	await create_timer(1.5).timeout
	assert(not demo.panel.vista_dado_2.visible)
	await _capturar("un_dado_resultado")
	quit()

