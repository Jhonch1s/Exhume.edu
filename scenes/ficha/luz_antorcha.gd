extends PointLight2D

#velocidad del parpadeo
var tiempo: float = 0.0

#delta es el tiempo que tomo renderizar el ultimo fotograma (basicamente pa que ande bien en todas las pc a la misma vez aunque tengas una tostadora)
func _process(delta: float) -> void:
	tiempo += delta * 12.0 #lo multiplicamos por 12 pa que se mueva bien rico (sin el x12 va muy lento)
	
	#variación suave de intensidad combinando una onda senoidal y un poco de ruido aleatorio
	#sin(tiempo) es para la onda que sube y baja suavemente
	#ranf_range(-0.05, 0.05) es para generar un numero aleatorio en ese rango para que parezca mas realista con un parpadeo en la luz
	var variacion = sin(tiempo) * 0.1 + randf_range(-0.05, 0.05)
	
	#mantiene la energía base alrededor de 1.3 con pequeñas oscilaciones
	#energy es nativa de godot
	energy = 1.3 + variacion
