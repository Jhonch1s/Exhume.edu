extends "res://scenes/pruebas_habilidades/escenario_nivel_dos_base.gd"


func _crear_ficha() -> Ficha:
	var ficha := ESCENA_FICHA.instantiate() as Ficha
	ficha.set_script(preload("res://scenes/pruebas_habilidades/ficha_laboratorio.gd"))
	return ficha


func _ready() -> void:
	await super._ready()
	boton_campamento.text = "Reponer [B]"
	hud.habilidades[2].pressed.connect(func(): _apuntar_activa(1))
	hud.habilidades[3].pressed.connect(_alternar_pasiva_laboratorio)


func entrar_campamento() -> StringName:
	# El laboratorio recupera la ficha real; el campamento normal clona una ficha con una sola recompensa.
	return &"" if get_parent().reponer() else &"laboratorio_ocupado"


func abrir_progresion() -> StringName:
	var motivo := super.abrir_progresion()
	if motivo == &"":
		panel_progresion.detalle.text = panel_progresion.detalle.text.replace("Con 2", "Con 4").replace("con 2", "con 4")
	return motivo


func _on_habilidad_aprendida_hud() -> void:
	_apuntar_activa(0)


func _apuntar_activa(indice: int) -> void:
	if not hud.aprendida_disponible or ficha_jugador.activas_aprendidas.size() <= indice or _acciones_en_resolucion > 0:
		return
	var id: String = ficha_jugador.activas_aprendidas[indice]
	var opcion := CatalogoHabilidades.obtener(id)
	if ficha_jugador.usos_activas.get(id, 0) < 1 or ficha_jugador.validar_coste_turno(opcion["recurso"], 1) != &"":
		return
	var anterior := habilidad_en_seleccion
	_cancelar_habilidad_nueva()
	_cancelar_bola_fuego()
	seleccionando_ataque_doble = false
	if anterior != id:
		habilidad_en_seleccion = id


func _alternar_pasiva_laboratorio() -> void:
	if ficha_jugador != null and ficha_jugador.clase != "Ladrón":
		super._on_habilidad_aprendida_hud()


func _actualizar_disponibilidad_turno() -> void:
	super._actualizar_disponibilidad_turno()
	if ficha_jugador == null or not is_instance_valid(hud):
		return
	if is_instance_valid(boton_campamento):
		boton_campamento.disabled = get_parent()._bloqueado()
		boton_campamento.tooltip_text = "Laboratorio: reponer PV, energía, usos y oportunidades de turno."
	var boton := hud.habilidades[2]
	var deshabilitada := true
	if ficha_jugador.activas_aprendidas.size() == 2:
		var id: String = ficha_jugador.activas_aprendidas[1]
		var opcion := CatalogoHabilidades.obtener(id)
		boton.add_theme_font_size_override(&"font_size", 12)
		boton.text = "%s\n%d/1" % [opcion["nombre"].to_upper().replace(" ", "\n"), ficha_jugador.usos_activas.get(id, 0)]
		boton.tooltip_text = "Atajo 3 · %s\n%s\n%s" % [opcion["nombre"], opcion["descripcion"], opcion["coste"]]
		deshabilitada = not hud.aprendida_disponible or ficha_jugador.usos_activas.get(id, 0) < 1 or ficha_jugador.validar_coste_turno(opcion["recurso"], 1) != &""
		if id == "paso_sombra" and ficha_jugador.turnos_oculto < 1:
			deshabilitada = true
			boton.tooltip_text += "\nFalta estar OCULTO. Se permite en combate con una acción adicional libre."
	boton.disabled = deshabilitada
	boton = hud.habilidades[3]
	boton.add_theme_font_size_override(&"font_size", 12)
	deshabilitada = not hud.aprendida_disponible
	boton.text = "PASIVAS\nAUTOMÁTICAS"
	match ficha_jugador.clase:
		"Guerrero":
			boton.text = "EMPUJE\nAL ACERTAR"
			deshabilitada = true
		"Mago":
			boton.text = "CONTAGIO\n" + (ficha_jugador.contagio_elegido.to_upper() if ficha_jugador.contagio_elegido != "" else "NO")
		"Ladrón":
			deshabilitada = true
	boton.disabled = deshabilitada
	var textos: Array[String] = []
	for id in ficha_jugador.pasivas_aprendidas:
		var opcion := CatalogoHabilidades.obtener(id)
		textos.append("%s: %s" % [opcion["nombre"], opcion["descripcion"].replace("Con 2", "Con 4").replace("con 2", "con 4")])
	boton.tooltip_text = "Atajo 4 · " + "\n".join(textos)
