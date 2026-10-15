extends SceneTree

const RUTA := "user://prueba_persistencia_fase12.json"
const ESCENARIO_SIN_RENDER := preload("res://tests/soporte/escenario_sin_render.gd")

var _fallos: Array[String] = []
var _casos := 0


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escenario := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	escenario.set_script(ESCENARIO_SIN_RENDER)
	root.add_child(escenario)
	for _intento in range(200):
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	if escenario.ficha_jugador == null or escenario.hud.ficha != escenario.ficha_jugador:
		_comprobar(false, "El escenario debe terminar de preparar la ficha y el HUD.")
		escenario.queue_free()
		await process_frame
		_finalizar()
		return
	escenario.set_process(false)
	var ficha: Ficha = escenario.ficha_jugador
	var palanca := escenario.tablero.obtener_interactuable(
		&"zona1_palanca_03_m03"
	) as PalancaInteractuable
	var puerta := escenario.tablero.obtener_interactuable(
		&"zona1_puerta_mecanismo_05_m03"
	) as PuertaInteractuable
	if palanca == null or puerta == null:
		_comprobar(false, "La zona de integración debe ofrecer puerta y palanca.")
		escenario.queue_free()
		await process_frame
		_finalizar()
		return
	# El botín y la superficie son del fixture; no dependen del contenido jugable.
	var tablero: TableroGrid = escenario.tablero
	for coordenada in [Vector2i(100, 100), Vector2i(101, 100)]:
		tablero.datos[coordenada] = Celda.new()
	var cofre := CofreInteractuable.new()
	cofre.id_instancia = &"archivo_cofre_prueba"
	cofre.definicion = load("res://scenes/interactuables/cofres/cofre_pequeno.tres")
	var entrada := EntradaInventarioInicial.new()
	entrada.definicion = load("res://assets/items/piedra/piedra.tres")
	entrada.cantidad = 3
	cofre.contenido_inicial = [entrada]
	escenario.zona_actual.add_child(cofre)
	_comprobar(tablero.registrar_interactuable(Vector2i(100, 100), cofre), "Registrar el cofre de prueba.")
	var superficie := (load("res://scenes/efectos_superficie/Humo.tscn") as PackedScene).instantiate()
	superficie.configurar_id_instancia(&"archivo_humo_prueba")
	escenario.zona_actual.get_node("EfectosSuperficie").add_child(superficie)
	_comprobar(tablero.registrar_efecto_superficie(Vector2i(101, 100), superficie), "Registrar la superficie de prueba.")
	var item_suelo := ItemSuelo.new(ItemInstancia.new(&"archivo_piedra_suelo", entrada.definicion, 1))
	_comprobar(tablero.registrar_item_suelo(Vector2i(101, 100), item_suelo), "Registrar el item de suelo de prueba.")
	palanca.activada = true
	puerta.abierta = true
	cofre.abierto = true
	var item_retirado := cofre.inventario.obtener_contenido()[0]
	cofre.inventario.retirar(item_retirado.id_instancia)
	var ids_cofre_guardados: Array[StringName] = []
	for item in cofre.inventario.obtener_contenido():
		ids_cofre_guardados.append(item.id_instancia)
	ficha.pv_actual -= 2
	ficha.aplicar_o_renovar_estado(&"veneno", 1.0, 2, 1)
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = &"identidad"
	fragmento.id_mensaje = &"examen.prueba"
	fragmento.se_recuerda = true
	var fragmentos: Array[FragmentoInformacion] = [fragmento]
	escenario.registro_conocimiento.registrar_descubrimientos(
		ficha.id_observador, palanca.id_instancia, fragmentos
	)
	superficie.call(&"consumir_turno_superficie")
	var turnos_guardados: int = superficie.call(&"obtener_turnos_restantes_superficie")
	_comprobar(escenario.guardar_partida(RUTA) == &"", "La partida completa debe guardarse.")

	palanca.activada = false
	puerta.abierta = false
	cofre.abierto = false
	cofre._cargar_contenido_inicial()
	ficha.pv_actual = ficha.pv_max
	ficha.consumir_tick_estado(&"veneno")
	escenario.registro_conocimiento.restaurar_estado_persistente([])
	superficie.call(&"consumir_turno_superficie")
	_comprobar(escenario.cargar_partida(RUTA) == &"", "La partida completa debe cargarse.")
	var superficie_restaurada: Object = tablero.efectos_superficie_por_id.get(&"archivo_humo_prueba")
	_comprobar(
		palanca.activada and puerta.abierta
		and cofre.abierto
		and cofre.inventario.obtener_por_id(item_retirado.id_instancia) == null
		and cofre.inventario.obtener_contenido().map(
			func(item): return item.id_instancia
		) == ids_cofre_guardados
		and ficha.pv_actual == ficha.pv_max - 2
		and ficha.obtener_estado(&"veneno").ticks_pendientes == 1,
		"Puerta, palanca, ficha y estado activo deben recuperar su estado."
	)
	_comprobar(
		escenario.registro_conocimiento.conoce_fragmento(
			ficha.id_observador, palanca.id_instancia, &"identidad"
		)
		and superficie_restaurada != null and superficie_restaurada.call(&"obtener_turnos_restantes_superficie")
		== turnos_guardados
		and tablero.obtener_item_suelo(&"archivo_piedra_suelo") != null,
		"Conocimiento, items de suelo y duración deben recuperarse."
	)
	var estado_antes: Dictionary = escenario.persistencia_partida.crear_snapshot(tablero, &"zona1", ficha, escenario.registro_conocimiento)
	var corrupto := estado_antes.duplicate(true)
	corrupto["ficha"]["pv_actual"] = ficha.pv_max + 1
	_comprobar(escenario.persistencia_partida.archivos.guardar(RUTA + ".invalida", corrupto) == &"", "Preparar archivo incompatible.")
	_comprobar(escenario.cargar_partida(RUTA + ".invalida") != &"" and escenario.persistencia_partida.crear_snapshot(tablero, &"zona1", ficha, escenario.registro_conocimiento) == estado_antes, "Una carga de archivo incompatible no modifica ninguna parte de la partida.")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA + ".invalida"))
	escenario.queue_free()
	await process_frame
	_finalizar()


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PersistenciaPartidaArchivo: %d comprobaciones correctas; archivo completo y rechazo atómico." % _casos)
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)
