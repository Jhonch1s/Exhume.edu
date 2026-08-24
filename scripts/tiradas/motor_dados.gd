class_name MotorDados
extends RefCounted

var _generador: RandomNumberGenerator


func _init(generador_inicial: RandomNumberGenerator = null) -> void:
	_generador = generador_inicial
	if _generador == null:
		_generador = RandomNumberGenerator.new()
		_generador.randomize()


func resolver(
	terminos: Array,
	minimo_efectivo: Variant = 0,
	origen: Variant = TiposTirada.Origen.SOLICITADA,
	presentacion: Variant = TiposTirada.Presentacion.PRIMER_PLANO
) -> ResultadoTirada:
	var motivo := _validar(terminos, minimo_efectivo, origen, presentacion)
	if motivo != &"":
		return ResultadoTirada.new(false, motivo)

	var resueltos: Array[Dictionary] = []
	var total := 0
	for termino: Dictionary in terminos:
		var dados: Array[int] = []
		var subtotal := 0
		for indice in termino[&"cantidad"]:
			var dado := _generador.randi_range(1, termino[&"caras"])
			dados.append(dado)
			subtotal += dado
		var signo: int = termino[&"signo"]
		resueltos.append({
			&"cantidad": termino[&"cantidad"],
			&"caras": termino[&"caras"],
			&"signo": signo,
			&"resultados": dados,
			&"subtotal": subtotal,
		})
		total += signo * subtotal
	return ResultadoTirada.new(
		true, &"", resueltos, total, minimo_efectivo, origen, presentacion
	)


func resolver_prueba(
	atributo: Variant,
	fuentes_ventaja: Array[StringName] = [],
	fuentes_desventaja: Array[StringName] = [],
	origen: Variant = TiposTirada.Origen.SOLICITADA,
	presentacion: Variant = TiposTirada.Presentacion.PRIMER_PLANO
) -> ResultadoPrueba:
	var motivo := _validar_prueba(
		atributo, fuentes_ventaja, fuentes_desventaja, origen, presentacion
	)
	if motivo != &"":
		return ResultadoPrueba.new(false, motivo)

	var balance := fuentes_ventaja.size() - fuentes_desventaja.size()
	var modo := ResultadoPrueba.Modo.NORMAL
	if balance > 0:
		modo = ResultadoPrueba.Modo.VENTAJA
	elif balance < 0:
		modo = ResultadoPrueba.Modo.DESVENTAJA
	var tirada := resolver([{
		&"cantidad": 1 if modo == ResultadoPrueba.Modo.NORMAL else 2,
		&"caras": 6,
		&"signo": 1,
	}], 0, origen, presentacion)
	var dados: Array[int] = tirada.terminos[0][&"resultados"]
	var seleccionado := dados[0]
	if modo == ResultadoPrueba.Modo.VENTAJA:
		seleccionado = mini(dados[0], dados[1])
	elif modo == ResultadoPrueba.Modo.DESVENTAJA:
		seleccionado = maxi(dados[0], dados[1])
	var clasificacion := ResultadoPrueba.Clasificacion.NORMAL
	if seleccionado == 1:
		clasificacion = ResultadoPrueba.Clasificacion.CRITICO
	elif seleccionado == 6:
		clasificacion = ResultadoPrueba.Clasificacion.PIFIA
	var exitosa: bool = seleccionado <= atributo
	if clasificacion == ResultadoPrueba.Clasificacion.CRITICO:
		exitosa = true
	elif clasificacion == ResultadoPrueba.Clasificacion.PIFIA:
		exitosa = false
	return ResultadoPrueba.new(
		true,
		&"",
		dados,
		seleccionado,
		atributo,
		fuentes_ventaja,
		fuentes_desventaja,
		modo,
		clasificacion,
		exitosa,
		origen,
		presentacion
	)


func _validar(
	terminos: Array,
	minimo_efectivo: Variant,
	origen: Variant,
	presentacion: Variant
) -> StringName:
	var motivo_politica := _validar_politica(origen, presentacion)
	if motivo_politica != &"":
		return motivo_politica
	if typeof(minimo_efectivo) != TYPE_INT:
		return &"minimo_efectivo_invalido"
	if terminos.is_empty():
		return &"terminos_invalidos"
	for valor: Variant in terminos:
		if typeof(valor) != TYPE_DICTIONARY:
			return &"termino_invalido"
		var termino: Dictionary = valor
		if not termino.has(&"cantidad") or not termino.has(&"caras") or not termino.has(&"signo"):
			return &"termino_invalido"
		if (
			typeof(termino[&"cantidad"]) != TYPE_INT
			or termino[&"cantidad"] < 1
		):
			return &"cantidad_dados_invalida"
		if typeof(termino[&"caras"]) != TYPE_INT or termino[&"caras"] < 2:
			return &"caras_dado_invalidas"
		if typeof(termino[&"signo"]) != TYPE_INT or termino[&"signo"] not in [-1, 1]:
			return &"signo_invalido"
	return &""


func _validar_prueba(
	atributo: Variant,
	fuentes_ventaja: Array[StringName],
	fuentes_desventaja: Array[StringName],
	origen: Variant,
	presentacion: Variant
) -> StringName:
	var motivo_politica := _validar_politica(origen, presentacion)
	if motivo_politica != &"":
		return motivo_politica
	if typeof(atributo) != TYPE_INT or atributo < 1 or atributo > 5:
		return &"atributo_prueba_invalido"
	for fuente in fuentes_ventaja + fuentes_desventaja:
		if fuente == &"":
			return &"fuente_prueba_invalida"
	return &""


func _validar_politica(origen: Variant, presentacion: Variant) -> StringName:
	if typeof(origen) != TYPE_INT or origen not in TiposTirada.Origen.values():
		return &"origen_tirada_invalido"
	if typeof(presentacion) != TYPE_INT or presentacion not in TiposTirada.Presentacion.values():
		return &"presentacion_tirada_invalida"
	return &""
