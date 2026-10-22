extends Node2D

@export_enum("Guerrero", "Ladrón", "Mago") var clase := "Guerrero"

const ESCENARIO := preload("res://scenes/escenario_base/escenario_base.tscn")
const ZONA := preload("res://scenes/pruebas_habilidades/zona_prueba_habilidades.tscn")
var escenario: Node
var capa_ayuda: CanvasLayer
var ayuda: Label


func _ready() -> void:
	escenario = _crear_escenario()
	escenario.get_node("Zona").free()
	var zona := ZONA.instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	EstadoPartida.establecer_aventurero({
		"nombre": "Prueba nivel 2", "titulo": "Explorador de posibilidades",
		"clase": clase, "origen": "Prueba", "fuerza": 4, "destreza": 4, "voluntad": 3,
	})
	add_child(escenario)
	while escenario.ficha_jugador == null or escenario.hud.ficha != escenario.ficha_jugador:
		await get_tree().process_frame
	var f: Ficha = escenario.ficha_jugador
	f.ganar_experiencia(100)
	for npc in escenario.tablero.interactuables_por_id.values():
		if npc is PersonajeNPC:
			npc.definicion = npc.obtener_definicion_personaje().duplicate(true)
			npc.definicion.vida_maxima = 4
			npc.definicion.movimiento_fijo = 3
			npc.definicion.faccion_id = &"banda_arena"
			npc.estado_personaje = null
			npc._asegurar_estado()
	var coord_segundo := f.coordenada_mapa + Vector2i(4, 1)
	if escenario.habilidades_nivel_dos.libre(coord_segundo):
		var segundo := preload("res://scenes/personajes/npc.tscn").instantiate() as PersonajeNPC
		segundo.id_instancia = &"segundo_enemigo_nivel_dos"
		segundo.nombre_unico = "Compañero de arena"
		segundo.definicion = preload("res://scenes/pruebas_habilidades/enemigo_prueba_habilidad.tres").duplicate(true)
		segundo.definicion.vida_maxima = 4
		segundo.definicion.movimiento_fijo = 3
		segundo.definicion.faccion_id = &"banda_arena"
		segundo.coordenada_mapa = coord_segundo
		zona.get_node("Interactuables/Personajes").add_child(segundo)
		escenario.tablero.registrar_interactuable(coord_segundo, segundo)
		segundo.actualizar_posicion_visual()
	for entrada in [
		[Vector2i(1, 2), "res://scenes/efectos_superficie/Fuego.tscn", &"arena_fuego"],
		[Vector2i(-1, 2), "res://scenes/efectos_superficie/HumoVeneno.tscn", &"arena_veneno"],
		[Vector2i(-2, 0), "res://scenes/efectos_superficie/Humo.tscn", &"arena_humo"],
	]:
		var coord: Vector2i = f.coordenada_mapa + entrada[0]
		if escenario.habilidades_nivel_dos.libre(coord):
			escenario.tablero.desplegar_efecto_superficie(load(entrada[1]), coord, 0, entrada[2])
	var coord_trampa := f.coordenada_mapa + Vector2i(2, 1)
	if escenario.habilidades_nivel_dos.libre(coord_trampa):
		var trampa := preload("res://scenes/interactuables/trampas/TrampaSuperficie.tscn").instantiate() as TrampaSuperficie
		trampa.id_instancia = &"arena_placa_descubierta"
		trampa.estado = TrampaSuperficie.Estado.DESCUBIERTA
		zona.get_node("Interactuables").add_child(trampa)
		trampa.global_position = escenario.tablero.capa_referencia.to_global(escenario.tablero.capa_referencia.map_to_local(coord_trampa))
		escenario.tablero.registrar_interactuable(coord_trampa, trampa)
	var capa := CanvasLayer.new()
	capa_ayuda = capa
	capa.layer = 3
	add_child(capa)
	ayuda = Label.new()
	ayuda.position = Vector2(24, 180)
	ayuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ayuda.add_theme_font_size_override(&"font_size", 18)
	ayuda.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	ayuda.add_theme_constant_override(&"shadow_offset_x", 2)
	ayuda.add_theme_constant_override(&"shadow_offset_y", 2)
	ayuda.text = "NIVEL 2 · %s · Elige UNA recompensa [P]\n1: inicial · 2: activa / Contagio · Empuje: decidir tras acertar\nClic izquierdo: objetivo · Esc o clic derecho: cancelar apuntado\nClic derecho sin apuntado: caminar · B: campamento\nDos enemigos, fuego, veneno, humo y una placa · F6 reinicia para probar otra elección" % clase
	capa.add_child(ayuda)
	_al_preparar_arena()


func _crear_escenario() -> Node:
	var nuevo := ESCENARIO.instantiate()
	nuevo.set_script(preload("res://scenes/pruebas_habilidades/escenario_nivel_dos_base.gd"))
	nuevo.ruta_guardado_prueba = "user://prueba_nivel_dos_%s.json" % clase
	return nuevo


func _al_preparar_arena() -> void:
	escenario.abrir_progresion()
