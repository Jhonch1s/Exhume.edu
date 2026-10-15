extends SceneTree


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var menu := (load("res://scenes/menu/menu_principal.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame

	var fondo := menu.get_node("FondoParallax")
	menu.call("_on_jugar_pressed")
	var termino_entrada := await _esperar_transicion(menu)

	var nueva_partida := menu.get_node("NuevaPartida")
	var entrada_correcta: bool = (
		termino_entrada and menu.mostrando_nueva_partida
		and menu.get_node("FondoParallax") == fondo
		and nueva_partida.visible
		and not menu.get_node("MenuColgante").visible
		and nueva_partida.has_node("RigIzquierdo/Encabezado")
		and nueva_partida.has_node("RigIzquierdo/Atributos")
		and nueva_partida.has_node("RigIzquierdo/Volver")
		and nueva_partida.has_node("RigCentral/Ficha")
		and nueva_partida.has_node("RigDerecho/Ritual")
		and nueva_partida.has_node("RigDerecho/ComenzarRig")
		and nueva_partida.has_node("RigCentral/Cadenas/SuperiorIzquierda")
	)

	nueva_partida.emit_signal("volver_solicitado")
	var termino_salida := await _esperar_transicion(menu)
	var correcto: bool = (
		entrada_correcta and termino_salida and not menu.mostrando_nueva_partida
		and menu.get_node("FondoParallax") == fondo
		and not nueva_partida.visible
		and is_zero_approx(menu.get_node("MenuColgante").position.y)
	)
	print("TransicionNuevaPartida: prueba correcta." if correcto else "TransicionNuevaPartida: fallo.")
	menu.queue_free()
	await process_frame
	quit(0 if correcto else 1)


func _esperar_transicion(menu: Control) -> bool:
	for _intento in range(300):
		if not menu.transicion_activa:
			return true
		await create_timer(0.02).timeout
	return false
