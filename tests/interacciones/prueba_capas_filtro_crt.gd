extends SceneTree


func _initialize() -> void:
	var escenario: Node = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	var filtro: CanvasLayer = escenario.get_node("FiltroCRT")
	for ruta in [
		"res://scenes/ui/presentacion_zona.tscn",
		"res://scenes/ui/pantalla_muerte.tscn",
		"res://scenes/ui/pantalla_desmayo.tscn",
		"res://scenes/campamento/campamento.tscn",
	]:
		var pantalla: CanvasLayer = load(ruta).instantiate()
		assert(filtro.layer > pantalla.layer, "%s debe quedar debajo del filtro CRT" % ruta)
		pantalla.free()
	assert(filtro.layer > 50, "El efecto de cercanía a la muerte debe quedar debajo del filtro")
	escenario.free()
	print("Filtro CRT: capas de presentación, muerte, desmayo y campamento verificadas")
	quit()
