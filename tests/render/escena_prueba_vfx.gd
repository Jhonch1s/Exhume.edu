extends Node

var escenario: Node


func _ready() -> void:
	escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	escenario.get_node("Zona").free()
	var zona := (load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn") as PackedScene).instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	add_child(escenario)
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	var ayuda := Label.new()
	ayuda.position = Vector2(24, 24)
	ayuda.text = "VFX · 1 Piedra · 2 Encaje · 3 Trampa · 4 Impacto · 5 Explosión · 6 Chillido · 7 Derrumbe · 0 Activar/desactivar"
	ayuda.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	ayuda.add_theme_constant_override(&"shadow_offset_x", 2)
	ayuda.add_theme_constant_override(&"shadow_offset_y", 2)
	capa.add_child(ayuda)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or escenario.ficha_jugador == null:
		return
	if event.keycode == KEY_0:
		escenario.gestor_vfx.intensidad_sacudida = 0.0 if escenario.gestor_vfx.intensidad_sacudida > 0.0 else 1.0
		escenario.gestor_vfx.limpiar()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_7:
		var perfiles := [&"piedra_moviendo", &"piedra_encajada", &"trampa", &"impacto", &"explosion", &"chillido", &"derrumbe"]
		escenario.gestor_vfx.solicitar(perfiles[event.keycode - KEY_1], escenario.ficha_jugador.global_position)
