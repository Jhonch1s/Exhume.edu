@tool
class_name ZonaExplorable
extends Node2D

const RUTA_ESCENARIO_BASE := "res://scenes/escenario_base/escenario_base.tscn"

@export var nombre_zona: String = ""

var _iniciando_prueba_individual := false


func _ready() -> void:
	if Engine.is_editor_hint():
		get_tree().node_added.connect(_al_agregar_nodo_en_editor)
		return
	if get_tree().current_scene == self:
		call_deferred(&"_iniciar_prueba_individual")


func _exit_tree() -> void:
	if Engine.is_editor_hint() and get_tree().node_added.is_connected(_al_agregar_nodo_en_editor):
		get_tree().node_added.disconnect(_al_agregar_nodo_en_editor)


func _al_agregar_nodo_en_editor(nodo: Node) -> void:
	if nodo is Interactuable and is_ancestor_of(nodo):
		_asignar_id_en_editor.call_deferred(nodo)


func _asignar_id_en_editor(nodo: Interactuable) -> void:
	if not is_instance_valid(nodo) or nodo.owner != self or EditorInterface.get_edited_scene_root() != self:
		return
	if _asignar_id_nuevo(nodo):
		nodo.notify_property_list_changed()
		EditorInterface.mark_scene_as_unsaved()


func _asignar_id_nuevo(nodo: Interactuable) -> bool:
	var ids: Dictionary = {}
	for otro in find_children("*", "", true, false):
		if otro is Interactuable and otro != nodo and otro.id_instancia != &"":
			ids[String(otro.id_instancia)] = true
	var actual := String(nodo.id_instancia)
	if not actual.is_empty() and not ids.has(actual):
		return false
	var prefijo := actual
	if prefijo.is_empty():
		prefijo = String(nodo.definicion.id_definicion) if nodo.definicion != null else "interactuable"
	var separador := prefijo.rfind("_")
	if separador >= 0 and prefijo.substr(separador + 1).is_valid_int():
		prefijo = prefijo.substr(0, separador)
	var siguiente := 1
	for id: String in ids:
		if id.begins_with(prefijo + "_"):
			var sufijo := id.trim_prefix(prefijo + "_")
			if sufijo.is_valid_int():
				siguiente = maxi(siguiente, sufijo.to_int() + 1)
	var nuevo := "%s_%03d" % [prefijo, siguiente]
	while ids.has(nuevo):
		siguiente += 1
		nuevo = "%s_%03d" % [prefijo, siguiente]
	nodo.id_instancia = StringName(nuevo)
	return true


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
	
