extends SceneTree


func _init() -> void:
	var zona := Node2D.new()
	zona.set_script(load("res://scripts/zonas/zona_explorable.gd"))
	var primero := Interactuable.new()
	primero.id_instancia = &"antorcha_005"
	zona.add_child(primero)
	var segundo := Interactuable.new()
	segundo.id_instancia = &"antorcha_012"
	zona.add_child(segundo)
	var duplicado := Interactuable.new()
	duplicado.id_instancia = &"antorcha_005"
	zona.add_child(duplicado)
	assert(zona._asignar_id_nuevo(duplicado))
	assert(duplicado.id_instancia == &"antorcha_013")
	assert(primero.id_instancia == &"antorcha_005")
	assert(not zona._asignar_id_nuevo(duplicado))
	var nuevo := Interactuable.new()
	zona.add_child(nuevo)
	assert(zona._asignar_id_nuevo(nuevo))
	assert(nuevo.id_instancia == &"interactuable_001")
	for nodo in [primero, segundo, duplicado, nuevo]:
		nodo.owner = zona
	# Fuera del editor, este callback no debe consultar EditorInterface ni cambiar IDs.
	zona._asignar_id_en_editor(duplicado)
	assert(duplicado.id_instancia == &"antorcha_013")
	var escena := PackedScene.new()
	assert(escena.pack(zona) == OK)
	var restaurada := escena.instantiate()
	assert(restaurada.get_child(2).id_instancia == &"antorcha_013")
	assert(restaurada.get_child(3).id_instancia == &"interactuable_001")
	restaurada.free()
	zona.free()
	print("IDs de interactuables: prueba correcta.")
	quit()
