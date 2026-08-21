extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var escena := load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene
	var escenario = escena.instantiate()
	root.add_child(escenario)
	await process_frame
	await process_frame

	var fuente := escenario.tablero.obtener_interactuable(
		&"zona1_antorcha_pie_02_01"
	) as FuenteLuzInteractuable
	_comprobar(fuente != null, "La integración necesita la antorcha vertical slice.")
	if fuente == null:
		escenario.free()
		_finalizar()
		return
	escenario.tablero.obtener_celda(fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	var cambios_modal: Array[bool] = []
	escenario.estado_modal_interaccion_cambiado.connect(
		func(activo): cambios_modal.append(activo)
	)

	var origen_adyacente := _buscar_origen_adyacente(escenario, fuente.coordenada_mapa)
	escenario.ficha_jugador.coordenada_mapa = origen_adyacente
	var estado_inicial := fuente.encendida
	escenario.camino_actual_tentativo.assign([
		escenario.ficha_jugador.coordenada_mapa,
		fuente.coordenada_mapa,
	])
	escenario._manejar_clic_izquierdo(fuente.coordenada_mapa)
	var menu: MenuContextualInteracciones = escenario.menu_contextual
	var botones := menu.obtener_botones()
	_comprobar(menu.visible, "El clic izquierdo debe abrir siempre el menú de acciones.")
	_comprobar(
		escenario.interaccion_modal_activa,
		"Abrir el menú debe activar el bloqueo modal del escenario."
	)
	_comprobar(
		escenario.camino_actual_tentativo.is_empty(),
		"Activar el modal debe limpiar la trayectoria tentativa del mundo."
	)
	_comprobar(
		menu.etiqueta_titulo.text == fuente.definicion.nombre,
		"El menú debe mostrar el nombre genérico de la definición."
	)
	_comprobar(
		botones.size() == 3
		and botones[0].text == "Examinar"
		and botones[1].text in ["Apagar", "Encender"]
		and botones[2].text == "Cancelar",
		"La antorcha debe mostrar Examinar, su acción específica y Cancelar."
	)
	_comprobar(
		escenario.objetivo_seleccionado == fuente and fuente.esta_resaltado(),
		"El objetivo debe permanecer seleccionado y resaltado con el menú abierto."
	)

	var coordenada_antes: Vector2i = escenario.ficha_jugador.coordenada_mapa
	escenario._manejar_clic_derecho(coordenada_antes + Vector2i.RIGHT)
	_comprobar(
		not escenario.ficha_jugador.esta_moviendose
		and escenario.ficha_jugador.coordenada_mapa == coordenada_antes,
		"El menú abierto debe bloquear órdenes de movimiento."
	)

	var evento_cancelar := InputEventAction.new()
	evento_cancelar.action = &"ui_cancel"
	evento_cancelar.pressed = true
	menu._input(evento_cancelar)
	_comprobar(
		not menu.visible
		and escenario.objetivo_seleccionado == null
		and not fuente.esta_resaltado()
		and not escenario.interaccion_modal_activa,
		"Cancelar debe cerrar el menú y limpiar selección y resaltado."
	)
	_comprobar(
		cambios_modal == [true, false],
		"El bloqueo modal debe activarse y restaurarse exactamente una vez."
	)

	_probar_ejecucion_accion(escenario, fuente, estado_inicial, origen_adyacente)
	_probar_ejecucion_examen(escenario, fuente, origen_adyacente)
	_probar_bloqueo_distancia(escenario, fuente)

	_probar_panel_resultado_modal(escenario)
	_probar_examen_otras_fuentes(escenario)
	_probar_seleccion_item(escenario, fuente, origen_adyacente)
	_probar_palanca(escenario)
	_probar_puerta_con_llave(escenario)
	await _probar_lanzamiento_desde_inventario(escenario)
	await process_frame

	_probar_multiples_objetivos(escenario, fuente)
	escenario.free()
	_finalizar()


func _probar_ejecucion_accion(
	escenario: Variant,
	fuente: FuenteLuzInteractuable,
	estado_inicial: bool,
	origen_adyacente: Vector2i
) -> void:
	escenario.ficha_jugador.coordenada_mapa = origen_adyacente
	escenario.tablero.obtener_celda(fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(fuente.coordenada_mapa)
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	botones[1].pressed.emit()
	_comprobar(
		escenario.ultima_opcion_contextual_seleccionada != null
		and escenario.ultima_opcion_contextual_seleccionada.id in [&"apagar", &"encender"],
		"Elegir una acción debe conservar la OpcionAccion ejecutada."
	)
	_comprobar(
		escenario.ultimo_contexto_contextual != null
		and escenario.ultimo_contexto_contextual.alcance_maximo == 1.0
		and escenario.ultimo_resultado_contextual.exitosa,
		"La opción específica debe construir y resolver un contexto adyacente."
	)
	_comprobar(
		fuente.encendida != estado_inicial,
		"Encender o Apagar debe modificar el estado únicamente mediante GestorAcciones."
	)
	_comprobar(
		not escenario.menu_contextual.visible
		and escenario.panel_resultado_accion.visible
		and escenario.interaccion_modal_activa
		and escenario.objetivo_seleccionado == fuente
		and fuente.esta_resaltado(),
		"El resultado debe sustituir al menú sin liberar modal, selección ni resaltado."
	)
	_comprobar(
		escenario.panel_resultado_accion.etiqueta_titulo.text == fuente.definicion.nombre,
		"El panel debe conservar el nombre genérico del objetivo."
	)
	escenario.panel_resultado_accion.ocultar()
	_comprobar(
		not escenario.interaccion_modal_activa and not fuente.esta_resaltado(),
		"Cerrar el resultado debe restaurar input y retirar el resaltado."
	)

	escenario.tablero.obtener_celda(fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(fuente.coordenada_mapa)
	var opciones_actualizadas: Array[Button] = escenario.menu_contextual.obtener_botones()
	_comprobar(
		opciones_actualizadas[1].text
		== ("Apagar" if fuente.encendida else "Encender"),
		"La siguiente apertura debe reconstruir la acción desde el estado actualizado."
	)
	escenario._cerrar_menu_contextual()


func _probar_ejecucion_examen(
	escenario: Variant,
	fuente: FuenteLuzInteractuable,
	origen_adyacente: Vector2i
) -> void:
	escenario.ficha_jugador.coordenada_mapa = origen_adyacente
	escenario.tablero.obtener_celda(fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(fuente.coordenada_mapa)
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	botones[0].pressed.emit()
	_comprobar(
		escenario.ultimo_contexto_contextual != null
		and escenario.ultimo_contexto_contextual.tipo == TiposInteraccion.TipoAccion.EXAMINAR
		and escenario.ultimo_contexto_contextual.solicitud_examen != null
		and escenario.ultimo_resultado_contextual.exitosa
		and not escenario.ultimo_resultado_contextual.mensajes.is_empty(),
		"Examinar debe conservar su solicitud tipada y resolver información."
	)
	_comprobar(
		escenario.panel_resultado_accion.visible
		and escenario.interaccion_modal_activa
		and not escenario.panel_resultado_accion.etiqueta_mensajes.text.is_empty(),
		"Examinar desde el menú debe presentar inmediatamente su ResultadoAccion."
	)
	escenario.panel_resultado_accion.ocultar()


func _probar_bloqueo_distancia(
	escenario: Variant,
	fuente: FuenteLuzInteractuable
) -> void:
	var origen_lejano := _buscar_origen_lejano(escenario, fuente.coordenada_mapa)
	escenario.ficha_jugador.coordenada_mapa = origen_lejano
	escenario.tablero.obtener_celda(fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	var estado_anterior := fuente.encendida
	escenario._manejar_clic_izquierdo(fuente.coordenada_mapa)
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	botones[1].pressed.emit()
	_comprobar(
		escenario.ultimo_resultado_contextual.estado
		== TiposInteraccion.EstadoResolucion.BLOQUEO
		and escenario.ultimo_resultado_contextual.motivo == &"fuera_de_alcance",
		"GestorAcciones debe revalidar y bloquear la interacción a distancia."
	)
	_comprobar(
		fuente.encendida == estado_anterior,
		"Un bloqueo por distancia no debe modificar el objetivo."
	)
	_comprobar(
		escenario.panel_resultado_accion.visible
		and "Debes estar junto" in escenario.panel_resultado_accion.etiqueta_mensajes.text,
		"Los bloqueos del gestor deben presentarse con un motivo comprensible."
	)
	escenario.panel_resultado_accion.ocultar()


func _probar_seleccion_item(
	escenario: Variant,
	objetivo: FuenteLuzInteractuable,
	origen_adyacente: Vector2i
) -> void:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"herramienta_integracion"
	definicion.nombre = "Martillo"
	definicion.etiquetas = [&"herramienta"]
	definicion.magnitudes = {&"potencia": 2.0}
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	var item := ItemInstancia.new(&"martillos_integracion", definicion, 2)
	escenario.ficha_jugador.inventario.agregar(item)
	escenario.ficha_jugador.coordenada_mapa = origen_adyacente
	escenario.tablero.obtener_celda(objetivo.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(objetivo.coordenada_mapa)
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 4 and botones[1].text == "Usar item…",
		"Un objetivo debe ofrecer Usar item cuando el inventario no está vacío."
	)
	botones[1].pressed.emit()
	botones = escenario.menu_contextual.obtener_botones()
	_comprobar(
		escenario.menu_contextual.etiqueta_titulo.text == "¿Qué item quieres usar?"
		and botones.size() == 2
		and botones[0].text == "Martillo ×2",
		"Usar item debe reutilizar el menú para seleccionar una pila."
	)
	botones[0].pressed.emit()
	_comprobar(
		escenario.ultimo_contexto_contextual != null
		and escenario.ultimo_contexto_contextual.tipo == TiposInteraccion.TipoAccion.USAR_ITEM
		and escenario.ultimo_contexto_contextual.item == item
		and escenario.ultimo_resultado_contextual.motivo == &"reaccion_item_no_implementada",
		"La selección debe construir y resolver USAR_ITEM mediante GestorAcciones."
	)
	_comprobar(
		escenario.ficha_jugador.inventario.obtener_por_id(item.id_instancia) == item,
		"8.2 no debe consumir la pila seleccionada."
	)
	escenario.panel_resultado_accion.ocultar()
	escenario.ficha_jugador.inventario.retirar(item.id_instancia)


func _probar_palanca(escenario: Variant) -> void:
	var palanca := escenario.tablero.obtener_interactuable(
		&"zona1_palanca_03_m03"
	) as PalancaInteractuable
	_comprobar(palanca != null, "Zona1 debe registrar la palanca de 8.3.")
	if palanca == null:
		return
	escenario.ficha_jugador.coordenada_mapa = _buscar_origen_adyacente(
		escenario, palanca.coordenada_mapa
	)
	escenario.tablero.obtener_celda(palanca.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(palanca.coordenada_mapa)
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 3 and botones[1].text == "Accionar",
		"La palanca debe publicar Examinar, Accionar y Cancelar."
	)
	botones[1].pressed.emit()
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and palanca.activada
		and escenario.ultimo_contexto_contextual.item == null,
		"Un actor adyacente debe accionar la palanca sin seleccionar un item."
	)
	escenario.panel_resultado_accion.ocultar()


func _probar_lanzamiento_desde_inventario(escenario: Variant) -> void:
	var trampa := escenario.tablero.obtener_interactuable(
		&"zona1_trampa_humo_04_03"
	) as TrampaSuperficie
	_comprobar(trampa != null, "Zona1 debe ofrecer una trampa para probar IMPACTAR.")
	if trampa == null:
		return
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"piedra_lanzamiento_menu"
	definicion.nombre = "Piedra de lanzamiento"
	definicion.etiquetas = [&"solido", &"arrojable"]
	definicion.escena_mundo = load(
		"res://scenes/items/piedra_suelo.tscn"
	) as PackedScene
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	escenario.duracion_paso_lanzamiento = 0.02
	var item := ItemInstancia.new(&"piedras_lanzamiento_menu", definicion, 2)
	escenario.ficha_jugador.inventario.agregar(item)
	var destino: Vector2i = trampa.coordenada_mapa
	escenario.ficha_jugador.coordenada_mapa = _buscar_origen_adyacente(
		escenario,
		destino
	)
	var celda: Celda = escenario.tablero.obtener_celda(destino)
	celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE

	escenario._abrir_selector_item_lanzamiento()
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	_comprobar(
		escenario.menu_contextual.etiqueta_titulo.text == "¿Qué item quieres lanzar?"
		and botones.size() == 2
		and botones[0].text == "Piedra de lanzamiento ×2",
		"L debe mostrar únicamente las pilas arrojables."
	)
	botones[0].pressed.emit()
	_comprobar(
		escenario.item_lanzamiento_pendiente == item
		and not escenario.interaccion_modal_activa,
		"Elegir el item debe habilitar la selección de celda."
	)
	escenario._actualizar_previsualizacion_lanzamiento(destino)
	_comprobar(
		escenario.trayectoria_lanzamiento.points.size() == 2,
		"La selección de celda debe dibujar la trayectoria lógica compartida."
	)
	escenario._manejar_clic_izquierdo(destino)
	botones = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 3
		and botones[0].text == "Piso"
		and botones[1].text == "Trampa",
		"Una celda con objetivo debe ofrecer Piso y el objetivo."
	)
	botones[1].pressed.emit()
	_comprobar(
		escenario.lanzamiento_en_vuelo
		and escenario.interaccion_modal_activa
		and is_instance_valid(escenario.representacion_lanzamiento)
		and item.cantidad == 2,
		"El vuelo debe ser visible y conservar el inventario hasta finalizar."
	)
	await escenario.accion_contextual_finalizada
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and trampa.activada
		and item.cantidad == 1
		and not escenario.lanzamiento_en_vuelo
		and escenario.representacion_lanzamiento == null
		and escenario.ultimo_resultado_contextual.destino_item
		== TiposInteraccion.DestinoItem.DEJAR_EN_CELDA,
		"El impacto debe activar la trampa y dejar caer una sola unidad."
	)
	escenario.panel_resultado_accion.ocultar()

	escenario._abrir_selector_item_lanzamiento()
	escenario.menu_contextual.obtener_botones()[0].pressed.emit()
	escenario._manejar_clic_izquierdo(destino)
	await escenario.accion_contextual_finalizada
	var item_suelo: ItemSuelo = escenario.tablero.obtener_item_suelo(item.id_instancia)
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and escenario.ultimo_resultado_contextual.destino_item
		== TiposInteraccion.DestinoItem.DEJAR_EN_CELDA
		and not escenario.menu_contextual.visible
		and item_suelo != null,
		"Sin objetivos debe impactar automáticamente en el piso."
	)
	escenario.panel_resultado_accion.ocultar()
	for candidato in celda.items_suelo.duplicate():
		if candidato.item.definicion == definicion:
			escenario.tablero.retirar_item_suelo(candidato)

	var palanca := escenario.tablero.obtener_interactuable(
		&"zona1_palanca_03_m03"
	) as PalancaInteractuable
	_comprobar(palanca != null, "Zona1 debe permitir dirigir impactos a la palanca.")
	if palanca == null:
		return
	var item_palanca := ItemInstancia.new(&"piedras_para_palanca", definicion, 2)
	escenario.ficha_jugador.inventario.agregar(item_palanca)
	var destino_palanca := palanca.coordenada_mapa
	escenario.ficha_jugador.coordenada_mapa = _buscar_origen_adyacente(
		escenario, destino_palanca
	)
	escenario.tablero.obtener_celda(destino_palanca).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)

	escenario._abrir_selector_item_lanzamiento()
	escenario.menu_contextual.obtener_botones()[0].pressed.emit()
	escenario._manejar_clic_izquierdo(destino_palanca)
	botones = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 3 and botones[0].text == "Piso" and botones[1].text == "Palanca",
		"La palanca debe aparecer como objetivo de impacto dirigido."
	)
	botones[0].pressed.emit()
	await escenario.accion_contextual_finalizada
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and palanca.activada
		and item_palanca.cantidad == 1,
		"Elegir Piso no debe accionar la palanca."
	)
	escenario.panel_resultado_accion.ocultar()

	escenario._abrir_selector_item_lanzamiento()
	escenario.menu_contextual.obtener_botones()[0].pressed.emit()
	escenario._manejar_clic_izquierdo(destino_palanca)
	escenario.menu_contextual.obtener_botones()[1].pressed.emit()
	await escenario.accion_contextual_finalizada
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and not palanca.activada
		and escenario.ficha_jugador.inventario.obtener_por_id(item_palanca.id_instancia) == null,
		"Elegir la palanca debe accionarla mediante IMPACTAR y retirar una unidad."
	)
	escenario.panel_resultado_accion.ocultar()
	for candidato in escenario.tablero.obtener_celda(destino_palanca).items_suelo.duplicate():
		if candidato.item.definicion == definicion:
			escenario.tablero.retirar_item_suelo(candidato)
	await _probar_bomba_humo(escenario)


