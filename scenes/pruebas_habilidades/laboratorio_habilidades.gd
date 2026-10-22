extends "res://scenes/pruebas_habilidades/escenario_nivel_dos.gd"

const CLASES := ["Guerrero", "Ladrón", "Mago"]
var reconstruyendo := false
var selector_clase: OptionButton
var boton_reponer: Button
var boton_reiniciar: Button
var resumen: Label


func _crear_escenario() -> Node:
	var nuevo := ESCENARIO.instantiate()
	nuevo.set_script(preload("res://scenes/pruebas_habilidades/escenario_laboratorio_base.gd"))
	nuevo.ruta_guardado_prueba = "user://laboratorio_habilidades_%s.json" % clase
	return nuevo


func _al_preparar_arena() -> void:
	var f: Ficha = escenario.ficha_jugador
	for opcion in CatalogoHabilidades.opciones(clase):
		if opcion["tipo"] == "Activa":
			f.activas_aprendidas.append(opcion["id"])
			f.usos_activas[opcion["id"]] = 1
		else:
			f.pasivas_aprendidas.append(opcion["id"])
	f.nivel_recompensa_pendiente = 0
	f.progresion_cambiada.emit()
	ayuda.text = "LABORATORIO · %s · Todo desbloqueado\n1: inicial · 2 y 3: activas · 4: Contagio (Mago)\nEmpuje: decidir tras acertar · Esc: cancelar apuntado\nClic derecho: caminar · P: efectos · B: reponer\nCambiar de clase o reiniciar reconstruye toda la arena." % clase
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 345)
	panel.custom_minimum_size = Vector2(410, 0)
	capa_ayuda.add_child(panel)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override(&"separation", 10)
	panel.add_child(contenido)
	selector_clase = OptionButton.new()
	for nombre in CLASES:
		selector_clase.add_item(nombre)
	selector_clase.select(CLASES.find(clase))
	selector_clase.item_selected.connect(func(indice: int): cambiar_clase(indice))
	contenido.add_child(selector_clase)
	boton_reponer = Button.new()
	boton_reponer.text = "Reponer PV, energía, usos y turno"
	boton_reponer.tooltip_text = "Control de pruebas: limpia estados, recupera las tres activas y reinicia tus oportunidades de turno."
	boton_reponer.pressed.connect(reponer)
	contenido.add_child(boton_reponer)
	boton_reiniciar = Button.new()
	boton_reiniciar.text = "Reiniciar enemigos y superficies"
	boton_reiniciar.pressed.connect(func(): cambiar_clase(CLASES.find(clase)))
	contenido.add_child(boton_reiniciar)
	resumen = Label.new()
	resumen.add_theme_font_size_override(&"font_size", 16)
	contenido.add_child(resumen)
	escenario._actualizar_disponibilidad_turno()


func _bloqueado() -> bool:
	return reconstruyendo or not is_instance_valid(escenario) or escenario.ficha_jugador == null or escenario.hud.ficha != escenario.ficha_jugador or is_instance_valid(escenario.campamento) or escenario.interaccion_modal_activa or escenario._acciones_en_resolucion > 0 or escenario._turno_exploracion_en_curso or escenario._hay_actor_moviendose() or (escenario.en_combate and not escenario._es_turno_jugador())


func _process(_delta: float) -> void:
	if not is_instance_valid(selector_clase):
		return
	var bloqueado := _bloqueado()
	selector_clase.disabled = bloqueado
	boton_reponer.disabled = bloqueado
	boton_reiniciar.disabled = bloqueado
	if not is_instance_valid(escenario) or escenario.ficha_jugador == null:
		return
	var f: Ficha = escenario.ficha_jugador
	var lineas: Array[String] = ["Pasivas disponibles:"]
	for id in f.pasivas_aprendidas:
		lineas.append("• " + CatalogoHabilidades.obtener(id)["nombre"] + (" · usada este turno" if id in f.pasivas_usadas_turno else ""))
	if f.conoce_habilidad("inercia"):
		lineas.append("Inercia: %d pasos gratuitos" % f.pasos_inercia)
	lineas.append("Guardado propio del laboratorio [F5/F9]")
	resumen.text = "\n".join(lineas)


func reponer() -> bool:
	if _bloqueado():
		return false
	var f: Ficha = escenario.ficha_jugador
	escenario._cancelar_habilidad_nueva()
	escenario._cancelar_bola_fuego()
	escenario.seleccionando_ataque_doble = false
	for clave in f.obtener_claves_estado():
		f.retirar_estado(clave)
	f.raciones = maxi(f.raciones, 1)
	f.descansar_en_campamento()
	f.raciones = 3
	f.romper_ocultamiento()
	f.iniciar_turno()
	escenario.hud.actualizar_desde_ficha()
	escenario._actualizar_disponibilidad_turno()
	return true


func cambiar_clase(indice: int) -> void:
	if indice < 0 or indice >= CLASES.size() or _bloqueado():
		return
	reconstruyendo = true
	clase = CLASES[indice]
	escenario.queue_free()
	capa_ayuda.queue_free()
	await get_tree().process_frame
	await super._ready()
	reconstruyendo = false
