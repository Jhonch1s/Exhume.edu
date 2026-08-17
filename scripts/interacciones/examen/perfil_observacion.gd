class_name PerfilObservacion
extends Resource

@export_category("Alcances")
@export_range(0.0, 100.0, 1.0, "or_greater") var alcance_basico: float = 5.0
@export_range(0.0, 100.0, 1.0, "or_greater") var alcance_detallado: float = 1.0
@export_range(0.0, 100.0, 1.0, "or_greater") var alcance_secreto: float = 1.0

@export_category("Requisitos actuales")
@export var requiere_objetivo_visible: bool = true
@export var requiere_linea_visual: bool = true


func es_valido() -> bool:
	return (
		alcance_basico >= 0.0
		and alcance_detallado >= 0.0
		and alcance_secreto >= 0.0
		and alcance_detallado <= alcance_basico
		and alcance_secreto <= alcance_basico
	)
