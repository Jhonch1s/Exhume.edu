extends Node
class_name TableroGrid

var datos: Dictionary={}

func generar_desde_zona(zona: Node2D) -> void:
	datos.clear()
	var _capa_suelo:TileMapLayer = zona.get_node("CapaSuelo")
	var _capa_agua:TileMapLayer = zona.get_node("CapaAgua")
	var _capa_lava:TileMapLayer = zona.get_node("CapaLava")
	var _capa_luces:TileMapLayer = zona.get_node("CapaLuces")
	var _capa_paredes: TileMapLayer = zona.get_node("CapaParedes")
	
	if (not _capa_suelo):
		print("Todo mal gato")
		return
		
	# escaneamos las celdas que usa cada capa
	var _celdas_suelo = _capa_suelo.get_used_cells()
	
	for coordenada in _celdas_suelo:
		datos[coordenada]={
			"zona":"piso_vacio",
			"contenido": [],
			"caminable": true,
			"damage": null,
			"visibilidad": null,
			"iluminacion":[]
		}
		
	if _capa_agua:
		var _celdas_agua= _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			datos[coordenada]={
				"zona":"agua",
				"contenido":[],
				"caminable":false,
				"damage":null,
				"visibilidad": null,
				"iluminacion":[]
			}
			
	if _capa_lava:
		var _celdas_lava=_capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			datos[coordenada]={
				"zona":"lava",
				"contenido":[],
				"caminable":true,
				"damage":{
					"tipo": "fuego",
					"turnos": 5,
					"damage": 2
				},
				"visibilidad": null,
				"iluminacion":[]
			}
	if _capa_paredes:
		var _celdas_paredes = _capa_paredes.get_used_cells()
		for coordenada in _celdas_paredes:
			datos[coordenada] = {
				"zona": "pared",
				"contenido": [],
				"caminable": false,
				"damage": null,
				"visibilidad": null,
				"iluminacion": []
			}

	if _capa_luces:
			var _celdas_luces = _capa_luces.get_used_cells()
			for coordenada in _celdas_luces:
				# Si una  luz está en el vacío, creamos la celda base
				if not datos.has(coordenada):
					datos[coordenada] = {
						"zona": "piso_vacio",
						"contenido": [],
						"caminable": true,
						"damage": null,
						"visibilidad": null,
						"iluminacion": []
					}
					
				var tile_coords = _capa_luces.get_cell_atlas_coords(coordenada)
				var info_luz = _obtener_info_luz_desde_tile(tile_coords)
				if info_luz and not info_luz.is_empty():
					datos[coordenada]["iluminacion"].append(info_luz)
	


#utilidades
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

func registrar_luz (coord: Vector2i, info_luz: Dictionary) -> void:
	if datos.has(coord):
		if info_luz not in datos[coord]["iluminacion"]:
			datos[coord]["iluminacion"].append(info_luz)

func eliminar_luz(coord: Vector2i, info_luz: Dictionary) -> void:
	if datos.has(coord):
		datos[coord]["iluminacion"].erase(info_luz)

func obtener_luces_visibles()-> Array:
	var luces: Array=[]
	for coord in datos:
		for luz in datos[coord]["iluminacion"]:
			if luz["encendida"]:
				luces.append({
					"coord":coord,
					"info": luz
				})
	return luces

func _obtener_info_luz_desde_tile(atlas_coords: Vector2i) -> Dictionary:
	# Mapear coordenadas del tile a tipo de luz
	match atlas_coords:
		Vector2i(0, 0):  # antorcha pared izq prendida
			return {
				"tipo": "antorcha",
				"variante": "pared_izq",
				"encendida": true,
				"radio": 0.10,
				"intensidad": 1.3,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(1, 0):  # antorcha pared der prendida
			return {
				"tipo": "antorcha",
				"variante": "pared_der",
				"encendida": true,
				"radio": 0.10,
				"intensidad": 1.3,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(2, 0):  # antorcha pared izq apagada
			return {
				"tipo": "antorcha",
				"variante": "pared_izq",
				"encendida": false,
				"radio": 0.0,
				"intensidad": 0.0,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(3, 0):  # antorcha pared izq apagada
			return {
				"tipo": "antorcha",
				"variante": "pared_der",
				"encendida": false,
				"radio": 0.0,
				"intensidad": 0.0,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(0, 1):  # fogata simple apagada
			return {
				"tipo": "fogata",
				"variante": "fogata_apagada",
				"encendida": false,
				"radio": 0.0,
				"intensidad": 0.0,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(1, 1):  # fogata simple encendida
			return {
				"tipo": "fogata",
				"variante": "fogata_encendida",
				"encendida": true,
				"radio": 0.10,
				"intensidad": 1.3,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(0, 2): # antorcha pie simple encendida
			return {
				"tipo": "antorcha_pie",
				"variante": "antorcha_pie_encendida",
				"encendida": true,
				"radio": 0.10,
				"intensidad": 1.3,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		Vector2i(1, 2):  # antorcha pie simple apagada
			return {
				"tipo": "antorcha_pie",
				"variante": "antorcha_pie_apagada",
				"encendida": false,
				"radio": 0.0,
				"intensidad": 0.0,
				"color": Color(1, 0.6, 0.2),
				"offset_luz": Vector2(0, -32)
			}
		# ... agregar más tiles según tu atlas
		_:
			return {}
