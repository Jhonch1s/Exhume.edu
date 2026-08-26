extends SceneTree


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var menu := (load("res://scenes/menu/menu_principal.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame

	var fondo := menu.get_node("FondoParallax")
	menu.call("_on_jugar_pressed")
	await create_timer(0.8).timeout

	var nueva_partida := menu.get_node("NuevaPartida")
	var entrada_correcta: bool = (
		menu.get_node("FondoParallax") == fondo
		and nueva_partida.visible
		and is_zero_approx(nueva_partida.position.y)
		and menu.get_node("MenuColgante").position.y <= -1080.0
		and nueva_partida.has_node("RigIzquierdo/Encabezado")
		and nueva_partida.has_node("RigIzquierdo/Atributos")
		and nueva_partida.has_node("RigIzquierdo/Volver")
		and nueva_partida.has_node("RigCentral/Ficha")
		and nueva_partida.has_node("RigDerecho/Ritual")
		and nueva_partida.has_node("RigDerecho/ComenzarRig")
		and nueva_partida.has_node("RigCentral/Cadenas/SuperiorIzquierda")
	)

	nueva_partida.emit_signal("volver_solicitado")
	await create_timer(0.8).timeout
	var correcto: bool = (
		entrada_correcta
		and menu.get_node("FondoParallax") == fondo
		and not nueva_partida.visible
		and is_zero_approx(menu.get_node("MenuColgante").position.y)
	)
	print("TransicionNuevaPartida: prueba correcta." if correcto else "TransicionNuevaPartida: fallo.")
	quit(0 if correcto else 1)
