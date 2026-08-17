extends Node2D
class_name Ficha

@export var nombre: String = "Heroe Jr."
@export var titulo: String = "El come cebolla"
@export var id_observador: StringName = &"jugador_principal"

var fue: int = 3
var des: int = 4
var vol: int = 2
var energia_maxima: int = 200
var energia_actual: int = 200

var pv_max: int
var pv_actual: int
var clase: String = "Ladron"

var antorchas: int = 3
var PASOS_MAX_ANTORCHA: int = 80
var pasos_antorcha_actual: int = 80
var raciones: int = 3

var coordenada_mapa: Vector2i = Vector2i.ZERO
var capa_referencia: TileMapLayer = null
var esta_moviendose: bool = false
var interrupcion_solicitada: bool = false

@export var velocidad_paso: float = 0.2

signal paso_dado(nueva_coordenada: Vector2i)
signal movimiento_terminado(interrumpido: bool)


func obtener_id_observador() -> StringName:
	return id_observador

func _ready() -> void:
	pv_max = fue + des + vol
	pv_actual = pv_max

func inicializar(coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	capa_referencia = capa
	coordenada_mapa = coordenada_inicial
	if capa_referencia:
		global_position = capa_referencia.map_to_local(coordenada_mapa)

func consumir_o_recargar_antorcha() -> bool:
	if pasos_antorcha_actual > 0:
		return true
	if antorchas > 1:
		antorchas -= 1
		pasos_antorcha_actual = PASOS_MAX_ANTORCHA
		print("Se cambia antorcha")
		return true
	antorchas = 0
	print("No quedan mas antorchas")
	return false

func solicitar_interrupcion() -> void:
	if esta_moviendose:
		interrupcion_solicitada = true

func mover_por_camino(
	camino: Array[Vector2i],
	preparar_paso: Callable,
	confirmar_paso: Callable,
	cancelar_paso: Callable
) -> void:
	if camino.is_empty() or esta_moviendose or not capa_referencia:
		return

	esta_moviendose = true
	interrupcion_solicitada = false
	var fue_interrumpido := false

	for siguiente_coord in camino:
		# AStar incluye el origen: no cuenta como paso ni consume recursos.
		if siguiente_coord == coordenada_mapa:
			continue
		if interrupcion_solicitada:
			fue_interrumpido = true
			break
		if energia_actual <= 0:
			print("sin energia para caminar mas")
			fue_interrumpido = true
			break

		var origen := coordenada_mapa
		# La ruta puede quedar obsoleta; reservamos cada destino antes de usarlo.
		if not preparar_paso.call(origen, siguiente_coord, self):
			fue_interrumpido = true
			break

		var destino_pixeles := capa_referencia.map_to_local(siguiente_coord)
		var tween := create_tween()
		tween.tween_property(self, "global_position", destino_pixeles, velocidad_paso)
		await tween.finished

		if not confirmar_paso.call(origen, siguiente_coord, self):
			cancelar_paso.call(siguiente_coord, self)
			global_position = capa_referencia.map_to_local(origen)
			fue_interrumpido = true
			break

		# El paso se vuelve definitivo solamente al llegar.
		coordenada_mapa = siguiente_coord
		energia_actual -= 1
		print("energia actual: ", energia_actual)
		paso_dado.emit(coordenada_mapa)

	esta_moviendose = false
	interrupcion_solicitada = false
	movimiento_terminado.emit(fue_interrumpido)
