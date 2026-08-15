extends Node
class_name TableroGrid

var datos: Dictionary[Vector2i, Celda] = {}

# Puntos de extension para trampas, encuentros, puertas y otros triggers.
signal celda_reservada(coord: Vector2i, contenido: Object)
signal reserva_cancelada(coord: Vector2i, contenido: Object)
signal reserva_confirmada(coord: Vector2i, contenido: Object)
signal celda_ocupada(coord: Vector2i, contenido: Object)
signal celda_desocupada(coord: Vector2i, contenido: Object)

func generar_desde_zona(zona: Node2D) -> void:
	datos.clear()
	var _capa_suelo: TileMapLayer = zona.get_node_or_null("CapaSuelo")
	var _capa_agua: TileMapLayer = zona.get_node_or_null("CapaAgua")
	var _capa_lava: TileMapLayer = zona.get_node_or_null("CapaLava")
	var _capa_luces: TileMapLayer = zona.get_node_or_null("CapaLuces")
	var _capa_paredes: TileMapLayer = zona.get_node_or_null("CapaParedes")
	var _capa_columnas: TileMapLayer = zona.get_node_or_null("CapaColumnas")
	var _capa_deco_nocaminable: TileMapLayer = zona.get_node_or_null("CapaDecoracionNoCaminable")
	var _capa_decoracion: TileMapLayer = zona.get_node_or_null("CapaDecoracion")
	
	if not _capa_suelo:
		print("Error: No se encontró CapaSuelo")
		return
		
	# 1. Escaneamos Suelo
	var _celdas_suelo = _capa_suelo.get_used_cells()
	for coordenada in _celdas_suelo:
		datos[coordenada] = _crear_celda_desde_tile(_capa_suelo, coordenada, &"piso_vacio")

	# 2. Escaneamos Agua
	if _capa_agua:
		var _celdas_agua = _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			var celda_agua := _crear_celda_desde_tile(_capa_agua, coordenada, &"agua")
			# La capa define el comportamiento del líquido, independientemente de su textura.
			celda_agua.caminable = false
			datos[coordenada] = celda_agua

	# 3. Escaneamos Lava
	if _capa_lava:
		var _celdas_lava = _capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			var celda_lava := _crear_celda_desde_tile(_capa_lava, coordenada, &"lava")
			celda_lava.damage = {
				"tipo": "fuego",
				"turnos": 5,
				"damage": 2
			}
			datos[coordenada] = celda_lava

	# 4. Escaneamos Paredes
	if _capa_paredes:
		var _celdas_paredes = _capa_paredes.get_used_cells()
		for coordenada in _celdas_paredes:
			datos[coordenada] = _crear_celda_desde_tile(_capa_paredes, coordenada, &"pared")
	
	# 5. Escaneamos columnas: son altas y bloquean tanto el paso como la visión.
	if _capa_columnas:
		for coordenada in _capa_columnas.get_used_cells():
			datos[coordenada] = _crear_celda_desde_tile(_capa_columnas, coordenada, &"columna")

	# 6. Escaneamos Decoraciones No Caminables
	if _capa_deco_nocaminable:
		var _celdas_decoracion = _capa_deco_nocaminable.get_used_cells()
		for coord in _celdas_decoracion:
			var celda_decoracion := _crear_celda_desde_tile(
				_capa_deco_nocaminable,
				coord,
				&"decoracion"
			)
			if datos.has(coord):
				datos[coord].caminable = datos[coord].caminable and celda_decoracion.caminable
				datos[coord].bloquea_vision = (
					datos[coord].bloquea_vision or celda_decoracion.bloquea_vision
				)
				# No degradamos una pared o columna si las capas se solapan.
				if celda_decoracion.altura > datos[coord].altura:
					datos[coord].altura = celda_decoracion.altura
					datos[coord].zona = &"decoracion"
					datos[coord].configurar_fog(
						celda_decoracion.familia_fog,
						celda_decoracion.coordenada_fog
					)
			else:
				datos[coord] = celda_decoracion

	# 7. Las decoraciones planas pueden modificar propiedades sin sustituir el terreno.
	if _capa_decoracion:
		for coord in _capa_decoracion.get_used_cells():
			if not datos.has(coord):
				continue
			var celda_decoracion := _crear_celda_desde_tile(
				_capa_decoracion,
				coord,
				&"decoracion"
			)
			datos[coord].caminable = datos[coord].caminable and celda_decoracion.caminable
			datos[coord].bloquea_vision = (
				datos[coord].bloquea_vision or celda_decoracion.bloquea_vision
			)

	# 8. Escaneo de luces del mapa.
	if _capa_luces:
		var _celdas_luces = _capa_luces.get_used_cells()
		for coord in _celdas_luces:
			var tile_data := _capa_luces.get_cell_tile_data(coord)
			var info_luz := _obtener_info_luz_desde_tile(tile_data)
			if not info_luz.is_empty():
				var propiedades_luz := _crear_celda_desde_tile(_capa_luces, coord, &"luz")
				info_luz["aplicar_mascara_fog"] = propiedades_luz.familia_fog == &"luz"
				info_luz["altura_fog"] = propiedades_luz.altura
				info_luz["coordenada_fog"] = propiedades_luz.coordenada_fog
				if datos.has(coord):
					datos[coord].caminable = datos[coord].caminable and propiedades_luz.caminable
					datos[coord].bloquea_vision = (
						datos[coord].bloquea_vision or propiedades_luz.bloquea_vision
					)
				registrar_luz(coord, info_luz)


