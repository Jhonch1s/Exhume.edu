@tool
class_name AccionTriggerViajar
extends AccionTrigger

## Se guarda una ruta para permitir conexiones de ida/vuelta sin recursos circulares.
@export_file("*.tscn") var escena_destino: String = ""
@export var id_spawn_destino: StringName = &"entrada"


func validar_configuracion() -> String:
	var ruta := obtener_ruta_destino()
	if not ruta.begins_with("res://") or not ruta.ends_with(".tscn") or not ResourceLoader.exists(ruta, "PackedScene"):
		return "Asigna una escena de zona de destino válida."
	if String(id_spawn_destino).strip_edges().is_empty():
		return "Asigna el ID del punto de aparición de destino."
	return ""


func obtener_ruta_destino() -> String:
	# El inspector puede serializar @export_file como uid:// al seleccionar una escena.
	if escena_destino.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(escena_destino)
		return ResourceUID.get_id_path(uid) if ResourceUID.has_id(uid) else ""
	return escena_destino


func ejecutar(escenario: Node, _trigger: TriggerMapa) -> StringName:
	if not validar_configuracion().is_empty():
		return &"destino_trigger_invalido"
	return await escenario.viajes.viajar(escenario, obtener_ruta_destino(), id_spawn_destino)
