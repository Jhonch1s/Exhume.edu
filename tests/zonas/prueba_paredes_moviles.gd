extends SceneTree

var fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_probar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)
		push_error(mensaje)


func _probar() -> void:
	var zona := (load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var suelo: TileMapLayer = zona.get_node("CapaSuelo")
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	comprobar(ValidadorContenidoZona.new().validar(zona, tablero, suelo).is_empty(), "La zona debe ser válida antes de registrar.")
	comprobar(tablero.registrar_interactuables_desde_zona(zona, suelo), "Registro completo de los mecanismos.")
	var posiciones := [Vector2i(0, -28), Vector2i(1, -28), Vector2i(0, -29), Vector2i(1, -29)]
	var paredes: Array[PuertaInteractuable] = []
	var origenes: Array[Vector2] = []
	for indice in range(4):
		var pared := tablero.obtener_interactuable(StringName("templo_pared_movil_%03d" % (indice + 1))) as PuertaInteractuable
		paredes.append(pared)
		origenes.append(pared.sprite.position)
		pared.set("duracion_deslizamiento", 0.2)
		comprobar(pared.coordenada_mapa == posiciones[indice] and not tablero.puede_entrar(posiciones[indice]), "Pared en su casilla original, bloqueando el paso.")
		comprobar(tablero.obtener_celda(posiciones[indice]).bloquea_vision_efectiva() and tablero.obtener_celda(posiciones[indice]).bloquea_proyectiles_efectiva(), "Una pared cerrada bloquea visión y proyectiles.")
		comprobar((zona.get_node("CapaParedes") as TileMapLayer).get_cell_source_id(posiciones[indice]) == -1, "El muro móvil sustituye al tile estático.")
	var persistencia := PersistenciaInteractuables.new()
	var cerrado := persistencia.crear_snapshot(tablero, &"templo")
	comprobar(persistencia.validar_restauracion(cerrado, tablero, &"templo") == &"", "El estado cerrado se puede guardar.")
	var placa := tablero.obtener_interactuable(&"trampa_superficie_001") as TrampaSuperficie
	var actor := Ficha.new()
	var gestor := GestorAcciones.new()
	var camara := Camera2D.new()
	root.add_child(camara)
	camara.position = placa.global_position
	camara.force_update_scroll()
	tablero.obtener_celda(placa.coordenada_mapa).visibilidad = Celda.EstadoVisibilidad.VISIBLE
	var vfx := load("res://scripts/render/gestor_vfx.gd").new() as Node
	root.add_child(vfx)
	vfx.configurar(camara, tablero, gestor)
	var efectos: Array[StringName] = []
	vfx.efecto_emitido.connect(func(tipo, _pos): efectos.append(tipo))
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.ENTRAR, actor, placa.coordenada_mapa + Vector2i.LEFT, placa.coordenada_mapa, placa)
	var datos := paredes[0].definicion.duplicate() as DefinicionPuerta
	paredes[0].definicion = datos
	datos.desplazamiento_apertura = Vector2.ZERO
	var rechazado := gestor.procesar_accion(contexto)
	comprobar(not rechazado.exitosa and placa.estado == TrampaSuperficie.Estado.OCULTA and not paredes[0].abierta, "Un destino inválido rechaza el grupo sin consumir la placa.")
	datos.desplazamiento_apertura = Vector2(64, -32)
	var resultado := gestor.procesar_accion(contexto)
	comprobar(resultado.exitosa and placa.estado == TrampaSuperficie.Estado.ACTIVADA, "Pisar la placa activa los cuatro receptores.")
	comprobar(efectos.count(&"piedra_moviendo") == 1 and &"trampa" not in efectos, "La placa visible produce un temblor aunque sus cuatro bloques estén en la niebla.")
	for pared in paredes:
		var animacion: Tween = pared.get("_deslizamiento")
		animacion.pause()
		animacion.custom_step(0.08)
	for indice in range(4):
		var pared := paredes[indice]
		comprobar(pared.sprite.position != origenes[indice] and not pared.permite_caminar_interactuable(), "El bloque se desliza y conserva el bloqueo hasta terminar.")
		var posicion := pared.sprite.position
		comprobar(pared.aplicar_cambio_mecanismo(&"repeticion", true).exitosa and pared.sprite.position == posicion, "Repetir la señal no reinicia ni salta la animación.")
	var durante_animacion: Dictionary = JSON.parse_string(JSON.stringify(persistencia.crear_snapshot(tablero, &"templo")))
	for pared in paredes:
		(pared.get("_deslizamiento") as Tween).custom_step(0.2)
	comprobar(efectos.count(&"piedra_encajada") == 1, "El grupo produce un único golpe final al encajar.")
	var rutas := PathFindingManager.new()
	rutas.inicializar(tablero.datos)
	var camino := rutas.calcular_camino(Vector2i(0, -27), Vector2i(0, -30), tablero.datos)
	for indice in range(4):
		var pared := paredes[indice]
		comprobar(pared.sprite.position.is_equal_approx(origenes[indice] + Vector2(64, -32)), "Desplazamiento de dos casillas +X.")
		comprobar(tablero.puede_entrar(posiciones[indice]) and not tablero.obtener_celda(posiciones[indice]).bloquea_vision_efectiva() and not tablero.obtener_celda(posiciones[indice]).bloquea_proyectiles_efectiva(), "El pasaje abierto permite paso, visión y proyectiles.")
		comprobar(not tablero.puede_entrar(posiciones[indice] + Vector2i(2, 0)), "La pared receptora sigue bloqueando su casilla.")
		comprobar(pared.validar_cambio_mecanismo(&"placa", false) != &"", "El paso queda abierto permanentemente.")
	comprobar(Vector2i(0, -28) in camino and Vector2i(0, -29) in camino, "El pathfinding atraviesa el nuevo pasaje.")
	var abierto: Dictionary = JSON.parse_string(JSON.stringify(persistencia.crear_snapshot(tablero, &"templo")))
	comprobar(persistencia.restaurar(cerrado, tablero, &"templo") == &"" and not tablero.puede_entrar(Vector2i(0, -28)), "Restaurar un estado cerrado recupera el bloqueo.")
	comprobar(persistencia.restaurar(abierto, tablero, &"templo") == &"" and tablero.puede_entrar(Vector2i(0, -28)), "Guardar y cargar mantiene abierto el paso.")
	for indice in range(4):
		comprobar(paredes[indice].sprite.position.is_equal_approx(origenes[indice] + Vector2(64, -32)), "Al cargar aparece en la posición final sin repetir la animación.")
	comprobar(persistencia.restaurar(durante_animacion, tablero, &"templo") == &"" and tablero.puede_entrar(Vector2i(0, -28)), "El guardado durante la animación restaura la apertura final.")
	rutas.free()
	vfx.free()
	camara.free()
	gestor.free()
	actor.free()
	zona.queue_free()
	tablero.queue_free()
	await process_frame
	print("ParedesMoviles: %d fallos." % fallos.size())
	quit(0 if fallos.is_empty() else 1)
