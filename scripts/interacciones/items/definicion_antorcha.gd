class_name DefinicionAntorcha
extends DefinicionItem

@export_range(1, 20, 1) var radio_vision: int = 5
@export_range(0, 999, 1) var pasos_atenuacion: int = 10
@export_range(0.0, 5.0, 0.05) var energia_luz: float = 1.3
@export_range(0.1, 5.0, 0.05) var escala_luz: float = 1.0
@export var color_luz: Color = Color(1.0, 0.8980392, 0.0)
