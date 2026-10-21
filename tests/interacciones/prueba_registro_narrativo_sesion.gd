extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var registro := RegistroNarrativoSesion.new()
	registro.registrar(EntradaRegistroNarrativo.Categoria.SISTEMA, "Oculto", "secreto", [], EntradaRegistroNarrativo.Visibilidad.OCULTA)
	for indice in 4:
		registro.registrar(EntradaRegistroNarrativo.Categoria.MOVIMIENTO, "Evento %d" % indice, "Consecuencia")
	_comprobar(registro.obtener_entradas_visibles().size() == 4, "La política oculta no debe llegar al panel.")
	_comprobar(registro.obtener_entradas_visibles()[0].secuencia == 2, "La secuencia debe conservar el orden global.")

	var panel := (load("res://scenes/ui/interacciones/panel_registro_narrativo.tscn") as PackedScene).instantiate() as PanelRegistroNarrativo
	root.add_child(panel)
	panel.observar(registro)
	await process_frame
	_comprobar(panel.tarjetas.get_child_count() == 3, "El modo compacto debe mostrar las tres últimas.")
	panel.alternar()
	await process_frame
	_comprobar(panel.tarjetas.get_child_count() == 4, "El modo expandido debe mostrar todo el historial visible.")
	panel.alternar()
	await process_frame
	_comprobar(panel.tarjetas.get_child_count() == 3 and not panel.expandido, "El panel debe poder contraerse.")
	for indice in 20:
		registro.registrar(
			EntradaRegistroNarrativo.Categoria.MOVIMIENTO,
			"Evento largo %d" % indice,
			"Consecuencia extensa para comprobar el desplazamiento automático. ".repeat(3)
		)
	await process_frame
	panel.boton_expandir.pressed.emit()
	await process_frame
	await process_frame
	var barra := panel.desplazamiento.get_v_scroll_bar()
	_comprobar(barra.max_value > barra.page, "El registro largo debe tener desplazamiento vertical.")
	_comprobar(
		panel.expandido and barra.value >= barra.max_value - barra.page - 1.0,
		"Al pulsar Expandir debe mostrarse el final del registro."
	)
	panel.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("RegistroNarrativoSesion: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
