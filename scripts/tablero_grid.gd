extends Node
class_name TableroGrid

var datos: Dictionary = {}

func generar_desde_zona(zona: Node2D) -> void:
	datos.clear()
	var _capa_suelo: TileMapLayer = zona.get_node_or_null("CapaSuelo")
	var _capa_agua: TileMapLayer = zona.get_node_or_null("CapaAgua")
	var _capa_lava: TileMapLayer = zona.get_node_or_null("CapaLava")
	var _capa_luces: TileMapLayer = zona.get_node_or_null("CapaLuces")
	var _capa_paredes: TileMapLayer = zona.get_node_or_null("CapaParedes")
	var _capa_deco_nocaminable: TileMapLayer = zona.get_node_or_null("CapaDecoracionNoCaminable")
	
	if not _capa_suelo:
		print("Error: No se encontró CapaSuelo")
		return
		
	# 1. Escaneamos Suelo
	var _celdas_suelo = _capa_suelo.get_used_cells()
	for coordenada in _celdas_suelo:
		datos[coordenada] = {
			"zona": "piso_vacio",
			"altura": 0,
			"contenido": [],
			"caminable": true,
			"damage": null,
			"visibilidad": null,
			"iluminacion": []
		}

	# 2. Escaneamos Agua
	if _capa_agua:
		var _celdas_agua = _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			datos[coordenada] = {
				"zona": "agua",
				"altura": 0,
				"contenido": [],
				"caminable": false,
				"damage": null,
				"visibilidad": null,
				"iluminacion": []
			}

	# 3. Escaneamos Lava
	if _capa_lava:
		var _celdas_lava = _capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			datos[coordenada] = {
				"zona": "lava",
				"altura": 0,
				"contenido": [],
				"caminable": true,
				"damage": {
					"tipo": "fuego",
					"turnos": 5,
					"damage": 2
				},
				"visibilidad": null,
				"iluminacion": []
			}

	# 4. Escaneamos Paredes
	if _capa_paredes:
		var _celdas_paredes = _capa_paredes.get_used_cells()
		for coordenada in _celdas_paredes:
			datos[coordenada] = {
				"zona": "pared",
				"altura": 2,
				"contenido": [],
				"caminable": false,
				"damage": null,
				"visibilidad": null,
				"iluminacion": []
			}
	
	# 5. Escaneamos Decoraciones No Caminables
	if _capa_deco_nocaminable:
		var _celdas_decoracion = _capa_deco_nocaminable.get_used_cells()
		for coord in _celdas_decoracion:
			if datos.has(coord):
				datos[coord]["caminable"] = false
				datos[coord]["altura"] = 1
				datos[coord]["zona"] = "decoracion"
			else:
				datos[coord] = {
					"caminable": false,
					"zona": "decoracion",
					"altura": 1,
					"visibilidad": "OCULTO",
					"contenido": [],
					"damage": null,
					"iluminacion": []
				}

	# 6. ESCANEO DE LUCES DEL MAPA (Agregado)
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
	return datos.has(coord) and datos[coord]["caminable"]

func obtener_datos_celda(coord: Vector2i) -> Dictionary:
	return datos.get(coord, {})

func ocupar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido not in datos[coord]["contenido"]:
			datos[coord]["contenido"].append(contenido)

func liberar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido != null:
			datos[coord]["contenido"].erase(contenido)
		else:
			datos[coord]["contenido"].clear()

func registrar_luz(coord: Vector2i, info_luz: Dictionary) -> void:
	if datos.has(coord):
		if info_luz not in datos[coord]["iluminacion"]:
			datos[coord]["iluminacion"].append(info_luz)

func eliminar_luz(coord: Vector2i, info_luz: Dictionary) -> void:
	if datos.has(coord):
		datos[coord]["iluminacion"].erase(info_luz)

func obtener_luces_visibles() -> Array:
	var luces: Array = []
	for coord in datos:
		for luz in datos[coord]["iluminacion"]:
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
				"atraviesa_muros": false
			}
		Vector2i(1, 0): # Antorcha pared der prendida
			return {
				"tipo": "antorcha",
				"variante": "pared_der",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 2,
				"atraviesa_muros": false
			}
		Vector2i(2, 0): # Antorcha pared izq apagada
			return {
				"tipo": "antorcha",
				"variante": "pared_izq",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false
			}
		Vector2i(3, 0): # Antorcha pared der apagada
			return {
				"tipo": "antorcha",
				"variante": "pared_der",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false
			}
		Vector2i(0, 1): # Fogata simple apagada
			return {
				"tipo": "fogata",
				"variante": "fogata_apagada",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false
			}
		Vector2i(1, 1): # Fogata simple encendida
			return {
				"tipo": "fogata",
				"variante": "fogata_encendida",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 3,
				"atraviesa_muros": false
			}
		Vector2i(0, 2): # Antorcha pie simple encendida
			return {
				"tipo": "antorcha_pie",
				"variante": "antorcha_pie_encendida",
				"encendida": true,
				"radio_luz": 1,
				"radio_penumbra": 2,
				"atraviesa_muros": false
			}
		Vector2i(1, 2): # Antorcha pie simple apagada
			return {
				"tipo": "antorcha_pie",
				"variante": "antorcha_pie_apagada",
				"encendida": false,
				"radio_luz": 0,
				"radio_penumbra": 0,
				"atraviesa_muros": false
			}
		_:
			return {}
