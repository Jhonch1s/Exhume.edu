extends SceneTree

const RUTA := "user://prueba_luz_percepcion.json"
const IZQUIERDA := Vector2i(101, 102)
const DERECHA := Vector2i(104, 102)
const FONDO := Vector2i(107, 102)
const HALO := Vector2i(109, 102)
var _fallos: Array[String] = []
var _casos := 0
var _escenario: Node2D
var _tablero: TableroGrid
var _fov: FOVManager
var _ficha: Ficha
var _puerta: PuertaInteractuable
var _luz: FuenteLuzInteractuable
var _npc: PersonajeNPC
var _trampa: TrampaSuperficie


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	_escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(_escenario)
	for intento in 200:
		await process_frame
		if _escenario.ficha_jugador != null and _escenario.hud.ficha == _escenario.ficha_jugador:
			break
	if _escenario.ficha_jugador == null or _escenario.hud.ficha != _escenario.ficha_jugador:
		_comprobar(false, "Inicializar escenario y HUD reales.")
		_finalizar()
		return
	_escenario.set_process(false)
	_tablero = _escenario.tablero
	_fov = _escenario.gestor_vision
	_ficha = _escenario.ficha_jugador
	_preparar_habitaciones()
	_probar_ocultos()
	await _probar_recorrido()
	await _probar_carga()
	await _probar_carga_ampliada()
	_probar_esquina_y_diccionario()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	_finalizar()


func _preparar_habitaciones() -> void:
	for x in range(100, 111):
		for y in range(100, 105):
			var coord := Vector2i(x, y)
			_tablero.datos[coord] = Celda.new()
			if x == 103 and y != 102:
				_tablero.datos[coord].bloquea_vision = true
	_puerta = load("res://scenes/interactuables/puertas/puerta_interactuable.tscn").instantiate()
	_puerta.id_instancia = &"vision_puerta"
	_puerta.definicion = load("res://assets/interactuables/puertas/puerta/puerta.tres")
	_registrar(_puerta, Vector2i(103, 102))
	_luz = load("res://scenes/interactuables/fuentes_luz/fuente_luz_interactuable.tscn").instantiate()
	_luz.id_instancia = &"vision_luz"
	_luz.definicion = load("res://assets/interactuables/luces/antorcha_pie.tres").duplicate(true)
	_luz.definicion.radio_luz = 2
	_luz.definicion.radio_penumbra = 1
	_registrar(_luz, Vector2i(106, 102))
	_npc = load("res://scenes/personajes/npc.tscn").instantiate()
	_npc.id_instancia = &"vision_npc"
	_npc.definicion = _npc.definicion.duplicate(true)
	_npc.definicion.radio_agro = 12
	_registrar(_npc, FONDO)
	_trampa = load("res://scenes/interactuables/trampas/TrampaSuperficie.tscn").instantiate()
	_trampa.id_instancia = &"vision_trampa"
	_registrar(_trampa, Vector2i(105, 102))
	var item := ItemSuelo.new(ItemInstancia.new(&"vision_piedra", load("res://assets/items/piedra/piedra.tres"), 1))
	_comprobar(_tablero.registrar_item_suelo(FONDO, item), "Registrar item detrás de la puerta.")
	_situar(IZQUIERDA)
	_fov.inicializar(_escenario.capa_oscuridad, _tablero)
	_escenario._actualizar_luz_jugador(IZQUIERDA)


func _registrar(objeto: Interactuable, coord: Vector2i) -> void:
	_escenario.zona_actual.add_child(objeto)
	_comprobar(_tablero.registrar_interactuable(coord, objeto), "Registrar %s." % objeto.id_instancia)


func _situar(coord: Vector2i) -> void:
	_tablero.liberar_celda(_ficha.coordenada_mapa, _ficha)
	_ficha.coordenada_mapa = coord
	_tablero.ocupar_celda(coord, _ficha)


