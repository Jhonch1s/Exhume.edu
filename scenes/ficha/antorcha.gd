extends PointLight2D

var tiempo: float = 0.0

func _process(delta: float) -> void:
	var ficha := get_parent() as Ficha
	var antorcha := ficha.obtener_antorcha_activa()
	enabled = antorcha != null
	if not enabled:
		return
	tiempo += delta
	color = antorcha.color_luz
	var variacion := sin(tiempo * 5.0) * 0.10 + sin(tiempo * 8.3) * 0.05
	texture_scale = antorcha.escala_luz * (1.0 + variacion * 0.35)
	var intensidad := antorcha.energia_luz
	if antorcha.pasos_atenuacion > 0 and ficha.pasos_antorcha_actual <= antorcha.pasos_atenuacion:
		intensidad *= float(ficha.pasos_antorcha_actual) / antorcha.pasos_atenuacion
	energy = intensidad * (0.85 + variacion)
