class_name PanelOrdenCombate
extends PanelContainer

@onready var etiqueta_ronda: Label = $Margen/Fila/Ronda
@onready var participantes: HBoxContainer = $Margen/Fila/Participantes


func mostrar(ronda: int, entradas: Array[Dictionary], id_activo: StringName) -> void:
	etiqueta_ronda.text = "RONDA %d" % ronda
	for hijo in participantes.get_children():
		hijo.queue_free()
	for entrada in entradas:
		var etiqueta := Label.new()
		var nombre: String = entrada.get("nombre", String(entrada.get("id", "")))
		var id: StringName = entrada.get("id", &"")
		var derrotado: bool = entrada.get("derrotado", false)
		etiqueta.text = ("▶ " if id == id_activo else "· ") + nombre
		etiqueta.add_theme_color_override(
			&"font_color",
			Color("#777573") if derrotado else (
				Color("#f0d69c") if id == id_activo else Color("#d7d1c5")
			)
		)
		participantes.add_child(etiqueta)
	visible = true


func ocultar() -> void:
	visible = false
