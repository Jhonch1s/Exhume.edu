extends SceneTree


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var escena: Node2D = load("res://tests/interacciones/escena_guardian.tscn").instantiate()
	var escenario: Node2D = escena.get_node("Escenario")
	var catalogo: CatalogoMensajesInteraccion = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.catalogo_mensajes = catalogo
	root.add_child(escena)
	for intento in 300:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 1:
			break
	if escena.get("_enemigos").size() != 1:
		push_error("No se pudo preparar el Guardián.")
		quit(1)
		return
	var guardian: PersonajeNPC = escena.get("_enemigos")[0]
	var ficha: Ficha = escenario.ficha_jugador
	var tablero: TableroGrid = escenario.tablero
	var capa: TileMapLayer = tablero.capa_referencia
	var ancla := Vector2i(100, 100)
	for x in range(98, 104):
		for y in range(98, 104):
			tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	var correcto := tablero.reubicar_interactuable(guardian, ancla)
	guardian.actualizar_posicion_visual()
	var casos := 0
	var opcion: OpcionAccion
	for candidata in guardian.obtener_opciones_accion(ficha):
		if candidata.id == &"ataque_basico":
			opcion = candidata
	for desplazamiento in [Vector2i.LEFT, Vector2i.UP, Vector2i(2, 1), Vector2i(1, 2)]:
		tablero.liberar_celda(ficha.coordenada_mapa, ficha)
		ficha.inicializar(ancla + desplazamiento, capa)
		tablero.ocupar_celda(ficha.coordenada_mapa, ficha)
		for celda in guardian.obtener_coordenadas_ocupadas():
			var punto := capa.to_global(capa.map_to_local(celda))
			var seleccionada: bool = escenario._solicitar_interaccion_en_celda(celda, punto)
			var destino: Variant = escenario.celda_seleccionada
			var contexto: Variant = escenario.constructor_contexto_accion.construir_desde_opcion(opcion, ficha, ficha.coordenada_mapa, destino)
			var valido: bool = seleccionada and escenario.objetivo_seleccionado == guardian and contexto is ContextoAccion
			valido = valido and escenario.gestor_acciones.esta_en_alcance(contexto) and guardian.validar_accion(contexto) == &""
			if not valido:
				push_error("No se puede atacar desde %s pulsando %s; destino %s" % [ficha.coordenada_mapa, celda, destino])
			correcto = correcto and valido
			casos += 1
		# La elección entre varios objetivos tampoco debe restaurar el ancla.
		escenario.estado_seleccion_objetivos.iniciar(ancla, [guardian, ficha])
		correcto = correcto and escenario.seleccionar_objetivo_interaccion(guardian)
		correcto = correcto and escenario.celda_seleccionada == guardian.obtener_celda_mas_cercana(ficha.coordenada_mapa)
	print("SeleccionGuardian: %s (%d clics desde los cuatro lados)" % ["correcto" if correcto else "fallo", casos])
	escena.queue_free()
	await process_frame
	quit(0 if correcto else 1)
