extends SceneTree

const ESCENARIO_SIN_RENDER = preload("res://tests/soporte/escenario_sin_render.gd")
const RUTA_GUARDADO := "user://prueba_triggers_mapa.json"
var _fallos: Array[String] = []
var _casos := 0


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_probar_geometria()
	_probar_memoria()
	await _probar_integracion()
	if _fallos.is_empty():
		print("TriggersMapa: %d comprobaciones correctas." % _casos)
	else:
		for fallo in _fallos:
			push_error(fallo)
	quit(0 if _fallos.is_empty() else 1)


func _probar_geometria() -> void:
	var trigger := TriggerMapa.new()
	_comprobar(trigger.detecta_paso(Vector2i(-1, 0), Vector2i.ZERO, Vector2i.ZERO), "Entrar desde fuera activa una zona.")
	_comprobar(not trigger.detecta_paso(Vector2i.ZERO, Vector2i.ONE, Vector2i.ZERO), "Caminar dentro no vuelve a activar la zona.")
	_comprobar(not trigger.detecta_paso(Vector2i.ZERO, Vector2i(-1, 0), Vector2i.ZERO), "Salir no es entrar.")
	_comprobar(not trigger.detecta_paso(Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO), "Restaurar la misma posición no es entrar.")
	for forma in [TriggerMapa.Forma.UMBRAL_X, TriggerMapa.Forma.UMBRAL_Y]:
		trigger.forma = forma
		var normal := Vector2i.RIGHT if forma == TriggerMapa.Forma.UMBRAL_X else Vector2i.DOWN
		var paralelo := Vector2i.DOWN if forma == TriggerMapa.Forma.UMBRAL_X else Vector2i.RIGHT
		_comprobar(trigger.detecta_paso(Vector2i.ZERO, normal, Vector2i.ZERO), "Cruce de umbral hacia delante.")
		_comprobar(trigger.detecta_paso(normal, Vector2i.ZERO, Vector2i.ZERO), "Cruce de umbral hacia atrás.")
		_comprobar(not trigger.detecta_paso(Vector2i.ZERO, paralelo, Vector2i.ZERO), "Un paso paralelo no cruza el umbral.")
		_comprobar(not trigger.detecta_paso(paralelo, paralelo + normal, Vector2i.ZERO), "Un cruce fuera de la longitud no activa el umbral.")
		_comprobar(trigger.detecta_paso(-normal * 2, normal * 2, Vector2i.ZERO), "Un desplazamiento largo puede cruzar un umbral.")
	trigger.free()


func _probar_memoria() -> void:
	EstadoPartida.restaurar_estado_persistente({"trompo_conocido": false})
	EstadoPartida.consumir_trigger(&"zona_a", &"entrada")
	EstadoPartida.consumir_trigger(&"zona_a", &"entrada")
	_comprobar(EstadoPartida.trigger_consumido(&"zona_a", &"entrada") and not EstadoPartida.trigger_consumido(&"zona_b", &"entrada"), "La memoria separa zona e ID y no duplica consumos.")
	var datos: Dictionary = EstadoPartida.obtener_estado_persistente()
	_comprobar(datos["triggers_consumidos"]["zona_a"].size() == 1, "Un ID consumido se guarda una sola vez.")
	datos["triggers_consumidos"]["zona_a"].clear()
	_comprobar(EstadoPartida.trigger_consumido(&"zona_a", &"entrada"), "El snapshot no comparte el estado mutable.")
	for invalido in [null, [], {"zona": "entrada"}, {"zona": [12]}, {"zona": ["x", "x"]}, {"": ["x"]}]:
		_comprobar(EstadoPartida.validar_estado_persistente({"trompo_conocido": false, "triggers_consumidos": invalido}) != &"", "Se rechazan triggers guardados inválidos.")
	_comprobar(EstadoPartida.restaurar_estado_persistente({"trompo_conocido": true}) == &"" and not EstadoPartida.trigger_consumido(&"zona_a", &"entrada"), "Un guardado anterior restaura cero triggers consumidos.")
	EstadoPartida.consumir_trigger(&"zona_a", &"entrada")
	_comprobar(EstadoPartida.establecer_aventurero({"nombre": "Prueba", "titulo": "Probador", "clase": "Guerrero", "origen": "Prueba", "fuerza": 4, "destreza": 4, "voluntad": 4}) and not EstadoPartida.trigger_consumido(&"zona_a", &"entrada"), "Una partida nueva reinicia los triggers.")


