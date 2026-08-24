class_name ResultadoPrueba
extends RefCounted

enum Modo {
	NORMAL,
	VENTAJA,
	DESVENTAJA,
}

enum Clasificacion {
	NORMAL,
	CRITICO,
	PIFIA,
}

var valida: bool:
	get:
		return _valida

var motivo: StringName:
	get:
		return _motivo

var dados: Array[int]:
	get:
		return _dados.duplicate()

var dado_seleccionado: int:
	get:
		return _dado_seleccionado

var atributo: int:
	get:
		return _atributo

var fuentes_ventaja: Array[StringName]:
	get:
		return _fuentes_ventaja.duplicate()

var fuentes_desventaja: Array[StringName]:
	get:
		return _fuentes_desventaja.duplicate()

var modo: Modo:
	get:
		return _modo

var clasificacion: Clasificacion:
	get:
		return _clasificacion

var exitosa: bool:
	get:
		return _exitosa

var origen: TiposTirada.Origen:
	get:
		return _origen

var presentacion: TiposTirada.Presentacion:
	get:
		return _presentacion

var _valida: bool
var _motivo: StringName
var _dados: Array[int]
var _dado_seleccionado: int
var _atributo: int
var _fuentes_ventaja: Array[StringName]
var _fuentes_desventaja: Array[StringName]
var _modo: Modo
var _clasificacion: Clasificacion
var _exitosa: bool
var _origen: TiposTirada.Origen
var _presentacion: TiposTirada.Presentacion


func _init(
	valida_inicial: bool,
	motivo_inicial: StringName = &"",
	dados_iniciales: Array[int] = [],
	dado_inicial: int = 0,
	atributo_inicial: int = 0,
	ventajas_iniciales: Array[StringName] = [],
	desventajas_iniciales: Array[StringName] = [],
	modo_inicial: Modo = Modo.NORMAL,
	clasificacion_inicial: Clasificacion = Clasificacion.NORMAL,
	exitosa_inicial: bool = false,
	origen_inicial: TiposTirada.Origen = TiposTirada.Origen.SOLICITADA,
	presentacion_inicial: TiposTirada.Presentacion = TiposTirada.Presentacion.PRIMER_PLANO
) -> void:
	_valida = valida_inicial
	_motivo = &"" if valida_inicial else motivo_inicial
	_dados = dados_iniciales.duplicate()
	_dado_seleccionado = dado_inicial if valida_inicial else 0
	_atributo = atributo_inicial if valida_inicial else 0
	_fuentes_ventaja = ventajas_iniciales.duplicate()
	_fuentes_desventaja = desventajas_iniciales.duplicate()
	if not valida_inicial:
		_dados.clear()
		_fuentes_ventaja.clear()
		_fuentes_desventaja.clear()
	_modo = modo_inicial if valida_inicial else Modo.NORMAL
	_clasificacion = clasificacion_inicial if valida_inicial else Clasificacion.NORMAL
	_exitosa = exitosa_inicial if valida_inicial else false
	_origen = origen_inicial
	_presentacion = presentacion_inicial
