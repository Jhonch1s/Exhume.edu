extends Node


func _ready() -> void:
	var escena := load("res://scenes/interactuables/fuentes_luz/fuente_luz_interactuable.tscn") as PackedScene
	var antorcha := escena.instantiate() as FuenteLuzInteractuable
	add_child(antorcha)
	var vela := escena.instantiate() as FuenteLuzInteractuable
	vela.definicion = load("res://assets/interactuables/luces/vela_01.tres")
	add_child(vela)
	var efecto := antorcha.get_node_or_null("AntorchaAmbiental")
	assert(efecto != null, "La antorcha debe tener el efecto")
	assert(vela.get_node_or_null("AntorchaAmbiental") == null, "La vela no debe tener el efecto")
	antorcha.actualizar_presentacion_visibilidad(Celda.EstadoVisibilidad.VISIBLE)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(efecto.get_node("Humo").emitting, "La antorcha visible debe emitir humo")
	antorcha.encendida = false
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not efecto.get_node("Humo").visible and not efecto.get_node("Chispas").visible, "Al apagarla deben ocultarse los efectos")
	antorcha.encendida = true
	antorcha.actualizar_presentacion_visibilidad(Celda.EstadoVisibilidad.EXPLORADO)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not efecto.get_node("Humo").visible, "El humo no debe verse fuera de la vision")
	print("Prueba VFX antorcha: OK")
	get_tree().quit()
