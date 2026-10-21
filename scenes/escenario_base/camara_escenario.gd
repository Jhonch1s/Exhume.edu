class_name CamaraEscenario
extends Camera2D

const ANCHO_BORDE := 24.0
const VELOCIDAD := 600.0
const MARGEN_MAPA := 64.0
const ZOOM_MINIMO := 1.5
const ZOOM_MAXIMO := 4.5
const FACTOR_ZOOM := 1.2

var libre := false
var desplazando := false
var limites := Rect2()
var _esperar_salida_borde := true


func configurar_limites(zona: Node2D) -> void:
	limites = Rect2()
	var iniciado := false
	for nodo in zona.find_children("*", "TileMapLayer", true, false):
		var capa := nodo as TileMapLayer
		if capa.name == &"CapaOscuridad" or capa.tile_set == null:
			continue
		var tamano := Vector2(capa.tile_set.tile_size)
		for coordenada in capa.get_used_cells():
			var celda := capa.global_transform * Rect2(capa.map_to_local(coordenada) - tamano / 2.0, tamano)
			limites = limites.merge(celda) if iniciado else celda
			iniciado = true
	if iniciado:
		limites = limites.grow(MARGEN_MAPA)


func suspender_bordes() -> void:
	desplazando = false
	# Al cerrar un panel o recentrar, el cursor debe abandonar el borde primero.
	_esperar_salida_borde = true


func centrar(objetivo: Vector2) -> void:
	libre = false
	suspender_bordes()
	global_position = limitar_posicion(objetivo, get_viewport_rect().size)
	force_update_scroll()


func cambiar_zoom(pasos: float, objetivo: Vector2) -> void:
	var nuevo := clampf(zoom.x * pow(FACTOR_ZOOM, pasos), ZOOM_MINIMO, ZOOM_MAXIMO)
	if is_equal_approx(nuevo, zoom.x):
		return
	zoom = Vector2(nuevo, nuevo)
	global_position = limitar_posicion(global_position if libre else objetivo, get_viewport_rect().size)
	suspender_bordes()
	force_update_scroll()


func actualizar(delta: float, objetivo: Vector2, tamano_vista: Vector2, puntero: Vector2, permitir_bordes: bool, bloqueada: bool = false) -> void:
	desplazando = false
	if bloqueada:
		suspender_bordes()
		return
	var direccion := Vector2.ZERO
	if permitir_bordes:
		direccion = direccion_borde(puntero, tamano_vista)
		if direccion == Vector2.ZERO and Rect2(Vector2.ZERO, tamano_vista).has_point(puntero):
			_esperar_salida_borde = false
	else:
		suspender_bordes()
	if _esperar_salida_borde:
		direccion = Vector2.ZERO
	var destino := global_position
	if direccion != Vector2.ZERO:
		libre = true
		desplazando = true
		destino += direccion * VELOCIDAD * delta / zoom
	elif not libre:
		destino = objetivo
	global_position = limitar_posicion(destino, tamano_vista)
	force_update_scroll()


func direccion_borde(puntero: Vector2, tamano_vista: Vector2) -> Vector2:
	if not Rect2(Vector2.ZERO, tamano_vista).has_point(puntero):
		return Vector2.ZERO
	var ancho := minf(ANCHO_BORDE, minf(tamano_vista.x, tamano_vista.y) * 0.05)
	var direccion := Vector2.ZERO
	if puntero.x < ancho:
		direccion.x = -1.0
	elif puntero.x >= tamano_vista.x - ancho:
		direccion.x = 1.0
	if puntero.y < ancho:
		direccion.y = -1.0
	elif puntero.y >= tamano_vista.y - ancho:
		direccion.y = 1.0
	return direccion.normalized()


func limitar_posicion(destino: Vector2, tamano_vista: Vector2) -> Vector2:
	if not limites.has_area():
		return destino
	var semivista := tamano_vista / zoom / 2.0
	for eje in 2:
		if limites.size[eje] <= semivista[eje] * 2.0:
			destino[eje] = limites.get_center()[eje]
		else:
			destino[eje] = clampf(destino[eje], limites.position[eje] + semivista[eje], limites.end[eje] - semivista[eje])
	return destino
