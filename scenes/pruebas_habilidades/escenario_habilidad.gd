extends Node2D

@export_enum("Ladrón", "Mago") var clase: String = "Ladrón"

const ESCENARIO := preload("res://scenes/escenario_base/escenario_base.tscn")
const ZONA := preload("res://scenes/pruebas_habilidades/zona_prueba_habilidades.tscn")


func _ready() -> void:
	var escenario := ESCENARIO.instantiate()
	escenario.get_node("Zona").free()
	var zona := ZONA.instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	var datos := {
		"nombre": "Aventurero de prueba", "titulo": "Prueba de habilidades",
		"clase": clase, "origen": "Prueba", "fuerza": 3,
		"destreza": 4, "voluntad": 4,
	}
	if not EstadoPartida.establecer_aventurero(datos):
		push_error("No se pudo preparar la clase de prueba.")
		escenario.free()
		return
	add_child(escenario)
	_crear_instrucciones()


func _crear_instrucciones() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	var ayuda := Label.new()
	ayuda.position = Vector2(12, 112)
	ayuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ayuda.add_theme_font_size_override(&"font_size", 17)
	ayuda.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	ayuda.add_theme_constant_override(&"shadow_offset_x", 2)
	ayuda.add_theme_constant_override(&"shadow_offset_y", 2)
	ayuda.text = (
		"PRUEBA %s · 1: %s\n" % [clase.to_upper(), "Ocultarse" if clase == "Ladrón" else "Bola de fuego"]
		+ "Enemigo a 4 casillas · Detecta a 2 casillas.\n"
		+ ("1: apunta y haz clic en la casilla del enemigo · Esc: cancelar.\n" if clase == "Mago" else "")
		+ "Clic derecho: caminar · Acércate para iniciar combate.\n"
		+ "Habilidades 1–4 · Objetos 5–8 · Fogata: recuperar usos."
	)
	capa.add_child(ayuda)
