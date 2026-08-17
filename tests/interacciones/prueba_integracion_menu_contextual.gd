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
