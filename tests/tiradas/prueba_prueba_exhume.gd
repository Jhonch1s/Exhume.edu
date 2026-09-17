extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_comparacion_y_extremos()
	_probar_ventaja_y_desventaja()
	_probar_cancelacion_y_copias()
	_probar_modificadores()
	_probar_rechazo_sin_tirar()

	if _fallos.is_empty():
		print("PruebaExhume: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_comparacion_y_extremos() -> void:
	var exito := _buscar_resultado(5, ResultadoPrueba.Modo.NORMAL, 2)
	var fallo := _buscar_resultado(1, ResultadoPrueba.Modo.NORMAL, 2)
	var critico := _buscar_resultado(1, ResultadoPrueba.Modo.NORMAL, 1)
	var pifia := _buscar_resultado(5, ResultadoPrueba.Modo.NORMAL, 6)
	_comprobar(exito.dado_seleccionado <= 5 and exito.exitosa, "d6 ≤ atributo debe tener éxito.")
	_comprobar(
		fallo.dado_seleccionado > 1 and not fallo.exitosa,
		"d6 > atributo debe fallar fuera de los extremos."
	)
	_comprobar(
		critico.clasificacion == ResultadoPrueba.Clasificacion.CRITICO and critico.exitosa,
		"El 1 natural debe ser crítico y éxito asegurado."
	)
	_comprobar(
		pifia.clasificacion == ResultadoPrueba.Clasificacion.PIFIA and not pifia.exitosa,
		"El 6 natural debe ser pifia y fallo asegurado."
	)


func _probar_ventaja_y_desventaja() -> void:
	var semilla := _buscar_semilla_uno_y_seis()
	var ventaja := _motor_con_semilla(semilla).resolver_prueba(3, [&"ventaja"])
	var desventaja := _motor_con_semilla(semilla).resolver_prueba(3, [], [&"desventaja"])
	var dados_ventaja := ventaja.dados
	var dados_desventaja := desventaja.dados
	dados_ventaja.sort()
	dados_desventaja.sort()
	_comprobar(
		dados_ventaja == [1, 6]
		and ventaja.dado_seleccionado == mini(ventaja.dados[0], ventaja.dados[1])
		and ventaja.clasificacion == ResultadoPrueba.Clasificacion.CRITICO,
		"Ventaja debe elegir y clasificar únicamente el dado menor."
	)
	_comprobar(
		dados_desventaja == [1, 6]
		and desventaja.dado_seleccionado == maxi(desventaja.dados[0], desventaja.dados[1])
		and desventaja.clasificacion == ResultadoPrueba.Clasificacion.PIFIA,
		"Desventaja debe elegir y clasificar únicamente el dado mayor."
	)


func _probar_cancelacion_y_copias() -> void:
	var ventajas: Array[StringName] = [&"luz", &"herramienta"]
	var desventajas: Array[StringName] = [&"distancia"]
	var resultado := _motor_con_semilla(14).resolver_prueba(3, ventajas, desventajas)
	ventajas.clear()
	var dados := resultado.dados
	dados[0] = 99
	_comprobar(
		resultado.modo == ResultadoPrueba.Modo.VENTAJA
		and resultado.fuentes_ventaja == [&"luz", &"herramienta"]
		and resultado.dados[0] != 99,
		"Debe cancelar por balance y copiar defensivamente fuentes y dados."
	)
	var cancelada := _motor_con_semilla(14).resolver_prueba(3, [&"luz"], [&"distancia"])
	_comprobar(
		cancelada.modo == ResultadoPrueba.Modo.NORMAL and cancelada.dados.size() == 1,
		"Fuentes equilibradas deben producir una prueba normal."
	)


func _probar_rechazo_sin_tirar() -> void:
	var generador := RandomNumberGenerator.new()
	generador.seed = 14
	var estado := generador.state
	var resultado := MotorDados.new(generador).resolver_prueba(6)
	_comprobar(
		not resultado.valida and resultado.dados.is_empty() and generador.state == estado,
		"Un atributo fuera de 1..5 debe rechazarse sin consumir azar."
	)
	var invalida := MotorDados.new(generador).resolver_prueba(
		3, [], [], TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.PRIMER_PLANO,
		[{&"fuente": &"anillo", &"valor": 1.5}]
	)
	_comprobar(
		not invalida.valida and generador.state == estado,
		"Un bono no entero debe rechazarse sin consumir azar."
	)


func _probar_modificadores() -> void:
	var semilla := 0
	for candidata in 1000:
		if _motor_con_semilla(candidata).resolver_prueba(3).dado_seleccionado == 4:
			semilla = candidata
			break
	var modificadores: Array[Dictionary] = [{&"fuente": &"anillo", &"valor": 2}]
	var sin_bono := _motor_con_semilla(semilla).resolver_prueba(3)
	var con_bono := _motor_con_semilla(semilla).resolver_prueba(
		3, [], [], TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.PRIMER_PLANO, modificadores
	)
	modificadores[0][&"valor"] = 99
	var copia := con_bono.modificadores
	copia[0][&"valor"] = 99
	_comprobar(
		not sin_bono.exitosa and con_bono.exitosa
		and con_bono.dado_seleccionado == 4
		and con_bono.bono_total == 2
		and con_bono.atributo_efectivo == 5
		and con_bono.modificadores[0][&"valor"] == 2,
		"El bono debe aumentar el objetivo y conservar copias defensivas."
	)
	var penalizada := _motor_con_semilla(semilla).resolver_prueba(
		5, [], [], TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.PRIMER_PLANO,
		[{&"fuente": &"herida", &"valor": -2}]
	)
	_comprobar(
		penalizada.atributo_efectivo == 3 and not penalizada.exitosa,
		"Una penalización debe reducir el objetivo efectivo."
	)
	var critico_con_penalizacion: ResultadoPrueba
	var pifia_con_bono: ResultadoPrueba
	for candidata in 1000:
		var prueba := _motor_con_semilla(candidata).resolver_prueba(3)
		if prueba.dado_seleccionado == 1 and critico_con_penalizacion == null:
			critico_con_penalizacion = _motor_con_semilla(candidata).resolver_prueba(
				1, [], [], TiposTirada.Origen.SOLICITADA,
				TiposTirada.Presentacion.PRIMER_PLANO,
				[{&"fuente": &"herida", &"valor": -5}]
			)
		if prueba.dado_seleccionado == 6 and pifia_con_bono == null:
			pifia_con_bono = _motor_con_semilla(candidata).resolver_prueba(
				5, [], [], TiposTirada.Origen.SOLICITADA,
				TiposTirada.Presentacion.PRIMER_PLANO,
				[{&"fuente": &"anillo", &"valor": 5}]
			)
		if critico_con_penalizacion != null and pifia_con_bono != null:
			break
	_comprobar(
		critico_con_penalizacion != null and critico_con_penalizacion.exitosa
		and critico_con_penalizacion.clasificacion == ResultadoPrueba.Clasificacion.CRITICO
		and pifia_con_bono != null and not pifia_con_bono.exitosa
		and pifia_con_bono.clasificacion == ResultadoPrueba.Clasificacion.PIFIA,
		"Los extremos naturales deben prevalecer sobre los modificadores."
	)


func _buscar_resultado(atributo: int, modo: ResultadoPrueba.Modo, dado: int) -> ResultadoPrueba:
	for semilla in 1000:
		var ventajas: Array[StringName] = []
		var desventajas: Array[StringName] = []
		if modo == ResultadoPrueba.Modo.VENTAJA:
			ventajas.append(&"ventaja")
		elif modo == ResultadoPrueba.Modo.DESVENTAJA:
			desventajas.append(&"desventaja")
		var resultado := _motor_con_semilla(semilla).resolver_prueba(atributo, ventajas, desventajas)
		if resultado.dado_seleccionado == dado:
			return resultado
	return null


func _buscar_semilla_uno_y_seis() -> int:
	for semilla in 1000:
		var resultado := _motor_con_semilla(semilla).resolver_prueba(3, [&"ventaja"])
		var dados := resultado.dados
		dados.sort()
		if dados == [1, 6]:
			return semilla
	return -1
func _motor_con_semilla(semilla: int) -> MotorDados:
	var generador := RandomNumberGenerator.new()
	generador.seed = semilla
	return MotorDados.new(generador)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
