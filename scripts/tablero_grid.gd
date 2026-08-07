extends Node
class_name TableroGrid

var datos: Dictionary[Vector2i, Celda] = {}

func generar_desde_zona(zona: Node2D) -> void:
	datos.clear()
	var _capa_suelo: TileMapLayer = zona.get_node_or_null("CapaSuelo")
	var _capa_agua: TileMapLayer = zona.get_node_or_null("CapaAgua")
	var _capa_lava: TileMapLayer = zona.get_node_or_null("CapaLava")
	var _capa_luces: TileMapLayer = zona.get_node_or_null("CapaLuces")
	var _capa_paredes: TileMapLayer = zona.get_node_or_null("CapaParedes")
	var _capa_columnas: TileMapLayer = zona.get_node_or_null("CapaColumnas")
	var _capa_deco_nocaminable: TileMapLayer = zona.get_node_or_null("CapaDecoracionNoCaminable")
	
	if not _capa_suelo:
		print("Error: No se encontró CapaSuelo")
		return
		
	# 1. Escaneamos Suelo
	var _celdas_suelo = _capa_suelo.get_used_cells()
	for coordenada in _celdas_suelo:
		datos[coordenada] = Celda.new(&"piso_vacio", true)

	# 2. Escaneamos Agua
	if _capa_agua:
		var _celdas_agua = _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			datos[coordenada] = Celda.new(&"agua", false)

	# 3. Escaneamos Lava
	if _capa_lava:
		var _celdas_lava = _capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			datos[coordenada] = Celda.new(
				&"lava",
				true,
				0,
				{
					"tipo": "fuego",
					"turnos": 5,
					"damage": 2
				}
			)

	# 4. Escaneamos Paredes
	if _capa_paredes:
		var _celdas_paredes = _capa_paredes.get_used_cells()
		for coordenada in _celdas_paredes:
			var celda_pared := Celda.new(&"pared", false, 2)
			celda_pared.bloquea_vision = true
			celda_pared.configurar_fog(&"pared", _capa_paredes.get_cell_atlas_coords(coordenada))
			datos[coordenada] = celda_pared
	
	# 5. Escaneamos columnas: son altas y bloquean el paso, pero dejan pasar la luz.
	if _capa_columnas:
		for coordenada in _capa_columnas.get_used_cells():
			var celda_columna := Celda.new(&"columna", false, 2)
			celda_columna.bloquea_vision = false
			celda_columna.configurar_fog(&"columna", _capa_columnas.get_cell_atlas_coords(coordenada))
			datos[coordenada] = celda_columna

	# 6. Escaneamos Decoraciones No Caminables
	if _capa_deco_nocaminable:
		var _celdas_decoracion = _capa_deco_nocaminable.get_used_cells()
		for coord in _celdas_decoracion:
			if datos.has(coord):
				datos[coord].caminable = false
				# No degradamos una pared o columna si las capas se solapan.
				if datos[coord].altura < 2:
					datos[coord].altura = 1
					datos[coord].zona = &"decoracion"
					datos[coord].configurar_fog(
						&"estalagmita",
						_capa_deco_nocaminable.get_cell_atlas_coords(coord)
					)
			else:
				var celda_decoracion := Celda.new(&"decoracion", false, 1)
				celda_decoracion.configurar_fog(
					&"estalagmita",
					_capa_deco_nocaminable.get_cell_atlas_coords(coord)
				)
				datos[coord] = celda_decoracion

	# 7. Escaneo de luces del mapa.
	if _capa_luces:
		var _celdas_luces = _capa_luces.get_used_cells()
		for coord in _celdas_luces:
			var atlas_coords = _capa_luces.get_cell_atlas_coords(coord)
			var info_luz = _obtener_info_luz_desde_tile(atlas_coords)
			if not info_luz.is_empty():
				registrar_luz(coord, info_luz)


# --- UTILIDADES ---

func es_celda_valida(coord: Vector2i) -> bool:
	return datos.has(coord)

func es_caminable(coord: Vector2i) -> bool:
	return datos.has(coord) and datos[coord].caminable

func obtener_celda(coord: Vector2i) -> Celda:
	return datos.get(coord) as Celda

func ocupar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido not in datos[coord].contenido:
			datos[coord].contenido.append(contenido)

func liberar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido != null:
			datos[coord].contenido.erase(contenido)
		else:
			datos[coord].contenido.clear()

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

func _obtener_info_luz_desde_tile(atlas_coords: Vector2i) -> Dictionary:
	match atlas_coords:
		Vector2i(0, 0): # Antorcha pared izq prendida
			return {
				"tipo": "antorcha",
				"variante": "pared_izq",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 2,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": false,
				"coordenada_fog": Vector2i(2, 0)
			}
		Vector2i(1, 0): # Antorcha pared der prendida
			return {
				"tipo": "antorcha",
				"variante": "pared_der",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 2,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": false,
				"coordenada_fog": Vector2i(3, 0)
			}
		Vector2i(2, 0): # Antorcha pared izq apagada
			return {
				"tipo": "antorcha",
				"variante": "pared_izq",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": false,
				"coordenada_fog": Vector2i(2, 0)
			}
		Vector2i(3, 0): # Antorcha pared der apagada
			return {
				"tipo": "antorcha",
				"variante": "pared_der",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": false,
				"coordenada_fog": Vector2i(3, 0)
			}
		Vector2i(0, 3): # Fogata simple apagada
			return {
				"tipo": "fogata",
				"variante": "fogata_apagada",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": true,
				"altura_fog": 1,
				"coordenada_fog": Vector2i(0, 3)
			}
		Vector2i(1, 3): # Fogata simple encendida
			return {
				"tipo": "fogata",
				"variante": "fogata_encendida",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 3,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": true,
				"altura_fog": 1,
				"coordenada_fog": Vector2i(0, 3)
			}
		Vector2i(0, 6): # Antorcha pie simple encendida
			return {
				"tipo": "antorcha_pie",
				"variante": "antorcha_pie_encendida",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 2,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": true,
				"altura_fog": 1,
				"coordenada_fog": Vector2i(1, 6)
			}
		Vector2i(1, 6): # Antorcha pie simple apagada
			return {
				"tipo": "antorcha_pie",
				"variante": "antorcha_pie_apagada",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false,
				"aplicar_mascara_fog": true,
				"altura_fog": 1,
				"coordenada_fog": Vector2i(1, 6)
			}
		_:
			return {}
