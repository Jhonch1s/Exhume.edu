extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escena: Node = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	var escenario = escena.get_node("Escenario")
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(escena)
	for intento in 200:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 5:
			break
	escena.set_process(false)
	escenario.set_process(false)
	if escena.get("_enemigos").is_empty():
		comprobar(false, "El fixture creó los enemigos.")
		finalizar()
		return
	var npc: PersonajeNPC = escena.get("_enemigos")[0]
	var ficha: Ficha = escenario.ficha_jugador
	comprobar(ficha != null and npc != null, "Preparar el encuentro.")
	if ficha == null or npc == null:
		finalizar()
		return
	# El fixture usa suelo propio para asegurar un objetivo adyacente.
	var origen := Vector2i(99, 100)
	var destino := Vector2i(100, 100)
	for x in range(98, 103):
		for y in range(98, 103):
			escenario.tablero.datos[Vector2i(x, y)] = Celda.new(
				&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE
			)
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(origen, escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(origen, ficha)
	comprobar(escenario.tablero.reubicar_interactuable(npc, destino), "Acercar objetivo.")
	npc.actualizar_posicion_visual()
	comprobar(escenario._iniciar_combate(npc, false), "Iniciar combate.")
	var rondas: Dictionary = escenario.gestor_rondas.obtener_estado_persistente()
	rondas["actor_activo_id"] = String(ficha.obtener_id_actor())
	comprobar(escenario.gestor_rondas.restaurar_estado_persistente(rondas) == &"", "Dar turno al Guerrero.")
	ficha.iniciar_turno()
	escenario._actualizar_disponibilidad_turno()
	comprobar(not escenario.hud.habilidades[0].disabled and escenario.hud.habilidades[0].text.contains("1/1"), "HUD ofrece Ataque doble 1/1.")
	comprobar(is_equal_approx(ResolverAtaqueBasico.probabilidad_de_dano(5, 4), 10.0 / 36.0), "La probabilidad incluye ataque y esquiva.")
	comprobar(is_equal_approx(ResolverAtaqueBasico.probabilidad_de_dano(1, 5), 1.0 / 36.0), "Los extremos del d6 respetan crítico y pifia.")
	escenario._actualizar_hover_interaccion(destino, null)
	var indicador: PanelContainer = root.get_node("CursorJuego/CapaIndicadorCombate/ProbabilidadAtaqueBasico")
	comprobar(
		(indicador.get_parent() as CanvasLayer).layer < (escenario.get_node("FiltroCRT") as CanvasLayer).layer,
		"El porcentaje queda bajo la capa del filtro CRT."
	)
	var porcentaje := roundi(100.0 * ResolverAtaqueBasico.probabilidad_de_dano(ficha.fue, npc.obtener_destreza()))
	comprobar(indicador.visible and (indicador.get_child(0) as Label).text.contains("%d%%" % porcentaje), "Hover sobre oponente muestra la probabilidad al puntero.")
	escenario._limpiar_hover_interaccion()
	comprobar(not indicador.visible, "El indicador se oculta al salir del enemigo.")
	var prueba: Node = load("res://tests/interacciones/prueba_actitud_npc.gd").new()
	npc.motor_dados = MotorDados.new(prueba._rng_para([6, 6]))
	prueba.free()
	var principal := ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL)
	var lejos := npc.coordenada_mapa
	npc.coordenada_mapa = Vector2i(101, 100)
	var invalido: Array[ResultadoAccion] = escenario.ejecutar_ataque_doble(npc)
	comprobar(invalido.size() == 1 and invalido[0].tirada == null and ficha.usos_ataque_doble == 1 and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == principal, "Objetivo lejano no consume acción ni uso.")
	npc.coordenada_mapa = lejos
	escenario._on_ataque_doble_hud()
	comprobar(escenario.seleccionando_ataque_doble, "El botón activa la selección.")
	escenario._on_ataque_doble_hud()
	comprobar(not escenario.seleccionando_ataque_doble and ficha.usos_ataque_doble == 1, "Cancelar selección no consume el uso.")
	var golpes: Array[ResultadoAccion] = escenario.ejecutar_ataque_doble(npc)
	comprobar(golpes.size() == 2 and golpes[0].tirada != null and golpes[1].tirada != null, "Se realizan dos tiradas consecutivas.")
	comprobar(ficha.usos_ataque_doble == 0 and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == principal - 1, "Dos golpes gastan una acción y un uso.")
	escenario.objetivos_hover.clear()
	escenario.objetivos_hover.append(npc)
	escenario._actualizar_probabilidad_ataque_basico()
	comprobar(indicador.visible and (indicador.get_child(0) as Label).text.contains("0%") and (indicador.get_child(0) as Label).text.contains("Sin acción principal"), "Sin acción principal el ataque básico marca 0% y explica el bloqueo.")
	escenario._limpiar_hover_interaccion()
	comprobar(escenario.hud.habilidades[0].text.contains("0/1") and escenario.hud.habilidades[0].disabled, "HUD muestra uso agotado.")
	var repetido: Array[ResultadoAccion] = escenario.ejecutar_ataque_doble(npc)
	comprobar(repetido.size() == 1 and repetido[0].tirada == null, "No se repite antes de descansar.")
	var estado := ficha.obtener_estado_persistente()
	comprobar(estado["usos_ataque_doble"] == 0, "El guardado incluye el uso agotado.")
	ficha.usos_ataque_doble = 1
	comprobar(ficha.restaurar_estado_persistente(estado) == &"" and ficha.usos_ataque_doble == 0, "La carga restaura el uso agotado.")
	var viejo := estado.duplicate(true)
	viejo.erase("usos_ataque_doble")
	comprobar(ficha.restaurar_estado_persistente(viejo) == &"" and ficha.usos_ataque_doble == 1, "Los guardados anteriores arrancan en 1/1.")
	var corrupto := estado.duplicate(true)
	corrupto["usos_ataque_doble"] = 2
	comprobar(ficha.validar_estado_persistente(corrupto) != &"", "Se rechaza un contador inválido.")
	ficha.usos_ataque_doble = 0
	var raciones := ficha.raciones
	comprobar(ficha.descansar_en_campamento() == &"" and ficha.raciones == raciones - 1 and ficha.usos_ataque_doble == 1, "Una ración recupera Ataque doble.")
	ficha.iniciar_turno()
	npc.recibir_danio(npc.vida_actual - 1)
	prueba = load("res://tests/interacciones/prueba_actitud_npc.gd").new()
	npc.motor_dados = MotorDados.new(prueba._rng_para([1, 6]))
	prueba.free()
	escenario._actualizar_disponibilidad_turno()
	escenario._on_ataque_doble_hud()
	var tiradas_antes: int = escenario.historial_tiradas.obtener_entradas().size()
	escenario._seleccionar_objetivo_ataque_doble(destino, null)
	comprobar(npc.esta_derrotado() and ficha.usos_ataque_doble == 0 and not escenario.seleccionando_ataque_doble, "Seleccionar objetivo desde el botón resuelve el golpe letal.")
	comprobar(escenario.historial_tiradas.obtener_entradas().size() == tiradas_antes + 2, "Si el primer golpe mata, solo se registran ataque y defensa.")
	escena.queue_free()
	await process_frame
	finalizar()


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)


func finalizar() -> void:
	for fallo in fallos:
		push_error(fallo)
	print("Ataque doble: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)
