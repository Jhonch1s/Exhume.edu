class_name PruebaDialogoNPC
extends Resource

## ID estable y único entre los temas del mismo NPC; identifica el intento guardado.
@export var id_prueba: StringName = &""
@export var titulo: String = ""
@export_enum("fuerza", "destreza", "voluntad") var atributo: String = "voluntad"
@export var una_sola_vez: bool = true
@export var consecuencias_exito: Array[ConsecuenciaDialogoNPC] = []
@export var consecuencias_fallo: Array[ConsecuenciaDialogoNPC] = []


func es_valida() -> bool:
	return (
		id_prueba != &"" and not String(id_prueba).strip_edges().is_empty()
		and not titulo.strip_edges().is_empty()
		and atributo in ["fuerza", "destreza", "voluntad"]
	)


func validar_consecuencias(npc: PersonajeNPC, ficha: Ficha, conocimiento: RegistroConocimiento) -> StringName:
	for consecuencia in consecuencias_exito + consecuencias_fallo:
		if consecuencia == null:
			return &"consecuencia_dialogo_ausente"
		var motivo := consecuencia.validar(npc, ficha, conocimiento)
		if motivo != &"":
			return motivo
	return &""
