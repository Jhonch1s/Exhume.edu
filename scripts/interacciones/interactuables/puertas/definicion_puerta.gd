class_name DefinicionPuerta
extends DefinicionInteractuable

@export_category("Cerradura")
@export var patron_cerradura: StringName = &""

@export_category("Representacion")
@export var textura: Texture2D
@export var region_cerrada: Rect2 = Rect2(0, 0, 64, 96)
@export var region_abierta: Rect2 = Rect2(64, 0, 64, 96)
@export var desplazamiento_sprite: Vector2 = Vector2(0, -32)


func es_valida() -> bool:
	return (
		super.es_valida()
		and patron_cerradura != &""
		and textura != null
		and region_cerrada.size == Vector2(64, 96)
		and region_abierta.size == Vector2(64, 96)
	)
