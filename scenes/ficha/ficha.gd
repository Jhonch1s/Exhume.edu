extends Node2D
class_name Ficha

@export var nombre: String = "Heroe Jr."
@export var titulo: String = "El come cebolla"

##atributos
var fue: int = 3
var des: int = 4
var vol: int = 2
var energia_maxima: int = 20
var energia_actual: int = 20

#cosas de exhume
var pv_max: int
var pv_actual: int

##clases: fuerza = guerrero, des = ladrón, vol = mago
var clase: String = "Ladrón"

#inventario super bascio ¿Final?
var antorchas: int = 2
var pasos_antorcha_actual : int = 50 ##-1 por cada casilla que se mueva
var raciones: int = 3 #necesarias pa descansar

#movimiento y posicion
var coordenada_mapa: Vector2i = Vector2i(0,0)
var capa_referencia: TileMapLayer = null
var esta_moviendose: bool= false

#vel movimiento
@export var velocidad_paso:float=0.5 #en segundos

#señales para conectar al tablero
signal paso_dado(nueva_coordenada)
signal movimiento_terminado



func _ready()->void:
	pv_max=fue+des+vol
	pv_actual=pv_max

func inicializar (coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	capa_referencia = capa
	coordenada_mapa = coordenada_inicial
	if capa_referencia:
		global_position = capa_referencia.map_to_local(coordenada_mapa)
	
func mover_por_camino(camino: Array[Vector2i])-> void:
	if camino.is_empty() or esta_moviendose or not capa_referencia:
		return
	
	esta_moviendose = true
	
	for siguiente_coord in camino:
		
		#para que no de mas pasos si se canso
		if energia_actual <= 0:
			print("sin energia para caminar mas")
			break
		#restamos energia por maso
		energia_actual -= 1
		print("energia actual: ", energia_actual)
		
		var destino_pixeles = capa_referencia.map_to_local(siguiente_coord)
		
		#aca animamos movimiento de una celda a la que siga
		var tween = create_tween()
		tween.tween_property(self, "global_position", destino_pixeles, velocidad_paso)
		
		#esperamos que termine a animacion
		await tween.finished
		
		#al llegar se actualiza la coordenada
		coordenada_mapa = siguiente_coord
		
		#emitimos la señal de que estamos en una nueva casilla
		paso_dado.emit(coordenada_mapa)
	
	esta_moviendose=false
	movimiento_terminado.emit()
