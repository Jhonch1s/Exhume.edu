class_name DefinicionLlave
extends DefinicionItem

@export var patron_cerradura: StringName = &""
@export var consumir_al_usar: bool = false


func es_valida() -> bool:
	return (
		super.es_valida()
		and &"llave" in etiquetas
		and patron_cerradura != &""
	)
