extends SceneTree

class FuenteReaccionPrueba extends RefCounted:
	var id_reaccion: StringName
	var prioridad: int
	var tipos: Array[TiposInteraccion.TipoAccion]
	var tipos_dirigidos: Array[TiposInteraccion.TipoAccion]

	func _init(
		id_inicial: StringName,
		prioridad_inicial: int,
		tipos_iniciales: Array[TiposInteraccion.TipoAccion],
		tipos_dirigidos_iniciales: Array[TiposInteraccion.TipoAccion] = []
	) -> void:
		id_reaccion = id_inicial
		prioridad = prioridad_inicial
		tipos = tipos_iniciales
		tipos_dirigidos = tipos_dirigidos_iniciales

	func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
		return tipo in tipos

	func admite_reaccion_dirigida(tipo: TiposInteraccion.TipoAccion) -> bool:
		return tipo in tipos_dirigidos

	func obtener_id_reaccion() -> StringName:
		return id_reaccion

	func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
		return prioridad

	func validar_accion(_contexto: ContextoAccion) -> StringName:
		return &""

	func resolver_accion(_contexto: ContextoAccion) -> ResultadoAccion:
		return ResultadoAccion.crear_exito()


var _fallos: Array[String] = []


func _init() -> void:
	_probar_consulta_ordenada()
	if _fallos.is_empty():
		print("ConsultorReaccionesCelda: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_consulta_ordenada() -> void:
	var celda := Celda.new()
	var actor := FuenteReaccionPrueba.new(
		&"actor",
		0,
		[TiposInteraccion.TipoAccion.ENTRAR]
	)
	celda.reaccion_terreno = FuenteReaccionPrueba.new(
		&"barro",
		99,
		[TiposInteraccion.TipoAccion.ENTRAR]
	)
	celda.efectos_superficie.assign([
		FuenteReaccionPrueba.new(
			&"humo_veneno_b",
			10,
			[TiposInteraccion.TipoAccion.ENTRAR]
		),
		FuenteReaccionPrueba.new(
			&"humo_veneno_a",
			10,
			[TiposInteraccion.TipoAccion.ENTRAR]
		),
		FuenteReaccionPrueba.new(
			&"solo_salir",
			0,
			[TiposInteraccion.TipoAccion.SALIR]
		),
	])
	celda.interactuables.append(FuenteReaccionPrueba.new(
		&"trampa",
		0,
		[TiposInteraccion.TipoAccion.ENTRAR]
	))
	celda.ocupantes.assign([
		actor,
		FuenteReaccionPrueba.new(
			&"ocupante",
			0,
			[TiposInteraccion.TipoAccion.ENTRAR]
		),
	])

	var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
		celda,
		TiposInteraccion.TipoAccion.ENTRAR,
		actor
	)
	var ids: Array[StringName] = []
	for reaccion in reacciones:
		ids.append(reaccion.id_estable)

	_comprobar(
		ids == [
			&"barro",
			&"humo_veneno_a",
			&"humo_veneno_b",
			&"trampa",
			&"ocupante",
		],
		"Debe ordenar por categoría, prioridad e ID estable."
	)
	_comprobar(&"actor" not in ids, "El actor no debe reaccionar como ocupante de sí mismo.")
	_comprobar(&"solo_salir" not in ids, "Debe filtrar fuentes que no admiten ENTRAR.")
	_comprobar(
		reacciones[1].categoria == TiposInteraccion.CategoriaReaccion.EFECTO_SUPERFICIE,
		"El humo venenoso debe conservar la categoría de superficie."
	)
	var dirigida := FuenteReaccionPrueba.new(
		&"palanca",
		0,
		[],
		[TiposInteraccion.TipoAccion.IMPACTAR]
	)
	celda.interactuables.append(dirigida)
	var consultor := ConsultorReaccionesCelda.new()
	_comprobar(
		consultor.obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.IMPACTAR, actor
		).is_empty(),
		"Una reacción dirigida no debe ejecutarse al elegir el piso."
	)
	_comprobar(
		consultor.obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.IMPACTAR, actor, dirigida
		)[0].receptor == dirigida,
		"El objetivo dirigido elegido debe incorporarse a la resolución."
	)
	_comprobar(
		consultor.obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.IMPACTAR, actor, null, true
		)[0].receptor == dirigida,
		"La UI debe poder descubrir receptores dirigidos sin ejecutarlos."
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
