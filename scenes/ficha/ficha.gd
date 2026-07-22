extends Node2D
class_name Ficha

var coordenada_mapa: Vector2i = Vector2i(0,0)

var capa_referencia: TileMapLayer = null

func inicializar (coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	capa_referencia = capa
	mover_a_coordenada_instantaneo(coordenada_inicial)
	
func mover_a_coordenada_instantaneo(nueva_coordeanada: Vector2i) -> void:
	coordenada_mapa = nueva_coordeanada
	
	if capa_referencia:
		global_position =capa_referencia.map_to_local(coordenada_mapa)
