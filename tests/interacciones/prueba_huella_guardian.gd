extends SceneTree


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var tablero := TableroGrid.new()
	var buscador := PathFindingManager.new()
	root.add_child(tablero)
	root.add_child(buscador)
	for x in range(7):
		for y in range(5):
			tablero.datos[Vector2i(x, y)] = Celda.new()
	var guardian := (load("res://scenes/personajes/guardian.tscn") as PackedScene).instantiate() as PersonajeNPC
	guardian.id_instancia = &"guardian_huella"
	root.add_child(guardian)
	for par in [[Vector2i.RIGHT, 0], [Vector2i.DOWN, 1], [Vector2i.LEFT, 2], [Vector2i.UP, 3]]:
		guardian.orientar_paso_movimiento(Vector2i.ZERO, par[0])
		if guardian.sprite_personaje.frame != par[1]:
			push_error("Orientación incorrecta para %s" % str(par[0]))
			quit(1)
			return
	var correcto := tablero.registrar_interactuable(Vector2i(1, 1), guardian)
	correcto = correcto and guardian.obtener_coordenadas_ocupadas().size() == 4
	for celda in guardian.obtener_coordenadas_ocupadas():
		correcto = correcto and guardian in tablero.datos[celda].interactuables and not tablero.puede_entrar(celda)
	buscador.inicializar(tablero.datos)
	var ruta := buscador.calcular_camino(Vector2i(1, 1), Vector2i(4, 1), tablero.datos, guardian)
	correcto = correcto and ruta.size() > 1
	correcto = correcto and tablero.reservar_celda(Vector2i(2, 1), guardian)
	for celda in guardian.obtener_coordenadas_ocupadas(Vector2i(2, 1)):
		correcto = correcto and guardian in tablero.datos[celda].reservas
	correcto = correcto and tablero.confirmar_movimiento(Vector2i(1, 1), Vector2i(2, 1), guardian)
	correcto = correcto and guardian not in tablero.datos[Vector2i(1, 1)].interactuables
	correcto = correcto and guardian in tablero.datos[Vector2i(3, 2)].interactuables
	tablero.datos[Vector2i(4, 2)].caminable = false
	correcto = correcto and not tablero.puede_entrar(Vector2i(3, 1), guardian)
	correcto = correcto and not tablero.reservar_celda(Vector2i(3, 1), guardian)
	correcto = correcto and not tablero.puede_entrar(Vector2i(6, 1), guardian)
	for celda in [Vector2i(1, 1), Vector2i(2, 0), Vector2i(4, 1), Vector2i(3, 3)]:
		var borde := guardian.obtener_celda_mas_cercana(celda)
		correcto = correcto and absi(celda.x - borde.x) + absi(celda.y - borde.y) == 1
	var blanco := PersonajeNPC.new()
	blanco.definicion = guardian.definicion
	blanco.id_instancia = &"blanco_huella"
	root.add_child(blanco)
	var rondas := GestorRondas.new(ServicioTurnos.new(GestorAcciones.new()))
	rondas.iniciar([guardian, blanco])
	rondas.bandos[guardian.id_instancia] = GestorRondas.Bando.OPONENTE
	rondas.bandos[blanco.id_instancia] = GestorRondas.Bando.JUGADOR
	guardian.iniciar_turno()
	for celda in [Vector2i(1, 1), Vector2i(2, 0), Vector2i(4, 1), Vector2i(3, 3)]:
		blanco.coordenada_mapa = celda
		var ataque := AccionPicotazoGuardian.new(blanco, rondas)
		var contexto := ataque.construir_contexto(guardian)
		correcto = correcto and guardian.ocupa_coordenada(contexto.origen) and absi(contexto.origen.x - celda.x) + absi(contexto.origen.y - celda.y) == 1
		correcto = correcto and ataque.validar_accion(contexto) == &""
	for y in range(5):
		tablero.datos[Vector2i(4, y)].caminable = y == 1
	correcto = correcto and buscador.calcular_camino(Vector2i(2, 1), Vector2i(5, 1), tablero.datos, guardian).is_empty()
	tablero.retirar_interactuable(guardian)
	for celda in guardian.obtener_coordenadas_ocupadas():
		correcto = correcto and guardian not in tablero.datos[celda].interactuables
	print("HuellaGuardian: ", "correcto" if correcto else "fallo")
	guardian.queue_free()
	blanco.queue_free()
	tablero.queue_free()
	buscador.queue_free()
	await process_frame
	quit(0 if correcto else 1)