func _probar_integracion() -> void:
	var escenario := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	var ilustracion_guerrero: Texture2D = escenario.ilustracion_dialogo_guerrero
	escenario.set_script(ESCENARIO_SIN_RENDER)
	escenario.ilustracion_dialogo_guerrero = ilustracion_guerrero
	escenario.get_node("Zona").free()
	var zona := (load("res://tests/zonas/zona_triggers.tscn") as PackedScene).instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	for _intento in 250:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	if escenario.ficha_jugador == null or escenario.hud.ficha != escenario.ficha_jugador:
		_comprobar(false, "La zona de prueba debe inicializar jugador y HUD.")
		escenario.queue_free()
		await process_frame
		return
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var ficha: Ficha = escenario.ficha_jugador
	var gestor: GestorTriggersMapa = escenario.gestor_triggers
	var trigger := zona.get_node("Triggers/EntradaDialogo") as TriggerMapa
	var umbral := zona.get_node("Triggers/UmbralPuerta") as TriggerMapa
	var capa := zona.get_node("CapaSuelo") as TileMapLayer
	var puerta := escenario.tablero.obtener_interactuable(&"puerta_trigger") as PuertaInteractuable
	_comprobar(trigger != null and puerta != null, "El fixture ofrece diálogo y puerta de mecanismo.")
	_comprobar(gestor.configurar(zona, escenario.tablero, escenario.obtener_id_zona()).is_empty(), "La configuración del fixture es válida.")
	var ancla := trigger.obtener_coordenada(capa)
	var origen := ancla - Vector2i.RIGHT
	var pasos: Array[Vector2i] = [origen, ancla, ancla + Vector2i.RIGHT]
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(origen, capa)
	escenario.tablero.ocupar_celda(origen, ficha)
	var activaciones: Array[StringName] = []
	gestor.trigger_activado.connect(func(id: StringName): activaciones.append(id))
	var completo: bool = await ficha.mover_por_camino(
		pasos, escenario._preparar_paso_actor, escenario._confirmar_paso_actor,
		escenario._cancelar_paso_actor, escenario._procesar_salida_paso_actor,
		escenario._procesar_entrada_paso_actor, escenario._calcular_coste_paso_actor
	)
	_comprobar(not completo and ficha.coordenada_mapa == ancla and not ficha.esta_moviendose, "El trigger interrumpe después del paso confirmado y cancela el resto de la ruta.")
	_comprobar(gestor.tiene_actividad() and activaciones.is_empty(), "El callback de entrada solo reserva el evento; no abre UI.")
	_comprobar(escenario.guardar_partida(RUTA_GUARDADO) == &"partida_interaccion_activa", "Un evento pendiente bloquea el guardado.")
	# Otro diálogo mantiene el evento pendiente y sin consumir.
	var recurso := (trigger.accion as AccionTriggerDialogo).recurso_dialogo
	escenario._on_dialogo_camara_iniciado(recurso)
	gestor.procesar(escenario)
	_comprobar(activaciones.is_empty() and not EstadoPartida.trigger_consumido(escenario.obtener_id_zona(), trigger.id_trigger), "Otro diálogo aplaza la activación sin consumirla.")
	escenario._on_dialogo_camara_finalizado(recurso)
	gestor.procesar(escenario)
	await process_frame
	_comprobar(activaciones == [trigger.id_trigger] and EstadoPartida.trigger_consumido(escenario.obtener_id_zona(), trigger.id_trigger), "Abrir correctamente el diálogo confirma el consumo.")
	_comprobar(gestor.tiene_actividad(), "El diálogo mantiene el bloqueo hasta cerrar el globo.")
	var globo: Node = gestor._globo_activo
	_comprobar(globo.ilustracion_jugador.visible and globo.ilustracion_jugador.texture == escenario._obtener_ilustracion_dialogo_jugador() and globo.ilustracion_jugador.texture != null, "Los diálogos de triggers muestran la ilustración de la clase del protagonista.")
	_comprobar(globo.nombre_jugador == ficha.nombre and not globo.ilustracion_npc.visible, "El diálogo interno configura solo al protagonista como participante.")
	globo.dialogue_line = await recurso.get_next_dialogue_line(globo.dialogue_line.next_id)
	await process_frame
	_comprobar(not gestor.tiene_actividad() and escenario._dialogos_camara.is_empty(), "Terminar el diálogo libera la cola y el bloqueo de cámara.")
	_comprobar(not gestor.registrar_paso(origen, ancla, ficha), "Reentrar en un trigger consumido no lo dispara.")
	escenario._actualizar_estado_modal_interaccion()
	_comprobar(escenario.guardar_partida(RUTA_GUARDADO) == &"", "La partida con triggers consumidos se guarda.")
	EstadoPartida.restaurar_estado_persistente({"trompo_conocido": false})
	_comprobar(escenario.cargar_partida(RUTA_GUARDADO) == &"", "La partida con triggers consumidos se carga.")
	_comprobar(EstadoPartida.trigger_consumido(escenario.obtener_id_zona(), trigger.id_trigger) and not gestor.tiene_actividad(), "Cargar dentro de la zona restaura el consumo sin generar una entrada.")
	# La misma escena/ID conserva el consumo al configurar el gestor de nuevo.
	gestor.configurar(zona, escenario.tablero, escenario.obtener_id_zona())
	_comprobar(not gestor.registrar_paso(origen, ancla, ficha), "Volver a configurar la zona conserva la memoria de activación.")
	trigger.frecuencia = TriggerMapa.Frecuencia.CADA_ENTRADA
	_comprobar(gestor.registrar_paso(origen, ancla, ficha), "El modo repetible admite otra entrada.")
	_comprobar(not gestor.registrar_paso(origen, ancla, ficha), "El mismo evento pendiente no se duplica.")
	gestor.limpiar()
	trigger.habilitado = false
	_comprobar(not gestor.registrar_paso(origen, ancla, ficha), "Un trigger deshabilitado no se activa.")
	trigger.habilitado = true
	var npc := Ficha.new()
	npc.id_actor = &"otro_actor"
	_comprobar(not gestor.registrar_paso(origen, ancla, npc), "Los NPC no activan triggers del jugador.")
	npc.free()
	# Una habilidad usa el mismo callback después de confirmar su desplazamiento.
	var ancla_umbral := umbral.obtener_coordenada(capa)
	_comprobar(escenario.habilidades_nivel_dos.mover_forzado(ficha, ancla_umbral + Vector2i.RIGHT), "Una habilidad confirma su desplazamiento y notifica la entrada.")
	_comprobar(gestor.tiene_actividad() and not puerta.abierta, "El umbral reserva una acción de mecanismo sin ejecutarla dentro del callback.")
	gestor.procesar(escenario)
	_comprobar(puerta.abierta and activaciones.back() == umbral.id_trigger, "El mecanismo abre la puerta mediante su contrato existente.")
	# La misma cola modal funciona durante un combate real y conserva el turno.
	var enemigo := (load("res://scenes/personajes/npc.tscn") as PackedScene).instantiate() as PersonajeNPC
	enemigo.id_instancia = &"enemigo_triggers"
	var perfil := (load("res://recursos/personajes/goblin_unico.tres") as DefinicionPersonaje).duplicate(true) as DefinicionPersonaje
	perfil.puede_combatir = true
	perfil.radio_agro = 0
	enemigo.definicion = perfil
	zona.get_node("Interactuables/Personajes").add_child(enemigo)
	_comprobar(escenario.tablero.registrar_interactuable(Vector2i(4, 3), enemigo) and escenario._iniciar_combate(enemigo), "Preparar un combate con NPC para probar el bloqueo del trigger.")
	var ronda: int = escenario.gestor_rondas.ronda_actual
	var actor_activo: Object = escenario.gestor_rondas.actor_activo
	var recursos: Dictionary = ficha.obtener_estado_persistente()["recursos_turno"]
	_comprobar(escenario.habilidades_nivel_dos.mover_forzado(ficha, ancla), "Una habilidad dentro del combate puede entrar en la zona del diálogo.")
	gestor.procesar(escenario)
	_comprobar(is_instance_valid(gestor._globo_activo), "El diálogo del trigger puede comenzar en combate al terminar el desplazamiento.")
	escenario._on_pasar_turno_hud()
	_comprobar(escenario.en_combate and not escenario._resolver_perdida_agro() and escenario.gestor_rondas.ronda_actual == ronda and escenario.gestor_rondas.actor_activo == actor_activo and ficha.obtener_estado_persistente()["recursos_turno"] == recursos, "El diálogo impide avanzar o finalizar el combate y no gasta recursos.")
	gestor.limpiar()
	await process_frame
	_comprobar(escenario._dialogos_camara.is_empty(), "Cerrar anticipadamente el globo también libera la cámara.")
	escenario._terminar_combate(false)
	escenario._cancelar_exploracion_npc()
	escenario.tablero.retirar_interactuable(enemigo)
	enemigo.queue_free()
	await process_frame
	# Dos triggers coincidentes ejecutan por ID y en serie.
	trigger.habilitado = false
	var segundo := umbral.duplicate() as TriggerMapa
	segundo.id_trigger = &"a_segundo_mecanismo"
	zona.get_node("Triggers").add_child(segundo)
	gestor.configurar(zona, escenario.tablero, escenario.obtener_id_zona())
	activaciones.clear()
	gestor.registrar_paso(ancla_umbral, ancla_umbral + Vector2i.RIGHT, ficha)
	gestor.procesar(escenario)
	_comprobar(activaciones == [segundo.id_trigger] and gestor.tiene_actividad(), "Los triggers coincidentes se ordenan por ID y se ejecuta uno por vez.")
	gestor.procesar(escenario)
	_comprobar(activaciones == [segundo.id_trigger, umbral.id_trigger], "La segunda acción conserva su turno en la cola.")
	segundo.id_trigger = umbral.id_trigger
	_comprobar(not gestor.configurar(zona, escenario.tablero, escenario.obtener_id_zona()).is_empty(), "Los IDs duplicados se rechazan antes de jugar.")
	segundo.free()
	gestor.configurar(zona, escenario.tablero, escenario.obtener_id_zona())
	# Un fallo de configuración de contenido no consume el evento.
	var accion := umbral.accion as AccionTriggerMecanismo
	accion.id_receptor = &"inexistente"
	umbral.frecuencia = TriggerMapa.Frecuencia.UNA_VEZ_POR_PARTIDA
	gestor.registrar_paso(ancla_umbral, ancla_umbral + Vector2i.RIGHT, ficha)
	gestor.procesar(escenario)
	_comprobar(not EstadoPartida.trigger_consumido(escenario.obtener_id_zona(), umbral.id_trigger), "Una acción fallida no consume el trigger.")
	accion.id_receptor = &"puerta_trigger"
	# Incapacitado por el terreno: ni registrar ni ejecutar un evento pendiente.
	ficha.pv_actual = 0
	_comprobar(not gestor.registrar_paso(ancla_umbral, ancla_umbral + Vector2i.RIGHT, ficha), "Un jugador caído no inicia un evento narrativo.")
	if FileAccess.file_exists(RUTA_GUARDADO):
		DirAccess.remove_absolute(RUTA_GUARDADO)
	escenario.queue_free()
	await process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
