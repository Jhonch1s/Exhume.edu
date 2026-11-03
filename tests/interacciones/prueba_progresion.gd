extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var ficha := (load("res://scenes/ficha/ficha.tscn") as PackedScene).instantiate() as Ficha
	root.add_child(ficha)
	var hud := (load("res://scenes/ui/hud/hud.tscn") as PackedScene).instantiate() as HUD
	root.add_child(hud)
	hud.configurar_ficha(ficha)
	ficha.progresion_cambiada.connect(hud.actualizar_desde_ficha)
	comprobar(not hud.indicador_progresion.visible, "Sin recompensa pendiente no aparece el indicador.")
	ficha.pv_actual -= 2
	ficha.energia_actual -= 10
	ficha.usos_ataque_doble = 0
	ficha.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	var recursos := ficha.recursos_turno.obtener_restantes()
	var vida := ficha.pv_actual
	ficha.ganar_experiencia(99)
	comprobar(ficha.nivel == 1 and ficha.nivel_recompensa_pendiente == 0, "99 XP no sube de nivel.")
	ficha.ganar_experiencia(1)
	comprobar(ficha.nivel == 2 and ficha.nivel_recompensa_pendiente == 2, "100 XP concede nivel 2 y una elección pendiente.")
	comprobar(hud.indicador_progresion.visible, "El indicador aparece al obtener la recompensa.")
	comprobar(ficha.pv_actual == vida and ficha.energia_actual == 190 and ficha.usos_ataque_doble == 0 and ficha.recursos_turno.obtener_restantes() == recursos, "Subir no cura ni repone energía, acciones o habilidades.")
	ficha.ganar_experiencia(550)
	comprobar(ficha.experiencia_acumulada == 650 and ficha.nivel == 2 and ficha.nivel_recompensa_pendiente == 2, "Conserva XP excedente y una sola elección en el corte de nivel 2.")
	ficha.ganar_experiencia(-100)
	comprobar(ficha.experiencia_acumulada == 650, "Una recompensa negativa no retira XP.")
	var pendiente: Dictionary = JSON.parse_string(JSON.stringify(ficha.obtener_estado_persistente()))
	var motivo := ficha.restaurar_estado_persistente(pendiente)
	comprobar(motivo == &"" and ficha.nivel_recompensa_pendiente == 2 and ficha.experiencia_acumulada == 650, "JSON conserva XP y elección pendiente: %s." % motivo)
	var antiguo := pendiente.duplicate(true)
	antiguo.erase("nivel_recompensa_pendiente")
	antiguo.erase("pasivas_aprendidas")
	antiguo["nivel"] = 1
	comprobar(ficha.restaurar_estado_persistente(antiguo) == &"" and ficha.nivel == 2 and ficha.nivel_recompensa_pendiente == 2, "Migra XP antigua sin perder la recompensa.")
	comprobar(ficha.pv_actual == vida and ficha.usos_ataque_doble == 0, "La migración no cura ni recupera habilidades.")
	for valor in [-1, 1, 3, "2", null, 2.5]:
		var corrupto := pendiente.duplicate(true)
		corrupto["nivel_recompensa_pendiente"] = valor
		comprobar(ficha.restaurar_estado_persistente(corrupto) != &"" and ficha.nivel_recompensa_pendiente == 2, "Rechaza elección inválida sin mutar: %s." % str(valor))
	var panel = (load("res://scenes/ui/personajes/panel_progresion.tscn") as PackedScene).instantiate()
	root.add_child(panel)
	var seleccion: Array[String] = []
	panel.recompensa_elegida.connect(func(id: String): seleccion.append(id))
	var opciones: Array[Dictionary] = [{"id": "prueba", "nombre": "Prueba de interfaz", "tipo": "Pasiva", "descripcion": "Efecto de prueba", "coste": "Sin usos"}]
	panel.mostrar(2, opciones, "")
	comprobar(panel.visible and panel.selector.get_selected_items().is_empty() and panel.boton_aprender.disabled, "La elección espera una selección explícita.")
	panel._confirmar()
	comprobar(seleccion.is_empty(), "Confirmar sin selección no emite una recompensa.")
	panel.selector.select(0)
	panel._seleccionar(0)
	comprobar(panel.visible and panel.detalle.text.contains("Efecto de prueba") and panel.detalle.text.contains("Sin usos"), "La elección muestra tipo, efecto y coste antes de confirmar.")
	comprobar(not panel.boton_aprender.disabled and panel.boton_aprender.text.contains("Prueba de interfaz"), "La confirmación identifica la opción elegida.")
	panel.hide()
	comprobar(seleccion.is_empty() and ficha.nivel_recompensa_pendiente == 2, "Cerrar el panel conserva la elección pendiente.")
	panel.mostrar(2, opciones, "")
	comprobar(panel.selector.get_selected_items().is_empty() and panel.boton_aprender.disabled, "Reabrir vuelve a pedir selección.")
	panel.selector.select(0)
	panel._seleccionar(0)
	panel._confirmar()
	comprobar(seleccion == ["prueba"], "Confirmar entrega el ID de la opción elegida.")
	panel._confirmar()
	comprobar(seleccion.size() == 1, "Una doble confirmación no emite la recompensa dos veces.")
	opciones = []
	panel.mostrar(2, opciones, "Resumen")
	panel._confirmar()
	comprobar(seleccion.size() == 1, "Un resumen sin opciones no emite recompensas.")
	for clase in ["Guerrero", "Ladrón", "Mago"]:
		var catalogo := CatalogoHabilidades.opciones(clase)
		panel.mostrar(2, catalogo, "", clase)
		comprobar(panel.titulo.text.contains(clase.to_upper()), "El panel identifica la clase " + clase)
		for i in catalogo.size():
			var textura := CatalogoHabilidades.icono(catalogo[i]["id"])
			comprobar(textura != null and textura.get_size() == Vector2(32, 32) and panel.selector.get_item_icon(i) == textura, "El panel muestra el icono de " + catalogo[i]["id"])
			panel.selector.select(i)
			panel._seleccionar(i)
			comprobar(panel.icono.texture == textura and panel.detalle.text.contains(catalogo[i]["descripcion"]) and panel.detalle.text.contains(catalogo[i]["coste"]), "El detalle muestra imagen, efecto y coste de " + catalogo[i]["id"])
	for id in ["ataque_doble", "ocultarse", "bola_de_fuego"]:
		var textura := CatalogoHabilidades.icono(id)
		comprobar(textura != null and textura.get_size() == Vector2(32, 32), "Existe el icono inicial de " + id)
	comprobar(ficha.aprender_recompensa("ariete") and not hud.indicador_progresion.visible, "El indicador desaparece al aprender.")
	var aprendido := ficha.obtener_estado_persistente()
	comprobar(ficha.restaurar_estado_persistente(pendiente) == &"" and hud.indicador_progresion.visible, "Cargar una elección pendiente restaura el indicador.")
	comprobar(ficha.restaurar_estado_persistente(aprendido) == &"" and not hud.indicador_progresion.visible, "Cargar una elección resuelta mantiene oculto el indicador.")
	panel.queue_free()
	hud.queue_free()
	ficha.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Progresión: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
