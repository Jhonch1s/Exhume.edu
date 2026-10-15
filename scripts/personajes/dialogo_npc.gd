class_name DialogoNPC
extends Resource

## Tema que un personaje puede ofrecer desde su menu de interaccion.

@export var id_dialogo: StringName = &""
@export var titulo: String = ""
@export var recurso: DialogueResource
@export var punto_inicio: String = "start"
@export var pruebas: Array[PruebaDialogoNPC] = []


func obtener_prueba(id_prueba: StringName) -> PruebaDialogoNPC:
	var encontrada: PruebaDialogoNPC
	for prueba in pruebas:
		if prueba == null or not prueba.es_valida():
			return null
		if prueba.id_prueba == id_prueba:
			if encontrada != null:
				return null
			encontrada = prueba
	return encontrada


func es_valido() -> bool:
	return (
		id_dialogo != &""
		and not titulo.strip_edges().is_empty()
		and recurso != null
		and not punto_inicio.strip_edges().is_empty()
	)
