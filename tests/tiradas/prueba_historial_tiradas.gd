extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	var generador := RandomNumberGenerator.new()
	generador.seed = 143
	var motor := MotorDados.new(generador)
	var historial := HistorialTiradas.new()
	var automatica := motor.resolver_prueba(
		3,
		[&"luz"],
		[&"distancia"],
		TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.PRIMER_PLANO
	)
	var solicitada := motor.resolver(
		[{&"cantidad": 1, &"caras": 3, &"signo": 1}],
		0,
		TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.SOLO_LOG
	)
	_comprobar(
		automatica.origen == TiposTirada.Origen.AUTOMATICA
		and automatica.presentacion == TiposTirada.Presentacion.PRIMER_PLANO
		and solicitada.origen == TiposTirada.Origen.SOLICITADA
		and solicitada.presentacion == TiposTirada.Presentacion.SOLO_LOG,
		"Origen y presentación deben ser ortogonales en ambos resultados."
	)
	_comprobar(
		historial.registrar(automatica) and historial.registrar(solicitada),
		"El historial debe aceptar pruebas y cantidades válidas."
	)
	var entradas := historial.obtener_entradas()
	entradas.clear()
	_comprobar(
		historial.obtener_entradas().size() == 2
		and "AUTOMATICA | PRIMER_PLANO" in historial.obtener_entradas()[0]
		and "ventaja=[luz] desventaja=[distancia]" in historial.obtener_entradas()[0]
		and "SOLICITADA | SOLO_LOG" in historial.obtener_entradas()[1]
		and "terminos=+1d3=" in historial.obtener_entradas()[1],
		"Debe conservar un texto explicable y copias defensivas, incluso para SOLO_LOG."
	)

	var estado := generador.state
	var invalida := motor.resolver([], 0, 99, TiposTirada.Presentacion.SOLO_LOG)
	_comprobar(
		not invalida.valida
		and generador.state == estado
		and not historial.registrar(invalida)
		and historial.obtener_entradas().size() == 2,
		"Una política inválida debe rechazarse sin tirar ni registrar una entrada."
	)

	if _fallos.is_empty():
		print("HistorialTiradas: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
