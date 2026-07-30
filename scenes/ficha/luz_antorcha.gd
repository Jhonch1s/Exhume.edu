extends PointLight2D

var tiempo: float = 0.0

func _process(delta: float) -> void:
	tiempo += delta * 12.0
	var variacion = sin(tiempo) * 0.1 + randf_range(-0.05, 0.05)
	energy = 1.3 + variacion
