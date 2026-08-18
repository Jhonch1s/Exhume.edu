class_name ResultadoReacciones
extends RefCounted

var resultados: Array[ResultadoAccion]:
	get:
		return _resultados.duplicate()
var mensajes: Array[StringName]:
	get:
		return _mensajes.duplicate()
var efectos_aplicados: Array:
	get:
		return _efectos_aplicados.duplicate(true)
var solicitudes_efecto: Array[SolicitudEfecto]:
	get:
		return _solicitudes_efecto.duplicate()
var solicitudes_validas: bool:
	get:
		return _solicitudes_validas
var motivo_solicitudes: StringName:
	get:
		return _motivo_solicitudes
var efectos_validos: bool:
	get:
		return _efectos_validos
var motivo_efectos: StringName:
	get:
		return _motivo_efectos
var cambios_estado: Array[Dictionary]:
	get:
		return _cambios_estado.duplicate(true)
var costes_consumidos: Dictionary[StringName, float]:
	get:
		return _costes_consumidos.duplicate()
var interrumpe_movimiento: bool:
	get:
		return _interrumpe_movimiento
var terminal: bool:
	get:
		return _terminal

var _resultados: Array[ResultadoAccion] = []
var _mensajes: Array[StringName] = []
var _efectos_aplicados: Array = []
var _solicitudes_sin_agregar: Array[SolicitudEfecto] = []
var _solicitudes_efecto: Array[SolicitudEfecto] = []
var _solicitudes_validas: bool = true
var _motivo_solicitudes: StringName = &""
var _efectos_validos: bool = true
var _motivo_efectos: StringName = &""
var _cambios_estado: Array[Dictionary] = []
var _costes_consumidos: Dictionary[StringName, float] = {}
var _interrumpe_movimiento: bool = false
var _terminal: bool = false


func agregar(resultado: ResultadoAccion) -> void:
	if resultado == null:
		return
	_resultados.append(resultado)
	_mensajes.append_array(resultado.mensajes)
	_efectos_aplicados.append_array(resultado.efectos_aplicados)
	_solicitudes_sin_agregar.append_array(resultado.solicitudes_efecto)
	_cambios_estado.append_array(resultado.cambios_estado)
	for clave in resultado.costes_consumidos:
		_costes_consumidos[clave] = (
			_costes_consumidos.get(clave, 0.0)
			+ resultado.costes_consumidos[clave]
		)
	_interrumpe_movimiento = (
		_interrumpe_movimiento or resultado.interrumpe_movimiento
	)
	_terminal = _terminal or resultado.terminal


func finalizar_solicitudes() -> void:
	var resultado := AgregadorSolicitudesEfecto.new().agregar(_solicitudes_sin_agregar)
	_solicitudes_validas = resultado.valido
	_motivo_solicitudes = resultado.motivo
	_solicitudes_efecto = resultado.solicitudes


func aplicar_efectos(aplicador: AplicadorEfectos) -> void:
	if not _solicitudes_validas or aplicador == null:
		return
	for solicitud in _solicitudes_efecto:
		if not aplicador.admite(solicitud):
			continue
		var motivo := aplicador.validar(solicitud)
		if motivo != &"":
			_efectos_validos = false
			_motivo_efectos = motivo
			return
	for solicitud in _solicitudes_efecto:
		if not aplicador.admite(solicitud):
			continue
		var aplicado: Variant = aplicador.aplicar(solicitud)
		if aplicado is StringName:
			_efectos_validos = false
			_motivo_efectos = aplicado
			return
		_efectos_aplicados.append(aplicado)
		_mensajes.append_array(aplicado.mensajes)
		_cambios_estado.append_array(aplicado.cambios_estado)
