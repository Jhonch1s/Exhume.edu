extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load(
		"res://scenes/ui/interacciones/panel_resultado_accion.tscn"
	) as PackedScene
	var panel := escena.instantiate() as PanelResultadoAccion
	root.add_child(panel)
	await process_frame

	var generador := RandomNumberGenerator.new()
	generador.seed = 144
	var motor := MotorDados.new(generador)
	var prueba := motor.resolver_prueba(3, [&"luz"])
	var estado_resuelto := generador.state
	var presentadas := [0]
	panel.tirada_presentada.connect(func(resultado):
		if resultado == prueba:
			presentadas[0] += 1
	)
	_comprobar(
		panel.mostrar_tirada("Prueba de percepción", prueba)
		and panel.visible
		and panel.etiqueta_titulo.text == "Prueba de percepción"
		and "Modo: Ventaja" in panel.etiqueta_mensajes.text
		and "Dados:" in panel.etiqueta_mensajes.text
		and "Seleccionado: %d" % prueba.dado_seleccionado in panel.etiqueta_mensajes.text
		and presentadas[0] == 1
		and generador.state == estado_resuelto,
		"El panel debe presentar la prueba ya resuelta sin volver a tirar."
	)
	panel.ocultar()

	var cantidad := motor.resolver(
		[{&"cantidad": 1, &"caras": 3, &"signo": 1}],
		0,
		TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.PRIMER_PLANO
	)
	_comprobar(
		panel.mostrar_tirada("Cantidad", cantidad)
		and "+1d3:" in panel.etiqueta_mensajes.text
		and "Total: %d" % cantidad.total_calculado in panel.etiqueta_mensajes.text,
		"El mismo panel debe presentar cantidades resueltas."
	)
	panel.ocultar()

	var solo_log := motor.resolver_prueba(
		3,
		[],
		[],
		TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.SOLO_LOG
	)
	_comprobar(
		not panel.mostrar_tirada("Secreta", solo_log) and not panel.visible,
		"SOLO_LOG no debe abrir la presentación en primer plano."
	)

	panel.queue_free()
	if _fallos.is_empty():
		print("PresentacionTirada: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
