class_name DefinicionFuenteLuz
extends DefinicionInteractuable

@export_category("Iluminacion logica")
@export_range(0, 32, 1, "or_greater") var radio_luz: int = 2
@export_range(0, 16, 1, "or_greater") var radio_penumbra: int = 1
@export var atraviesa_muros: bool = false

@export_category("Presencia en la celda")
@export_range(0, 16, 1, "or_greater") var altura: int = 0
@export var permite_caminar: bool = true
@export var bloquea_vision: bool = false

@export_category("Mascara de fog")
@export var familia_fog: StringName = &"terreno"
@export var coordenada_fog: Vector2i = Vector2i.ZERO

@export_category("Representacion")
@export var textura: Texture2D
@export var region_encendida: Rect2
@export var region_apagada: Rect2
@export var desplazamiento_sprite: Vector2 = Vector2(0, -32)

@export_category("Presentacion del estado")
@export var mensaje_basico_encendida: StringName = &"fuente_luz.basico_encendida"
@export var mensaje_basico_apagada: StringName = &"fuente_luz.basico_apagada"

@export_category("Sonido")
@export var sonido_ambiente: AudioStream
@export var sonido_encender: AudioStream
@export var sonido_apagar: AudioStream


func es_valida() -> bool:
	return (
		super.es_valida()
		and textura != null
		and region_encendida.size.x > 0.0
		and region_encendida.size.y > 0.0
		and region_apagada.size.x > 0.0
		and region_apagada.size.y > 0.0
	)
