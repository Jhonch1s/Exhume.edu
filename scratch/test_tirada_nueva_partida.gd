extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/menu/menu_principal.tscn")
	var menu: Control = escena.instantiate()
	root.add_child(menu)
	await process_frame
	
	menu.call("_on_jugar_pressed")
	while menu.transicion_activa:
		await process_frame
		
	var nueva_partida: Control = menu.get_node("NuevaPartida")
	
	# Simular tirada con valores prefijados: Fuerza=5, Destreza=3, Voluntad=2 -> Guerrero
	nueva_partida.atributos.assign({&"fuerza": 5, &"destreza": 3, &"voluntad": 2})
	nueva_partida.valores[&"fuerza"].text = "5"
	nueva_partida.valores[&"destreza"].text = "3"
	nueva_partida.valores[&"voluntad"].text = "2"
	nueva_partida.botones_tirada[&"fuerza"].disabled = true
	nueva_partida.botones_tirada[&"destreza"].disabled = true
	nueva_partida.botones_tirada[&"voluntad"].disabled = true
	nueva_partida.estado_atributos.text = "3 de 3 atributos resueltos"
	nueva_partida.resolver_clase()
	
	# Asignar nombre y título
	nueva_partida.nombre.text = "Valerius"
	nueva_partida.titulo_aventurero.text = "el Inquebrantable"
	
	# Sortear origen
	await nueva_partida._sortear_origen()
	
	# Esperar a que la animación de revelado del retrato termine
	for i in range(75):
		await process_frame
		
	var img: Image = root.get_texture().get_image()
	img.save_png("res://scratch/captura_nueva_partida_revelada.png")
	print("Captura con héroe revelado guardada en res://scratch/captura_nueva_partida_revelada.png")
	quit(0)
