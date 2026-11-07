extends Node

const RUTA := "user://preferencias.cfg"
var volumen := 1.0
var pantalla_completa := true
var sacudida := 1.0

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(RUTA) == OK:
		volumen = clampf(float(config.get_value("opciones", "volumen", 1.0)), 0.0, 1.0)
		pantalla_completa = bool(config.get_value("opciones", "pantalla_completa", true))
		sacudida = clampf(float(config.get_value("opciones", "sacudida", 1.0)), 0.0, 1.0)
	aplicar_volumen()
	aplicar_pantalla()

func aplicar_volumen() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volumen <= 0.0)
	if volumen > 0.0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(volumen))

func aplicar_pantalla() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED)

func guardar() -> void:
	var config := ConfigFile.new()
	config.set_value("opciones", "volumen", volumen)
	config.set_value("opciones", "pantalla_completa", pantalla_completa)
	config.set_value("opciones", "sacudida", sacudida)
	var error := config.save(RUTA)
	if error != OK:
		push_warning("No se pudieron guardar las preferencias: %s" % error)
