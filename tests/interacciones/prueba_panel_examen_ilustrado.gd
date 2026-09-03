extends Node

var _fallos: Array[String] = []


func _ready() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load(
		"res://scenes/ui/interacciones/panel_examen_ilustrado.tscn"
	) as PackedScene
	var panel: Variant = escena.instantiate()
	get_tree().root.add_child(panel)
	await get_tree().process_frame
	var ilustracion := GradientTexture1D.new()
	panel.mostrar("Estatua", ilustracion, "Descripción")
	_comprobar(panel.visible, "Mostrar debe abrir el panel.")
	_comprobar(panel.etiqueta_titulo.text == "Estatua", "Debe mostrar el titulo.")
	_comprobar(panel.imagen.texture == ilustracion, "Debe mostrar la ilustracion.")
	_comprobar(panel.etiqueta_texto.text == "Descripción", "Debe mostrar el texto.")
	var cierres := [0]
	panel.cerrado.connect(func(): cierres[0] += 1)
	panel.boton_cerrar.pressed.emit()
	_comprobar(not panel.visible and cierres[0] == 1, "Cerrar debe ocultar y emitir.")
	panel.queue_free()
	await get_tree().process_frame
	if _fallos.is_empty():
		print("PanelExamenIlustrado: prueba correcta.")
		get_tree().quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	get_tree().quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
