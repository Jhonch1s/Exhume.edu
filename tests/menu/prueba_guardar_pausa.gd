extends SceneTree


class EscenarioPrueba extends Node:
	var es_escenario_de_descanso := false
	var control_descanso: Node
	var bloqueo: StringName = &""
	var resultado: StringName = &""
	var guardados := 0

	func _motivo_bloqueo_persistencia(_reposo: bool, _diagnostico: bool) -> StringName:
		return bloqueo

	func guardar_partida() -> StringName:
		guardados += 1
		return resultado


class CampamentoPrueba extends Node:
	var escenario: Node


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escenario := EscenarioPrueba.new()
	root.add_child(escenario)
	var capa := CanvasLayer.new()
	escenario.add_child(capa)
	var menu: Control = load("res://scenes/menu/menu_pausa_core.tscn").instantiate()
	capa.add_child(menu)
	menu._on_guardar_pressed()
	assert(escenario.guardados == 1 and menu.estado_guardado.text == "Partida guardada.")
	escenario.bloqueo = &"partida_jugador_en_movimiento"
	menu._on_guardar_pressed()
	assert(escenario.guardados == 1 and menu.estado_guardado.text.contains("No se pudo"))
	escenario.bloqueo = &""
	escenario.resultado = &"error_archivo"
	menu._on_guardar_pressed()
	assert(menu.estado_guardado.text.contains("error_archivo"))
	var mundo := EscenarioPrueba.new()
	root.add_child(mundo)
	var campamento := CampamentoPrueba.new()
	root.add_child(campamento)
	campamento.escenario = mundo
	escenario.es_escenario_de_descanso = true
	escenario.control_descanso = campamento
	menu._on_guardar_pressed()
	assert(mundo.guardados == 1 and menu.estado_guardado.text == "Partida guardada.")
	campamento.free()
	mundo.free()
	escenario.free()
	print("Menú de pausa: guardado y errores verificados")
	quit()
