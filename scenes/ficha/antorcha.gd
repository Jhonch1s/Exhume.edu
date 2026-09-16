extends PointLight2D

var tiempo: float = 0.0

func _process(delta: float) -> void:
	var ficha := get_parent() as Ficha
	var antorcha := ficha.obtener_antorcha_activa()
	enabled = antorcha != null
	if not enabled:
		return
	tiempo += delta * 12.0
	color = antorcha.color_luz
	texture_scale = antorcha.escala_luz
	var intensidad := antorcha.energia_luz
	if antorcha.pasos_atenuacion > 0 and ficha.pasos_antorcha_actual <= antorcha.pasos_atenuacion:
		intensidad *= float(ficha.pasos_antorcha_actual) / antorcha.pasos_atenuacion
	energy = maxf(0.0, intensidad + sin(tiempo) * 0.1 + randf_range(-0.05, 0.05))
