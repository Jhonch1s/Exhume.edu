@tool
class_name AccionTriggerDialogo
extends AccionTrigger

@export var recurso_dialogo: DialogueResource
@export var punto_inicio: String = "start"


func validar_configuracion() -> String:
	if recurso_dialogo == null:
		return "Asigna un recurso de diálogo."
	if not recurso_dialogo.cues.has(punto_inicio):
		return "La etiqueta '%s' no existe en el diálogo." % punto_inicio
	return ""


func ejecutar(escenario: Node, _trigger: TriggerMapa) -> StringName:
	if not validar_configuracion().is_empty():
		return &"dialogo_trigger_invalido"
	var globo := DisparadorDialogoArea.mostrar(
		recurso_dialogo, punto_inicio, [escenario.ficha_jugador, escenario]
	)
	if globo == null:
		return &"dialogo_trigger_no_iniciado"
	# Cerrar el globo anticipadamente también libera la cámara del escenario.
	globo.tree_exiting.connect(escenario._on_dialogo_camara_finalizado.bind(recurso_dialogo), CONNECT_ONE_SHOT)
	escenario.gestor_triggers.esperar_globo(globo)
	return &""
