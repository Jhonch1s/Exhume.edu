@tool
class_name DisparadorDialogoArea
extends Area2D

## Este sript es para que no tengamos que reescribir constantemente lo de que aparezca
## el dialogo una y otra vez

signal dialogo_iniciado(recurso: Resource)
signal dialogo_finalizado(recurso: Resource)

@export_category("Configuración de Diálogo")
@export var recurso_dialogo: Resource = preload("res://dialogues/my_dialogue.dialogue")

##título o etiqueta de inicio dentro del archivo de diálogo (ej. 'start').
@export var punto_inicio: String = "start"

##acción de entrada para activar el diálogo cuando el jugador esté en el área.
@export var accion_activacion: StringName = &"ui_accept"

##si es true, solo reacciona cuando entra el jugador principal
@export var solo_jugador_principal: bool = true

##si es true, el diálogo se abre automáticamente al entrar en el área sin esperar a presionar Enter
@export var auto_iniciar_al_entrar: bool = false

##si es true, el diálogo solo se podrá activar una vez.
@export var una_sola_vez: bool = false

##Desactiva temporalmente el disparador si es true.
@export var deshabilitado: bool = false

var jugador_en_area: bool = false
var dialogo_activo: bool = false
var ya_ejecutado: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	var gestor := _obtener_dialogue_manager()
	if gestor != null:
		if not gestor.dialogue_started.is_connected(_on_dialogue_started):
			gestor.dialogue_started.connect(_on_dialogue_started)
		if not gestor.dialogue_ended.is_connected(_on_dialogue_ended):
			gestor.dialogue_ended.connect(_on_dialogue_ended)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not jugador_en_area or dialogo_activo or deshabilitado:
		return
	if una_sola_vez and ya_ejecutado:
		return
	if auto_iniciar_al_entrar:
		return

	var es_accion: bool = event.is_action_pressed(accion_activacion)
	var es_tecla_enter: bool = (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)
	)

	if es_accion or es_tecla_enter:
		abrir_dialogo()
		get_viewport().set_input_as_handled()


## Abre el diálogo si no hay otro en curso y el recurso es válido.
func abrir_dialogo() -> void:
	var gestor := _obtener_dialogue_manager()
	if dialogo_activo or deshabilitado or recurso_dialogo == null or gestor == null:
		return
	if una_sola_vez and ya_ejecutado:
		return

	ya_ejecutado = true
	dialogo_activo = true
	gestor.call(&"show_dialogue_balloon", recurso_dialogo, punto_inicio)
	dialogo_iniciado.emit(recurso_dialogo)


##desplegar un diálogo directamente desde código en 1 sola línea
static func mostrar(recurso: Resource, punto_de_inicio: String = "start", estados: Array = []) -> Node:
	var gestor: Node = null
	if Engine.has_singleton("DialogueManager"):
		gestor = Engine.get_singleton("DialogueManager")
	else:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null and tree.root.has_node("DialogueManager"):
			gestor = tree.root.get_node("DialogueManager")

	if gestor != null and recurso != null:
		return gestor.call(&"show_dialogue_balloon", recurso, punto_de_inicio, estados)
	return null


##vincular un area2D existente con un diálogo por código
static func vincular(area: Area2D, recurso: Resource, punto_de_inicio: String = "start", auto_iniciar: bool = false) -> DisparadorDialogoArea:
	if area == null:
		return null
	if area is DisparadorDialogoArea:
		var disp := area as DisparadorDialogoArea
		disp.recurso_dialogo = recurso
		disp.punto_inicio = punto_de_inicio
		disp.auto_iniciar_al_entrar = auto_iniciar
		return disp

	var nuevo_disparador := DisparadorDialogoArea.new()
	nuevo_disparador.name = "DisparadorDialogo"
	nuevo_disparador.recurso_dialogo = recurso
	nuevo_disparador.punto_inicio = punto_de_inicio
	nuevo_disparador.auto_iniciar_al_entrar = auto_iniciar
	area.add_child(nuevo_disparador)
	return nuevo_disparador


func _on_area_entered(area: Area2D) -> void:
	if _es_objetivo_valido(area):
		jugador_en_area = true
		if auto_iniciar_al_entrar and not dialogo_activo:
			abrir_dialogo()


func _on_area_exited(area: Area2D) -> void:
	if _es_objetivo_valido(area):
		jugador_en_area = false


func _on_body_entered(body: Node2D) -> void:
	if _es_objetivo_valido(body):
		jugador_en_area = true
		if auto_iniciar_al_entrar and not dialogo_activo:
			abrir_dialogo()


func _on_body_exited(body: Node2D) -> void:
	if _es_objetivo_valido(body):
		jugador_en_area = false


func _on_dialogue_started(resource: Resource) -> void:
	if resource == recurso_dialogo:
		dialogo_activo = true


func _on_dialogue_ended(resource: Resource) -> void:
	if resource == recurso_dialogo:
		await get_tree().create_timer(0.15).timeout
		dialogo_activo = false
		dialogo_finalizado.emit(resource)


func _obtener_dialogue_manager() -> Node:
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	if not Engine.is_editor_hint():
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null and tree.root.has_node("DialogueManager"):
			return tree.root.get_node("DialogueManager")
	return null


func _es_objetivo_valido(nodo: Node) -> bool:
	if nodo == null:
		return false
	if not solo_jugador_principal:
		return true
	var ficha := nodo as Ficha
	if ficha == null and nodo is Area2D:
		ficha = nodo.get_parent() as Ficha
	return ficha != null and ficha.id_actor == &"jugador_principal"