func _probar_ocultos() -> void:
	_comprobar(_fov.iluminacion_actual.get(FONDO) == FOVManager.NivelLuz.LUZ, "Hay luz real en el cuarto oculto.")
	_comprobar(_fov.iluminacion_actual.get(HALO) == FOVManager.NivelLuz.PENUMBRA, "El halo también se calcula sin descubrirlo.")
	for coord in [FONDO, HALO, _luz.coordenada_mapa, _trampa.coordenada_mapa]:
		_comprobar(_tablero.obtener_celda(coord).visibilidad == Celda.EstadoVisibilidad.OCULTO, "La pared impide descubrir %s, con luz o penumbra." % coord)
	_comprobar(not _npc.visible, "El NPC iluminado detrás de puerta está oculto.")
	_comprobar(SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(_tablero, FONDO, _ficha).is_empty(), "Objetivos e items ocultos no se seleccionan.")
	_comprobar(SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(_tablero, FONDO, _ficha, _npc.global_position).is_empty(), "La selección por sprite tampoco filtra información.")
	_comprobar(not _escenario._es_celda_lanzamiento_valida(FONDO), "No se puede apuntar a una celda oculta.")
	_comprobar(not _luz.visible, "La fuente oculta no muestra su sprite.")
	_comprobar(not _escenario.servicio_examen.resolver_examen(_contexto_examen(), _luz).exitosa, "No se examina una luz que no se puede ver.")
	_comprobar(not _escenario.registro_conocimiento.intento_percepcion_realizado(_ficha.id_observador, _trampa.id_instancia), "No se gasta el intento de detectar una trampa oculta por pared.")
	_comprobar(not _npc.puede_ver_coordenada(IZQUIERDA, _escenario.validador_espacial), "La puerta también bloquea la percepción propia del NPC.")
	_luz.definicion.atraviesa_muros = true
	_tablero.iluminacion_cambiada.emit(_luz.coordenada_mapa)
	_comprobar(_tablero.obtener_celda(FONDO).visibilidad == Celda.EstadoVisibilidad.OCULTO, "Luz que atraviesa muros no concede visión a la ficha.")


func _probar_recorrido() -> void:
	_puerta.abierta = true
	_puerta.presencia_cambiada.emit()
	_comprobar(_tablero.obtener_celda(FONDO).visibilidad == Celda.EstadoVisibilidad.VISIBLE and _npc.visible, "Abrir descubre el cuarto iluminado y el NPC.")
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.EXPLORADO, "Una fuente percibida amplía su penumbra a ocho casillas.")
	_comprobar(_tablero.obtener_celda(Vector2i(108, 102)).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "La luz ajena se percibe hasta siete casillas incluidas.")
	_luz.definicion.radio_luz = 4
	_tablero.iluminacion_cambiada.emit(_luz.coordenada_mapa)
	_comprobar(_fov.iluminacion_actual.get(HALO) == FOVManager.NivelLuz.LUZ and _tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Una fuente percibida permite ver su luz plena a ocho casillas.")
	_luz.definicion.radio_luz = 2
	_tablero.iluminacion_cambiada.emit(_luz.coordenada_mapa)
	_comprobar(_npc.puede_ver_coordenada(IZQUIERDA, _escenario.validador_espacial), "El NPC detecta por su radio y línea propios.")
	_comprobar(not SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(_tablero, FONDO, _ficha).is_empty(), "Objetivos e items se ofrecen al verlos.")
	_ficha.velocidad_paso = 0.001
	var camino: Array[Vector2i] = [IZQUIERDA, Vector2i(102, 102), Vector2i(103, 102), DERECHA]
	_comprobar(await _escenario._recorrer_camino_interaccion(camino), "Movimiento real a través de la puerta abierta.")
	_comprobar(_ficha.coordenada_mapa == DERECHA and _fov.ultimo_centro_jugador == DERECHA, "Cada paso actualiza la percepción desde la ficha.")
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Acercarse permite descubrir la casilla antes fuera de alcance.")
	_comprobar(_escenario.servicio_examen.resolver_examen(_contexto_examen(), _luz).exitosa, "Dentro del cuarto se puede examinar la luz.")
	_comprobar(_escenario.registro_conocimiento.intento_percepcion_realizado(_ficha.id_observador, _trampa.id_instancia), "Al entrar en alcance visible se intenta percibir la trampa.")
	var humo := Humo.new()
	humo.configurar_id_instancia(&"vision_humo")
	_escenario.zona_actual.add_child(humo)
	_tablero.registrar_efecto_superficie(Vector2i(105, 102), humo)
	_comprobar(_fov.iluminacion_actual.get(FONDO) == FOVManager.NivelLuz.LUZ and not _npc.visible, "El humo oculta al NPC aunque la fuente conserve luz detrás.")
	_tablero.retirar_efecto_superficie(humo)
	humo.queue_free()
	_comprobar(_npc.visible, "Retirar humo restaura visión inmediatamente.")
	_situar(IZQUIERDA)
	_puerta.abierta = false
	_puerta.presencia_cambiada.emit()
	_escenario._actualizar_luz_jugador(IZQUIERDA)
	_comprobar(_tablero.obtener_celda(FONDO).visibilidad == Celda.EstadoVisibilidad.EXPLORADO and not _npc.visible, "Al salir se recuerda terreno sin seguir al NPC.")
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.EXPLORADO, "Lo descubierto al acercarse se conserva explorado al quedar a más de siete casillas.")
	_comprobar(SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(_tablero, FONDO, _ficha).is_empty(), "Recordar terreno no ofrece objetivos actuales.")
	_comprobar(not _escenario.servicio_examen.resolver_examen(_contexto_examen(), _luz).exitosa, "Terreno recordado no permite examinar el estado actual.")
	_luz.encendida = false
	_comprobar(not _fov.iluminacion_actual.has(FONDO), "Apagar retira iluminación anterior.")
	_puerta.abierta = true
	_puerta.presencia_cambiada.emit()
	_fov.actualizar_vision(IZQUIERDA, 1)
	_comprobar(_tablero.obtener_celda(Vector2i(102, 102)).visibilidad == Celda.EstadoVisibilidad.VISIBLE and _tablero.obtener_celda(DERECHA).visibilidad != Celda.EstadoVisibilidad.VISIBLE, "En oscuridad, una antorcha atenuada no concede siete casillas de visión.")
	_comprobar(_npc.puede_ver_coordenada(IZQUIERDA, _escenario.validador_espacial) and not _npc.visible, "Un NPC vivo conserva percepción independiente de luz y niebla del jugador.")
	_npc.recibir_danio(999)
	_comprobar(not _npc.visible, "La muerte fuera de vista tampoco revela el cadáver.")
	_comprobar(not _npc.puede_ver_coordenada(IZQUIERDA, _escenario.validador_espacial), "Un cadáver no percibe.")


