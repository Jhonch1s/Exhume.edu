extends Node2D

@onready var fuente: FuenteLuzInteractuable = get_parent() as FuenteLuzInteractuable
@onready var humo: CPUParticles2D = $Humo
@onready var chispas: CPUParticles2D = $Chispas
var tiempo := randf() * TAU


func _ready() -> void:
	position = fuente.particulas.position if is_instance_valid(fuente.particulas) else fuente._obtener_offset_particulas()


func _process(delta: float) -> void:
	var activo := fuente.encendida and fuente._motas_celda_visible
	for particulas in [humo, chispas]:
		particulas.visible = activo
		particulas.emitting = activo
	if activo and is_instance_valid(fuente.particulas):
		tiempo += delta
		var brillo := 0.84 + 0.08 * sin(tiempo * 7.0) + 0.06 * sin(tiempo * 11.3)
		fuente.particulas.modulate = Color(brillo, brillo, brillo, 1.0)
