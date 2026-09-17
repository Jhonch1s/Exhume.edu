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
	_comprobar(
		panel.vista_dado_1.get_node("SubViewport").find_world_3d()
		!= panel.vista_dado_2.get_node("SubViewport").find_world_3d(),
		"Cada dado debe tener su propio mundo 3D para evitar modelos superpuestos."
	)

	var generador := RandomNumberGenerator.new()
	generador.seed = 144
	var motor := MotorDados.new(generador)
	var prueba := motor.resolver_prueba(
		3, [&"luz"], [], TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.PRIMER_PLANO,
		[{&"fuente": &"anillo", &"valor": 2}]
	)
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
		and panel.etiqueta_objetivo.text == "OBJETIVO  ·  5 O MENOS"
		and "Base 3 +2 Anillo  =  5" in panel.etiqueta_bonos.text
		and not panel.etiqueta_veredicto.visible
		and panel.contenedor_dados.visible
		and panel.vista_dado_2.visible == (prueba.dados.size() == 2)
		and presentadas[0] == 1
		and generador.state == estado_resuelto,
		"El panel debe presentar la prueba ya resuelta sin volver a tirar."
	)
	await create_timer(1.5).timeout
	_comprobar(
		panel.etiqueta_veredicto.visible
		and "%d" % prueba.dado_seleccionado in panel.etiqueta_veredicto.text
		and panel.etiqueta_objetivo.visible
		and generador.state == estado_resuelto,
		"La animación debe revelar el resultado resuelto sin consumir azar adicional."
	)
	panel.ocultar()
	panel.vista_dado_1.call(&"mostrar_valor", 1)
	_comprobar(
		is_equal_approx(panel.vista_dado_1.get_node("SubViewport/PivoteDado").rotation_degrees.y, 270.0),
		"La cara 1 debe mirar a cámara en la orientación calibrada."
	)
	var prueba_sin_bono := motor.resolver_prueba(3)
	_comprobar(
		panel.mostrar_tirada("Sin bono", prueba_sin_bono)
		and panel.etiqueta_objetivo.text == "OBJETIVO  ·  3 O MENOS"
		and not panel.etiqueta_bonos.visible
		and not panel.antetitulo.visible,
		"Una prueba normal debe ocultar bono y modo cuando no aplican."
	)
	panel.ocultar()
	var mallas := panel.vista_dado_1.get_node("SubViewport/PivoteDado/Dado").find_children(
		"*", "MeshInstance3D", true, false
	)
	_comprobar(
		not mallas.is_empty()
		and (mallas[0] as MeshInstance3D).mesh.get_surface_count() == 3
		and (mallas[0] as MeshInstance3D).get_active_material(1) != null,
		"La vista debe conservar el cuerpo y los símbolos del dado."
	)

	var cantidad := motor.resolver(
		[{&"cantidad": 1, &"caras": 3, &"signo": 1}],
		0,
		TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.PRIMER_PLANO
	)
	_comprobar(
		panel.mostrar_tirada("Cantidad", cantidad)
		and "+1d3:" in panel.etiqueta_mensajes.text
		and "Total: %d" % cantidad.total_calculado in panel.etiqueta_mensajes.text
		and not panel.etiqueta_objetivo.visible,
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
