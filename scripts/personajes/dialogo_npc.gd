class_name DialogoNPC
extends Resource

## Tema que un personaje puede ofrecer desde su menu de interaccion.

@export var id_dialogo: StringName = &""
@export var titulo: String = ""
@export var recurso: DialogueResource
@export var punto_inicio: String = "start"


func es_valido() -> bool:
	return (
		id_dialogo != &""
		and not titulo.strip_edges().is_empty()
		and recurso != null
		and not punto_inicio.strip_edges().is_empty()
	)
