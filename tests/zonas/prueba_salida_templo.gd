extends SceneTree


func _init() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var texturas: Array[Texture2D] = []
	for nombre in ["icono", "ilustracion", "suelo"]:
		var ruta := "res://assets/items/anillo_impacto/%s.png" % nombre
		var textura := ImageTexture.create_from_image(Image.load_from_file(ruta))
		textura.take_over_path(ruta)
		texturas.append(textura)
	var templo := (load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn") as PackedScene).instantiate()
	root.add_child(templo)
	var salida := templo.get_node("Triggers/Viajes/SalidaASalonDeCombate") as TriggerMapa
	var viaje := salida.accion as AccionTriggerViajar
	assert(viaje.validar_configuracion().is_empty())
	assert(viaje.obtener_ruta_destino() == "res://scenes/CombateSalidaTemplo/combate_salida_templo.tscn")
	assert(viaje.id_spawn_destino == &"entrada")
	var salida_prision := templo.get_node("Triggers/Viajes/VueltaPrision") as TriggerMapa
	assert((salida_prision.accion as AccionTriggerViajar).id_spawn_destino == &"entrada_prision")
	var zona := (load("res://scenes/CombateSalidaTemplo/combate_salida_templo.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var suelo: TileMapLayer = zona.get_node("CapaSuelo")
	var cofre := zona.get_node("Interactuables/Cofres/CofreInteractuable") as CofreInteractuable
	assert(cofre.inventario.obtener_contenido().size() == 1)
	assert(cofre.inventario.obtener_contenido()[0].definicion.id_definicion == &"anillo_impacto")
	var spawn := zona.get_node("PuntosSpawn/PuntoSpawnEntrada") as PuntoSpawnZona
	assert(spawn.id_spawn == viaje.id_spawn_destino and suelo.get_cell_source_id(spawn.obtener_coordenada(suelo)) >= 0)
	var regreso := zona.get_node("Triggers/Viajes/vuelta_prision") as TriggerMapa
	var viaje_regreso := regreso.accion as AccionTriggerViajar
	assert(viaje_regreso != null and viaje_regreso.validar_configuracion().is_empty())
	assert(viaje_regreso.obtener_ruta_destino() == "res://scenes/Prision/prision.tscn")
	var prision := (load(viaje_regreso.obtener_ruta_destino()) as PackedScene).instantiate()
	var entrada3 := prision.get_node("PuntosSpawn/PuntoSpawnEntrada3") as PuntoSpawnZona
	assert(viaje_regreso.id_spawn_destino == entrada3.id_spawn)
	assert(ViajeEntreZonas.new()._validar_destino(prision, entrada3.id_spawn) == &"")
	prision.free()
	templo.free()
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	assert(ValidadorContenidoZona.new().validar(zona, tablero, suelo).is_empty())
	assert(tablero.registrar_interactuables_desde_zona(zona, suelo))
	for trigger: TriggerMapa in zona.get_node("Triggers/Dialogos").get_children():
		assert(trigger.validar_configuracion(suelo, tablero).is_empty())
	var actor := Ficha.new()
	var gestor := GestorAcciones.new()
	for indice in [1, 2]:
		var placa := tablero.obtener_interactuable(StringName("salida_placa_%03d" % indice)) as TrampaSuperficie
		var estatua := tablero.obtener_interactuable(StringName("salida_estatua_%03d" % indice)) as EstatuaMecanismo
		var celdas := estatua._obtener_celdas_fuego()
		assert(not celdas.is_empty())
		if indice == 2:
			assert(Vector2i(-3, 1) in celdas)
		var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.ENTRAR, actor, placa.coordenada_mapa + Vector2i.RIGHT, placa.coordenada_mapa, placa)
		var resultado := gestor.procesar_accion(contexto)
		assert(resultado.exitosa and &"estatua.escupe_fuego" in resultado.mensajes)
		assert(placa.estado == TrampaSuperficie.Estado.ACTIVADA)
	gestor.free()
	actor.free()
	zona.free()
	tablero.free()
	print("SalidaTemplo: diálogos y trampas válidos.")
	quit()
