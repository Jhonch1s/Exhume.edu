extends SceneTree

const RUTA := "user://prueba_persistencia_fase12.json"

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escenario := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	root.add_child(escenario)
	var ficha: Ficha = escenario.ficha_jugador
	var palanca := escenario.tablero.obtener_interactuable(
		&"zona1_palanca_03_m03"
	) as PalancaInteractuable
	var puerta := escenario.tablero.obtener_interactuable(
		&"zona1_puerta_mecanismo_05_m03"
	) as PuertaInteractuable
	palanca.activada = true
	puerta.abierta = true
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
	var superficie: Object = escenario.tablero.efectos_superficie_por_id.values()[0]
	superficie.call(&"consumir_turno_superficie")
	var turnos_guardados: int = superficie.call(&"obtener_turnos_restantes_superficie")
	_comprobar(escenario.guardar_partida(RUTA) == &"", "La partida completa debe guardarse.")

	palanca.activada = false
	puerta.abierta = false
	ficha.pv_actual = ficha.pv_max
	ficha.consumir_tick_estado(&"veneno")
	escenario.registro_conocimiento.restaurar_estado_persistente([])
	superficie.call(&"consumir_turno_superficie")
	_comprobar(escenario.cargar_partida(RUTA) == &"", "La partida completa debe cargarse.")
	var superficie_restaurada: Object = escenario.tablero.efectos_superficie_por_id.values()[0]
	_comprobar(
		palanca.activada and puerta.abierta
		and ficha.pv_actual == ficha.pv_max - 2
		and ficha.obtener_estado(&"veneno").ticks_pendientes == 1,
		"Puerta, palanca, ficha y estado activo deben recuperar su estado."
	)
	_comprobar(
		escenario.registro_conocimiento.conoce_fragmento(
			ficha.id_observador, palanca.id_instancia, &"identidad"
		)
		and superficie_restaurada.call(&"obtener_turnos_restantes_superficie")
		== turnos_guardados
		and not escenario.tablero.items_suelo_por_id.is_empty(),
		"Conocimiento, items de suelo y duración deben recuperarse."
	)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	escenario.queue_free()
	await process_frame
	_finalizar()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PersistenciaPartidaArchivo: 4 grupos correctos.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)
