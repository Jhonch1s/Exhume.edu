extends PointLight2D

# velocidad del parpadeo
var tiempo: float = 0.0

func _process(delta: float) -> void:
	tiempo += delta * 12.0 # lo multiplicamos por 12 pa que se mueva bien rico
	
	# variación suave de intensidad
	var variacion = sin(tiempo) * 0.1 + randf_range(-0.05, 0.05)
	
	# mantiene la energía base
	energy = 1.3 + variacion
