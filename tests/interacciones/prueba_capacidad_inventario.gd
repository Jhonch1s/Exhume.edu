@tool
extends EditorScript


func _run() -> void:
	var piedra := DefinicionItem.new()
	piedra.id_definicion = &"piedra_prueba"
	piedra.nombre = "Piedra"
	piedra.apilable = true
	piedra.cantidad_maxima = 10

	var inventario := Inventario.new()
	inventario.capacidad = 1

	assert(inventario.agregar(
		ItemInstancia.new(&"pila_a", piedra, 5)
	).exitosa)
	assert(inventario.agregar(
		ItemInstancia.new(&"pila_b", piedra, 1)
	).motivo == &"inventario_lleno")
	assert(inventario.separar(
		&"pila_a", 2, &"pila_c"
	).motivo == &"inventario_lleno")
	assert(inventario.obtener_por_id(&"pila_a").cantidad == 5)

	assert(inventario.retirar(&"pila_a").exitosa)
	assert(not inventario.esta_lleno())
	print("Capacidad del inventario: correcto.")
	
	var datos := DefinicionCofre.new()
	datos.columnas = 4
	datos.filas = 3

	var cofre := CofreInteractuable.new()
	cofre.definicion = datos

	assert(cofre.obtener_inventario().capacidad == 12)

	var otro_cofre := CofreInteractuable.new()
	otro_cofre.definicion = datos

	assert(cofre.obtener_inventario() != otro_cofre.obtener_inventario())

	cofre.free()
	otro_cofre.free()
	print("Cofres: capacidad correcta e inventarios independientes.")
