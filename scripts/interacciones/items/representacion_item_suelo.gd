class_name RepresentacionItemSuelo
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var resaltador: ResaltadorOutline2D


func establecer_resaltado(activo: bool) -> void:
	if resaltador == null:
		resaltador = ResaltadorOutline2D.new()
		add_child(resaltador)
		resaltador.configurar(sprite, Color.WHITE, 1.0)
	resaltador.establecer_activo(activo)