func _probar_carga() -> void:
	_puerta.abierta = false
	_puerta.presencia_cambiada.emit()
	_luz.encendida = true
	_escenario._actualizar_luz_jugador(IZQUIERDA)
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Guardar partida completa con luz encendida y puerta cerrada.")
	var guardado: Dictionary = _escenario.persistencia_partida.archivos.cargar(RUTA)
	_luz.encendida = false
	_puerta.abierta = true
	_puerta.presencia_cambiada.emit()
	_situar(DERECHA)
	_ficha.pasos_antorcha_actual = 1
	_fov.inicializar(_escenario.capa_oscuridad, _tablero)
	_escenario._actualizar_luz_jugador(DERECHA)
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.OCULTO, "Preparar halo nunca visto antes de cargar desde otra posición.")
	var revision := _fov.revision_vision
	_comprobar(_escenario.cargar_partida(RUTA) == &"", "Cargar archivo restaura posición, puerta y luz.")
	_comprobar(_ficha.coordenada_mapa == IZQUIERDA and not _puerta.abierta and _luz.encendida, "Se recupera el estado guardado.")
	_comprobar(_fov.revision_vision == revision + 1 and _fov.ultimo_centro_jugador == IZQUIERDA, "Carga recalcula una vez desde la posición restaurada antes de volver.")
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.EXPLORADO, "Restaurar recupera el halo explorado guardado sin hacerlo visible desde la posición anterior.")
	_comprobar(not _npc.visible and SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(_tablero, FONDO, _ficha).is_empty(), "Tras carga no reaparecen NPC ni objetivos tras pared.")
	var restaurado: Dictionary = _escenario.persistencia_partida.crear_snapshot(_tablero, &"zona1", _ficha, _escenario.registro_conocimiento)
	_comprobar(_estado_mundo(restaurado) == _estado_mundo(guardado), "La percepción no altera recursos, conocimiento ni exploración del snapshot.")
	await process_frame
	_comprobar(_fov.revision_vision == revision + 1, "No queda un segundo recálculo diferido de carga.")
	_comprobar(_escenario.cargar_partida(RUTA) == &"", "Una segunda carga conserva el recorrido.")
	var anterior := guardado.duplicate(true)
	anterior["version"] = 1
	anterior.erase("memoria_narrativa")
	_comprobar(_escenario.persistencia_partida.archivos.guardar(RUTA, anterior) == &"" and _escenario.cargar_partida(RUTA) == &"", "Se conserva carga del formato anterior v1.")
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.EXPLORADO and not _npc.visible, "Cargar v1 también respeta la pared y conserva terreno recordado.")


