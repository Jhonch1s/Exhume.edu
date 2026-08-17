extends RefCounted
class_name Celda

enum EstadoVisibilidad {
	OCULTO,
	EXPLORADO,
	VISIBLE,
}

var zona: StringName
var altura: int
var caminable: bool
var bloquea_vision: bool = false
var damage: Variant
var visibilidad: int
var familia_fog: StringName = &"terreno"
var coordenada_fog: Vector2i = Vector2i.ZERO
var ocupantes: Array[Object] = []
var contenido: Array[Object]:
	get:
		return ocupantes
var reservas: Array[Object] = []
var interactuables: Array[Object] = []
var items_suelo: Array[Object] = []
var efectos_superficie: Array[Object] = []
var iluminacion: Array[Object] = []

func _init(
	tipo_zona: StringName = &"piso_vacio",
	es_caminable: bool = true,
	altura_inicial: int = 0,
	damage_inicial: Variant = null,
	estado_inicial: int = EstadoVisibilidad.OCULTO
) -> void:
	zona = tipo_zona
	caminable = es_caminable
	altura = altura_inicial
	damage = damage_inicial
	visibilidad = estado_inicial

func tiene_contenido() -> bool:
	return not ocupantes.is_empty()

func tiene_interactuables() -> bool:
	return not interactuables.is_empty()

func esta_reservada() -> bool:
	return not reservas.is_empty()

func tiene_iluminacion() -> bool:
	return not iluminacion.is_empty()

func configurar_fog(familia: StringName, coordenada_atlas: Vector2i) -> void:
	familia_fog = familia
	coordenada_fog = coordenada_atlas
