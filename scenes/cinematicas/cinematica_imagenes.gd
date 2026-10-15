extends Control

signal terminada

@export var imagenes: Array[Texture2D] = []
## Tiempo con cada imagen completamente visible, sin contar los fundidos.
@export_range(0.1, 30.0, 0.1) var tiempo_por_imagen: float = 4.0
@export_range(0.01, 3.0, 0.01) var tiempo_fundido: float = 0.6

@onready var imagen: TextureRect = $Imagen


func _ready() -> void:
	imagen.modulate.a = 0.0
	for textura in imagenes:
		if textura == null:
			continue
		imagen.texture = textura
		var secuencia := create_tween()
		secuencia.tween_property(imagen, "modulate:a", 1.0, tiempo_fundido)
		secuencia.tween_interval(tiempo_por_imagen)
		secuencia.tween_property(imagen, "modulate:a", 0.0, tiempo_fundido)
		await secuencia.finished
	terminada.emit()