func _probar_bomba_humo(escenario: Variant) -> void:
	var bomba_suelo := escenario.tablero.obtener_item_suelo(&"zona1_bomba_humo") as ItemSuelo
	_comprobar(bomba_suelo != null, "Zona1 debe ofrecer la bomba de humo de prueba.")
	if bomba_suelo == null:
		return
	var destino: Vector2i = bomba_suelo.coordenada_mapa
	escenario.ficha_jugador.coordenada_mapa = destino
	var opcion_recoger := bomba_suelo.obtener_opciones_accion(escenario.ficha_jugador)[0]
	var recogida: ResultadoAccion = escenario.gestor_acciones.procesar_accion(
		bomba_suelo.construir_contexto_accion(
			opcion_recoger,
			escenario.ficha_jugador,
			destino,
			destino
		)
	)
	var bomba: ItemInstancia = escenario.ficha_jugador.inventario.obtener_por_id(
		&"zona1_bomba_humo"
	)
	_comprobar(recogida.exitosa and bomba != null, "La bomba debe poder recogerse.")
	if bomba == null:
		return

	escenario.ficha_jugador.coordenada_mapa = _buscar_origen_adyacente(escenario, destino)
	escenario.tablero.obtener_celda(destino).visibilidad = Celda.EstadoVisibilidad.VISIBLE
	escenario._abrir_selector_item_lanzamiento()
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 2 and botones[0].text == "Bomba de humo",
		"La bomba recogida debe aparecer como item arrojable."
	)
	botones[0].pressed.emit()
	escenario._manejar_clic_izquierdo(destino)
	await escenario.accion_contextual_finalizada

	var celda: Celda = escenario.tablero.obtener_celda(destino)
	var humo: Humo = null
	for efecto in celda.efectos_superficie:
		if efecto is Humo:
			humo = efecto
			break
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and escenario.ultimo_resultado_contextual.destino_item
		== TiposInteraccion.DestinoItem.CONSUMIR
		and escenario.ficha_jugador.inventario.obtener_por_id(bomba.id_instancia) == null
		and escenario.tablero.obtener_item_suelo(bomba.id_instancia) == null
		and humo != null
		and celda.bloquea_vision_efectiva()
		and &"bomba_humo.activada" in escenario.ultimo_resultado_contextual.mensajes,
		"La bomba debe consumirse y desplegar humo opaco en la celda de caída."
	)
	escenario.panel_resultado_accion.ocultar()
	if humo != null:
		escenario.tablero.retirar_efecto_superficie(humo)
		humo.queue_free()


