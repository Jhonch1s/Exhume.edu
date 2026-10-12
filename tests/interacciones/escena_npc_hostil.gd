extends Node2D

## Escena manual aislada: añade hostiles y asigna rutas editables a los dos primeros.

const ESCENA_NPC := preload("res://scenes/personajes/npc.tscn")
const DEFINICION_TROMPO := preload("res://recursos/personajes/goblin_unico.tres")
const RUTA_GUARDADO_PRUEBA := "user://prueba_npc_hostil.json"
const SIN_CELDA := Vector2i(-999, -999)

@export_range(1, 5, 1) var cantidad_enemigos: int = 3
@export_range(0, 20, 1) var radio_vision_enemigos: int = 0

var _escenario: Node2D
var _enemigos: Array[PersonajeNPC] = []
var _ruta_guardado := RUTA_GUARDADO_PRUEBA
var _estado: Label


func _ready() -> void:
	if cantidad_enemigos > 1:
		_ruta_guardado = "user://prueba_npc_hostil_%d_enemigos.json" % cantidad_enemigos
	_escenario = $Escenario as Node2D
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
	for indice in range(cantidad_enemigos):
		var destino := _buscar_celda_cercana(
			ficha.coordenada_mapa, tablero,
			_escenario.get("pathfinding") as PathFindingManager
		)
		if destino == SIN_CELDA or not _crear_enemigo(zona, capa_suelo, tablero, destino, indice + 1):
			_mostrar_estado("No se pudieron colocar todos los enemigos: %d/%d." % [_enemigos.size(), cantidad_enemigos])
			push_error("EscenaNPCHostil: faltan celdas válidas para el grupo de enemigos.")
			return
	_mostrar_estado("Grupo: %d enemigos, 2 PV cada uno." % _enemigos.size())


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
	# F7 y F8 pertenecen a pausa y parada del editor de Godot.
	if event.keycode == KEY_K:
		motivo = _escenario.call(&"guardar_partida", _ruta_guardado)
	elif event.keycode == KEY_C:
		motivo = _escenario.call(&"cargar_partida", _ruta_guardado)
	else:
		return
	var catalogo := _escenario.get("catalogo_mensajes") as CatalogoMensajesInteraccion
	var detalle := "OK" if motivo == &"" else (
		catalogo.resolver(motivo) if catalogo != null else String(motivo)
	)
	_mostrar_estado(("Guardado: " if event.keycode == KEY_K else "Carga: ") + detalle)
	if motivo != &"":
		print("EscenaNPCHostil: %s — %s" % [motivo, detalle])
	get_viewport().set_input_as_handled()


func _buscar_celda_cercana(
	origen: Vector2i,
	tablero: TableroGrid,
	pathfinding: PathFindingManager
) -> Vector2i:
	var validador := _escenario.get("validador_espacial") as ValidadorEspacialTablero
	if pathfinding == null or validador == null:
		return SIN_CELDA
	var candidatas: Array[Vector2i] = []
	candidatas.assign(tablero.datos.keys())
	candidatas.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	# Preferimos cinco casillas para que el jugador pueda ver al grupo al inicio.
	for distancia in [5, 4, 3, 2]:
		for candidata in candidatas:
			if Vector2(candidata - origen).length_squared() != distancia * distancia:
				continue
			var celda := tablero.obtener_celda(candidata)
			if (
				celda == null
				or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE
				or not celda.interactuables.is_empty()
				or not tablero.puede_entrar(candidata)
				or validador.validar_linea_visual(candidata, origen) != &""
			):
				continue
			if not pathfinding.calcular_camino(origen, candidata, tablero.datos).is_empty():
				return candidata
	return SIN_CELDA


func _crear_enemigo(
	zona: Node2D,
	capa_suelo: TileMapLayer,
	tablero: TableroGrid,
	coordenada: Vector2i,
	numero: int
) -> bool:
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"npc_hostil_prueba"
	perfil.nombre = "Objetivo hostil de prueba"
	perfil.vida_maxima = 2
	perfil.nivel = 1
	perfil.fuerza = 2
	perfil.destreza = 2
	perfil.voluntad = 2
	perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.HOSTIL
	perfil.actitud_hacia_jugador_fija = true
	perfil.puede_combatir = true
	perfil.puede_tener_inventario = true
	# Excepción temporal de esta escena; la regla general de NPC es DES + 3.
	perfil.movimiento_fijo = 4
	perfil.radio_agro = radio_vision_enemigos
	perfil.textura_mapa = DEFINICION_TROMPO.textura_mapa
	perfil.ilustracion_examen = DEFINICION_TROMPO.ilustracion_examen
	perfil.perfil_observacion = PerfilObservacion.new()
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = &"aspecto"
	fragmento.id_mensaje = &"examen.npc_hostil_prueba.basico"
	perfil.fragmentos_informacion.append(fragmento)
	var enemigo := ESCENA_NPC.instantiate() as PersonajeNPC
	enemigo.name = "ObjetivoHostilPrueba%d" % numero
	enemigo.id_instancia = StringName("npc_hostil_prueba_%03d" % numero)
	enemigo.nombre_unico = "Goblin %d" % numero
	enemigo.definicion = perfil
	var botin := EntradaInventarioInicial.new()
	botin.definicion = preload("res://assets/items/piedra/piedra.tres")
	botin.cantidad = 2
	enemigo.contenido_inicial.append(botin)
	zona.get_node("Interactuables/Personajes").add_child(enemigo)
	enemigo.global_position = capa_suelo.to_global(capa_suelo.map_to_local(coordenada))
	enemigo.sprite_personaje.modulate = Color(1.0, 0.45, 0.45)
	if numero <= 2:
		var nombre_ruta := "RutaPatrulla" if numero == 1 else "RutaPatrulla2"
		var ruta := get_node(nombre_ruta) as PatrullaNPC
		var patrulla := enemigo.obtener_patrulla()
		patrulla.turnos_espera = ruta.turnos_espera
		patrulla.curve.clear_points()
		for indice in range(ruta.curve.point_count):
			patrulla.curve.add_point(patrulla.to_local(ruta.to_global(ruta.curve.get_point_position(indice))))
	if not tablero.registrar_interactuable(coordenada, enemigo):
		enemigo.queue_free()
		return false
	_enemigos.append(enemigo)
	enemigo.actualizar_presentacion_visibilidad(
		tablero.obtener_celda(coordenada).visibilidad
	)
	enemigo.puntos_vida_cambiados.connect(func(actual: int, maximo: int):
		_mostrar_estado("%s: %d/%d PV" % [enemigo.obtener_nombre_interaccion(), actual, maximo])
	)
	print("EscenaNPCHostil: %s registrado en %s." % [enemigo.nombre_unico, coordenada])
	return true


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
			"PRUEBA NPC HOSTIL — %d enemigos\n" % cantidad_enemigos
			+ "NPC: movimiento 4 puntos | visión/agro %d casillas\n" % radio_vision_enemigos
			+ "Clic derecho: moverse | HUD: pasar turno\n"
			+ "NPC: se acerca y ataca | FUE: ataque | DES: esquiva automática\n"
			+ "Agro colectivo: combate mientras alguno te vea\n"
			+ "Goblin 1: RutaPatrulla | Goblin 2: RutaPatrulla2 | Goblin 3: sin ruta\n"
			+ "Dibuja al menos 2 puntos por ruta | visión 0 para patrullar sin combate\n"
			+ "K: guardar | C: cargar\n"
			+ "Al derrotarlos: Recoger botín junto al cuerpo (2 piedras por NPC)\n"
			+ detalle
		)
