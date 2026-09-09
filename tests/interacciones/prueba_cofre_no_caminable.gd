extends SceneTree


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var cofre = load("res://scripts/interacciones/interactuables/cofres/cofre_interactuable.gd").new()
	var celda = load("res://scripts/celda.gd").new()
	assert(celda.es_caminable_efectiva())
	celda.interactuables.append(cofre)
	for abierto in [false, true]:
		cofre.abierto = abierto
		assert(not celda.es_caminable_efectiva(), "El cofre debe bloquear el paso.")
	celda.interactuables.erase(cofre)
	assert(celda.es_caminable_efectiva())
	cofre.free()
	print("Cofre: bloquea el paso abierto y cerrado; retirarlo libera la celda.")
	quit()