func _probar_carga_ampliada() -> void:
	_luz.definicion.radio_luz = 4
	_puerta.bloqueada = false
	_puerta.abierta = true
	_puerta.presencia_cambiada.emit()
	_escenario._actualizar_luz_jugador(IZQUIERDA)
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Preparar visión ampliada más allá de siete antes de guardar.")
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Guardar con fuente directa y extensión activa.")
	var guardado: Dictionary = _escenario.persistencia_partida.archivos.cargar(RUTA)
	_luz.encendida = false
	_puerta.abierta = false
	_puerta.presencia_cambiada.emit()
	_situar(DERECHA)
	_escenario._actualizar_luz_jugador(DERECHA)
	_comprobar(_escenario.cargar_partida(RUTA) == &"", "Cargar recupera la fuente percibida desde la posición guardada.")
	_comprobar(_ficha.coordenada_mapa == IZQUIERDA and _tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "La carga reconstruye la extensión sin usar la posición anterior.")
	var restaurado: Dictionary = _escenario.persistencia_partida.crear_snapshot(_tablero, &"zona1", _ficha, _escenario.registro_conocimiento)
	_comprobar(_estado_mundo(restaurado) == _estado_mundo(guardado), "Reconstruir la ampliación no cambia recursos ni exploración guardada.")
	var revision := _fov.revision_vision
	await process_frame
	_comprobar(_fov.revision_vision == revision and _tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "La ampliación cargada permanece estable en el siguiente frame.")
	_luz.encendida = false
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Guardar también sin fuente directa encendida.")
	_luz.encendida = true
	_comprobar(_escenario.cargar_partida(RUTA) == &"" and not _luz.encendida, "Cargar fuente apagada retira su aportación ampliada.")
	_comprobar(_tablero.obtener_celda(HALO).visibilidad == Celda.EstadoVisibilidad.EXPLORADO and not _fov.iluminacion_fuentes_percibidas.has(HALO), "No quedan restos de extensión tras cargar una luz apagada.")


func _probar_esquina_y_diccionario() -> void:
	var datos := {}
	for coord in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
		datos[coord] = Celda.new()
	datos[Vector2i.RIGHT].bloquea_vision = true
	datos[Vector2i.DOWN].bloquea_vision = true
	var capa := TileMapLayer.new()
	capa.tile_set = load("res://assets/tile_sets/fog/cave_fog.tres")
	root.add_child(capa)
	var fov := FOVManager.new()
	root.add_child(fov)
	fov.inicializar(capa, datos)
	fov.proyectar_luz_fuente(Vector2i.ONE, 3, 1, true)
	_comprobar(datos[Vector2i.ONE].visibilidad == Celda.EstadoVisibilidad.OCULTO, "El proyector solo modifica luz, nunca conocimiento.")
	fov.actualizar_vision(Vector2i.ZERO, 3)
	_comprobar(datos[Vector2i.ONE].visibilidad == Celda.EstadoVisibilidad.OCULTO, "La esquina cerrada bloquea también con inicialización por diccionario.")
	fov.queue_free()
	capa.queue_free()


func _estado_mundo(snapshot: Dictionary) -> Dictionary:
	var estado: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	estado.erase("escena_zona")
	estado.erase("en_campamento")
	return estado


func _contexto_examen() -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR, _ficha, _ficha.coordenada_mapa,
		_luz.coordenada_mapa, _luz, null, &"", [], {}, 12.0, {},
		TiposInteraccion.TipoLineaEfecto.VISUAL, {},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO, SolicitudExamen.new(_ficha.id_observador)
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	for fallo in _fallos:
		push_error(fallo)
	print("LuzPercepcion: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	_escenario.queue_free()
	quit(0 if _fallos.is_empty() else 1)
