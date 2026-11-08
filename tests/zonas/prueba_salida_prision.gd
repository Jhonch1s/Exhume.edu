extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var prision := (load("res://scenes/Prision/prision.tscn") as PackedScene).instantiate()
	var salida := prision.get_node("Triggers/Mecanismos/escape_prision") as TriggerMapa
	var viaje := prision.get_node("Triggers/Viajes/ViajeTemploDeLasTrampas") as TriggerMapa
	assert(salida.accion != viaje.accion)
	assert(salida.accion.get_script().resource_path == "res://scripts/zonas/triggers/accion_escape_prision.gd")
	assert(viaje.accion is AccionTriggerViajar)
	var pantalla := (load("res://scenes/Prision/fin_demo.tscn") as PackedScene).instantiate()
	root.add_child(pantalla)
	assert(not pantalla.get_node("Creditos").visible)
	pantalla.get_node("Contenido/Columna/VerCreditos").pressed.emit()
	assert(not pantalla.get_node("Contenido").visible and pantalla.get_node("Creditos").visible)
	assert(pantalla.get_node("Creditos/Columna/VolverAlMenu").pressed.is_connected(pantalla._on_volver_al_menu_pressed))
	prision.free()
	pantalla.queue_free()
	print("SalidaPrision: acción independiente y pantalla final correctas.")
	quit()
