extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_d3()
	_probar_repetibilidad_y_expresion()
	_probar_total_negativo()
	_probar_rechazo_atomico()
	_probar_copias_defensivas()

	if _fallos.is_empty():
		print("MotorDados: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_d3() -> void:
	var resultado := _motor_con_semilla(14).resolver([_termino(100, 3)])
	_comprobar(resultado.valida, "Un d3 válido debe resolverse.")
	for dado: int in resultado.terminos[0][&"resultados"]:
		_comprobar(dado in [1, 2, 3], "Un d3 sólo debe producir 1, 2 o 3.")


func _probar_repetibilidad_y_expresion() -> void:
	var expresion := [_termino(2, 6), _termino(1, 3, -1)]
	var primero := _motor_con_semilla(141).resolver(expresion)
	var segundo := _motor_con_semilla(141).resolver(expresion)
	_comprobar(primero.terminos == segundo.terminos, "La misma semilla debe repetir los dados.")
	_comprobar(
		primero.terminos.size() == 2
		and primero.terminos[0][&"resultados"].size() == 2
		and primero.terminos[1][&"resultados"].size() == 1
		and primero.total_calculado
		== primero.terminos[0][&"subtotal"] - primero.terminos[1][&"subtotal"],
		"La expresión debe conservar términos, dados, subtotales, signos y total."
	)


func _probar_total_negativo() -> void:
	var resultado := _motor_con_semilla(3).resolver([
		_termino(1, 2),
		_termino(3, 6, -1),
	])
	_comprobar(
		resultado.total_calculado < 0 and resultado.total_efectivo == 0,
		"El total calculado puede ser negativo y el efectivo debe respetar el mínimo cero."
	)


func _probar_rechazo_atomico() -> void:
	var casos := [
		[[_termino(1, 6), _termino(0, 3, -1)], 0],
		[[_termino(1, 1)], 0],
		[[_termino(1, 6, 0)], 0],
		[[{&"cantidad": 1}], 0],
		[[_termino(1, 6)], 0.5],
	]
	for caso: Array in casos:
		var generador := RandomNumberGenerator.new()
		generador.seed = 141
		var estado := generador.state
		var resultado := MotorDados.new(generador).resolver(caso[0], caso[1])
		_comprobar(
			not resultado.valida
			and resultado.terminos.is_empty()
			and generador.state == estado,
			"Toda entrada inválida debe rechazarse completa sin avanzar el generador."
		)


func _probar_copias_defensivas() -> void:
	var resultado := _motor_con_semilla(141).resolver([_termino(2, 6)])
	var obtenidos := resultado.terminos
	obtenidos[0][&"resultados"][0] = 99
	obtenidos.append({})
	_comprobar(
		resultado.terminos.size() == 1
		and resultado.terminos[0][&"resultados"][0] != 99,
		"Modificar colecciones obtenidas no debe alterar el resultado."
	)


func _motor_con_semilla(semilla: int) -> MotorDados:
	var generador := RandomNumberGenerator.new()
	generador.seed = semilla
	return MotorDados.new(generador)


func _termino(cantidad: int, caras: int, signo: int = 1) -> Dictionary:
	return {&"cantidad": cantidad, &"caras": caras, &"signo": signo}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
