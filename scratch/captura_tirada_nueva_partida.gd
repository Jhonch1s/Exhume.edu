extends SceneTree

func _init() -> void:
	call_deferred(&'_ejecutar')

func _ejecutar() -> void:
	var escena: PackedScene = load('res://scenes/menu/menu_principal.tscn')
	var menu: Control = escena.instantiate()
	root.add_child(menu)
	await process_frame
	
	# Llamar a entrar a nueva partida
	menu.call('_on_jugar_pressed')
	
	# Esperar a que la transición termine
	while menu.transicion_activa:
		await process_frame
		
	for i in range(40):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png('res://scratch/captura_nueva_partida_dado_reposo.png')
	print('Captura reposo guardada')
	
	# Buscar la instancia de NuevaPartida
	var nueva_partida = menu.get_node_or_null('NuevaPartida')
	if nueva_partida:
		# Ejecutar tirada de fuerza
		var boton_fuerza = nueva_partida.botones_tirada[&'fuerza']
		boton_fuerza.emit_signal('pressed')
		
		# Esperar a que termine la animacion de la tirada
		await nueva_partida.vista_dado.animacion_finalizada
		for i in range(30):
			await process_frame
			
		var img_tirada: Image = root.get_texture().get_image()
		img_tirada.save_png('res://scratch/captura_nueva_partida_dado_tirada.png')
		print('Captura tirada guardada')
		
	quit(0)
