extends SceneTree

const SIN_RENDER = preload("res://tests/soporte/escenario_sin_render.gd")
const ORIGEN := "res://tests/zonas/zona_triggers.tscn"
const DESTINO := "res://tests/zonas/zona_viaje_destino.tscn"
const TEMPLO := "res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"
const RUTA_GUARDADO := "user://prueba_viajes_zonas.json"
var _fallos: Array[String] = []
var _casos := 0


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escenario := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	escenario.set_script(SIN_RENDER)
	escenario.get_node("Zona").free()
	var zona := (load(ORIGEN) as PackedScene).instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	current_scene = escenario
	for _intento in 250:
		await process_frame
		if escenario.escenario_preparado:
			break
	if not escenario.escenario_preparado:
		_comprobar(false, "Preparar el escenario de origen.")
		quit(1)
		return
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var viajes: ViajeEntreZonas = escenario.viajes
	var accion := AccionTriggerViajar.new()
	_comprobar(not accion.validar_configuracion().is_empty(), "El inspector rechaza una acción sin escena.")
	accion.escena_destino = DESTINO
	accion.id_spawn_destino = &"desde_prueba"
	_comprobar(accion.validar_configuracion().is_empty(), "Se configura escena y spawn por ID.")
	accion.escena_destino = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(TEMPLO))
	_comprobar(accion.validar_configuracion().is_empty() and accion.obtener_ruta_destino() == TEMPLO, "El UID serializado por el inspector resuelve la escena de destino.")
	accion.escena_destino = DESTINO
	var zona_duplicada := (load(DESTINO) as PackedScene).instantiate() as Node2D
	var spawn_duplicado := zona_duplicada.get_node("PuntosSpawn/DesdePrueba").duplicate() as PuntoSpawnZona
	zona_duplicada.get_node("PuntosSpawn").add_child(spawn_duplicado)
	_comprobar(viajes._validar_destino(zona_duplicada, &"desde_prueba") == &"spawn_destino_duplicado", "Un ID de spawn duplicado se rechaza.")
	zona_duplicada.free()
	_comprobar(await viajes.viajar(escenario, DESTINO, &"inexistente") == &"spawn_destino_inexistente" and current_scene == escenario, "Un spawn inexistente conserva el mapa original.")
	_comprobar(await viajes.viajar(escenario, "res://no_existe.tscn", &"entrada") == &"escena_destino_invalida", "Una escena inexistente se rechaza sin perder estado.")
	escenario.en_combate = true
	_comprobar(await viajes.viajar(escenario, DESTINO, &"desde_prueba") == &"viaje_no_disponible", "El combate bloquea el viaje.")
	escenario.en_combate = false
	var ficha: Ficha = escenario.ficha_jugador
	ficha.pv_actual -= 2
	ficha.energia_actual -= 7
	ficha.inventario.agregar(ItemInstancia.new(&"piedra_viaje", load("res://assets/items/piedra/piedra.tres"), 2))
	var estado_ficha := ficha.obtener_estado_persistente()
	var puerta: PuertaInteractuable = escenario.tablero.obtener_interactuable(&"puerta_trigger")
	puerta.abierta = true
	EstadoPartida.trompo_conocido = true
	EstadoPartida.consumir_trigger(StringName(ORIGEN), &"entrada_dialogo")
	# Añadir el viaje a una zona activa y ejecutarlo por el gestor real.
	var trigger := TriggerMapa.new()
	trigger.name = "ViajePrueba"
	trigger.id_trigger = &"viaje_spawn_prueba"
	trigger.tamano = Vector2i.ONE
	trigger.accion = accion
	var capa := zona.get_node("CapaSuelo") as TileMapLayer
	trigger.position = capa.map_to_local(Vector2i(8, 3))
	zona.get_node("Triggers").add_child(trigger)
	_comprobar(escenario.gestor_triggers.configurar(zona, escenario.tablero, StringName(ORIGEN)).is_empty(), "Registrar un trigger de viaje junto a los demás tipos de acción.")
	accion.id_spawn_destino = &"inexistente"
	escenario.gestor_triggers.registrar_paso(Vector2i(7, 3), Vector2i(8, 3), ficha)
	await escenario.gestor_triggers.procesar(escenario)
	_comprobar(not EstadoPartida.trigger_consumido(StringName(ORIGEN), trigger.id_trigger) and current_scene == escenario and not viajes.en_curso, "Un viaje fallido no consume el trigger ni deja bloqueado el mapa.")
	accion.id_spawn_destino = &"desde_prueba"
	_comprobar(escenario.gestor_triggers.registrar_paso(Vector2i(7, 3), Vector2i(8, 3), ficha), "Cruzar la frontera reserva el viaje.")
	await escenario.gestor_triggers.procesar(escenario)
	var destino: Node = current_scene
	_comprobar(destino != escenario and destino.zona_actual.scene_file_path == DESTINO, "La acción del trigger cambia de mapa.")
	_comprobar(EstadoPartida.trigger_consumido(StringName(ORIGEN), trigger.id_trigger), "El viaje consume el trigger sólo después de preparar el destino.")
	await process_frame
	destino.set_process(false)
	destino._cancelar_exploracion_npc()
	var spawn: PuntoSpawnZona = destino.zona_actual.get_node("PuntosSpawn/DesdePrueba")
	_comprobar(destino.ficha_jugador.coordenada_mapa == spawn.obtener_coordenada(destino.zona_actual.get_node("CapaSuelo")), "La llegada usa el spawn elegido, no la entrada predeterminada.")
	var despues: Dictionary = destino.ficha_jugador.obtener_estado_persistente()
	_comprobar(despues["pv_actual"] == estado_ficha["pv_actual"] and despues["energia_actual"] == estado_ficha["energia_actual"] and despues["inventario"] == estado_ficha["inventario"] and despues["equipo"] == estado_ficha["equipo"], "Se conserva vida, energía, inventario y equipo.")
	_comprobar(EstadoPartida.trompo_conocido and EstadoPartida.trigger_consumido(StringName(ORIGEN), &"entrada_dialogo"), "El cambio de escena conserva la memoria narrativa.")
	_comprobar(not destino.gestor_triggers.tiene_actividad(), "Aparecer en destino no dispara un nuevo trigger.")
	_comprobar(destino.guardar_partida(RUTA_GUARDADO) == &"", "Guardar incluye los mapas visitados.")
	var archivo: Dictionary = destino.persistencia_partida.archivos.cargar(RUTA_GUARDADO)
	_comprobar(archivo["zonas_visitadas"].has(ORIGEN), "El archivo conserva el mapa que se abandonó.")
	viajes.restaurar_estado_persistente({})
	_comprobar(destino.cargar_partida(RUTA_GUARDADO) == &"", "La carga recupera los mapas visitados.")
	_comprobar(await viajes.viajar(destino, ORIGEN, &"entrada") == &"", "Se puede configurar el viaje de regreso al spawn de origen.")
	var regreso: Node = current_scene
	await process_frame
	regreso.set_process(false)
	regreso._cancelar_exploracion_npc()
	_comprobar(regreso.tablero.obtener_interactuable(&"puerta_trigger").abierta, "Al volver se conserva la puerta abierta antes del viaje.")
	_comprobar(EstadoPartida.trigger_consumido(StringName(ORIGEN), &"viaje_spawn_prueba"), "Los triggers consumidos siguen consumidos al regresar.")
	# Validación atómica del archivo de mapas anteriores.
	var antes: Dictionary = viajes.obtener_estado_persistente()
	archivo["zonas_visitadas"] = {DESTINO: {"zona_id": "otra"}}
	regreso.persistencia_partida.archivos.guardar(RUTA_GUARDADO + ".invalido", archivo)
	# La escena del archivo es distinta al mapa activo; se valida primero la caché.
	_comprobar(regreso.cargar_partida(RUTA_GUARDADO + ".invalido") != &"" and viajes.obtener_estado_persistente() == antes, "Una caché de mapas inválida no reemplaza el estado actual.")
	var corrupto := antes.duplicate(true)
	for entidad: Dictionary in corrupto[DESTINO]["interactuables"]:
		if entidad["id"] == "puerta_trigger":
			entidad["estado"]["abierta"] = "inválido"
	viajes.restaurar_estado_persistente(corrupto)
	var ficha_antes: Dictionary = regreso.ficha_jugador.obtener_estado_persistente()
	_comprobar(await viajes.viajar(regreso, DESTINO, &"desde_prueba") != &"" and current_scene == regreso and regreso.ficha_jugador.obtener_estado_persistente() == ficha_antes, "Una zona visitada corrupta se rechaza antes de abandonar el mapa actual.")
	viajes.restaurar_estado_persistente(antes)
	accion.escena_destino = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(TEMPLO))
	accion.id_spawn_destino = &"entrada"
	_comprobar(await accion.ejecutar(regreso, null) == &"", "La acción de viaje admite el UID del templo seleccionado desde el inspector.")
	var templo: Node = current_scene
	await process_frame
	templo.set_process(false)
	templo._cancelar_exploracion_npc()
	_comprobar(templo.zona_actual.scene_file_path == TEMPLO and templo.ficha_jugador != null, "El jugador llega al templo conservando su ficha.")
	templo.queue_free()
	await process_frame
	for ruta in [RUTA_GUARDADO, RUTA_GUARDADO + ".invalido"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ruta)
	for fallo in _fallos:
		push_error(fallo)
	print("ViajeEntreZonas: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
