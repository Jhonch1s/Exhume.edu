class_name ArchivoPartida
extends RefCounted


func guardar(ruta: String, snapshot: Dictionary) -> StringName:
	if ruta.is_empty() or snapshot.is_empty():
		return &"guardado_invalido"
	var temporal := ruta + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		return &"archivo_guardado_no_disponible"
	archivo.store_string(JSON.stringify(snapshot))
	archivo.close()
	var comprobacion: Variant = cargar(temporal)
	if not comprobacion is Dictionary or comprobacion.get("version") != snapshot.get("version"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
		return &"archivo_guardado_invalido"
	return _reemplazar(temporal, ruta)


func cargar(ruta: String) -> Variant:
	if ruta.is_empty() or not FileAccess.file_exists(ruta):
		return &"archivo_guardado_inexistente"
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return &"archivo_guardado_no_disponible"
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	return datos if datos is Dictionary else &"archivo_guardado_invalido"


func _reemplazar(temporal: String, destino: String) -> StringName:
	var ruta_temporal := ProjectSettings.globalize_path(temporal)
	var ruta_destino := ProjectSettings.globalize_path(destino)
	var respaldo := ruta_destino + ".bak"
	DirAccess.remove_absolute(respaldo)
	var habia_guardado := FileAccess.file_exists(destino)
	if habia_guardado and DirAccess.rename_absolute(ruta_destino, respaldo) != OK:
		DirAccess.remove_absolute(ruta_temporal)
		return &"archivo_guardado_no_reemplazado"
	if DirAccess.rename_absolute(ruta_temporal, ruta_destino) != OK:
		if habia_guardado:
			DirAccess.rename_absolute(respaldo, ruta_destino)
		return &"archivo_guardado_no_reemplazado"
	DirAccess.remove_absolute(respaldo)
	return &""
