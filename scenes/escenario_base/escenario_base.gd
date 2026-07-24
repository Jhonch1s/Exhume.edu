extends Node2D

# Referencia al nodo que dibuja los cuadraditos
@onready var zona_actual: Node2D = $Zona1
@onready var capa_selector: TileMapLayer = $CapaSelector
@onready var panel_detalles: PanelContainer = $CanvasLayer/PanelDetalle
@onready var texto_info: Label = $CanvasLayer/PanelDetalle/TextoInfo
@onready var camera_2d: Camera2D = $Camera2D
@onready var capa_camino: TileMapLayer = $CapaCamino


# Configuración del tablero
const ANCHO_MAPA: int = 20
const ALTO_MAPA: int = 10

# estructura de datos central
# algo como { Vector2i(0,0): {"tipo": "pasto", "ocupado": false} }
var tablero: Dictionary = {}

const ESCENA_FICHA = preload("res://scenes/ficha/ficha.tscn")
var ficha_jugador: Ficha = null

func _ready() -> void:
	generar_tablero_de_zona()
	spawnear_ficha_inicial()


func generar_tablero_de_zona() -> void:
	var _capa_suelo:TileMapLayer = zona_actual.get_node("CapaSuelo")
	var _capa_agua:TileMapLayer = zona_actual.get_node("CapaAgua")
	var _capa_lava:TileMapLayer = zona_actual.get_node("CapaLava")
	
	if (not _capa_suelo):
		print("Todo mal gato")
		return
	# escaneamos las celdas que usa cada capa
	var _celdas_suelo = _capa_suelo.get_used_cells()
	
	for coordenada in _celdas_suelo:
		tablero[coordenada]={
			"zona":"piso_vacio",
			"contenido": null,
			"caminable": true,
			"damage": null
		}
		
	if _capa_agua:
		var _celdas_agua= _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			if tablero.has(coordenada):
				tablero[coordenada]={
					"zona":"agua",
					"contenido":null,
					"caminable":false,
					"damage":null
				}
				
	if _capa_lava:
		var _celdas_lava=_capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			if tablero.has(coordenada):
				tablero[coordenada]={
					"zona":"lava",
					"contenido":null,
					"caminable":true,
					"damage":{
						"tipo": "fuego",
						"turnos": 5,
						"damage": 2
					}
				}
	inicializar_astar()

var ultima_coordenada_hover: Vector2i = Vector2i(-999,-999)
var camino_actual_tentativo: Array[Vector2i]=[]

func _process(_delta : float) -> void:
	var _capa_suelo : TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if _capa_suelo:
		var posicion_mouse = get_global_mouse_position()
		var coordenada_actual = _capa_suelo.local_to_map(posicion_mouse)
		#chequeamos que haya cambiado de casilla
		if coordenada_actual != ultima_coordenada_hover:
			capa_selector.clear() #borramo el viejo
			
			#ahora chequeamos que este dentro de lo dibujado
			if tablero.has(coordenada_actual):
				capa_selector.set_cell(coordenada_actual, 0, Vector2i(1,1)) ## 1,1 es la posi de mi selected en el atlas
				
				#esto es para el dibujar el path
				camino_actual_tentativo = calcular_camino(ficha_jugador.coordenada_mapa, coordenada_actual)
				dibujar_trayectoria(camino_actual_tentativo)
			else:
				capa_camino.clear()
			ultima_coordenada_hover=coordenada_actual

# ahora la funcion deberia resaltar la casilla y mostrar panel con label
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var _capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
		if not _capa_suelo:
			return
		var posicion_mouse = get_global_mouse_position()
		var coordenada_clic = _capa_suelo.local_to_map(posicion_mouse)
		
		#si el click es izquierdo
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if tablero.has(coordenada_clic):
				# logica del dialogo o menu a futuro
				var datos = tablero[coordenada_clic]
				
				# se construye texto segun lo guardado en el diccionario
				var info_texto = "Coordenada: "+ str(coordenada_clic)+"\n"
				info_texto += "Tipo: " + datos["zona"] + "\n"
				info_texto += "Caminable: " + ("Sí" if datos["caminable"] else "No") + "\n"
				if datos["contenido"] != null:
					info_texto+= "Contenido: Ficha presente \n"
				if datos["damage"] != null:
					info_texto += "¡PELIGRO!: Daño de " + str(datos["damage"]["tipo"])
				
				# mostramos la info en la interfaz
				texto_info.text = info_texto
				panel_detalles.visible = true
				
				# aver si anda que el panel este cerca del mouse
				panel_detalles.global_position = get_viewport().get_mouse_position() + Vector2(15, 15)
				
				print("Menú abierto para: ", coordenada_clic)
			else:
				# fuera del mapa = ocultamos el panel
				panel_detalles.visible = false
		
		#si el click es derecho
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if tablero.has(coordenada_clic) and ficha_jugador:
				if tablero[coordenada_clic]["caminable"]:
					var coord_anterior = ficha_jugador.coordenada_mapa
					tablero[coord_anterior]["contenido"] = null
					
					ficha_jugador.mover_a_coordenada_instantaneo(coordenada_clic)
					
					tablero[coordenada_clic]["contenido"] = ficha_jugador
					centrar_camara_en_ficha()
					
					panel_detalles.visible = false
					
					# LIMPIAMOS EL CAMINO DIBUJADO AL MOVER
					capa_camino.clear()
					
					print("fichamovida de: ", coord_anterior, " a ", coordenada_clic)
				else:
					print("No te puedes mover ahí")


