extends Node
class_name TableroGrid

var datos: Dictionary={}

func generar_desde_zona(zona: Node2D) -> void:
	datos.clear()
	var _capa_suelo:TileMapLayer = zona.get_node("CapaSuelo")
	var _capa_agua:TileMapLayer = zona.get_node("CapaAgua")
	var _capa_lava:TileMapLayer = zona.get_node("CapaLava")
	
	if (not _capa_suelo):
		print("Todo mal gato")
		return
		
	# escaneamos las celdas que usa cada capa
	var _celdas_suelo = _capa_suelo.get_used_cells()
	
	for coordenada in _celdas_suelo:
		datos[coordenada]={
			"zona":"piso_vacio",
			"contenido": null,
			"caminable": true,
			"damage": null
		}
		
	if _capa_agua:
		var _celdas_agua= _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			if datos.has(coordenada):
				datos[coordenada]={
					"zona":"agua",
					"contenido":[],
					"caminable":false,
					"damage":null
				}
				
	if _capa_lava:
		var _celdas_lava=_capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			if datos.has(coordenada):
				datos[coordenada]={
					"zona":"lava",
					"contenido":null,
					"caminable":true,
					"damage":{
						"tipo": "fuego",
						"turnos": 5,
						"damage": 2
					}
				}

#utilidades
func es_celda_valida(coord: Vector2i) -> bool:
	return datos.has(coord)

func es_caminable(coord: Vector2i) -> bool:
	return datos.has(coord) and datos[coord]["caminable"]

func obtener_datos_celda(coord: Vector2i) -> Dictionary:
	return datos.get(coord, {})

func ocupar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		datos[coord]["contenido"] = contenido

func liberar_celda(coord: Vector2i) -> void:
	if datos.has(coord):
		datos[coord]["contenido"] = null
