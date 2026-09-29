extends Node2D

## Escena manual aislada: monta EscenarioBase y añade un objetivo hostil cercano.

const ESCENA_ESCENARIO := preload("res://scenes/escenario_base/escenario_base.tscn")
const ESCENA_NPC := preload("res://scenes/personajes/npc.tscn")
const DEFINICION_TROMPO := preload("res://recursos/personajes/goblin_unico.tres")
const RUTA_GUARDADO_PRUEBA := "user://prueba_npc_hostil.json"
const SIN_CELDA := Vector2i(-999, -999)

var _escenario: Node2D
var _enemigo: PersonajeNPC
var _estado: Label


func _ready() -> void:
	_escenario = ESCENA_ESCENARIO.instantiate() as Node2D
	add_child(_escenario)
	_crear_cartel()
	_mostrar_estado("Preparando la escena…")
	if not _escenario.is_node_ready():
		await _escenario.ready
	var preparado: bool = await _esperar_ficha_y_vision()
	if not preparado:
		_mostrar_estado("No se pudo iniciar la ficha y la visión.")
		push_error("EscenaNPCHostil: la ficha o la visión no terminaron de iniciar.")
		return
	var tablero := _escenario.get("tablero") as TableroGrid
	var ficha := _escenario.get("ficha_jugador") as Ficha
	var zona := _escenario.get_node("Zona") as Node2D
	var capa_suelo := zona.get_node("CapaSuelo") as TileMapLayer
	if tablero == null or ficha == null or capa_suelo == null:
		_mostrar_estado("No se pudo preparar el escenario de prueba.")
		push_error("EscenaNPCHostil: faltan tablero, ficha o capa de suelo.")
		return
	var destino := _buscar_celda_cercana(
		ficha.coordenada_mapa, tablero,
		_escenario.get("pathfinding") as PathFindingManager
	)
	if destino == SIN_CELDA:
		_mostrar_estado("No hay una celda visible y accesible para el objetivo.")
		push_error("EscenaNPCHostil: no hay celda cercana válida para el objetivo.")
		return
	_crear_enemigo(zona, capa_suelo, tablero, destino)


func _esperar_ficha_y_vision() -> bool:
	for _fotograma in range(180):
		var tablero := _escenario.get("tablero") as TableroGrid
		var ficha := _escenario.get("ficha_jugador") as Ficha
		if tablero != null and ficha != null and ficha.is_inside_tree():
			var celda := tablero.obtener_celda(ficha.coordenada_mapa)
			if celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE:
				return true
		await get_tree().process_frame
	return false


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _escenario == null:
		return
	var motivo: StringName
	if event.keycode == KEY_F7:
		motivo = _escenario.call(&"guardar_partida", RUTA_GUARDADO_PRUEBA)
		_mostrar_estado("Guardado: OK" if motivo == &"" else "Guardado: " + String(motivo))
	elif event.keycode == KEY_F8:
		motivo = _escenario.call(&"cargar_partida", RUTA_GUARDADO_PRUEBA)
		_mostrar_estado("Carga: OK" if motivo == &"" else "Carga: " + String(motivo))
	else:
		return
	get_viewport().set_input_as_handled()


func _buscar_celda_cercana(
	origen: Vector2i,
	tablero: TableroGrid,
	pathfinding: PathFindingManager
) -> Vector2i:
	if pathfinding == null:
		return SIN_CELDA
	var candidatas: Array[Vector2i] = []
	candidatas.assign(tablero.datos.keys())
	candidatas.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	for distancia in range(2, 6):
		for candidata in candidatas:
			if abs(candidata.x - origen.x) + abs(candidata.y - origen.y) != distancia:
				continue
			var celda := tablero.obtener_celda(candidata)
			if (
				celda == null
				or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE
				or not celda.interactuables.is_empty()
				or not tablero.puede_entrar(candidata)
			):
				continue
			if not pathfinding.calcular_camino(origen, candidata, tablero.datos).is_empty():
				return candidata
	return SIN_CELDA


func _crear_enemigo(
	zona: Node2D,
	capa_suelo: TileMapLayer,
	tablero: TableroGrid,
	coordenada: Vector2i
) -> void:
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"npc_hostil_prueba"
	perfil.nombre = "Objetivo hostil de prueba"
	perfil.vida_maxima = 2
	perfil.iniciativa_base = -1
	perfil.nivel = 1
	perfil.fuerza = 2
	perfil.destreza = 2
	perfil.voluntad = 2
	perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.HOSTIL
	perfil.actitud_hacia_jugador_fija = true
	perfil.puede_combatir = true
	perfil.textura_mapa = DEFINICION_TROMPO.textura_mapa
	perfil.ilustracion_examen = DEFINICION_TROMPO.ilustracion_examen
	perfil.perfil_observacion = PerfilObservacion.new()
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = &"aspecto"
	fragmento.id_mensaje = &"examen.npc_hostil_prueba.basico"
	perfil.fragmentos_informacion.append(fragmento)
	_enemigo = ESCENA_NPC.instantiate() as PersonajeNPC
	_enemigo.name = "ObjetivoHostilPrueba"
	_enemigo.id_instancia = &"npc_hostil_prueba_001"
	_enemigo.nombre_unico = "Objetivo hostil de prueba"
	_enemigo.definicion = perfil
	zona.get_node("Interactuables/Personajes").add_child(_enemigo)
	_enemigo.global_position = capa_suelo.to_global(capa_suelo.map_to_local(coordenada))
	_enemigo.sprite_personaje.modulate = Color(1.0, 0.45, 0.45)
	if not tablero.registrar_interactuable(coordenada, _enemigo):
		_enemigo.queue_free()
		_enemigo = null
		_mostrar_estado("No se pudo registrar el objetivo de prueba.")
		return
	_enemigo.actualizar_presentacion_visibilidad(
		tablero.obtener_celda(coordenada).visibilidad
	)
	_enemigo.puntos_vida_cambiados.connect(func(actual: int, maximo: int):
		_mostrar_estado("Objetivo: %d/%d PV" % [actual, maximo])
	)
	_mostrar_estado("Objetivo: 2/2 PV")
	print("EscenaNPCHostil: objetivo registrado en %s." % coordenada)


func _crear_cartel() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	_estado = Label.new()
	_estado.position = Vector2(12, 112)
	_estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_estado.add_theme_font_size_override(&"font_size", 18)
	_estado.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_estado.add_theme_constant_override(&"shadow_offset_x", 2)
	_estado.add_theme_constant_override(&"shadow_offset_y", 2)
	capa.add_child(_estado)


func _mostrar_estado(detalle: String) -> void:
	if _estado != null:
		_estado.text = (
			"PRUEBA NPC HOSTIL\n"
			+ "Atacar inicia combate | arriba: orden de turnos\n"
			+ "Clic derecho: moverse | HUD: pasar turno\n"
			+ "Adyacente: el NPC intentará atacarte\n"
			+ "F7: guardar | F8: cargar\n"
			+ detalle
		)
