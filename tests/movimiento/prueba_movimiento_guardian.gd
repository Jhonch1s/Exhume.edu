extends SceneTree

var tablero := TableroGrid.new()
var guardian: PersonajeNPC


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var capa := TileMapLayer.new()
	capa.tile_set = load("res://assets/tile_sets/terrain/cave_terrain.tres")
	root.add_child(capa)
	root.add_child(tablero)
	tablero.capa_referencia = capa
	for x in range(5):
		for y in range(5):
			tablero.datos[Vector2i(x, y)] = Celda.new()
	guardian = load("res://scenes/personajes/guardian.tscn").instantiate()
	guardian.id_instancia = &"guardian_movimiento"
	root.add_child(guardian)
	tablero.registrar_interactuable(Vector2i.ZERO, guardian)
	guardian.actualizar_posicion_visual()
	guardian.iniciar_turno()
	var ruta: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]
	guardian.mover_por_camino(ruta, _preparar, _confirmar, _cancelar, Callable(), Callable(), Callable())
	var anterior := guardian.global_position
	var salto_maximo := 0.0
	var muestras_intermedias := 0
	while guardian.esta_moviendose:
		await process_frame
		salto_maximo = maxf(salto_maximo, guardian.global_position.distance_to(anterior))
		anterior = guardian.global_position
		if ruta.all(func(c): return anterior.distance_to(capa.map_to_local(c)) > 1.0):
			muestras_intermedias += 1
	var correcto: bool = guardian.coordenada_mapa == ruta.back() and guardian.movimiento.pasos_completados == 4
	correcto = correcto and muestras_intermedias > 4 and salto_maximo < 20.0
	correcto = correcto and guardian.global_position.is_equal_approx(capa.map_to_local(ruta.back()))
	print("MovimientoGuardian: %s (salto máximo %.2f px, %d muestras intermedias)" % ["correcto" if correcto else "fallo", salto_maximo, muestras_intermedias])
	tablero.retirar_interactuable(guardian)
	guardian.queue_free()
	tablero.queue_free()
	capa.queue_free()
	await process_frame
	quit(0 if correcto else 1)


func _preparar(_origen: Vector2i, destino: Vector2i, actor: Node2D) -> bool:
	return tablero.reservar_celda(destino, actor)


func _confirmar(origen: Vector2i, destino: Vector2i, actor: Node2D) -> bool:
	return tablero.confirmar_movimiento(origen, destino, actor)


func _cancelar(destino: Vector2i, actor: Node2D) -> void:
	tablero.cancelar_reserva(destino, actor)
