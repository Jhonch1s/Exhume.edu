extends SceneTree


func _init() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var zona := (load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var suelo: TileMapLayer = zona.get_node("CapaSuelo")
	var errores: Array[String] = []
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	errores.append_array(ValidadorContenidoZona.new().validar(zona, tablero, suelo))
	if errores.is_empty():
		if not tablero.registrar_interactuables_desde_zona(zona, suelo):
			errores.append("Falló el registro completo de interactuables del templo.")
		for nodo in zona.find_children("*", "", true, false):
			if nodo is Interactuable:
				if tablero.obtener_interactuable(nodo.id_instancia) != nodo:
					errores.append("Interactuable sin registrar: %s" % nodo.id_instancia)
				var visual := nodo.get_node_or_null(nodo.ruta_visual_resaltable)
				if visual == null or not nodo.is_ancestor_of(visual):
					errores.append("Visual de otra instancia: %s" % nodo.id_instancia)
		var actor := Ficha.new()
		var gestor := GestorAcciones.new()
		for id in [&"trampa_superficie_002", &"trampa_superficie_004"]:
			var placa := tablero.obtener_interactuable(id) as TrampaSuperficie
			var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.ENTRAR, actor, placa.coordenada_mapa + Vector2i.LEFT, placa.coordenada_mapa, placa)
			var resultado := gestor.procesar_accion(contexto)
			if not resultado.exitosa or placa.estado != TrampaSuperficie.Estado.ACTIVADA or &"estatua.escupe_fuego" not in resultado.mensajes:
				errores.append("No se activa la estatua desde %s: %s %s" % [id, resultado.motivo, resultado.mensajes])
		gestor.free()
		actor.free()
	for datos in [
		["CofreInteractuable2", {"pocion_1": 1, "bomba_humo": 1, "antorcha": 2}],
		["CofreInteractuable3", {"piedra": 3, "pocion_1": 1}],
		["CofreInteractuable4", {"antorcha": 3}],
		["CofreInteractuable7", {"racion": 3}],
		["CofreInteractuable6", {"pocion_1": 2, "bomba_humo": 2}],
	]:
		var cofre := zona.get_node("Interactuables/Cofres/" + datos[0]) as CofreInteractuable
		var contenido := {}
		for item in cofre.inventario.obtener_contenido():
			contenido[String(item.definicion.id_definicion)] = item.cantidad
		if contenido != datos[1]:
			errores.append("Contenido inesperado en %s: %s" % [datos[0], contenido])
	var nota := zona.get_node("Interactuables/Guias/NotaTrasEstatua") as HojasInteractuable
	var celda_nota := suelo.local_to_map(suelo.to_local(nota.global_position))
	if suelo.get_cell_source_id(celda_nota) < 0 or not nota.permite_caminar_interactuable():
		errores.append("La nota debe estar sobre suelo y permitir el paso.")
	var catalogo := load("res://assets/interactuables/mensajes_interacciones.tres") as CatalogoMensajesInteraccion
	if not catalogo.mensajes.has(&"examen.templo.nota_estatua.detalle"):
		errores.append("Falta el texto de la pista de la estatua.")
	var solida: TileMapLayer = zona.get_node("CapaDecoracionNoCaminable")
	var decoracion: TileMapLayer = zona.get_node("CapaDecoracion")
	if solida.tile_set.resource_path != "res://assets/tile_sets/decorations/cave_decorations_solid.tres" or decoracion.tile_set.resource_path != "res://assets/tile_sets/decorations/cave_decorations_walkable.tres":
		errores.append("El templo debe usar los TileSets de decoración de Prisión.")
	var anterior := load("res://assets/tile_sets/decorations/rocks_medium.tres") as TileSet
	for celda in decoracion.get_used_cells():
		var id := decoracion.get_cell_source_id(celda)
		var nueva := decoracion.tile_set.get_source(id) as TileSetAtlasSource
		var atlas := decoracion.get_cell_atlas_coords(celda)
		if nueva == null or not nueva.has_tile(atlas):
			errores.append("Decoración alterada en %s." % celda)
	for id in range(1, 5):
		var vieja := anterior.get_source(id - 1) as TileSetAtlasSource
		var nueva := decoracion.tile_set.get_source(id) as TileSetAtlasSource
		if vieja.texture != nueva.texture:
			errores.append("La fuente %d ya no corresponde a la decoración original." % id)
	for trigger: TriggerMapa in zona.get_node("Triggers/Dialogos").get_children():
		for error: String in trigger.validar_configuracion(suelo):
			errores.append("%s: %s" % [trigger.name, error])
	var celdas: Array[Vector2i] = []
	var trampas := zona.get_node("Interactuables/Trampas")
	var placa_1 := trampas.get_node("TrampaSuperficie11") as TrampaSuperficie
	var placa_2 := trampas.get_node("TrampaSuperficie12") as TrampaSuperficie
	var placa_3 := trampas.get_node("TrampaSuperficie13") as TrampaSuperficie
	var placa_4 := trampas.get_node("TrampaSuperficie14") as TrampaSuperficie
	if placa_1.escena_superficie != null or placa_1.ids_receptores_mecanismo.size() != 4:
		errores.append("La placa 001 debe controlar las cuatro paredes móviles.")
	if placa_2.ids_receptores_mecanismo != [&"estatua_templo_001"] or placa_4.ids_receptores_mecanismo != [&"estatua_templo_003"]:
		errores.append("Las placas deben apuntar a sus estatuas correspondientes.")
	if not placa_3.placa_senuelo or placa_3.escena_superficie != null or not placa_3.ids_receptores_mecanismo.is_empty():
		errores.append("La placa señuelo no debe tener efectos ni receptores.")
	for nombre in ["SirvienteEekTemplo1", "SirvienteEekTemplo2"]:
		var npc: Node2D = zona.get_node("Interactuables/Personajes/" + nombre)
		var celda := suelo.local_to_map(suelo.to_local(npc.global_position))
		if suelo.get_cell_source_id(celda) < 0 or celda in celdas:
			errores.append("Enemigo sin suelo o superpuesto: %s (%s)" % [nombre, celda])
		for capa in ["CapaParedes", "CapaColumnas", "CapaDecoracionNoCaminable", "CapaPinchos"]:
			if (zona.get_node(capa) as TileMapLayer).get_cell_source_id(celda) >= 0:
				errores.append("Enemigo sobre %s: %s (%s)" % [capa, nombre, celda])
		celdas.append(celda)
	for error in errores:
		push_error(error)
	print("Contenido del templo: %d errores; enemigos en %s" % [errores.size(), celdas])
	zona.queue_free()
	tablero.free()
	quit(0 if errores.is_empty() else 1)