func _probar_puerta_con_llave(escenario: Variant) -> void:
	var puerta := escenario.tablero.obtener_interactuable(
		&"zona1_puerta_04_m03"
	) as PuertaInteractuable
	var llave_suelo := escenario.tablero.obtener_item_suelo(&"zona1_llave_prueba") as ItemSuelo
	_comprobar(
		puerta != null and llave_suelo != null,
		"Zona1 debe registrar la puerta y la llave de prueba."
	)
	if puerta == null or llave_suelo == null:
		return
	var celda_puerta: Celda = escenario.tablero.obtener_celda(puerta.coordenada_mapa)
	_comprobar(
		not escenario.tablero.puede_entrar(puerta.coordenada_mapa)
		and celda_puerta.bloquea_vision_efectiva(),
		"La puerta real cerrada debe bloquear paso y visión."
	)

	escenario.ficha_jugador.coordenada_mapa = llave_suelo.coordenada_mapa
	var opcion_recoger := llave_suelo.obtener_opciones_accion(escenario.ficha_jugador)[0]
	var contexto_recoger: ContextoAccion = llave_suelo.construir_contexto_accion(
		opcion_recoger,
		escenario.ficha_jugador,
		llave_suelo.coordenada_mapa,
		llave_suelo.coordenada_mapa
	)
	var recogida: ResultadoAccion = escenario.gestor_acciones.procesar_accion(contexto_recoger)
	var llave: ItemInstancia = escenario.ficha_jugador.inventario.obtener_por_id(
		&"zona1_llave_prueba"
	)
	_comprobar(
		recogida.exitosa and llave != null,
		"La llave lógica del suelo debe poder llegar al inventario."
	)
	if llave == null:
		return

	escenario.ficha_jugador.coordenada_mapa = _buscar_origen_adyacente(
		escenario, puerta.coordenada_mapa
	)
	escenario.tablero.obtener_celda(puerta.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(puerta.coordenada_mapa)
	var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 4
		and botones[1].text == "Usar item…"
		and botones[2].disabled
		and botones[2].text.begins_with("Abrir"),
		"La puerta bloqueada debe ofrecer la llave y mostrar Abrir deshabilitado."
	)
	botones[1].pressed.emit()
	botones = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 2 and botones[0].text == "Llave de prueba",
		"El selector provisional debe mostrar la llave recogida."
	)
	botones[0].pressed.emit()
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and not puerta.bloqueada
		and not puerta.abierta
		and escenario.ficha_jugador.inventario.obtener_por_id(llave.id_instancia) == llave,
		"USAR_ITEM debe desbloquear la puerta sin consumir ni abrir automáticamente."
	)
	escenario.panel_resultado_accion.ocultar()

	escenario.tablero.obtener_celda(puerta.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	escenario._manejar_clic_izquierdo(puerta.coordenada_mapa)
	botones = escenario.menu_contextual.obtener_botones()
	_comprobar(
		botones.size() == 3 and botones[1].text == "Abrir",
		"Tras desbloquear, la puerta debe ofrecer Abrir sin Usar item."
	)
	botones[1].pressed.emit()
	_comprobar(
		escenario.ultimo_resultado_contextual.exitosa
		and puerta.abierta
		and escenario.tablero.puede_entrar(puerta.coordenada_mapa)
		and not celda_puerta.bloquea_vision_efectiva(),
		"Abrir debe liberar paso y visión como interacción manual independiente."
	)
	escenario.panel_resultado_accion.ocultar()
	escenario.ficha_jugador.inventario.retirar(llave.id_instancia)


func _probar_examen_otras_fuentes(escenario: Variant) -> void:
	var definiciones_probadas: Dictionary[StringName, bool] = {}
	for candidato in escenario.tablero.interactuables_por_id.values():
		if not candidato is FuenteLuzInteractuable or candidato.definicion == null:
			continue
		var id_definicion: StringName = candidato.definicion.id_definicion
		if (
			id_definicion == &"antorcha_pie"
			or definiciones_probadas.has(id_definicion)
		):
			continue
		definiciones_probadas[id_definicion] = true
		escenario.ficha_jugador.coordenada_mapa = candidato.coordenada_mapa
		escenario.tablero.obtener_celda(candidato.coordenada_mapa).visibilidad = (
			Celda.EstadoVisibilidad.VISIBLE
		)
		escenario._manejar_clic_izquierdo(candidato.coordenada_mapa)
		var botones: Array[Button] = escenario.menu_contextual.obtener_botones()
		_comprobar(
			botones.size() == 3 and botones[0].text == "Examinar",
			"Toda fuente de luz definida debe publicar Examinar y su acción específica."
		)
		if botones.size() < 3:
			escenario._cerrar_menu_contextual()
			continue
		botones[0].pressed.emit()
		_comprobar(
			escenario.ultimo_resultado_contextual.exitosa
			and escenario.panel_resultado_accion.visible
			and not escenario.panel_resultado_accion.etiqueta_mensajes.text.is_empty(),
			"Fogatas y antorchas de pared deben presentar su examen desde el menú."
		)
		escenario.panel_resultado_accion.ocultar()
	_comprobar(
		definiciones_probadas.size() == 3,
		"Deben probarse fogata y ambas definiciones de antorcha de pared."
	)


func _buscar_origen_adyacente(escenario: Variant, destino: Vector2i) -> Vector2i:
	var desplazamientos: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	]
	for desplazamiento in desplazamientos:
		var candidato := destino + desplazamiento
		if escenario.tablero.es_celda_valida(candidato):
			return candidato
	return destino


