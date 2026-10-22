extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var ficha := (load("res://scenes/ficha/ficha.tscn") as PackedScene).instantiate() as Ficha
	root.add_child(ficha)
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
	var panel = load("res://scenes/ui/personajes/panel_progresion.gd").new()
	root.add_child(panel)
	var seleccion: Array[String] = []
	panel.recompensa_elegida.connect(func(id: String): seleccion.append(id))
	var opciones: Array[Dictionary] = [{"id": "prueba", "nombre": "Prueba de interfaz", "tipo": "Pasiva", "descripcion": "Efecto de prueba", "coste": "Sin usos"}]
	panel.mostrar(2, opciones, "")
	comprobar(panel.visible and panel.detalle.text.contains("Efecto de prueba") and panel.detalle.text.contains("Sin usos"), "La elección muestra tipo, efecto y coste antes de confirmar.")
	panel.hide()
	comprobar(seleccion.is_empty() and ficha.nivel_recompensa_pendiente == 2, "Cerrar el panel conserva la elección pendiente.")
	panel._confirmar()
	comprobar(seleccion == ["prueba"], "Confirmar entrega el ID de la opción elegida.")
	opciones = []
	panel.mostrar(2, opciones, "Resumen")
	panel._confirmar()
	comprobar(seleccion.size() == 1, "Un resumen sin opciones no emite recompensas.")
	panel.queue_free()
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
