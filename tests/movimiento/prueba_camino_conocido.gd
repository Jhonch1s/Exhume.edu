extends SceneTree

class BuscadorContado:
	extends PathFindingManager
	var consultas := 0

	func calcular_camino_conocido(_origen: Vector2i, _destino: Vector2i, _datos: Dictionary, _actor: Object = null) -> Array[Vector2i]:
		consultas += 1
		return []


var _fallos: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var datos: Dictionary = {}
	for y in 2:
		for x in 3:
			datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.EXPLORADO)
	var origen := Vector2i.ZERO
	var destino := Vector2i(2, 0)
	datos[origen].visibilidad = Celda.EstadoVisibilidad.VISIBLE
	datos[Vector2i(1, 0)].visibilidad = Celda.EstadoVisibilidad.OCULTO
	var buscador := PathFindingManager.new()
	root.add_child(buscador)
	buscador.inicializar(datos)
	var ruta := buscador.calcular_camino_conocido(origen, destino, datos)
	_comprobar(ruta.size() == 5 and not ruta.has(Vector2i(1, 0)), "Un destino explorado rodea casillas nunca vistas.")
	_comprobar(buscador.calcular_camino(origen, destino, datos).has(Vector2i(1, 0)), "La ruta general de NPC conserva el grafo completo.")
	datos[Vector2i(1, 1)].visibilidad = Celda.EstadoVisibilidad.OCULTO
	_comprobar(buscador.calcular_camino_conocido(origen, destino, datos).is_empty(), "No calcula ruta a través de un corredor oculto.")
	datos[Vector2i(1, 0)].visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	_comprobar(buscador.calcular_camino_conocido(origen, destino, datos) == [origen, Vector2i(1, 0), destino], "Explorar el corredor permite trazarlo.")
	datos[destino].visibilidad = Celda.EstadoVisibilidad.OCULTO
	_comprobar(buscador.calcular_camino_conocido(origen, destino, datos).is_empty(), "Un destino desconocido no inicia búsqueda.")
	buscador.free()
	await _probar_orden_escenario()
	for fallo in _fallos:
		push_error(fallo)
	print("CaminoConocido: %d fallos." % _fallos.size())
	quit(0 if _fallos.is_empty() else 1)


func _probar_orden_escenario() -> void:
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
		_comprobar(false, "Debe iniciar el escenario de integración.")
		escena.queue_free()
		return
	var ficha: Ficha = escenario.ficha_jugador
	var destino := Vector2i(9999, 9999)
	for direccion in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var vecina: Vector2i = ficha.coordenada_mapa + direccion
		if escenario.tablero.puede_entrar(vecina, ficha):
			destino = vecina
			break
	if destino == Vector2i(9999, 9999):
		_comprobar(false, "La ficha necesita una celda vecina caminable.")
		escena.queue_free()
		return
	var celda: Celda = escenario.tablero.obtener_celda(destino)
	var estado_anterior := celda.visibilidad
	var contado := BuscadorContado.new()
	root.add_child(contado)
	escenario.pathfinding = contado
	celda.visibilidad = Celda.EstadoVisibilidad.OCULTO
	escenario._manejar_clic_derecho(destino)
	_comprobar(contado.consultas == 0 and not ficha.esta_moviendose, "Clic derecho en desconocido no consulta rutas ni mueve la ficha.")
	celda.visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	escenario._manejar_clic_derecho(destino)
	_comprobar(contado.consultas == 1, "Clic derecho en explorado sí consulta el camino.")
	celda.visibilidad = estado_anterior
	escena.queue_free()
	contado.queue_free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
