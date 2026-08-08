extends Control

# Zoom paramargen alrededor de la pantalla para el desplazamiento.
@export_group("Zoom por profundidad")
@export_range(1.0, 1.15, 0.005) var zoom_fondo: float = 1.04
@export_range(1.0, 1.15, 0.005) var zoom_posterior: float = 1.05
@export_range(1.0, 1.15, 0.005) var zoom_medio: float = 1.065
@export_range(1.0, 1.15, 0.005) var zoom_frontal: float = 1.08
# Rapidez capas alcanzan  posición objetivo
@export_range(0.5, 10.0, 0.1) var velocidad_respuesta: float = 2.0

@export_group("Haz de luz")
@export_range(0.0, 1.0, 0.01) var opacidad_haz: float = 1.0
@export_range(0.0, 0.5, 0.01) var variacion_haz: float = 0.30
@export_range(0.01, 1.0, 0.01) var frecuencia_haz: float = 0.15
@export var color_haz := Color(1.0, 0.98, 0.92, 1.0)

@export_group("Desplazamiento máximo")
@export var desplazamiento_posterior := Vector2(5.0, 0.0)
@export var desplazamiento_medio := Vector2(10.0, 0.0)
@export var desplazamiento_frontal := Vector2(18.0, 0.0)

@onready var fondo_limpio: TextureRect = $FondoLimpio
@onready var haz_luz: TextureRect = $HazLuz
@onready var medio_posterior: TextureRect = $MedioPosterior
@onready var medio_frontal: TextureRect = $MedioFrontal
@onready var frontal: TextureRect = $Frontal

var capas_moviles: Array[TextureRect]
var intensidades: Array[Vector2]
var tiempo_ambiente: float = 0.0


func _ready() -> void:
	capas_moviles = [medio_posterior, medio_frontal, frontal]
	intensidades = [
		desplazamiento_posterior,
		desplazamiento_medio,
		desplazamiento_frontal,
	]

	resized.connect(_configurar_capas)
	_configurar_capas()


func _process(delta: float) -> void:
	tiempo_ambiente += delta
	_actualizar_haz_luz()

	var direccion := _obtener_direccion_cursor()
	var peso_suavizado := 1.0 - exp(-velocidad_respuesta * delta)

	for indice in capas_moviles.size():
		var objetivo := -direccion * intensidades[indice]
		capas_moviles[indice].position = capas_moviles[indice].position.lerp(
			objetivo,
			peso_suavizado
		)


func _configurar_capas() -> void:
	var capas := [fondo_limpio, haz_luz, medio_posterior, medio_frontal, frontal]
	var niveles_zoom := [
		zoom_fondo,
		zoom_fondo,
		zoom_posterior,
		zoom_medio,
		zoom_frontal,
	]

	for indice in capas.size():
		var capa: TextureRect = capas[indice]
		# El zoom crece hacia arriba y los costados, conservando el borde inferior.
		capa.pivot_offset = Vector2(capa.size.x * 0.5, capa.size.y)
		capa.scale = Vector2.ONE * niveles_zoom[indice]


func _actualizar_haz_luz() -> void:
	var pulso := sin(tiempo_ambiente * TAU * frecuencia_haz)
	var pulso_normalizado := (pulso + 1.0) * 0.5
	var opacidad_actual := lerpf(
		maxf(0.0, opacidad_haz - variacion_haz),
		opacidad_haz,
		pulso_normalizado
	)
	haz_luz.modulate = Color(color_haz.r, color_haz.g, color_haz.b, opacidad_actual)


func _obtener_direccion_cursor() -> Vector2:
	var tamano_viewport := get_viewport_rect().size
	if tamano_viewport.x <= 0.0 or tamano_viewport.y <= 0.0:
		return Vector2.ZERO

	var posicion_mouse := get_viewport().get_mouse_position()
	var area_viewport := Rect2(Vector2.ZERO, tamano_viewport)
	if not area_viewport.has_point(posicion_mouse):
		return Vector2.ZERO

	var direccion := (posicion_mouse / tamano_viewport - Vector2(0.5, 0.5)) * 2.0
	direccion.y = 0.0
	return direccion.clamp(Vector2(-1.0, 0.0), Vector2(1.0, 0.0))
