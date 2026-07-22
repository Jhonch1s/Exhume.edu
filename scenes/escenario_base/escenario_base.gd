extends Node2D

# Referencia al nodo que dibuja los cuadraditos
@onready var zona_actual: Node2D = $Zona1
@onready var capa_selector: TileMapLayer = $CapaSelector
@onready var panel_detalles: PanelContainer = $CanvasLayer/PanelDetalle
@onready var texto_info: Label = $CanvasLayer/PanelDetalle/TextoInfo
@onready var camera_2d: Camera2D = $Camera2D


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
var ultima_coordenada_hover: Vector2i = Vector2i(-999,-999)

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
				
				#verificamos si es caminable
				if tablero[coordenada_clic]["caminable"]:
					
					# liberamos la casilla
					var coord_anterior = ficha_jugador.coordenada_mapa
					tablero[coord_anterior]["contenido"]=null
					
					#movemos la ficha a la nueva coord
					ficha_jugador.mover_a_coordenada_instantaneo(coordenada_clic)
					
					#ocupamos la casilla nueva
					tablero[coordenada_clic]["contenido"] = ficha_jugador
					
					#hacemos la que la camara la siga
					centrar_camara_en_ficha()
					
					#ocultamos el panel de detalles por siacaso
					panel_detalles.visible=false
					
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
