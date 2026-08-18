class_name Humo
extends Node2D

@export var id_instancia: StringName = &""
@export_range(1, 99, 1) var duracion_superficie: int = 10

var coordenada_mapa: Vector2i


func configurar_id_instancia(nuevo_id: StringName) -> void:
	id_instancia = nuevo_id


func configurar_registro(_tablero: TableroGrid, coordenada: Vector2i) -> void:
	coordenada_mapa = coordenada


func obtener_id_reaccion() -> StringName:
	return id_instancia


func obtener_coordenada_reaccion() -> Vector2i:
	return coordenada_mapa


func obtener_familia_superficie() -> StringName:
	return &"humo"


func bloquea_vision_superficie() -> bool:
	return true


func obtener_duracion_superficie() -> int:
	return duracion_superficie
