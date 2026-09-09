extends Node


func _ready() -> void:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"prueba"
	definicion.nombre = "Objeto de prueba"
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	definicion.icono = preload("res://icon.svg")

	var casilla := $CasillaInventario
	casilla.configurar(ItemInstancia.new(&"pila_prueba", definicion, 5))
	assert(casilla.get_node("Cantidad").text == "5")
	assert(casilla.get_node("Icono").texture == definicion.icono)

	casilla.configurar(null)
	assert(casilla.get_node("Cantidad").text == "")
	assert(casilla.get_node("Icono").texture == null)

	casilla.configurar(ItemInstancia.new(&"pila_prueba", definicion, 5))
	print("Casilla: presentación correcta.")
