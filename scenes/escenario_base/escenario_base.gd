extends Node2D

# Referencia al nodo que dibuja los cuadraditos
@onready var zona_actual: Node2D = $Zona1
@onready var capa_selector: TileMapLayer = $CapaSelector
@onready var panel_detalles: PanelContainer = $CanvasLayer/PanelDetalle
@onready var texto_info: Label = $CanvasLayer/PanelDetalle/TextoInfo
@onready var camera_2d: Camera2D = $Camera2D
@onready var capa_camino: TileMapLayer = $CapaCamino
@onready var niebla_shader: ColorRect = $NieblaShader

const ESCENA_FICHA=preload("res://scenes/ficha/ficha.tscn")
const maximoAntorcha: int = 50

# estructura de datos central
var tablero: TableroGrid = TableroGrid.new()
var pathfinding: PathFindingManager=PathFindingManager.new()
var ficha_jugador: Ficha = null
var ultima_coordenada_hover: Vector2i = Vector2i(-999,-999)
var camino_actual_tentativo: Array[Vector2i]=[]

func _ready() -> void:
	tablero.generar_desde_zona(zona_actual)
	pathfinding.inicializar(tablero.datos)
	spawnear_ficha_inicial()
	actualizar_luz_niebla()

func _process(_delta : float) -> void:
	centrar_camara_en_ficha()
	actualizar_luz_niebla()
	
	if ficha_jugador and ficha_jugador.esta_moviendose:
		capa_selector.clear()
		capa_camino.clear()
		return

	var capa_suelo : TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	if capa_suelo and ficha_jugador:
		var coord_actual = capa_suelo.local_to_map(get_global_mouse_position())
		#chequeamos que haya cambiado de casilla
		if coord_actual != ultima_coordenada_hover:
			capa_selector.clear() #borramo el viejo
			
			#ahora chequeamos que este dentro de lo dibujado
			if tablero.es_celda_valida(coord_actual):
				capa_selector.set_cell(coord_actual, 0, Vector2i(1,1)) ## 1,1 es la posi de mi selected en el atlas
				
				#esto es para el dibujar el path
				camino_actual_tentativo = pathfinding.calcular_camino(ficha_jugador.coordenada_mapa, coord_actual, tablero.datos)
				pathfinding.dibujar_trayectoria(camino_actual_tentativo, capa_camino)
			else:
				capa_camino.clear()
			ultima_coordenada_hover=coord_actual

# ahora la funcion deberia resaltar la casilla y mostrar panel con label
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
		if not capa_suelo:
			return
		var coord_clic = capa_suelo.local_to_map(get_global_mouse_position())
		
		#si el click es izquierdo
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			_manejar_clic_izquierdo(coord_clic)
			
		#si el click es derecho
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_manejar_clic_derecho(coord_clic)

func _manejar_clic_izquierdo(coord: Vector2i)->void:
	if tablero.es_celda_valida(coord):
		if not _esta_en_rango_vision(coord):
			texto_info.text = "Coordenada: " + str(coord) + "\nÁrea no explorada (A ciegas)"
		else:
		
			# logica del dialogo o menu a futuro
			var datos = tablero.obtener_datos_celda(coord)
		
			# se construye texto segun lo guardado en el diccionario
			var info_texto = "Coordenada: "+ str(coord)+"\n"
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
		
		print("Menú abierto para: ", coord)
	else:
		# fuera del mapa = ocultamos el panel
		panel_detalles.visible = false

func _manejar_clic_derecho(coord:Vector2i)-> void:
	if tablero.es_caminable(coord) and ficha_jugador and not ficha_jugador.esta_moviendose:
		if not camino_actual_tentativo.is_empty():
			#liberamos celda de origen en el diccionario
			tablero.liberar_celda(ficha_jugador.coordenada_mapa)
			
			#ocupamos la casilla de destino final
			var coord_destino = camino_actual_tentativo[-1]
			tablero.ocupar_celda(coord_destino, ficha_jugador)
			
			#Limpiamos flechas de la pantalla
			capa_camino.clear()
			panel_detalles.visible=false
			
			#iniciamos pasito a pasito
			ficha_jugador.mover_por_camino(camino_actual_tentativo)
			
		else:
			print("No te puedes mover ahí")

