extends Node2D

# Referencia al nodo que dibuja los cuadraditos
@onready var zona_actual: Node2D = $Zona1
@onready var capa_selector: TileMapLayer = $CapaSelector
@onready var panel_detalles: PanelContainer = $CanvasLayer/PanelDetalle
@onready var texto_info: Label = $CanvasLayer/PanelDetalle/TextoInfo
@onready var camera_2d: Camera2D = $Camera2D
@onready var capa_camino: TileMapLayer = $CapaCamino

#nodods de vision
@onready var gestor_vision: FOVManager = $GestorVision
@onready var capa_oscuridad: TileMapLayer = $Zona1/CapaOscuridad

const ESCENA_FICHA = preload("res://scenes/ficha/ficha.tscn")

# estructura de datos central
var tablero: TableroGrid = TableroGrid.new()
var pathfinding: PathFindingManager = PathFindingManager.new()
var ficha_jugador: Ficha = null
var ultima_coordenada_hover: Vector2i = Vector2i(-999,-999)
var camino_actual_tentativo: Array[Vector2i] = []

func _ready() -> void:
	tablero.generar_desde_zona(zona_actual)
	pathfinding.inicializar(tablero.datos)
	
	# 1 inicializamos el fov manager con la capa y los datos del mapa
	gestor_vision.inicializar(capa_oscuridad, tablero.datos)
	
	spawnear_ficha_inicial()
	
	# 2 forzamos la iluminación inicial donde spawnea la ficha
	if ficha_jugador:
		_actualizar_luz_jugador(ficha_jugador.coordenada_mapa)
		
func _process(_delta : float) -> void:
	centrar_camara_en_ficha()
	
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
			var celda: Celda = tablero.obtener_celda(coord)
		
			# se construye texto segun lo guardado en el diccionario
			var info_texto = "Coordenada: "+ str(coord)+"\n"
			info_texto += "Tipo: " + str(celda.zona) + "\n"
			info_texto += "Caminable: " + ("Sí" if celda.caminable else "No") + "\n"
			if celda.tiene_contenido():
				info_texto += "Contenido: " + str(celda.contenido.size()) + " objeto(s) \n"
			if celda.damage != null:
				info_texto += "¡PELIGRO!: Daño de " + str(celda.damage["tipo"]) + "\n"
			if celda.tiene_iluminacion():
				for luz in celda.iluminacion:
					var estado = "Encendida" if luz["encendida"] else "Apagada"
					info_texto += "Iluminación: " + luz["tipo"] + " - " + estado + "\n"

			# mostramos la info en la interfaz
			texto_info.text = info_texto
			
		panel_detalles.visible = true
		# aver si anda que el panel este cerca del mouse
		panel_detalles.global_position = get_viewport().get_mouse_position() + Vector2(15, 15)
		
	else:
		# fuera del mapa = ocultamos el panel
		panel_detalles.visible = false

func _manejar_clic_derecho(coord:Vector2i)-> void:
	if tablero.es_caminable(coord) and ficha_jugador and not ficha_jugador.esta_moviendose:
		if not camino_actual_tentativo.is_empty():
			#liberamos celda de origen en el diccionario
			tablero.liberar_celda(ficha_jugador.coordenada_mapa, ficha_jugador)
			
			#ocupamos la casilla de destino final
			var coord_destino = camino_actual_tentativo[-1]
			tablero.ocupar_celda(coord_destino, ficha_jugador)
			
			#Limpiamos flechas de la pantalla
			capa_camino.clear()
			panel_detalles.visible = false
			
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

func _on_ficha_paso_dado(nueva_coord: Vector2i) -> void:
	# Lógica de antorcha
	ficha_jugador.pasos_antorcha_actual -= 1
	
	if ficha_jugador.pasos_antorcha_actual <= 0:
		var tiene_luz = ficha_jugador.consumir_o_recargar_antorcha()
		if not tiene_luz:
			print("El jugador se ha quedado completamente a oscuras.")
	
	# 3. Actualizamos la visión en el nuevo tile donde pisó el jugador
	_actualizar_luz_jugador(nueva_coord)

func _actualizar_luz_jugador(coordenada: Vector2i) -> void:
	# Verificamos si le quedan antorchas/pasos
	if ficha_jugador.pasos_antorcha_actual <= 0 and ficha_jugador.antorchas <= 0:
		gestor_vision.actualizar_vision(coordenada, 1) # Radio mínimo a oscuras
		return
		
	var radio_actual: float = 5.0
	
	# 10 pasos o menos para aplicar la reducción
	if ficha_jugador.pasos_antorcha_actual <= 10:
		# porcentaje en base a esos últimos 10 pasos
		var porcentaje_final = float(max(0, ficha_jugador.pasos_antorcha_actual)) / 10.0
		
		# max(1.0) asegura que antes de apagarse siga viendo su propia casilla.
		radio_actual = max(1.0, porcentaje_final * 5.0)
	
	# Le decimos al FOVManager que trace los rayos
	gestor_vision.actualizar_vision(coordenada, int(radio_actual))

func centrar_camara_en_ficha() -> void:
	if ficha_jugador and camera_2d:
		camera_2d.global_position = ficha_jugador.global_position

# 4. ¡Ahora es ultra simple! Le preguntamos directo al diccionario.
func _esta_en_rango_vision(coord: Vector2i) -> bool:
	var celda: Celda = tablero.obtener_celda(coord)
	return celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE
