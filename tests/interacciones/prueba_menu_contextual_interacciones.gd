extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var catalogo := load(
		"res://assets/interactuables/mensajes_interacciones.tres"
	) as CatalogoMensajesInteraccion
	var objetivo := _crear_objetivo(&"objetivo_b", "Objetivo B")
	var opciones := _crear_opciones(objetivo)
	var adaptador := AdaptadorMenuContextual.new()
	var entradas := adaptador.construir_entradas_acciones(opciones, catalogo)

	_comprobar(entradas.size() == 4, "Deben mostrarse tres acciones visibles y Cancelar.")
	if entradas.size() == 4:
		_comprobar(
			entradas[0].opcion_accion.id == &"examinar",
			"La prioridad menor debe aparecer primero."
		)
		_comprobar(
			entradas[1].opcion_accion.id == &"accion_a"
			and entradas[2].opcion_accion.id == &"accion_b",
			"Los empates de prioridad deben ordenarse por ID estable."
		)
		_comprobar(
			entradas[2].texto == "Apagar"
			and not entradas[2].habilitada
			and entradas[2].motivo_bloqueo == "No puedes examinar algo que no ves en este momento.",
			"Una acción bloqueada debe conservar texto y motivo comprensibles."
		)
		_comprobar(
			entradas[3].tipo == EntradaMenuContextual.TipoEntrada.CANCELAR
			and entradas[3].opcion_accion == null,
			"Cancelar debe ser una entrada de UI y no una OpcionAccion."
		)
	for entrada in entradas:
		_comprobar(
			entrada.opcion_accion == null or entrada.opcion_accion.id != &"secreta",
			"Las acciones secretas no descubiertas deben omitirse completamente."
		)

	await _probar_vista_menu(entradas)
	_probar_objetivos_multiples(adaptador, catalogo, objetivo)
	objetivo.free()
	_finalizar()


func _crear_opciones(objetivo: Interactuable) -> Array[OpcionAccion]:
	var opciones: Array[OpcionAccion] = []
	opciones.append(OpcionAccion.crear_habilitada(
		&"accion_b",
		TiposInteraccion.TipoAccion.INTERACTUAR,
		&"interaccion.apagar",
		objetivo,
		{},
		10
	))
	opciones.append(OpcionAccion.crear_habilitada(
		&"examinar",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"interaccion.examinar",
		objetivo,
		{},
		0
	))
	opciones.append(OpcionAccion.crear_habilitada(
		&"secreta",
		TiposInteraccion.TipoAccion.INTERACTUAR,
		&"interaccion.encender",
		objetivo,
		{},
		1,
		true
	))
	opciones.append(OpcionAccion.crear_habilitada(
		&"accion_a",
		TiposInteraccion.TipoAccion.INTERACTUAR,
		&"interaccion.encender",
		objetivo,
		{},
		10
	))
	opciones[0] = OpcionAccion.crear_bloqueada(
		&"accion_b",
		TiposInteraccion.TipoAccion.INTERACTUAR,
		&"interaccion.apagar",
		objetivo,
		&"objetivo_no_visible",
		{},
		10
	)
	return opciones


func _probar_vista_menu(entradas: Array[EntradaMenuContextual]) -> void:
	var escena := load(
		"res://scenes/ui/interacciones/menu_contextual_interacciones.tscn"
	) as PackedScene
	var menu := escena.instantiate() as MenuContextualInteracciones
	root.add_child(menu)
	await process_frame
	var opcion_emitida: Array[OpcionAccion] = []
	var cancelaciones := [0]
	menu.opcion_accion_elegida.connect(func(opcion): opcion_emitida.append(opcion))
	menu.cancelado.connect(func(): cancelaciones[0] += 1)
	menu.mostrar("Antorcha de pie", entradas, Vector2(20, 30))

	var botones := menu.obtener_botones()
	_comprobar(menu.visible, "El menú debe mostrarse incluso con pocas acciones.")
	_comprobar(menu.etiqueta_titulo.text == "Antorcha de pie", "Debe mostrar el objetivo.")
	_comprobar(botones.size() == entradas.size(), "Debe crear un botón por entrada.")
	if botones.size() == entradas.size():
		_comprobar(
			botones[2].disabled
			and "No puedes examinar" in botones[2].text,
			"La vista debe mostrar deshabilitada la acción bloqueada y explicar el motivo."
		)
		_comprobar(
			menu.get_viewport().gui_get_focus_owner() == botones[0],
			"La primera entrada habilitada debe recibir el foco inicial."
		)
		menu.navegar(1)
		_comprobar(
			menu.get_viewport().gui_get_focus_owner() == botones[1],
			"Navegar hacia abajo debe avanzar a la siguiente opción."
		)
		menu.navegar(1)
		_comprobar(
			menu.get_viewport().gui_get_focus_owner() == botones[3],
			"La navegación debe saltar opciones deshabilitadas."
		)
		menu.navegar(1)
		_comprobar(
			menu.get_viewport().gui_get_focus_owner() == botones[0],
			"La navegación debe envolver desde Cancelar a la primera opción."
		)
		menu.activar_entrada_en_foco()
		var evento_cancelar := InputEventAction.new()
		evento_cancelar.action = &"ui_cancel"
		evento_cancelar.pressed = true
		menu._input(evento_cancelar)
	_comprobar(
		opcion_emitida.size() == 1 and opcion_emitida[0].id == &"examinar",
		"Pulsar una acción debe emitir su OpcionAccion sin resolverla."
	)
	_comprobar(cancelaciones[0] == 1, "Cancelar debe emitir su señal propia.")
	menu.ocultar()
	_probar_limites_viewport(menu, entradas)
	menu.ocultar()
	menu.free()


func _probar_limites_viewport(
	menu: MenuContextualInteracciones,
	entradas: Array[EntradaMenuContextual]
) -> void:
	menu.mostrar("Borde inferior derecho", entradas, Vector2(100000, 100000))
	var tamano_viewport := menu.get_viewport_rect().size
	_comprobar(
		menu.position.x + menu.size.x <= tamano_viewport.x - menu.margen_viewport + 0.1
		and menu.position.y + menu.size.y <= tamano_viewport.y - menu.margen_viewport + 0.1,
		"El menú debe desplazarse dentro de los bordes derecho e inferior."
	)

	menu._posicion_solicitada = Vector2(-100000, -100000)
	menu._ajustar_posicion_al_viewport()
	_comprobar(
		menu.position.x >= menu.margen_viewport
		and menu.position.y >= menu.margen_viewport,
		"El menú debe respetar los bordes izquierdo y superior."
	)


func _probar_objetivos_multiples(
	adaptador: AdaptadorMenuContextual,
	catalogo: CatalogoMensajesInteraccion,
	objetivo_b: Interactuable
) -> void:
	var objetivo_a := _crear_objetivo(&"objetivo_a", "Objetivo A")
	var objetivos: Array[Interactuable] = [objetivo_b, objetivo_a]
	var entradas := adaptador.construir_entradas_objetivos(objetivos, catalogo)
	_comprobar(
		entradas.size() == 3
		and entradas[0].objetivo == objetivo_a
		and entradas[1].objetivo == objetivo_b,
		"El selector debe mostrar todos los objetivos en orden estable."
	)
	_comprobar(
		entradas[2].tipo == EntradaMenuContextual.TipoEntrada.CANCELAR,
		"El selector de objetivos también debe permitir cancelar."
	)
	objetivo_a.free()


func _crear_objetivo(id: StringName, nombre: String) -> Interactuable:
	var objetivo := Interactuable.new()
	objetivo.id_instancia = id
	objetivo.definicion = DefinicionInteractuable.new()
	objetivo.definicion.id_definicion = &"definicion_prueba"
	objetivo.definicion.nombre = nombre
	return objetivo


func _finalizar() -> void:
	if _fallos.is_empty():
		print("MenuContextualInteracciones: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
