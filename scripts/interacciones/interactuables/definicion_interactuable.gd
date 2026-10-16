class_name DefinicionInteractuable
extends Resource

@export_category("Identidad")
@export var id_definicion: StringName = &""
@export var nombre: String = ""
@export_multiline var descripcion_base: String = ""

@export_category("Semantica")
@export var etiquetas: Array[StringName] = []

@export_category("Informacion examinable")
@export var ilustracion_examen: Texture2D
@export var fragmentos_informacion: Array[FragmentoInformacion] = []
@export var perfil_observacion: PerfilObservacion

@export_category("Audio")
@export var sonido_examen: AudioStream

const SONIDO_ESTATUA_ANGEL_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/Mystic Loop 2.wav")
const SONIDO_ESTATUA_SIMPLE_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/BB20.wav")


func obtener_sonido_examen() -> AudioStream:
	if sonido_examen != null:
		return sonido_examen
	if id_definicion == &"trampero_sin_rostro":
		return SONIDO_ESTATUA_ANGEL_DEFECTO
	if id_definicion == &"estatua_templo":
		return SONIDO_ESTATUA_SIMPLE_DEFECTO
	return null


func es_valida() -> bool:
	if id_definicion == &"" or nombre.is_empty():
		return false
	if perfil_observacion != null and not perfil_observacion.es_valido():
		return false

	var ids_fragmentos: Dictionary[StringName, bool] = {}
	for fragmento in fragmentos_informacion:
		if fragmento == null or not fragmento.es_valido():
			return false
		if ids_fragmentos.has(fragmento.id_fragmento):
			return false
		ids_fragmentos[fragmento.id_fragmento] = true
	return true
