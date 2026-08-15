class_name OpcionAccion
extends RefCounted

var id: StringName:
	get:
		return _id

var tipo: TiposInteraccion.TipoAccion:
	get:
		return _tipo

var texto: StringName:
	get:
		return _texto

var objetivo: Object:
	get:
		return _objetivo

var habilitada: bool:
	get:
		return _habilitada

var motivo_bloqueo: StringName:
	get:
		return _motivo_bloqueo

var secreta: bool:
	get:
		return _secreta

var costes_previstos: Dictionary[StringName, float]:
	get:
		return _costes_previstos.duplicate()

var prioridad: int:
	get:
		return _prioridad

var metadatos: Dictionary:
	get:
		return _metadatos.duplicate(true)

var tipo_linea_efecto: TiposInteraccion.TipoLineaEfecto:
	get:
		return _tipo_linea_efecto

var politica_cobro: TiposInteraccion.PoliticaCobro:
	get:
		return _politica_cobro

var _id: StringName
var _tipo: TiposInteraccion.TipoAccion
var _texto: StringName
var _objetivo: Object
var _habilitada: bool
var _motivo_bloqueo: StringName
var _secreta: bool
var _costes_previstos: Dictionary[StringName, float]
var _prioridad: int
var _metadatos: Dictionary
var _tipo_linea_efecto: TiposInteraccion.TipoLineaEfecto
var _politica_cobro: TiposInteraccion.PoliticaCobro


func _init(
	id_inicial: StringName,
	tipo_inicial: TiposInteraccion.TipoAccion,
	texto_inicial: StringName,
	objetivo_inicial: Object = null,
	habilitada_inicial: bool = true,
	motivo_bloqueo_inicial: StringName = &"",
	costes_previstos_iniciales: Dictionary[StringName, float] = {},
	prioridad_inicial: int = 0,
	secreta_inicial: bool = false,
	metadatos_iniciales: Dictionary = {},
	tipo_linea_efecto_inicial: TiposInteraccion.TipoLineaEfecto = (
		TiposInteraccion.TipoLineaEfecto.NINGUNA
	),
	politica_cobro_inicial: TiposInteraccion.PoliticaCobro = (
		TiposInteraccion.PoliticaCobro.SOLO_EXITO
	)
) -> void:
	_id = id_inicial
	_tipo = tipo_inicial
	_texto = texto_inicial
	_objetivo = objetivo_inicial
	_habilitada = habilitada_inicial
	_secreta = secreta_inicial
	_costes_previstos = costes_previstos_iniciales.duplicate()
	_prioridad = prioridad_inicial
	_metadatos = metadatos_iniciales.duplicate(true)
	_tipo_linea_efecto = tipo_linea_efecto_inicial
	_politica_cobro = politica_cobro_inicial

	if _habilitada:
		_motivo_bloqueo = &""
	elif motivo_bloqueo_inicial == &"":
		_motivo_bloqueo = &"motivo_no_especificado"
	else:
		_motivo_bloqueo = motivo_bloqueo_inicial


static func crear_habilitada(
	id_inicial: StringName,
	tipo_inicial: TiposInteraccion.TipoAccion,
	texto_inicial: StringName,
	objetivo_inicial: Object = null,
	costes_previstos_iniciales: Dictionary[StringName, float] = {},
	prioridad_inicial: int = 0,
	secreta_inicial: bool = false,
	metadatos_iniciales: Dictionary = {},
	tipo_linea_efecto_inicial: TiposInteraccion.TipoLineaEfecto = (
		TiposInteraccion.TipoLineaEfecto.NINGUNA
	),
	politica_cobro_inicial: TiposInteraccion.PoliticaCobro = (
		TiposInteraccion.PoliticaCobro.SOLO_EXITO
	)
) -> OpcionAccion:
	return OpcionAccion.new(
		id_inicial,
		tipo_inicial,
		texto_inicial,
		objetivo_inicial,
		true,
		&"",
		costes_previstos_iniciales,
		prioridad_inicial,
		secreta_inicial,
		metadatos_iniciales,
		tipo_linea_efecto_inicial,
		politica_cobro_inicial
	)


static func crear_bloqueada(
	id_inicial: StringName,
	tipo_inicial: TiposInteraccion.TipoAccion,
	texto_inicial: StringName,
	objetivo_inicial: Object,
	motivo_bloqueo_inicial: StringName,
	costes_previstos_iniciales: Dictionary[StringName, float] = {},
	prioridad_inicial: int = 0,
	secreta_inicial: bool = false,
	metadatos_iniciales: Dictionary = {},
	tipo_linea_efecto_inicial: TiposInteraccion.TipoLineaEfecto = (
		TiposInteraccion.TipoLineaEfecto.NINGUNA
	),
	politica_cobro_inicial: TiposInteraccion.PoliticaCobro = (
		TiposInteraccion.PoliticaCobro.SOLO_EXITO
	)
) -> OpcionAccion:
	return OpcionAccion.new(
		id_inicial,
		tipo_inicial,
		texto_inicial,
		objetivo_inicial,
		false,
		motivo_bloqueo_inicial,
		costes_previstos_iniciales,
		prioridad_inicial,
		secreta_inicial,
		metadatos_iniciales,
		tipo_linea_efecto_inicial,
		politica_cobro_inicial
	)
