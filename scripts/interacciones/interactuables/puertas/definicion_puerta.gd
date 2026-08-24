class_name DefinicionPuerta
extends DefinicionInteractuable

enum ModoControl {
	MANUAL_CON_CERRADURA,
	MECANISMO,
}

@export_category("Control")
@export var modo_control: ModoControl = ModoControl.MANUAL_CON_CERRADURA

@export_category("Cerradura")
@export var patron_cerradura: StringName = &""

@export_category("Representacion")
@export var textura: Texture2D
@export var region_cerrada: Rect2 = Rect2(0, 0, 64, 96)
@export var region_abierta: Rect2 = Rect2(64, 0, 64, 96)
@export var desplazamiento_sprite: Vector2 = Vector2(0, -32)

@export_category("Sonido")
@export var sonido_abrir: AudioStream
@export var sonido_cerrar: AudioStream


func es_valida() -> bool:
	return (
		super.es_valida()
		and (
			modo_control == ModoControl.MECANISMO
			or patron_cerradura != &""
		)
		and textura != null
		and region_cerrada.size.x > 0.0
		and region_cerrada.size.y > 0.0
		and region_abierta.size.x > 0.0
		and region_abierta.size.y > 0.0
	)
