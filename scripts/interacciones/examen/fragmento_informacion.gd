class_name FragmentoInformacion
extends Resource

@export_category("Identidad")
@export var id_fragmento: StringName = &""
@export var nivel: TiposInteraccion.NivelInformacion = (
	TiposInteraccion.NivelInformacion.VISIBLE
)
@export var id_mensaje: StringName = &""

@export_category("Descubrimiento")
@export var pistas_requeridas: Array[StringName] = []
@export var se_recuerda: bool = true


func es_valido() -> bool:
	if id_fragmento == &"" or id_mensaje == &"":
		return false
	if _tiene_pistas_invalidas_o_duplicadas():
		return false
	return (
		nivel != TiposInteraccion.NivelInformacion.SECRETO
		or not pistas_requeridas.is_empty()
	)


func _tiene_pistas_invalidas_o_duplicadas() -> bool:
	var pistas_vistas: Dictionary[StringName, bool] = {}
	for pista in pistas_requeridas:
		if pista == &"" or pistas_vistas.has(pista):
			return true
		pistas_vistas[pista] = true
	return false
