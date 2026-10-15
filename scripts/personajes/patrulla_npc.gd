@tool
class_name PatrullaNPC
extends Path2D

## La curva define puntos del circuito; el movimiento real usa las casillas del tablero.
@export_range(0, 99, 1) var turnos_espera: int = 1

var _puntos: Array[Vector2i] = []
var _indice_siguiente: int = 0
var _espera_restante: int = 0


func _ready() -> void:
	if curve == null:
		curve = Curve2D.new()
		curve.resource_local_to_scene = true
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() or not tiene_ruta():
		return
	var color := Color("#79d6ad")
	for indice in range(curve.point_count):
		var punto := curve.get_point_position(indice)
		var siguiente := curve.get_point_position((indice + 1) % curve.point_count)
		draw_line(punto, siguiente, color, 1.0)
		draw_circle(punto, 3.0, color)
		draw_string(ThemeDB.fallback_font, punto + Vector2(5, -5), str(indice + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)


func _get_configuration_warnings() -> PackedStringArray:
	if curve != null and curve.point_count == 1:
		return ["Dibuja al menos dos puntos distintos en Curve. El circuito se cierra automáticamente."]
	return []


func tiene_ruta() -> bool:
	return curve != null and curve.point_count >= 2


func configurar(tablero: TableroGrid) -> StringName:
	_puntos.clear()
	_indice_siguiente = 0
	_espera_restante = 0
	if not tiene_ruta():
		return &"" if curve == null or curve.point_count == 0 else &"puntos_patrulla_insuficientes"
	if turnos_espera < 0 or turnos_espera > 99:
		return &"espera_patrulla_invalida"
	if tablero == null or tablero.capa_referencia == null:
		return &"tablero_patrulla_invalido"
	var puntos: Array[Vector2i] = []
	for indice in range(curve.point_count):
		var posicion := tablero.capa_referencia.to_local(to_global(curve.get_point_position(indice)))
		var coordenada := tablero.capa_referencia.local_to_map(posicion)
		var celda := tablero.obtener_celda(coordenada)
		if celda == null or not celda.caminable:
			return &"punto_patrulla_fuera_de_suelo"
		if coordenada in puntos:
			return &"puntos_patrulla_repetidos"
		puntos.append(coordenada)
	_puntos = puntos
	return &""


func esta_configurada() -> bool:
	return not _puntos.is_empty()


func obtener_destino() -> Variant:
	return _puntos[_indice_siguiente] if esta_configurada() else null


func esta_esperando() -> bool:
	return _espera_restante > 0


func avanzar_punto() -> void:
	if not esta_configurada():
		return
	_indice_siguiente = (_indice_siguiente + 1) % _puntos.size()
	_espera_restante = turnos_espera


func consumir_turno_espera() -> void:
	_espera_restante = maxi(0, _espera_restante - 1)


func cancelar_espera() -> void:
	_espera_restante = 0


func obtener_estado_persistente() -> Dictionary:
	var puntos: Array[Array] = []
	for punto in _puntos:
		puntos.append([punto.x, punto.y])
	return {
		"puntos": puntos, "turnos_espera": turnos_espera,
		"indice_siguiente": _indice_siguiente, "espera_restante": _espera_restante,
	}


func validar_estado_persistente(estado: Variant) -> StringName:
	if not esta_configurada() or not estado is Dictionary or estado.size() != 4:
		return &"patrulla_guardada_invalida"
	for clave in ["indice_siguiente", "espera_restante", "turnos_espera"]:
		if not _es_entero(estado.get(clave)):
			return &"patrulla_guardada_invalida"
	if (
		estado["indice_siguiente"] < 0 or estado["indice_siguiente"] >= _puntos.size()
		or estado["turnos_espera"] != turnos_espera
		or estado["espera_restante"] < 0 or estado["espera_restante"] > turnos_espera
	):
		return &"patrulla_guardada_invalida"
	var puntos: Variant = estado.get("puntos")
	if not puntos is Array or puntos.size() != _puntos.size():
		return &"ruta_patrulla_guardada_no_coincide"
	for indice in range(puntos.size()):
		var punto: Variant = puntos[indice]
		if (
			not punto is Array or punto.size() != 2
			or not _es_entero(punto[0]) or not _es_entero(punto[1])
		):
			return &"patrulla_guardada_invalida"
		if Vector2i(int(punto[0]), int(punto[1])) != _puntos[indice]:
			return &"ruta_patrulla_guardada_no_coincide"
	return &""


func restaurar_estado_persistente(estado: Dictionary = {}) -> void:
	_indice_siguiente = int(estado.get("indice_siguiente", 0))
	_espera_restante = int(estado.get("espera_restante", 0))


func _es_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_finite(valor) and valor == roundf(valor))