func _buscar_origen_lejano(escenario: Variant, destino: Vector2i) -> Vector2i:
	for coordenada in escenario.tablero.datos:
		var candidato: Vector2i = coordenada
		if abs(candidato.x - destino.x) + abs(candidato.y - destino.y) > 1:
			return candidato
	return destino + Vector2i(2, 0)


func _probar_multiples_objetivos(escenario: Variant, fuente: FuenteLuzInteractuable) -> void:
	var otro_objetivo: FuenteLuzInteractuable = null
	for candidato in escenario.tablero.interactuables_por_id.values():
		if candidato is FuenteLuzInteractuable and candidato != fuente:
			otro_objetivo = candidato
			break
	_comprobar(otro_objetivo != null, "La zona debe ofrecer un segundo objetivo de prueba.")
	if otro_objetivo == null:
		return

	var celda: Celda = escenario.tablero.obtener_celda(fuente.coordenada_mapa)
	celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
	celda.interactuables.append(otro_objetivo)
	escenario._manejar_clic_izquierdo(fuente.coordenada_mapa)
	var menu: MenuContextualInteracciones = escenario.menu_contextual
	var botones := menu.obtener_botones()
	_comprobar(
		menu.etiqueta_titulo.text == "¿Qué quieres seleccionar?"
		and botones.size() == 3,
		"Varios objetivos deben abrir primero el selector con Cancelar."
	)
	_comprobar(
		escenario.objetivo_seleccionado == null,
		"El selector visual no debe elegir automáticamente el primer objetivo."
	)
	botones[0].pressed.emit()
	_comprobar(
		escenario.objetivo_seleccionado != null
		and menu.etiqueta_titulo.text == escenario.objetivo_seleccionado.definicion.nombre,
		"Elegir un objetivo debe abrir después su menú de acciones."
	)
	celda.interactuables.erase(otro_objetivo)
	escenario._cerrar_menu_contextual()


func _probar_panel_resultado_modal(escenario: Variant) -> void:
	escenario.panel_resultado_accion.mostrar_resultado(
		"Resultado de prueba",
		ResultadoAccion.crear_exito([&"fuente_luz.apagada"]),
		escenario.catalogo_mensajes
	)
	_comprobar(
		escenario.interaccion_modal_activa,
		"El panel de resultado también debe bloquear el input del mundo."
	)
	escenario.panel_resultado_accion.ocultar()
	_comprobar(
		not escenario.interaccion_modal_activa,
		"Cerrar el resultado debe restaurar el input si no queda otro modal abierto."
	)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("IntegracionMenuContextual: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