func spawnear_ficha_inicial() ->void:
	var _capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	
	if not _capa_suelo:
		return
	
	var coord_inicio = Vector2i(-999, -999)
	
	for coord in tablero:
		if tablero[coord]["caminable"]:
			coord_inicio = coord
			break
	if coord_inicio == Vector2i (-999, -999):
		print("Error todo mal, no se encontraron casillas caminables")
		return
	
	ficha_jugador = ESCENA_FICHA.instantiate()
	add_child(ficha_jugador)
	
	ficha_jugador.inicializar(coord_inicio,_capa_suelo)
	
	tablero[coord_inicio]["contenido"]= ficha_jugador
	centrar_camara_en_ficha()
	
	print("Ficha creada con éxito en la coordenada: ", coord_inicio)

func centrar_camara_en_ficha() -> void:
	if ficha_jugador and camera_2d:
		camera_2d.global_position = ficha_jugador.global_position
		

## Logica de crear mapa A* con los nodos caminables y cual es el camino de cada uno
var astar: AStar2D= AStar2D.new()

func inicializar_astar() -> void:
	astar.clear()
	
	#agregamos puntos validos del tablero
	for coord in tablero.keys():
		var id = obtener_id_unico(coord)
		astar.add_point(id, Vector2(coord.x, coord.y))
		
		##Configuramos el costo de pasar por una selda
		#si no es caminable (agua o tiene contenido), se desactiva
		if not tablero[coord]["caminable"]:
			astar.set_point_disabled(id, true)
		
		##sino, si tiene daño (lava u otras adiciones a futuro), le damos un costo muy alto para el algoritmo
		elif tablero[coord]["damage"] != null:
			astar.set_point_weight_scale(id, 5.0) #ta potente
		else:
			astar.set_point_weight_scale(id, 1.0) #piso de chill
	##ahora conectamos los puntos vecinos entre sí, porque están todos sueltos (vecinos arriba abajo costados)
	var direcciones = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	
	for coord in tablero.keys():
		var id_actual = obtener_id_unico(coord)
		for dir in direcciones:
			var vecino = coord + dir
			if tablero.has(vecino):
				var id_vecino = obtener_id_unico(vecino)
				if not astar.are_points_connected(id_actual, id_vecino):
					astar.connect_points(id_actual, id_vecino, true)

func obtener_id_unico(coord:Vector2i) -> int:
	#cuenta chota pa que de entero
	return (coord.x + 1000) + (coord.y+1000)*2000

func calcular_camino(origen: Vector2i, destino: Vector2i)-> Array[Vector2i]:
	var camino:Array[Vector2i]=[]
	if not tablero.has(origen) or not tablero.has(destino):
		return camino
	
	var id_origen = obtener_id_unico(origen)
	var id_destino = obtener_id_unico(destino)
	
	if astar.has_point(id_origen) and astar.has_point(id_destino):
		var id_path = astar.get_id_path(id_origen, id_destino)
		for id in id_path:
			var pos_vector = astar.get_point_position(id)
			camino.append(Vector2i(int(pos_vector.x), int(pos_vector.y)))
	
	return camino

#Logica de elegir camino
##la de DIBUJO:
func dibujar_trayectoria (camino: Array[Vector2i])-> void:
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
			var tile_flecha = obtener_tile_flecha(direccion_entrada)
			capa_camino.set_cell(actual, 0, tile_flecha)
		else: ##celdas intermedias, se dibua o una linea o una esquina
			var siguiente=camino[i+1]
			var direccion_salida = siguiente - actual
			var tile_linea= obtener_tile_camino(direccion_entrada, direccion_salida)
			capa_camino.set_cell(actual, 0, tile_linea)

##La de elegir bien la flecha
func obtener_tile_flecha(dir: Vector2i)-> Vector2i:
	match dir: ##tremendo el match, ahorra buen laburo
		Vector2i(1,0): return Vector2i(0,2) 
		Vector2i(-1,0): return Vector2i(1,3) 
		Vector2i(0,1): return Vector2i(0,3) 
		Vector2i(0,-1): return Vector2i(1,2) 
	return Vector2i(0,2)

##La brava
func obtener_tile_camino(dir_ingreso: Vector2i, dir_salida: Vector2i)->Vector2i:
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
