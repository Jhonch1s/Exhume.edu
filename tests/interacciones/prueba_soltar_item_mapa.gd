extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var definicion_racion := load("res://assets/items/racion/racion.tres") as DefinicionItem
	comprobar(definicion_racion != null, "Definición de ración cargada correctamente.")

	var ruta_escena := "res://scenes/pruebas_habilidades/PruebaLadron.tscn"
	var escena := (load(ruta_escena) as PackedScene).instantiate()
	root.add_child(escena)
	var escenario = escena.get_node("EscenarioBase")

	for intento in 240:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break

	var ficha: Ficha = escenario.ficha_jugador
	var panel = escenario.panel_inventario_equipo
	comprobar(ficha != null and panel != null, "Ficha y panel de inventario inicializados.")

	# Abrir el panel de inventario
	panel.abrir(ficha)
	comprobar(panel.visible, "El panel de inventario está visible.")

	# 1. Agregar item de prueba al inventario
	var item_racion := ItemInstancia.new(&"racion_drop_test", definicion_racion, 1)
	comprobar(ficha.inventario.agregar(item_racion).exitosa, "Ración agregada al inventario.")
	panel.refrescar_mochila()

	# 2. Validar reglas de drop
	var datos_drop := {
		"tipo": "item_inventario",
		"item": item_racion,
		"origen_indice": 0,
		"es_equipo": false,
		"tipo_equipo": -1
	}

	# Posición dentro de marco principal: debe rechazar
	var marco = panel.marco_principal
	var centro_marco: Vector2 = marco.get_global_rect().get_center()
	root.warp_mouse(centro_marco)
	await process_frame
	comprobar(not panel._can_drop_data(centro_marco, datos_drop), "Rechaza drop dentro de MarcoPrincipal.")

	# Posición en zona de HUD (y >= 830): debe rechazar
	var pos_hud := Vector2(centro_marco.x, 850.0)
	root.warp_mouse(pos_hud)
	await process_frame
	comprobar(not panel._can_drop_data(pos_hud, datos_drop), "Rechaza drop sobre la barra del HUD inferior.")

	# Posición fuera del marco y arriba de HUD: debe aceptar
	var pos_mapa := Vector2(100.0, 100.0)
	root.warp_mouse(pos_mapa)
	await process_frame
	comprobar(panel._can_drop_data(pos_mapa, datos_drop), "Acepta drop fuera del panel hacia el mapa.")

	# 3. Ejecutar drop hacia el mapa
	panel._drop_data(pos_mapa, datos_drop)
	await process_frame

	comprobar(ficha.inventario.obtener_por_id(&"racion_drop_test") == null, "El ítem fue retirado del inventario del jugador.")
	var item_suelo = escenario.tablero.obtener_item_suelo(&"racion_drop_test")
	comprobar(item_suelo != null, "El ítem existe como ItemSuelo en el tablero.")
	if item_suelo != null:
		var rep = item_suelo.obtener_representacion()
		comprobar(rep != null and is_instance_valid(rep), "El ítem en el suelo tiene representación visual instanciada.")

	# 4. Probar fallback visual para ítem sin escena_mundo
	var def_sin_escena := DefinicionItem.new()
	def_sin_escena.id_definicion = &"reliquia_prueba"
	def_sin_escena.nombre = "Reliquia de prueba"
	def_sin_escena.icono = definicion_racion.icono
	def_sin_escena.escena_mundo = null

	var item_reliquia := ItemInstancia.new(&"reliquia_sin_escena", def_sin_escena, 1)
	ficha.inventario.agregar(item_reliquia)
	panel.refrescar_mochila()

	var datos_reliquia := {
		"tipo": "item_inventario",
		"item": item_reliquia,
		"origen_indice": 0,
		"es_equipo": false,
		"tipo_equipo": -1
	}
	panel._drop_data(pos_mapa, datos_reliquia)
	await process_frame

	var item_suelo_reliquia = escenario.tablero.obtener_item_suelo(&"reliquia_sin_escena")
	comprobar(item_suelo_reliquia != null, "Reliquia existe en el suelo del tablero.")
	if item_suelo_reliquia != null:
		var rep_reliquia = item_suelo_reliquia.obtener_representacion()
		comprobar(rep_reliquia is RepresentacionItemSuelo, "Fallback visual crea un RepresentacionItemSuelo.")
		if rep_reliquia is RepresentacionItemSuelo:
			comprobar(rep_reliquia.get_node_or_null("Sprite2D") != null, "Fallback tiene Sprite2D asociado.")

	# 5. Probar drop desde equipamiento (es_equipo = true)
	var def_antorcha := load("res://assets/items/antorcha/antorcha.tres") as DefinicionItem
	var item_equipo := ItemInstancia.new(&"antorcha_equipada_test", def_antorcha, 1)
	ficha.equipo.ranuras[panel.RanuraEquipo.ANTORCHA] = item_equipo
	ficha.equipo.cambiado.emit()
	panel.refrescar_equipo()
	comprobar(ficha.equipo.ranuras.get(panel.RanuraEquipo.ANTORCHA) == item_equipo, "Antorcha equipada en ranura.")

	var datos_equipo_drop := {
		"tipo": "item_inventario",
		"item": item_equipo,
		"origen_indice": panel.RanuraEquipo.ANTORCHA,
		"es_equipo": true,
		"tipo_equipo": panel.RanuraEquipo.ANTORCHA
	}
	panel._drop_data(pos_mapa, datos_equipo_drop)
	await process_frame

	comprobar(ficha.equipo.ranuras.get(panel.RanuraEquipo.ANTORCHA) == null, "La ranura de equipo quedó vacía tras soltar.")
	comprobar(escenario.tablero.obtener_item_suelo(&"antorcha_equipada_test") != null, "La antorcha equipada cayó al suelo del mapa.")

	escena.queue_free()
	await process_frame

	for fallo in fallos:
		push_error(fallo)
	print("Pruebas de soltar ítems al mapa: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append("Fallo [%d]: %s" % [casos, mensaje])
