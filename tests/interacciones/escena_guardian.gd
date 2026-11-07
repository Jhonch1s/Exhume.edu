extends "res://tests/interacciones/escena_npc_hostil.gd"

const ESCENA_GUARDIAN := preload("res://scenes/personajes/guardian.tscn")


func _ready() -> void:
	cantidad_enemigos = 1
	_ruta_guardado = "user://prueba_guardian.json"
	await super._ready()
	_mostrar_estado("El Guardián: K/C para guardar/cargar.")


func _buscar_celda_cercana(origen: Vector2i, tablero: TableroGrid, pathfinding: PathFindingManager) -> Vector2i:
	var candidato := ESCENA_GUARDIAN.instantiate() as PersonajeNPC
	var celdas: Array[Vector2i] = []
	celdas.assign(tablero.datos.keys())
	celdas.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x or (a.x == b.x and a.y < b.y))
	var encontrada := SIN_CELDA
	for distancia in [5, 4, 3, 2]:
		for celda in celdas:
			if Vector2(celda - origen).length_squared() != distancia * distancia or not tablero.puede_entrar(celda, candidato):
				continue
			if tablero.obtener_celda(celda).visibilidad != Celda.EstadoVisibilidad.VISIBLE or not tablero.obtener_celda(celda).interactuables.is_empty():
				continue
			if _escenario.validador_espacial.validar_linea_visual(celda, origen) == &"" and not pathfinding.calcular_camino(origen, celda, tablero.datos).is_empty():
				encontrada = celda
				break
		if encontrada != SIN_CELDA:
			break
	candidato.free()
	return encontrada


func _crear_enemigo(zona: Node2D, capa_suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	var enemigo := ESCENA_GUARDIAN.instantiate() as PersonajeNPC
	enemigo.id_instancia = StringName("guardian_prueba_%d" % numero)
	zona.get_node("Interactuables/Personajes").add_child(enemigo)
	enemigo.global_position = capa_suelo.to_global(capa_suelo.map_to_local(coordenada))
	if not tablero.registrar_interactuable(coordenada, enemigo):
		enemigo.queue_free()
		return false
	_enemigos.append(enemigo)
	enemigo.actualizar_presentacion_visibilidad(tablero.obtener_celda(coordenada).visibilidad)
	return true