func spawnear_ficha_inicial() ->void:
	var _capa_suelo: TileMapLayer = zona_actual.get_node_or_null("CapaSuelo")
	
	if not _capa_suelo: return
	
	var coord_inicio = Vector2i(-999, -999)
	
	for coord in tablero.datos:
		if tablero.es_caminable(coord):
			coord_inicio = coord
			break
	
	if coord_inicio == Vector2i (-999, -999): return
	
	ficha_jugador = ESCENA_FICHA.instantiate()
	zona_actual.add_child(ficha_jugador)
	
	ficha_jugador.inicializar(coord_inicio,_capa_suelo)
	
	#conectamos las señales de la ficha
	ficha_jugador.paso_dado.connect(_on_ficha_paso_dado)
	tablero.ocupar_celda(coord_inicio, ficha_jugador)

func _on_ficha_paso_dado(_nueva_coord: Vector2i) -> void:
	# Lógica de antorcha
	ficha_jugador.pasos_antorcha_actual -= 1
	
	if ficha_jugador.pasos_antorcha_actual <=0:
		var tiene_luz= ficha_jugador.consumir_o_recargar_antorcha()
		
		if not tiene_luz:
			#acá podemos poner algún efecto o indicador
			pass
	
	
	var porcentaje_restante = float(max(0, ficha_jugador.pasos_antorcha_actual)) / 50.0
	
	# Reducir progresivamente el radio de la luz (sin el tope alto de 0.5)
	if ficha_jugador.has_node("Antorcha"):
		var luz = ficha_jugador.get_node("Antorcha")
		# Permitimos que baje hasta 0.2 para que se achique visualmente junto con la niebla
		luz.texture_scale = max(0.1, 2.5 * porcentaje_restante)

	if ficha_jugador.pasos_antorcha_actual <= 0:
		print("Antorcha consumida")
		if ficha_jugador.has_node("Antorcha"):
			ficha_jugador.get_node("Antorcha").enabled = false

func centrar_camara_en_ficha() -> void:
	if ficha_jugador and camera_2d:
		camera_2d.global_position = ficha_jugador.global_position

#apartado visual
func actualizar_luz_niebla() -> void:
	#verificamos que esta el jugador y la niebla para que no crashe
	if not is_instance_valid(ficha_jugador) or not is_instance_valid(niebla_shader):
		return
	#traducimos las cordenadas a uv
	var pos_ficha = ficha_jugador.global_position
	var pos_rect = niebla_shader.global_position
	var tamano_rect = niebla_shader.size

	var uv_x = (pos_ficha.x - pos_rect.x) / tamano_rect.x
	var uv_y = (pos_ficha.y - pos_rect.y) / tamano_rect.y
	var uv_pos = Vector2(uv_x, uv_y)

	var pasos = max(0, ficha_jugador.pasos_antorcha_actual)
	
	var radio_maximo: float = 0.18
	var radio_calculado: float = radio_maximo
	
	if pasos <=10:
		##mati ahora se reduce desde que le quedan 10 o menos
		var porcentaje: float = float(pasos) / 10.0
		radio_calculado=radio_maximo*porcentaje

	#se lo mandamos pal shader
	var mat = niebla_shader.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("posicion_jugador", uv_pos)
		mat.set_shader_parameter("radio_luz", radio_calculado)

#para verificar si una casilla está dentro del alcance visible actual, lo estamos usando para lo del click izquierdo asi no puede hacer trampa
#se puede agragar para que no ande caminando por lo oscuro pero ta, vemos
func _esta_en_rango_vision(coord: Vector2i) -> bool:
	if not ficha_jugador:
		return false
	
	#calculamos distancia en casillas desde la ficha a la coordenada destino
	var dist_casillas = Vector2(ficha_jugador.coordenada_mapa).distance_to(Vector2(coord))
	
	# calculamos el radio permitido según la antorcha
	# si tiene 50 la antorcha entonces ilumina 10 casillas, si le quedan 15 pasos ilumina solo 3 casillas
	var rango_maximo = float(max(0, ficha_jugador.pasos_antorcha_actual)) / maximoAntorcha
	
	return dist_casillas <= rango_maximo
