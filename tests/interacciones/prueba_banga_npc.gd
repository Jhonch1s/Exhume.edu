extends SceneTree


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_probar_banga("res://scenes/personajes/banga_npc.tscn", "banga_real_4_direcciones.png")
	_probar_banga("res://scenes/personajes/banga_npc_v2.tscn", "banga_real_4_direcciones.png")
	_probar_danio_bangas()
	print("BangaNPC: ambas escenas, nombre, sprite, registro y examen correctos.")
	quit()


func _probar_banga(ruta: String, textura: String) -> void:
	var zona := (load("res://scenes/ZonaPlantilla/zona_plantilla.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var suelo := zona.get_node("CapaSuelo") as TileMapLayer
	suelo.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)
	zona.get_node("PuntosSpawn/PuntoSpawnEntrada").position = suelo.map_to_local(Vector2i.ZERO)
	var banga := (load(ruta) as PackedScene).instantiate() as PersonajeNPC
	banga.id_instancia = &"banga_prueba_001"
	banga.nombre_unico = "Prueba"
	zona.get_node("Interactuables/Personajes").add_child(banga)
	assert(banga.ajustar_a_celda_en_editor)
	var centro := suelo.map_to_local(Vector2i.ZERO)
	banga.position = centro + Vector2(3, 2)
	banga._ajustar_al_centro_celda()
	assert(banga.position.is_equal_approx(centro))
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	var errores := ValidadorContenidoZona.new().validar(zona, tablero, suelo)
	if not errores.is_empty():
		push_error("Contenido inválido: %s" % [errores])
		quit(1)
		return
	tablero.registrar_interactuables_desde_zona(zona, suelo)
	assert(tablero.obtener_interactuable(&"banga_prueba_001") == banga)
	assert(banga.obtener_nombre_interaccion() == "Prueba")
	assert(banga.obtener_definicion_personaje().es_valida())
	assert(banga.sprite_personaje.texture != null)
	assert(banga.sprite_personaje.texture.resource_path.ends_with(textura))
	assert(banga.sprite_personaje.hframes == 2 and banga.sprite_personaje.vframes == 2)
	assert(banga.sprite_personaje.texture.get_size() == Vector2(1024, 1024))
	assert(banga.sprite_personaje.scale.is_equal_approx(Vector2(0.12, 0.12)))
	assert(banga.obtener_opciones_accion().any(func(opcion): return opcion.id == &"examinar"))
	assert(banga.vida_actual == 10)
	zona.free()
	tablero.free()


func _probar_danio_bangas() -> void:
	var npc := (load("res://scenes/personajes/banga_npc.tscn") as PackedScene).instantiate() as PersonajeNPC
	for ruta in ["res://recursos/personajes/banga.tres", "res://recursos/personajes/banga_v2.tres", "res://recursos/prision/guardia_peeble.tres", "res://recursos/prision/guardia_roffa.tres"]:
		npc.definicion = load(ruta)
		var terminos := EfectosEquipo.terminos_dano_armas(npc)
		assert(terminos.size() == 1 and terminos[0].cantidad == 1 and terminos[0].caras == 6)
		assert(EfectosEquipo.bono_fuerza_dano(npc) == 1)
		assert(npc.obtener_definicion_personaje().bono_dano_ataque == (2 if "guardia_" in ruta else 0))
	var defensor := (load("res://scenes/personajes/banga_npc.tscn") as PackedScene).instantiate() as PersonajeNPC
	var rng := RandomNumberGenerator.new()
	for semilla in 20000:
		rng.seed = semilla
		if rng.randi_range(1, 6) == 1 and rng.randi_range(1, 6) == 6 and rng.randi_range(1, 6) == 6:
			rng.seed = semilla
			break
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, npc, null, null, defensor, null, &"ataque_basico")
	var resultado := ResolverAtaqueBasico.resolver(contexto, defensor, MotorDados.new(rng), AplicadorEfectos.new())
	assert(resultado.tirada_dano != null and resultado.tirada_dano.total_efectivo == 6)
	assert(defensor.vida_actual == 1)
	defensor.free()
	npc.definicion = load("res://recursos/personajes/goblin_unico.tres")
	assert(EfectosEquipo.terminos_dano_armas(npc)[0].caras == 2)
	npc.free()
