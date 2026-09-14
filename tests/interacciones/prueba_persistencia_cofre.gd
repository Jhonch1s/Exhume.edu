extends SceneTree


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var cofre := CofreInteractuable.new()
	cofre.definicion = load("res://scenes/interactuables/cofres/cofre_pequeno.tres")
	cofre.inventario.capacidad = 4
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	cofre.inventario.agregar(ItemInstancia.new(&"cofre:contenido:0", piedra, 3))
	cofre.abierto = true

	var estado := cofre.obtener_estado_persistente()
	cofre.abierto = false
	cofre.inventario.retirar(&"cofre:contenido:0")
	assert(cofre.restaurar_estado_persistente(estado) == &"")
	assert(cofre.abierto)
	assert(cofre.inventario.obtener_por_id(&"cofre:contenido:0").cantidad == 3)

	var estado_invalido := estado.duplicate(true)
	estado_invalido["inventario"].append(estado_invalido["inventario"][0].duplicate())
	assert(cofre.validar_estado_persistente(estado_invalido) != &"")

	cofre.free()
	print("PersistenciaCofre: apertura, contenido y validación correctos.")
	quit()
