class_name DefinicionPalanca
extends DefinicionInteractuable

@export_category("Presencia")
@export_range(0, 16, 1, "or_greater") var altura: int = 1

@export_category("Representacion")
@export var textura: Texture2D
@export var region_desactivada: Rect2 = Rect2(0, 0, 64, 64)
@export var region_activada: Rect2 = Rect2(64, 0, 64, 64)
@export var desplazamiento_sprite: Vector2 = Vector2(0, -16)

@export_category("Sonido")
@export var sonido_activar: AudioStream
@export var sonido_desactivar: AudioStream


func es_valida() -> bool:
	return (
		super.es_valida()
		and altura == 1
		and textura != null
		and region_desactivada.size == Vector2(64, 64)
		and region_activada.size == Vector2(64, 64)
	)
