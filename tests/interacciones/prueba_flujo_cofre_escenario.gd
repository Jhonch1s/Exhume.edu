extends SceneTree

var _fallos: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escena := (load("res://tests/interacciones/escena_facciones_npc.tscn") as PackedScene).instantiate()
	var escenario = escena.get_node("Escenario")
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(escena)
	for intento in 200:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 5:
			break
	escena.set_process(false)
	escenario.set_process(false)
	if escena.get("_enemigos").size() != 5:
		_comprobar(false, "Debe iniciar el escenario de prueba.")
		_finalizar(escena)
		return

	var cofre := (load("res://scenes/interactuables/cofres/cofre_interactuable.tscn") as PackedScene).instantiate() as CofreInteractuable
	escenario.add_child(cofre)
	cofre.coordenada_mapa = escenario.ficha_jugador.coordenada_mapa + Vector2i.RIGHT
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	_comprobar(cofre.obtener_inventario().agregar(ItemInstancia.new(&"flujo:cofre:piedra", piedra, 2)).exitosa, "Preparar contenido del cofre.")
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		escenario.ficha_jugador,
		escenario.ficha_jugador.coordenada_mapa,
		cofre.coordenada_mapa,
		cofre,
		null,
		&"abrir_cofre"
	)
	var resultado := cofre.resolver_accion(contexto)
	_comprobar(resultado.exitosa and cofre.abierto, "La acción abre el cofre.")
	escenario._presentar_resultado_contextual("Cofre", resultado, contexto)
	var panel: PanelInventarioCofre = escenario.panel_inventario_cofre
	_comprobar(panel.visible and escenario.interaccion_modal_activa, "Abrir muestra el panel como modal real.")
	_comprobar(escenario._camara_bloqueada(), "El panel suspende la cámara.")
	_comprobar(panel.contenido.get_child_count() == 4, "El panel crea las cuatro casillas reales.")
	(panel.fondo.get_node("Botones/RecogerTodos") as Button).pressed.emit()
	_comprobar(cofre.obtener_inventario().obtener_contenido().is_empty(), "Recoger todo vacía el cofre.")
	_comprobar(escenario.ficha_jugador.obtener_inventario().obtener_por_id(&"flujo:cofre:piedra") != null, "Recoger todo entrega el item a la ficha.")
	var soltar := InputEventKey.new()
	soltar.keycode = KEY_G
	soltar.pressed = true
	escenario._unhandled_input(soltar)
	_comprobar(
		escenario.ficha_jugador.obtener_inventario().obtener_por_id(&"flujo:cofre:piedra") != null,
		"El modal impide soltar el item mientras el panel está abierto."
	)
	(panel.fondo.get_node("Botones/Cerrar") as Button).pressed.emit()
	_comprobar(not panel.visible and not escenario.interaccion_modal_activa, "Cerrar libera el bloqueo modal.")
	_finalizar(escena)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar(escena: Node) -> void:
	for fallo in _fallos:
		push_error(fallo)
	print("FlujoCofreEscenario: %d fallos." % _fallos.size())
	escena.queue_free()
	quit(0 if _fallos.is_empty() else 1)
