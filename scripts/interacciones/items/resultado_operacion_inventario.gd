class_name ResultadoOperacionInventario
extends RefCounted

var exitosa: bool:
	get:
		return _exitosa
var motivo: StringName:
	get:
		return _motivo
var item: ItemInstancia:
	get:
		return _item
var cantidad: int:
	get:
		return _cantidad
var id_origen: StringName:
	get:
		return _id_origen
var id_destino: StringName:
	get:
		return _id_destino

var _exitosa: bool
var _motivo: StringName
var _item: ItemInstancia
var _cantidad: int
var _id_origen: StringName
var _id_destino: StringName


func _init(
	exitosa_inicial: bool,
	motivo_inicial: StringName = &"",
	item_inicial: ItemInstancia = null,
	cantidad_inicial: int = 0,
	id_origen_inicial: StringName = &"",
	id_destino_inicial: StringName = &""
) -> void:
	_exitosa = exitosa_inicial
	_motivo = &"" if exitosa_inicial else motivo_inicial
	_item = item_inicial if exitosa_inicial else null
	_cantidad = cantidad_inicial if exitosa_inicial else 0
	_id_origen = id_origen_inicial if exitosa_inicial else &""
	_id_destino = id_destino_inicial if exitosa_inicial else &""


static func crear_exito(
	item_inicial: ItemInstancia,
	cantidad_inicial: int,
	id_origen_inicial: StringName = &"",
	id_destino_inicial: StringName = &""
) -> ResultadoOperacionInventario:
	return ResultadoOperacionInventario.new(
		true,
		&"",
		item_inicial,
		cantidad_inicial,
		id_origen_inicial,
		id_destino_inicial
	)


static func crear_fallo(motivo_inicial: StringName) -> ResultadoOperacionInventario:
	return ResultadoOperacionInventario.new(false, motivo_inicial)
