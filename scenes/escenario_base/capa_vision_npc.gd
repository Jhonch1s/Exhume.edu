class_name CapaVisionNPC
extends Node2D

const COLOR_HOSTIL := Color(0.95, 0.18, 0.16, 0.30)
const COLOR_NEUTRAL := Color(0.65, 0.65, 0.65, 0.27)
const COLOR_AMISTOSO := Color(0.18, 0.85, 0.30, 0.30)

var tablero: TableroGrid
var validador: ValidadorEspacialTablero
var ficha: Ficha
var vision_jugador: FOVManager
var campos: Array[Dictionary] = []
var _firma: Array = []


func configurar(
	tablero_actual: TableroGrid, validador_actual: ValidadorEspacialTablero,
	ficha_actual: Ficha, vision_actual: FOVManager
) -> void:
	tablero = tablero_actual
	validador = validador_actual
	ficha = ficha_actual
	vision_jugador = vision_actual
	visible = false


func alternar(gestor: GestorRondas) -> void:
	visible = not visible
	if visible:
		actualizar(gestor, true)
	else:
		campos.clear()
		_firma.clear()
		queue_redraw()


func actualizar(gestor: GestorRondas, forzar: bool = false) -> void:
	if not visible or tablero == null or validador == null or ficha == null or vision_jugador == null:
		return
	var ids := tablero.interactuables_por_id.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	var firma: Array = [vision_jugador.revision_vision, ficha.coordenada_mapa]
	for id in ids:
		var npc := tablero.obtener_interactuable(id) as PersonajeNPC
		if npc == null:
			continue
		var perfil := npc.obtener_definicion_personaje()
		var celda := tablero.obtener_celda(npc.coordenada_mapa)
		firma.append([
			id, npc.coordenada_mapa, npc.vida_actual,
			perfil.radio_agro if perfil != null else 0,
			celda.visibilidad if celda != null else Celda.EstadoVisibilidad.OCULTO,
			_color_para(npc, gestor),
		])
	if not forzar and firma == _firma:
		return
	_firma = firma
	campos.clear()
	for id in ids:
		var npc := tablero.obtener_interactuable(id) as PersonajeNPC
		if npc == null or not npc.puede_actuar():
			continue
		var perfil := npc.obtener_definicion_personaje()
		var origen := tablero.obtener_celda(npc.coordenada_mapa)
		if perfil == null or perfil.radio_agro <= 0 or origen == null or origen.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
			continue
		var radio := perfil.radio_agro
		var color := _color_para(npc, gestor)
		for x in range(npc.coordenada_mapa.x - radio, npc.coordenada_mapa.x + radio + 1):
			for y in range(npc.coordenada_mapa.y - radio, npc.coordenada_mapa.y + radio + 1):
				var coord := Vector2i(x, y)
				var celda := tablero.obtener_celda(coord)
				if celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE and npc.puede_ver_coordenada(coord, validador):
					campos.append({"npc_id": id, "coordenada": coord, "color": color})
	queue_redraw()


func _color_para(npc: PersonajeNPC, gestor: GestorRondas) -> Color:
	if gestor != null:
		match gestor.obtener_bando(npc):
			GestorRondas.Bando.OPONENTE:
				return COLOR_HOSTIL
			GestorRondas.Bando.JUGADOR:
				return COLOR_AMISTOSO
	match npc.obtener_actitud_hacia_jugador():
		DefinicionPersonaje.ActitudInicialJugador.HOSTIL:
			return COLOR_HOSTIL
		DefinicionPersonaje.ActitudInicialJugador.AMISTOSA:
			return COLOR_AMISTOSO
	return COLOR_NEUTRAL


func _draw() -> void:
	if tablero == null or tablero.capa_referencia == null or tablero.capa_referencia.tile_set == null:
		return
	var mitad := Vector2(tablero.capa_referencia.tile_set.tile_size) / 2.0
	for campo in campos:
		var centro := to_local(tablero.capa_referencia.to_global(
			tablero.capa_referencia.map_to_local(campo["coordenada"])
		))
		draw_colored_polygon(PackedVector2Array([
			centro + Vector2(0, -mitad.y), centro + Vector2(mitad.x, 0),
			centro + Vector2(0, mitad.y), centro + Vector2(-mitad.x, 0),
		]), campo["color"])
