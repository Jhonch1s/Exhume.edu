@tool
extends Node2D

@export var huella_celdas: Array[Vector2i] = [Vector2i.ZERO]


func obtener_coordenadas_ocupadas(capa: TileMapLayer) -> Array[Vector2i]:
	var origen := capa.local_to_map(capa.to_local(global_position))
	var coordenadas: Array[Vector2i] = []
	for desplazamiento in huella_celdas:
		coordenadas.append(origen + desplazamiento)
	return coordenadas


func actualizar_presentacion_visibilidad(estado: int) -> void:
	get_node("FogOculto").visible = estado == Celda.EstadoVisibilidad.OCULTO
	get_node("FogExplorado").visible = estado == Celda.EstadoVisibilidad.EXPLORADO
