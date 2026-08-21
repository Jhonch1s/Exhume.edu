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
var coste_movimiento_adicional: int = 0
var penalizacion_peligro_ruta: float = 0.0
var visibilidad: int
var familia_fog: StringName = &"terreno"
var coordenada_fog: Vector2i = Vector2i.ZERO
var reaccion_terreno: Object
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
	estado_inicial: int = EstadoVisibilidad.OCULTO
) -> void:
	zona = tipo_zona
	caminable = es_caminable
	altura = altura_inicial
	visibilidad = estado_inicial

func tiene_contenido() -> bool:
	return not ocupantes.is_empty()

func tiene_interactuables() -> bool:
	return not interactuables.is_empty()

func esta_reservada() -> bool:
	return not reservas.is_empty()

func tiene_iluminacion() -> bool:
	return not iluminacion.is_empty()

func calcular_coste_movimiento(actor: Object = null) -> int:
	var coste := 1 + maxi(0, coste_movimiento_adicional)
	var aportes_por_familia: Dictionary[StringName, int] = {}
	for efecto in efectos_superficie.duplicate():
		if efecto == null or not is_instance_valid(efecto):
			continue
		if not efecto.has_method(&"obtener_coste_movimiento_adicional"):
			continue
		var aporte: Variant = efecto.call(&"obtener_coste_movimiento_adicional", actor)
		if aporte is int and aporte >= 0:
			var familia := StringName("instancia_%d" % efecto.get_instance_id())
			if efecto.has_method(&"obtener_familia_superficie"):
				var familia_declarada: Variant = efecto.call(&"obtener_familia_superficie")
				if familia_declarada is StringName and familia_declarada != &"":
					familia = familia_declarada
			aportes_por_familia[familia] = maxi(
				aportes_por_familia.get(familia, 0),
				aporte
			)
	for aporte in aportes_por_familia.values():
		coste += aporte
	return coste

func calcular_peso_ruta(actor: Object = null) -> float:
	return float(calcular_coste_movimiento(actor)) + maxf(0.0, penalizacion_peligro_ruta)

func es_caminable_efectiva() -> bool:
	if not caminable:
		return false
	for interactuable in interactuables.duplicate():
		if (
			interactuable == null
			or not is_instance_valid(interactuable)
			or not interactuable.has_method(&"permite_caminar_interactuable")
		):
			continue
		var permite: Variant = interactuable.call(&"permite_caminar_interactuable")
		if permite is bool and not permite:
			return false
	return true

func bloquea_vision_efectiva() -> bool:
	if bloquea_vision:
		return true
	for interactuable in interactuables.duplicate():
		if (
			interactuable == null
			or not is_instance_valid(interactuable)
			or not interactuable.has_method(&"bloquea_vision_interactuable")
		):
			continue
		var bloquea_interactuable: Variant = interactuable.call(
			&"bloquea_vision_interactuable"
		)
		if bloquea_interactuable is bool and bloquea_interactuable:
			return true
	for efecto in efectos_superficie.duplicate():
		if (
			efecto == null
			or not is_instance_valid(efecto)
			or not efecto.has_method(&"bloquea_vision_superficie")
		):
			continue
		var bloquea: Variant = efecto.call(&"bloquea_vision_superficie")
		if bloquea is bool and bloquea:
			return true
	return false

func bloquea_proyectiles_efectiva() -> bool:
	if altura >= 2:
		return true
	for interactuable in interactuables.duplicate():
		if (
			interactuable == null
			or not is_instance_valid(interactuable)
			or not interactuable.has_method(&"bloquea_proyectiles_interactuable")
		):
			continue
		var bloquea: Variant = interactuable.call(&"bloquea_proyectiles_interactuable")
		if bloquea is bool and bloquea:
			return true
	return false

func configurar_fog(familia: StringName, coordenada_atlas: Vector2i) -> void:
	familia_fog = familia
	coordenada_fog = coordenada_atlas
