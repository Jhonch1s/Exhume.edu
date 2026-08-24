extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene
	var escenario := escena.instantiate()
	root.add_child(escenario)
	await process_frame

	var palanca := escenario.tablero.obtener_interactuable(
		&"zona1_palanca_03_m03"
	) as PalancaInteractuable
	_comprobar(palanca != null, "La palanca real de Zona 1 debe estar registrada.")
	if palanca != null:
		var ficha: Ficha = escenario.ficha_jugador
		ficha.coordenada_mapa = palanca.coordenada_mapa
		escenario.tablero.obtener_celda(palanca.coordenada_mapa).visibilidad = (
			Celda.EstadoVisibilidad.VISIBLE
		)
		var generador := RandomNumberGenerator.new()
		generador.seed = _buscar_semilla_exitosa(ficha.obtener_destreza())
		palanca.motor_dados = MotorDados.new(generador)
		escenario.estado_seleccion_objetivos.iniciar(
			palanca.coordenada_mapa, [palanca]
		)
		var opcion := _obtener_opcion_examinar(palanca, ficha)
		escenario._ejecutar_opcion_contextual(opcion)
		var resultado: ResultadoAccion = escenario.ultimo_resultado_contextual
		_comprobar(
			resultado.exitosa
			and resultado.tirada is ResultadoPrueba
			and resultado.tirada.exitosa
			and &"examen.palanca.basico" in resultado.mensajes
			and &"examen.palanca.muesca_secundaria" in resultado.mensajes,
			"Examinar la palanca debe tirar Destreza y revelar el detalle al tener éxito."
		)
		_comprobar(
			escenario.registro_conocimiento.conoce_fragmento(
				ficha.id_observador, palanca.id_instancia, &"muesca_secundaria"
			)
			and escenario.historial_tiradas.obtener_entradas().size() == 1,
			"La consecuencia debe registrarse como conocimiento y la tirada en el historial."
		)
		_comprobar(
			escenario.panel_resultado_accion.visible
			and escenario.interaccion_modal_activa
			and "Modo: Normal" in escenario.panel_resultado_accion.etiqueta_mensajes.text
			and "muesca secundaria" in escenario.panel_resultado_accion.etiqueta_mensajes.text,
			"La vertical debe presentar dados y consecuencia narrativa en el panel modal."
		)
		escenario.panel_resultado_accion.ocultar()
		var estado_antes_repetir := generador.state
		escenario.estado_seleccion_objetivos.iniciar(
			palanca.coordenada_mapa, [palanca]
		)
		escenario._ejecutar_opcion_contextual(opcion)
		_comprobar(
			escenario.ultimo_resultado_contextual.tirada == null
			and &"examen.palanca.muesca_secundaria"
			in escenario.ultimo_resultado_contextual.mensajes
			and generador.state == estado_antes_repetir
			and escenario.historial_tiradas.obtener_entradas().size() == 1,
			"El conocimiento recordado debe mostrar el detalle sin volver a tirar."
		)
		escenario.panel_resultado_accion.ocultar()

	escenario.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("VerticalTiradaExploracion: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _obtener_opcion_examinar(
	palanca: PalancaInteractuable,
	ficha: Ficha
) -> OpcionAccion:
	for opcion in palanca.obtener_opciones_accion(ficha):
		if opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
			return opcion
	return null


func _buscar_semilla_exitosa(atributo: int) -> int:
	for semilla in 1000:
		var generador := RandomNumberGenerator.new()
		generador.seed = semilla
		var resultado := MotorDados.new(generador).resolver_prueba(atributo)
		if resultado.exitosa and resultado.clasificacion == ResultadoPrueba.Clasificacion.NORMAL:
			return semilla
	return -1


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
