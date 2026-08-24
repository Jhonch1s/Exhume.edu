class_name ResultadoTirada
extends RefCounted

var valida: bool:
	get:
		return _valida

var motivo: StringName:
	get:
		return _motivo

var terminos: Array[Dictionary]:
	get:
		return _terminos.duplicate(true)

var total_calculado: int:
	get:
		return _total_calculado

var total_efectivo: int:
	get:
		return _total_efectivo

var origen: TiposTirada.Origen:
	get:
		return _origen

var presentacion: TiposTirada.Presentacion:
	get:
		return _presentacion

var _valida: bool
var _motivo: StringName
var _terminos: Array[Dictionary]
var _total_calculado: int
var _total_efectivo: int
var _origen: TiposTirada.Origen
var _presentacion: TiposTirada.Presentacion


func _init(
	valida_inicial: bool,
	motivo_inicial: StringName = &"",
	terminos_iniciales: Array[Dictionary] = [],
	total_inicial: int = 0,
	minimo_efectivo: int = 0,
	origen_inicial: TiposTirada.Origen = TiposTirada.Origen.SOLICITADA,
	presentacion_inicial: TiposTirada.Presentacion = TiposTirada.Presentacion.PRIMER_PLANO
) -> void:
	_valida = valida_inicial
	_motivo = &"" if valida_inicial else motivo_inicial
	_terminos = terminos_iniciales.duplicate(true)
	if not valida_inicial:
		_terminos.clear()
	_total_calculado = total_inicial if valida_inicial else 0
	_total_efectivo = maxi(total_inicial, minimo_efectivo) if valida_inicial else 0
	_origen = origen_inicial
	_presentacion = presentacion_inicial
