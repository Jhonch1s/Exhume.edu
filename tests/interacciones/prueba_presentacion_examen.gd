extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	_probar_catalogo()
	_probar_panel_exito_y_cierre()
	_probar_panel_bloqueo()
	_probar_retiro_activacion_provisional_en_escenario()

	if _fallos.is_empty():
		print("PresentacionExamen: 5 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_catalogo() -> void:
	var catalogo := load(
		"res://assets/interactuables/mensajes_interacciones.tres"
	) as CatalogoMensajesInteraccion
	_comprobar(catalogo != null, "El catálogo de mensajes debe cargar.")
	if catalogo == null:
		return
	_comprobar(catalogo.es_valido(), "Todas las entradas del catálogo deben ser válidas.")
	_comprobar(
		catalogo.resolver(&"examen.antorcha_pie.basico_encendida").begins_with(
			"Es una antorcha"
		),
		"El catálogo debe resolver IDs narrativos sin ayuda del interactuable."
	)
	_comprobar(
		catalogo.resolver(&"mensaje.no_catalogado") == "mensaje.no_catalogado",
		"Un ID ausente debe conservarse como respaldo diagnosticable."
	)


func _probar_panel_exito_y_cierre() -> void:
	var panel := _crear_panel()
	if panel == null:
		return
	var catalogo := load(
		"res://assets/interactuables/mensajes_interacciones.tres"
	) as CatalogoMensajesInteraccion
	var eventos := [0, 0]
	panel.resultado_presentado.connect(func(_resultado): eventos[0] += 1)
	panel.cerrado.connect(func(): eventos[1] += 1)
	panel.mostrar_resultado(
		"Antorcha de pie",
		ResultadoAccion.crear_exito([
			&"examen.antorcha_pie.basico_encendida",
		]),
		catalogo
	)

	_comprobar(panel.visible, "Presentar un resultado debe mostrar el panel.")
	_comprobar(panel.etiqueta_titulo.text == "Antorcha de pie", "Debe mostrar el título.")
	_comprobar(
		panel.etiqueta_mensajes.text.contains("Es una antorcha de pie"),
		"Debe presentar el único mensaje básico unificado."
	)
	_comprobar(eventos[0] == 1, "Debe emitir una presentación por resultado.")
	panel.boton_cerrar.pressed.emit()
	_comprobar(not panel.visible, "El botón debe ocultar el panel.")
	_comprobar(eventos[1] == 1, "Cerrar debe emitir su señal pública.")
	panel.queue_free()


func _probar_panel_bloqueo() -> void:
	var panel := _crear_panel()
	if panel == null:
		return
	var catalogo := load(
		"res://assets/interactuables/mensajes_interacciones.tres"
	) as CatalogoMensajesInteraccion
	panel.mostrar_resultado(
		"Antorcha de pie",
		ResultadoAccion.crear_bloqueo(&"objetivo_no_visible"),
		catalogo
	)
	_comprobar(
		panel.etiqueta_mensajes.text.contains("no ves"),
		"Un bloqueo sin mensajes debe presentar su motivo mediante el catálogo."
	)
	panel.queue_free()


func _probar_retiro_activacion_provisional_en_escenario() -> void:
	var escena := load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene
	_comprobar(escena != null, "La escena principal debe cargar con el panel reutilizable.")
	if escena == null:
		return
	var escenario := escena.instantiate()
	root.add_child(escenario)
	var fuente := escenario.tablero.obtener_interactuable(
		&"zona1_antorcha_pie_02_01"
	) as FuenteLuzInteractuable
	_comprobar(fuente != null, "La regresión necesita la antorcha vertical slice.")
	if fuente != null:
		escenario.ficha_jugador.coordenada_mapa = fuente.coordenada_mapa
		escenario.tablero.obtener_celda(fuente.coordenada_mapa).visibilidad = (
			Celda.EstadoVisibilidad.VISIBLE
		)
		escenario.ultima_coordenada_hover = fuente.coordenada_mapa
		var evento_e := InputEventKey.new()
		evento_e.keycode = KEY_E
		evento_e.pressed = true
		escenario._unhandled_input(evento_e)
		_comprobar(
			not escenario.has_method(&"_examinar_provisional"),
			"El helper que elegía automáticamente el primer examinable debe retirarse."
		)
		_comprobar(
			not escenario.panel_resultado_accion.visible
			and not escenario.menu_contextual.visible,
			"La tecla E ya no debe abrir una interacción ni saltarse el menú."
		)
		_comprobar(
			not escenario.registro_conocimiento.conoce_fragmento(
				&"jugador_principal",
				fuente.id_instancia,
				&"identidad"
			),
			"La tecla retirada no debe producir descubrimientos ni efectos laterales."
		)
	_comprobar(
		escenario.get_node_or_null("CanvasLayer/PanelDetalle") == null,
		"El panel técnico heredado debe retirarse de la escena principal."
	)
	var objetivo := Interactuable.new()
	objetivo.definicion = DefinicionInteractuable.new()
	objetivo.definicion.ilustracion_examen = GradientTexture2D.new()
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		escenario.ficha_jugador,
		Vector2i.ZERO,
		Vector2i.ZERO,
		objetivo
	)
	escenario._presentar_resultado_contextual(
		"Estatua",
		ResultadoAccion.crear_exito([&"examen.estatua.basico"]),
		contexto
	)
	_comprobar(
		escenario.panel_examen_ilustrado.visible
		and not escenario.panel_resultado_accion.visible,
		"Examinar un objeto ilustrado debe abrir solamente el panel grande."
	)
	_comprobar(
		escenario.panel_examen_ilustrado.etiqueta_titulo.text == "Estatua"
		and not escenario.panel_examen_ilustrado.etiqueta_texto.text.is_empty(),
		"El panel ilustrado debe recibir el título y la descripción resuelta."
	)
	escenario.panel_examen_ilustrado.ocultar()
	objetivo.free()
	escenario.queue_free()


func _crear_panel() -> PanelResultadoAccion:
	var escena := load(
		"res://scenes/ui/interacciones/panel_resultado_accion.tscn"
	) as PackedScene
	_comprobar(escena != null, "La escena reutilizable del panel debe cargar.")
	if escena == null:
		return null
	var panel := escena.instantiate() as PanelResultadoAccion
	root.add_child(panel)
	return panel


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
