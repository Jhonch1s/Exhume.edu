extends SceneTree

var _fallos: Array[String] = []
var _observador := RefCounted.new()


func _init() -> void:
	_probar_examen_basico_en_limite()
	_probar_examen_profundo_adyacente()
	_probar_secreto_con_pista()
	_probar_bloqueos_espaciales()
	_probar_contratos_invalidos()

	if _fallos.is_empty():
		print("EvaluadorInformacion: 5 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_examen_basico_en_limite() -> void:
	var fragmentos := _crear_fragmentos_vertical_slice()
	var resultado := EvaluadorInformacion.new().evaluar(
		fragmentos,
		CondicionesObservacion.new(_observador, 5.0, true, true),
		PerfilObservacion.new()
	)

	_comprobar(not resultado.bloqueada, "El alcance básico debe incluir cinco celdas.")
	_comprobar(not resultado.permite_detalle, "Cinco celdas no deben permitir detalle.")
	_comprobar(
		_obtener_ids(resultado) == [&"identidad"],
		"A distancia básica debe aparecer un único fragmento BASICO."
	)

	var copia := resultado.fragmentos_disponibles
	copia.clear()
	_comprobar(
		resultado.fragmentos_disponibles.size() == 1,
		"El resultado debe devolver una copia de sus fragmentos."
	)


func _probar_examen_profundo_adyacente() -> void:
	var resultado := EvaluadorInformacion.new().evaluar(
		_crear_fragmentos_vertical_slice(),
		CondicionesObservacion.new(_observador, 1.0, true, true),
		PerfilObservacion.new()
	)

	_comprobar(not resultado.bloqueada, "Una observación adyacente debe resolverse.")
	_comprobar(resultado.permite_detalle, "La adyacencia debe permitir detalle.")
	_comprobar(
		_obtener_ids(resultado) == [&"identidad", &"construccion"],
		"El examen profundo no debe revelar un secreto sin su pista."
	)


func _probar_secreto_con_pista() -> void:
	var resultado := EvaluadorInformacion.new().evaluar(
		_crear_fragmentos_vertical_slice(),
		CondicionesObservacion.new(
			_observador,
			1.0,
			true,
			true,
			[&"marca_oculta_revelable"]
		),
		PerfilObservacion.new()
	)

	_comprobar(
		_obtener_ids(resultado) == [
			&"identidad",
			&"construccion",
			&"marca_oculta",
		],
		"El secreto debe exigir simultáneamente cercanía y su pista explícita."
	)

	var desde_lejos := EvaluadorInformacion.new().evaluar(
		_crear_fragmentos_vertical_slice(),
		CondicionesObservacion.new(
			_observador,
			5.0,
			true,
			true,
			[&"marca_oculta_revelable"]
		),
		PerfilObservacion.new()
	)
	_comprobar(
		&"marca_oculta" not in _obtener_ids(desde_lejos),
		"Una pista no debe omitir el alcance secreto del perfil."
	)


func _probar_bloqueos_espaciales() -> void:
	var evaluador := EvaluadorInformacion.new()
	var fragmentos := _crear_fragmentos_vertical_slice()
	var perfil := PerfilObservacion.new()

	_comprobar(
		evaluador.evaluar(
			fragmentos,
			CondicionesObservacion.new(_observador, 1.0, false, true),
			perfil
		).motivo == &"objetivo_no_visible",
		"Una celda no visible debe bloquear descubrimientos nuevos."
	)
	_comprobar(
		evaluador.evaluar(
			fragmentos,
			CondicionesObservacion.new(_observador, 1.0, true, false),
			perfil
		).motivo == &"linea_visual_bloqueada",
		"La línea visual bloqueada debe producir un motivo estable."
	)
	_comprobar(
		evaluador.evaluar(
			fragmentos,
			CondicionesObservacion.new(_observador, 6.0, true, true),
			perfil
		).motivo == &"fuera_alcance_examen",
		"Más de cinco celdas debe quedar fuera del perfil inicial."
	)


func _probar_contratos_invalidos() -> void:
	var evaluador := EvaluadorInformacion.new()
	var condiciones := CondicionesObservacion.new(_observador, 1.0, true, true)
	var perfil_invalido := PerfilObservacion.new()
	perfil_invalido.alcance_basico = 1.0
	perfil_invalido.alcance_detallado = 2.0

	_comprobar(
		evaluador.evaluar(
			_crear_fragmentos_vertical_slice(),
			condiciones,
			perfil_invalido
		).motivo == &"perfil_observacion_invalido",
		"El alcance detallado no debe superar el básico."
	)

	var definicion := DefinicionInteractuable.new()
	definicion.id_definicion = &"objetivo_prueba"
	definicion.nombre = "Objetivo de prueba"
	definicion.perfil_observacion = perfil_invalido
	_comprobar(
		not definicion.es_valida(),
		"Una definición no debe aceptar un perfil de observación inválido."
	)

	var repetidos := _crear_fragmentos_vertical_slice()
	repetidos.append(repetidos[0])
	_comprobar(
		evaluador.evaluar(
			repetidos,
			condiciones,
			PerfilObservacion.new()
		).motivo == &"fragmentos_informacion_duplicados",
		"El evaluador debe rechazar IDs repetidos aunque el proveedor sea inválido."
	)


func _crear_fragmentos_vertical_slice() -> Array[FragmentoInformacion]:
	var fragmentos: Array[FragmentoInformacion] = []
	fragmentos.append(_crear_fragmento(
		&"identidad",
		TiposInteraccion.NivelInformacion.BASICO,
		&"examen.antorcha_pie.basico_encendida"
	))
	fragmentos.append(_crear_fragmento(
		&"construccion",
		TiposInteraccion.NivelInformacion.DETALLADO,
		&"examen.antorcha.construccion"
	))
	fragmentos.append(_crear_fragmento(
		&"marca_oculta",
		TiposInteraccion.NivelInformacion.SECRETO,
		&"examen.antorcha.marca_oculta",
		[&"marca_oculta_revelable"]
	))
	return fragmentos


func _crear_fragmento(
	id_fragmento: StringName,
	nivel: TiposInteraccion.NivelInformacion,
	id_mensaje: StringName,
	pistas: Array[StringName] = [],
	se_recuerda: bool = true
) -> FragmentoInformacion:
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = id_fragmento
	fragmento.nivel = nivel
	fragmento.id_mensaje = id_mensaje
	fragmento.pistas_requeridas = pistas
	fragmento.se_recuerda = se_recuerda
	return fragmento


func _obtener_ids(resultado: ResultadoEvaluacionInformacion) -> Array[StringName]:
	var ids: Array[StringName] = []
	for fragmento in resultado.fragmentos_disponibles:
		ids.append(fragmento.id_fragmento)
	return ids


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
