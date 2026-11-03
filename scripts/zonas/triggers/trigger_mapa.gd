@tool
class_name TriggerMapa
extends Node2D

enum Forma { ZONA, UMBRAL_X, UMBRAL_Y }
enum Frecuencia { UNA_VEZ_POR_PARTIDA, CADA_ENTRADA }

@export var id_trigger: StringName
@export var habilitado: bool = true
@export var frecuencia: Frecuencia = Frecuencia.UNA_VEZ_POR_PARTIDA
@export var forma: Forma = Forma.ZONA
## Región desde la casilla donde se coloca el nodo, hacia +X y +Y.
@export var tamano: Vector2i = Vector2i(2, 2)
## Umbral X: entre esta casilla y +X, extendido hacia +Y. Umbral Y: al revés.
@export_range(1, 64, 1) var longitud_umbral: int = 1
@export var accion: AccionTrigger
@export var mostrar_en_juego: bool = false

var _firma_editor: Array = []


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	queue_redraw()


func _process(_delta: float) -> void:
	var capa := obtener_capa_suelo()
	if capa != null:
		global_position = capa.to_global(capa.map_to_local(obtener_coordenada(capa)))
	var firma := [global_transform, id_trigger, habilitado, forma, tamano, longitud_umbral, accion, accion.validar_configuracion() if accion != null else ""]
	if firma != _firma_editor:
		_firma_editor = firma
		queue_redraw()
		update_configuration_warnings()
		# Actualiza también la advertencia del otro nodo al duplicar/cambiar un ID.
		if capa != null:
			for nodo in capa.get_parent().find_children("*", "TriggerMapa", true, false):
				if nodo != self:
					nodo.update_configuration_warnings()


func obtener_capa_suelo() -> TileMapLayer:
	var ancestro := get_parent()
	while ancestro != null:
		var capa := ancestro.get_node_or_null(^"CapaSuelo") as TileMapLayer
		if capa != null:
			return capa
		ancestro = ancestro.get_parent()
	return null


func obtener_coordenada(capa: TileMapLayer) -> Vector2i:
	return capa.local_to_map(capa.to_local(global_position))


func detecta_paso(origen: Vector2i, destino: Vector2i, ancla: Vector2i) -> bool:
	if origen == destino:
		return false
	if forma == Forma.ZONA:
		var region := Rect2i(ancla, tamano)
		return not region.has_point(origen) and region.has_point(destino)
	# El cruce se evalúa sobre el segmento lógico, también para desplazamientos largos.
	var desde := Vector2(origen - ancla)
	var hasta := Vector2(destino - ancla)
	if forma == Forma.UMBRAL_Y:
		desde = Vector2(desde.y, desde.x)
		hasta = Vector2(hasta.y, hasta.x)
	if (desde.x <= 0.5) == (hasta.x <= 0.5):
		return false
	var avance := (0.5 - desde.x) / (hasta.x - desde.x)
	var lateral := lerpf(desde.y, hasta.y, avance)
	return lateral >= -0.5 and lateral < float(longitud_umbral) - 0.5


func validar_configuracion(capa: TileMapLayer, tablero: TableroGrid = null) -> PackedStringArray:
	var errores := PackedStringArray()
	if id_trigger == &"":
		errores.append("Asigna un ID estable al trigger.")
	if forma not in Forma.values() or frecuencia not in Frecuencia.values():
		errores.append("Forma o frecuencia de trigger inválida.")
	if tamano.x < 1 or tamano.y < 1 or tamano.x > 64 or tamano.y > 64 or longitud_umbral < 1 or longitud_umbral > 64:
		errores.append("El tamaño y la longitud deben estar entre 1 y 64 casillas.")
	if accion == null:
		errores.append("Asigna una acción al trigger.")
	elif not accion.validar_configuracion().is_empty():
		errores.append(accion.validar_configuracion())
	if capa == null:
		errores.append("Coloca el trigger dentro de una zona con CapaSuelo.")
		return errores
	for nodo in capa.get_parent().find_children("*", "TriggerMapa", true, false):
		if nodo != self and id_trigger != &"" and nodo.id_trigger == id_trigger:
			errores.append("ID de trigger duplicado en la zona: %s." % id_trigger)
			break
	if not errores.is_empty():
		return errores
	var ancla := obtener_coordenada(capa)
	var extension := tamano if forma == Forma.ZONA else (
		Vector2i(2, longitud_umbral) if forma == Forma.UMBRAL_X else Vector2i(longitud_umbral, 2)
	)
	for x in extension.x:
		for y in extension.y:
			var coord := ancla + Vector2i(x, y)
			var valida := tablero.es_celda_valida(coord) if tablero != null else capa.get_cell_source_id(coord) >= 0
			if not valida:
				errores.append("El trigger abarca casillas fuera del suelo del mapa.")
				return errores
	return errores


func _get_configuration_warnings() -> PackedStringArray:
	return validar_configuracion(obtener_capa_suelo())


func _draw() -> void:
	if not Engine.is_editor_hint() and not mostrar_en_juego:
		return
	if tamano.x <= 0 or tamano.y <= 0 or longitud_umbral <= 0:
		return
	var capa := obtener_capa_suelo()
	if capa == null or capa.tile_set == null:
		return
	var coord := obtener_coordenada(capa)
	var centro := capa.map_to_local(coord)
	var eje_x := capa.map_to_local(coord + Vector2i.RIGHT) - centro
	var eje_y := capa.map_to_local(coord + Vector2i.DOWN) - centro
	var color := Color(0.2, 0.9, 0.8) if habilitado else Color(0.6, 0.6, 0.6)
	var puntos := PackedVector2Array()
	if forma == Forma.ZONA:
		var esquina := centro - (eje_x + eje_y) * 0.5
		for punto in [esquina, esquina + eje_x * tamano.x, esquina + eje_x * tamano.x + eje_y * tamano.y, esquina + eje_y * tamano.y]:
			puntos.append(to_local(capa.to_global(punto)))
		draw_colored_polygon(puntos, Color(color, 0.15))
		puntos.append(puntos[0])
	else:
		var normal := eje_x if forma == Forma.UMBRAL_X else eje_y
		var lateral := eje_y if forma == Forma.UMBRAL_X else eje_x
		var inicio := centro + (normal - lateral) * 0.5
		puntos.append(to_local(capa.to_global(inicio)))
		puntos.append(to_local(capa.to_global(inicio + lateral * longitud_umbral)))
	draw_polyline(puntos, color, 2.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(0, -12), String(id_trigger), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
