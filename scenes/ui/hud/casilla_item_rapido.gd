class_name CasillaItemRapido
extends Button

signal item_arrastrado_soltado(indice: int, item: ItemInstancia)
signal click_derecho_solicitado(indice: int)

@export var indice_rapido: int = 0


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("tipo") == "item_inventario" and data.get("item") != null


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_at_position, data):
		var item: ItemInstancia = data.get("item")
		item_arrastrado_soltado.emit(indice_rapido, item)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		click_derecho_solicitado.emit(indice_rapido)
		accept_event()
