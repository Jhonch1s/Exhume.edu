extends Node

var _fallos: Array[String] = []


func _ready() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var zona := Node2D.new()
	get_tree().root.add_child(zona)
	var capa := TileMapLayer.new()
	capa.tile_set = TileSet.new()
	capa.tile_set.tile_size = Vector2i(64, 32)
	zona.add_child(capa)
	var contenedor_efectos := Node2D.new()
	contenedor_efectos.name = "EfectosSuperficie"
	zona.add_child(contenedor_efectos)
	var tablero := TableroGrid.new()
	get_tree().root.add_child(tablero)
	tablero.zona_referencia = zona
	tablero.capa_referencia = capa
	for x in range(4):
		tablero.datos[Vector2i(x, 0)] = Celda.new()

	var estatua := EstatuaMecanismo.new()
	estatua.id_instancia = &"estatua_fuego"
	_comprobar(
		estatua._obtener_direccion_disparo() == Vector2i.LEFT,
		"Abajo izquierda debe avanzar hacia la izquierda del mapa isometrico."
	)
	estatua.orientacion = EstatuaMecanismo.Orientacion.ABAJO_DERECHA
	_comprobar(
		estatua._obtener_direccion_disparo() == Vector2i.DOWN,
		"Abajo derecha debe avanzar hacia abajo del mapa isometrico."
	)
	estatua.orientacion = EstatuaMecanismo.Orientacion.ARRIBA_IZQUIERDA
	_comprobar(
		estatua._obtener_direccion_disparo() == Vector2i.UP,
		"Arriba izquierda debe avanzar hacia arriba del mapa isometrico."
	)
	estatua.orientacion = EstatuaMecanismo.Orientacion.ARRIBA_DERECHA
	_comprobar(
		estatua._obtener_direccion_disparo() == Vector2i.RIGHT,
		"Arriba derecha debe avanzar hacia la derecha del mapa isometrico."
	)
	get_tree().root.add_child(estatua)
	tablero.registrar_interactuable(Vector2i.ZERO, estatua)

	var placa := (load(
		"res://scenes/interactuables/trampas/TrampaSuperficie.tscn"
	) as PackedScene).instantiate() as TrampaSuperficie
	placa.id_instancia = &"placa_estatua"
	placa.fila_atlas = 2
	placa.ids_receptores_mecanismo = [&"estatua_fuego"]
	get_tree().root.add_child(placa)
	tablero.registrar_interactuable(Vector2i(2, 0), placa)

	var ficha := Ficha.new()
	get_tree().root.add_child(ficha)
	tablero.ocupar_celda(Vector2i(2, 0), ficha)
	var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
		tablero.obtener_celda(Vector2i(2, 0)),
		TiposInteraccion.TipoAccion.ENTRAR,
		ficha
	)
	var gestor := GestorAcciones.new()
	get_tree().root.add_child(gestor)
	var resultado := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		ficha,
		Vector2i(1, 0),
		Vector2i(2, 0),
		reacciones
	)

	_comprobar(resultado.resultados.size() == 1, "La placa debe producir una sola reaccion.")
	_comprobar(placa.estado == TrampaSuperficie.Estado.ACTIVADA, "La placa debe quedar presionada.")
	_comprobar(
		placa.get_node("Sprite2D").region_rect.position == Vector2(64, 64),
		"La placa neutral activada debe usar la segunda columna de la tercera fila."
	)
	_comprobar(
		ficha.obtener_estado(&"quemado") != null,
		"La llamarada debe quemar a la ficha alcanzada al aparecer."
	)
	_comprobar(
		resultado.efectos_aplicados.size() == 1,
		"El quemado inicial debe quedar en el resultado estructurado."
	)
	_comprobar(
		&"trampa.mecanismo_activado" in resultado.mensajes
		and &"estatua.escupe_fuego" in resultado.mensajes
		and &"estado.quemado" in resultado.mensajes,
		"La reaccion debe agrupar la placa, la llamarada y el quemado."
	)
	var fuegos_validos := true
	for coord in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]:
		var celda := tablero.obtener_celda(coord)
		if celda.efectos_superficie.size() != 1:
			fuegos_validos = false
			continue
		var fuego := celda.efectos_superficie[0] as Fuego
		var visual := (
			fuego.get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
			if fuego != null else null
		)
		fuegos_validos = fuegos_validos and fuego != null and (
			fuego in celda.iluminacion
			and visual != null
			and visual.is_playing()
		)
	_comprobar(
		tablero.efectos_superficie_por_id.size() == 3 and fuegos_validos,
		"La estatua debe dejar tres superficies de fuego luminosas."
	)

	placa.estado = TrampaSuperficie.Estado.OCULTA
	tablero.obtener_celda(Vector2i(1, 0)).altura = 2
	var cantidad_fuegos := tablero.efectos_superficie_por_id.size()
	resultado = ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		ficha,
		Vector2i(1, 0),
		Vector2i(2, 0),
		ConsultorReaccionesCelda.new().obtener_reacciones(
			tablero.obtener_celda(Vector2i(2, 0)),
			TiposInteraccion.TipoAccion.ENTRAR,
			ficha
		)
	)
	_comprobar(
		tablero.efectos_superficie_por_id.size() == cantidad_fuegos
		and &"estatua.fuego_bloqueado" in resultado.mensajes,
		"Una pared debe detener la llamarada y evitar fuego nuevo."
	)

	gestor.queue_free()
	ficha.queue_free()
	placa.queue_free()
	estatua.queue_free()
	tablero.queue_free()
	zona.queue_free()
	await get_tree().process_frame
	if _fallos.is_empty():
		print("PlacaEstatua: prueba correcta.")
		get_tree().quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	get_tree().quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
