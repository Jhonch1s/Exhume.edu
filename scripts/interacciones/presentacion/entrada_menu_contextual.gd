class_name EntradaMenuContextual
extends RefCounted

enum TipoEntrada {
	ACCION,
	OBJETIVO,
	ITEM,
	IMPACTO,
	CANCELAR,
}

var tipo: TipoEntrada
var texto: String
var habilitada: bool
var motivo_bloqueo: String
var opcion_accion: OpcionAccion
var objetivo: Object
var item: ItemInstancia
var icono: Texture2D


func _init(
	tipo_inicial: TipoEntrada,
	texto_inicial: String,
	habilitada_inicial: bool = true,
	motivo_bloqueo_inicial: String = "",
	opcion_inicial: OpcionAccion = null,
	objetivo_inicial: Object = null,
	item_inicial: ItemInstancia = null,
	icono_inicial: Texture2D = null
) -> void:
	tipo = tipo_inicial
	texto = texto_inicial
	habilitada = habilitada_inicial
	motivo_bloqueo = motivo_bloqueo_inicial
	opcion_accion = opcion_inicial
	objetivo = objetivo_inicial
	item = item_inicial
	icono = icono_inicial


static func desde_opcion(
	opcion: OpcionAccion,
	texto_resuelto: String,
	motivo_resuelto: String = ""
) -> EntradaMenuContextual:
	return EntradaMenuContextual.new(
		TipoEntrada.ACCION,
		texto_resuelto,
		opcion.habilitada,
		motivo_resuelto,
		opcion
	)


static func desde_objetivo(
	objetivo_inicial: Object,
	texto_resuelto: String
) -> EntradaMenuContextual:
	return EntradaMenuContextual.new(
		TipoEntrada.OBJETIVO,
		texto_resuelto,
		true,
		"",
		null,
		objetivo_inicial
	)


static func desde_item(
	item_inicial: ItemInstancia,
	texto_resuelto: String
) -> EntradaMenuContextual:
	return EntradaMenuContextual.new(
		TipoEntrada.ITEM,
		texto_resuelto,
		true,
		"",
		null,
		null,
		item_inicial,
		item_inicial.definicion.icono
	)


static func desde_impacto(
	objetivo_inicial: Object,
	texto_resuelto: String
) -> EntradaMenuContextual:
	return EntradaMenuContextual.new(
		TipoEntrada.IMPACTO,
		texto_resuelto,
		true,
		"",
		null,
		objetivo_inicial
	)


static func cancelar(texto_resuelto: String) -> EntradaMenuContextual:
	return EntradaMenuContextual.new(TipoEntrada.CANCELAR, texto_resuelto)
