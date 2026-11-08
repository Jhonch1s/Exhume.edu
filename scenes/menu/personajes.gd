extends Control

signal volver_solicitado

@onready var boton: Button = $Panel/Personaje
@onready var etiqueta: Label = $Panel/Estado


func _ready() -> void:
	if get_parent() == get_tree().root:
		actualizar()


func actualizar() -> void:
	boton.disabled = false
	etiqueta.text = "Selecciona tu partida guardada"
	if EstadoPartida.error_carga != &"":
		etiqueta.text = "No se pudo cargar la partida: %s" % EstadoPartida.error_carga
		EstadoPartida.error_carga = &""
	var snapshot: Variant = ArchivoPartida.new().cargar("user://partida.json")
	if not snapshot is Dictionary or not snapshot.get("ficha") is Dictionary:
		boton.disabled = true
		etiqueta.text = "No hay una partida guardada disponible."
		return
	boton.text = str(snapshot["ficha"].get("nombre", "Partida guardada"))


func _on_personaje_pressed() -> void:
	var motivo: StringName = EstadoPartida.preparar_carga()
	if motivo != &"":
		etiqueta.text = "No se pudo cargar la partida: %s" % motivo


func _on_volver_pressed() -> void:
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/menu/menu_principal.tscn")
	else:
		volver_solicitado.emit()
