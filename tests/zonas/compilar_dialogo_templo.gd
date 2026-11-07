extends SceneTree


func _init() -> void:
	var ruta := "res://dialogues/templo/lamentos.dialogue"
	var resultado := DMCompiler.compile_string(FileAccess.get_file_as_string(ruta), ruta)
	if not resultado.errors.is_empty():
		push_error("El diálogo del templo contiene errores: %s" % resultado.errors)
		quit(1)
		return
	var recurso := DialogueResource.new()
	recurso.using_states = resultado.using_states
	recurso.cues = resultado.cues
	recurso.first_cue = resultado.first_cue
	recurso.character_names = resultado.character_names
	recurso.lines = resultado.lines
	quit(0 if ResourceSaver.save(recurso, "res://dialogues/templo/lamentos.tres") == OK else 1)
