class_name PresentacionZona
extends CanvasLayer

signal finalizada

@onready var fondo: ColorRect = $Fondo
@onready var contenedor: VBoxContainer = $Fondo/Contenedor
@onready var etiqueta_titulo: Label = $Fondo/Contenedor/Titulo
@onready var etiqueta_subtitulo: Label = $Fondo/Contenedor/Subtitulo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	fondo.modulate.a = 0.0


func presentar(nombre_zona: String, subtitulo: String = "ZONA EXPLORABLE") -> void:
	visible = true
	etiqueta_titulo.text = nombre_zona.to_upper()
	etiqueta_subtitulo.text = subtitulo
	fondo.modulate.a = 1.0
	
	var tween := create_tween()
	# Mantiene oscuro unos segundos y luego desvanece suavemente
	tween.tween_interval(1.6)
	tween.tween_property(fondo, "modulate:a", 0.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		visible = false
		finalizada.emit()
		queue_free()
	)
