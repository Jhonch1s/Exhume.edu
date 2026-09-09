class_name CasillaInventario
extends Button

var item: ItemInstancia


func _ready() -> void:
	configurar(item)


func configurar(nuevo_item: ItemInstancia) -> void:
	item = nuevo_item
	$Icono.texture = null
	$Cantidad.text = ""
	disabled = true
	if item == null or not item.es_valida():
		return
	$Icono.texture = item.definicion.icono
	$Cantidad.text = str(item.cantidad) if item.cantidad > 1 else ""
	disabled = false
