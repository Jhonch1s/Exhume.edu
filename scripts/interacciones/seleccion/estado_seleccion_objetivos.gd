class_name EstadoSeleccionObjetivos
extends RefCounted

var celda_seleccionada: Variant = null
var objetivos_pendientes: Array[Interactuable] = []
var objetivo_seleccionado: Interactuable = null


func iniciar(
	coordenada: Vector2i,
	objetivos: Array[Interactuable]
) -> bool:
	limpiar()
	if objetivos.is_empty():
		return false

	celda_seleccionada = coordenada
	if objetivos.size() == 1:
		objetivo_seleccionado = objetivos[0]
	else:
		objetivos_pendientes = objetivos.duplicate()
	return true


func seleccionar(objetivo: Interactuable) -> bool:
	if (
		objetivo == null
		or not is_instance_valid(objetivo)
		or objetivo not in objetivos_pendientes
	):
		return false
	objetivo_seleccionado = objetivo
	objetivos_pendientes.clear()
	return true


func limpiar() -> void:
	objetivo_seleccionado = null
	objetivos_pendientes.clear()
	celda_seleccionada = null
