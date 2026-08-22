extends Node
class_name PathFindingManager

var astar: AStar2D= AStar2D.new()

func inicializar(tablero_datos:Dictionary) -> void:
	astar.clear()
	
	#agregamos puntos validos del tablero
	for coord in tablero_datos.keys():
		var id = _obtener_id_unico(coord)
		astar.add_point(id, Vector2(coord.x, coord.y))
		
		##Configuramos el costo de pasar por una selda
		#si no es caminable (agua o tiene contenido), se desactiva
		var celda: Celda = tablero_datos[coord]
		if not celda.es_caminable_efectiva():
			astar.set_point_disabled(id, true)
		
		else:
			astar.set_point_weight_scale(id, celda.calcular_peso_ruta())
	##ahora conectamos los puntos vecinos entre sí, porque están todos sueltos (vecinos arriba abajo costados)
	var direcciones = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	
	for coord in tablero_datos.keys():
		var id_actual = _obtener_id_unico(coord)
		for dir in direcciones:
			var vecino = coord + dir
			if tablero_datos.has(vecino):
				var id_vecino = _obtener_id_unico(vecino)
				if not astar.are_points_connected(id_actual, id_vecino):
					astar.connect_points(id_actual, id_vecino, true)

func calcular_camino(
	origen: Vector2i,
	destino: Vector2i,
	tablero_datos: Dictionary,
	actor: Object = null
) -> Array[Vector2i]:
	var camino:Array[Vector2i]=[]
	if not tablero_datos.has(origen) or not tablero_datos.has(destino):
		return camino

	# La ocupacion es dinamica: se evalua en cada consulta de ruta.
	for coord in tablero_datos.keys():
		var celda: Celda = tablero_datos[coord]
		var bloqueada := (
			not celda.es_caminable_efectiva()
			or celda.tiene_contenido()
			or celda.esta_reservada()
		)
		if coord == origen:
			bloqueada = false
		var id := _obtener_id_unico(coord)
		astar.set_point_disabled(id, bloqueada)
		astar.set_point_weight_scale(id, celda.calcular_peso_ruta(actor))

	if destino != origen:
		var celda_destino: Celda = tablero_datos[destino]
		if celda_destino.tiene_contenido() or celda_destino.esta_reservada():
			return camino
	
	var id_origen = _obtener_id_unico(origen)
	var id_destino = _obtener_id_unico(destino)
	
	if astar.has_point(id_origen) and astar.has_point(id_destino):
		var id_path = astar.get_id_path(id_origen, id_destino)
		for id in id_path:
			var pos_vector = astar.get_point_position(id)
			camino.append(Vector2i(int(pos_vector.x), int(pos_vector.y)))
	
	return camino

func dibujar_trayectoria (camino: Array[Vector2i], capa_camino:TileMapLayer)-> void:
	capa_camino.clear()
	
	if camino.size() < 2:
		return #no hay camino que dibujar la vd
	
	for i in range(camino.size()):
		var actual = camino[i]

		#ignoramos la primera celda donde ya esta el pj
		if i == 0:
			continue
		
		var anterior = camino [i -1]
		var direccion_entrada = actual - anterior
		
		##es la unica celda: dibujamos la flecha de destino
		if i == camino.size() -1:
			var tile_flecha = _obtener_tile_flecha(direccion_entrada)
			capa_camino.set_cell(actual, 0, tile_flecha)
		else: ##celdas intermedias, se dibua o una linea o una esquina
			var siguiente=camino[i+1]
			var direccion_salida = siguiente - actual
			var tile_linea= _obtener_tile_camino(direccion_entrada, direccion_salida)
			capa_camino.set_cell(actual, 0, tile_linea)

func limitar_camino_por_movimiento(
	camino: Array[Vector2i],
	tablero_datos: Dictionary,
	actor: Object,
	movimiento_disponible: int
) -> Array[Vector2i]:
	if camino.is_empty():
		return []
	var limitado: Array[Vector2i] = [camino[0]]
	var gastado := 0
	for indice in range(1, camino.size()):
		var celda: Celda = tablero_datos.get(camino[indice]) as Celda
		if celda == null:
			break
		var coste := celda.calcular_coste_movimiento(actor)
		if gastado + coste > movimiento_disponible:
			break
		gastado += coste
		limitado.append(camino[indice])
	return limitado

func _obtener_tile_flecha(dir: Vector2i)-> Vector2i:
	match dir: ##tremendo el match, ahorra buen laburo
		Vector2i(1,0): return Vector2i(0,2) 
		Vector2i(-1,0): return Vector2i(1,3) 
		Vector2i(0,1): return Vector2i(0,3) 
		Vector2i(0,-1): return Vector2i(1,2) 
	return Vector2i(0,2)

##La brava
func _obtener_tile_camino(dir_ingreso: Vector2i, dir_salida: Vector2i)->Vector2i:
	#Si mantiene la misma direccion es linea recta
	if dir_ingreso== dir_salida:
		if dir_ingreso.x !=0:
			return Vector2i(0,0) ##linea recta en eje x
		else:
			return Vector2i(1,0) ## Linea recta en eje y
	
	##si cambia de direccion es una curva o esquina, aca se pone feo
	if (dir_ingreso == Vector2i(1, 0) and dir_salida == Vector2i(0, 1)) or (dir_ingreso == Vector2i(0, -1) and dir_salida == Vector2i(-1, 0)):
		return Vector2i(2,1) # coordenada tlas ^
	
	if (dir_ingreso == Vector2i(1, 0) and dir_salida == Vector2i(0, -1)) or (dir_ingreso == Vector2i(0, 1) and dir_salida == Vector2i(-1, 0)):
		return Vector2i(0, 1) # coordenada atlas >
	
	if (dir_ingreso == Vector2i(-1, 0) and dir_salida == Vector2i(0, 1)) or (dir_ingreso == Vector2i(0, -1) and dir_salida == Vector2i(1, 0)):
		return Vector2i(1, 1) # coord atlas <
	
	if (dir_ingreso == Vector2i(-1, 0) and dir_salida == Vector2i(0, -1)) or (dir_ingreso == Vector2i(0, 1) and dir_salida == Vector2i(1, 0)):
		return Vector2i(2, 0) # v
	
	return Vector2i(0,3)

func _obtener_id_unico(coord:Vector2i) -> int:
	#cuenta chota pa que de entero
	return (coord.x + 1000) + (coord.y+1000)*2000