# --- UTILIDADES ---

func _crear_celda_desde_tile(
	capa: TileMapLayer,
	coord: Vector2i,
	zona: StringName
) -> Celda:
	var tile_data := capa.get_cell_tile_data(coord)
	if tile_data == null:
		push_warning("No se encontraron datos para el tile %s en %s" % [coord, capa.name])
		return Celda.new(zona)

	var celda := Celda.new(
		zona,
		bool(tile_data.get_custom_data(&"caminable")),
		int(tile_data.get_custom_data(&"altura"))
	)
	celda.bloquea_vision = bool(tile_data.get_custom_data(&"bloquea_vision"))
	var familia := StringName(tile_data.get_custom_data(&"familia_fog"))
	if familia == &"":
		familia = &"terreno"
	celda.configurar_fog(
		familia,
		Vector2i(
			int(tile_data.get_custom_data(&"fog_atlas_x")),
			int(tile_data.get_custom_data(&"fog_atlas_y"))
		)
	)
	return celda

func es_celda_valida(coord: Vector2i) -> bool:
	return datos.has(coord)

func es_caminable(coord: Vector2i) -> bool:
	return datos.has(coord) and datos[coord].caminable

func puede_entrar(coord: Vector2i, contenido: Object = null) -> bool:
	if not es_caminable(coord):
		return false
	var celda: Celda = datos[coord]
	for ocupante in celda.contenido:
		if ocupante != contenido:
			return false
	for reserva in celda.reservas:
		if reserva != contenido:
			return false
	return true

func obtener_celda(coord: Vector2i) -> Celda:
	return datos.get(coord) as Celda

func ocupar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido not in datos[coord].contenido:
			datos[coord].contenido.append(contenido)
			celda_ocupada.emit(coord, contenido)

func liberar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido != null:
			if contenido in datos[coord].contenido:
				datos[coord].contenido.erase(contenido)
				celda_desocupada.emit(coord, contenido)
		else:
			for ocupante in datos[coord].contenido.duplicate():
				celda_desocupada.emit(coord, ocupante)
			datos[coord].contenido.clear()

func reservar_celda(coord: Vector2i, contenido: Object) -> bool:
	if contenido == null or not puede_entrar(coord, contenido):
		return false
	if contenido not in datos[coord].reservas:
		datos[coord].reservas.append(contenido)
		celda_reservada.emit(coord, contenido)
	return true

func cancelar_reserva(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord) and contenido in datos[coord].reservas:
		datos[coord].reservas.erase(contenido)
		reserva_cancelada.emit(coord, contenido)

func confirmar_movimiento(origen: Vector2i, destino: Vector2i, contenido: Object) -> bool:
	if not datos.has(destino) or contenido not in datos[destino].reservas:
		return false
	datos[destino].reservas.erase(contenido)
	reserva_confirmada.emit(destino, contenido)
	liberar_celda(origen, contenido)
	ocupar_celda(destino, contenido)
	return true

func registrar_luz(coord: Vector2i, info_luz: Dictionary) -> void:
	if datos.has(coord):
		if info_luz not in datos[coord].iluminacion:
			datos[coord].iluminacion.append(info_luz)
		if info_luz.get("aplicar_mascara_fog", false) and datos[coord].altura < 2:
			datos[coord].altura = maxi(datos[coord].altura, info_luz.get("altura_fog", 1))
			datos[coord].configurar_fog(&"luz", info_luz.get("coordenada_fog", Vector2i.ZERO))

func eliminar_luz(coord: Vector2i, info_luz: Dictionary) -> void:
	if datos.has(coord):
		datos[coord].iluminacion.erase(info_luz)

func obtener_luces_visibles() -> Array:
	var luces: Array = []
	for coord in datos:
		for luz in datos[coord].iluminacion:
			if luz["encendida"]:
				luces.append({
					"coord": coord,
					"info": luz
				})
	return luces

func _obtener_info_luz_desde_tile(tile_data: TileData) -> Dictionary:
	if tile_data == null:
		return {}

	var tipo := StringName(tile_data.get_custom_data(&"tipo_luz"))
	if tipo == &"":
		return {}

	return {
		"tipo": tipo,
		"variante": StringName(tile_data.get_custom_data(&"variante_luz")),
		"encendida": bool(tile_data.get_custom_data(&"encendida")),
		"radio_luz": int(tile_data.get_custom_data(&"radio_luz")),
		"radio_penumbra": int(tile_data.get_custom_data(&"radio_penumbra")),
		"atraviesa_muros": bool(tile_data.get_custom_data(&"atraviesa_muros"))
	}
