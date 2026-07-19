extends Node2D

# Referencia al nodo que dibuja los cuadraditos
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

# Configuración del tablero
const ANCHO_MAPA: int = 10
const ALTO_MAPA: int = 10

# Nuestra estructura de datos central
# Guardará cosas como: { Vector2i(0,0): {"tipo": "pasto", "ocupado": false} }
var tablero: Dictionary = {}

func _ready() -> void {
	generar_tablero()
}

func generar_tablero() -> void {
	for x in range(ANCHO_MAPA):
		for y in range(ALTO_MAPA):
			var coordenada = Vector2i(x, y)
			
			# 1. Creamos los datos lógicos de este cuadrado
			tablero[coordenada] = {
				"tipo": "suelo_basico",
				"contenido": null, # Aquí podrás meter personajes, cofres, etc.
				"es_caminable": true
			}
			
			# 2. Dibujamos el cuadrado en el TileMapLayer
			# (Por ahora usamos la celda 0 del tile ID 0 de tu Tileset)
			tile_map_layer.set_cell(coordenada, 0, Vector2i(0, 0))
			
	print("¡Tablero generado con ", tablero.size(), " casillas!")
}

# Función utilitaria para obtener los datos de una casilla haciendo clic
func _unhandled_input(event: InputEvent) -> void {
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convertimos la posición del mouse en la pantalla a la coordenada del tablero
		var posicion_mouse = get_global_mouse_position()
		var coordenada_clic = tile_map_layer.local_to_map(posicion_mouse)
		
		# Verificamos si esa coordenada existe en nuestro tablero lógico
		if tablero.has(coordenada_clic):
			print("Hiciste clic en la coordenada: ", coordenada_clic)
			print("Datos de la casilla: ", tablero[coordenada_clic])
		else:
			print("Clic fuera del tablero: ", coordenada_clic)
