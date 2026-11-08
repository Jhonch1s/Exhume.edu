@tool
extends AccionTrigger

const PANTALLA_FINAL := "res://scenes/Prision/fin_demo.tscn"


func validar_configuracion() -> String:
	return ""


func ejecutar(escenario: Node, _trigger: TriggerMapa) -> StringName:
	var peeble := escenario.tablero.obtener_interactuable(&"banga_peeble") as PersonajeNPC
	var rengo := escenario.tablero.obtener_interactuable(&"banga_peeble_001") as PersonajeNPC
	var roffa := escenario.tablero.obtener_interactuable(&"banga_roffa") as PersonajeNPC
	var puerta := escenario.tablero.obtener_interactuable(&"interactuable_001") as PuertaInteractuable
	if peeble == null or rengo == null or roffa == null or puerta == null:
		return &"salida_prision_sin_personajes"
	# La ruta con Roffa libre requiere resolver primero su encuentro en la salida.
	if peeble.esta_muerto() and rengo.esta_muerto() and not escenario.en_combate and (roffa.esta_muerto() or not puerta.abierta):
		escenario.get_tree().call_deferred(&"change_scene_to_file", PANTALLA_FINAL)
	return &""
