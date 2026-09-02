class_name ZonaExplorable
extends Node2D

const RUTA_ESCENARIO_BASE := "res://scenes/escenario_base/escenario_base.tscn"

var _iniciando_prueba_individual := false


func _ready() -> void:
	if get_tree().current_scene == self:
		call_deferred(&"_iniciar_prueba_individual")


func _iniciar_prueba_individual() -> void:
	if _iniciando_prueba_individual or get_tree().current_scene != self:
		return
	_iniciando_prueba_individual = true
	var escena_escenario := load(RUTA_ESCENARIO_BASE) as PackedScene
	if escena_escenario == null:
		push_error("No se pudo cargar EscenarioBase.")
		return
	var escenario := escena_escenario.instantiate()
	var zona_predeterminada := escenario.get_node_or_null(^"Zona")
	if zona_predeterminada == null:
		push_error("EscenarioBase no contiene el nodo Zona.")
		escenario.free()
		return
	var arbol := get_tree()
	var raiz := arbol.root
	zona_predeterminada.free()
	get_parent().remove_child(self)
	name = "Zona"
	escenario.add_child(self)
	raiz.add_child(escenario)
	arbol.current_scene = escenario
