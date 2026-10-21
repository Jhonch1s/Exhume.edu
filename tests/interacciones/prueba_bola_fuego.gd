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
	var ficha: Ficha = escenario.ficha_jugador
	var npc: PersonajeNPC = escena.get("_enemigos")[0]
	ficha.clase = "Mago"
	escenario.hud.actualizar_desde_ficha()
	var origen := Vector2i(99, 100)
	var destino := Vector2i(103, 100)
	for x in range(98, 106):
		for y in range(98, 103):
			escenario.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(origen, escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(origen, ficha)
	comprobar(escenario.tablero.reubicar_interactuable(npc, destino), "Colocar enemigo a cuatro casillas.")
	npc.actualizar_posicion_visual()
	comprobar(escenario._iniciar_combate(npc, false), "Iniciar combate.")
	var rondas: Dictionary = escenario.gestor_rondas.obtener_estado_persistente()
	rondas["actor_activo_id"] = String(ficha.obtener_id_actor())
	comprobar(escenario.gestor_rondas.restaurar_estado_persistente(rondas) == &"", "Dar turno al Mago.")
	ficha.iniciar_turno()
	escenario._actualizar_disponibilidad_turno()
	comprobar(not escenario.hud.habilidades[0].disabled and escenario.hud.habilidades[0].text.contains("1/1"), "HUD ofrece Bola de fuego.")
	comprobar(escenario.hud.habilidades[0].tooltip_text.contains("50%"), "HUD explica la probabilidad de Quemado.")
	var principal := ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL)
	npc.coordenada_mapa = Vector2i(104, 100)
	var invalido: ResultadoAccion = escenario.ejecutar_bola_fuego(npc)
	comprobar(not invalido.exitosa and ficha.usos_bola_fuego == 1 and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == principal, "Fuera de alcance no consume recursos.")
	npc.coordenada_mapa = destino
	var celda_objetivo: Celda = escenario.tablero.obtener_celda(destino)
	celda_objetivo.visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	comprobar(escenario.ejecutar_bola_fuego(npc).motivo == &"objetivo_no_visible" and ficha.usos_bola_fuego == 1, "No puede lanzar a un enemigo fuera de la visión actual.")
	celda_objetivo.visibilidad = Celda.EstadoVisibilidad.VISIBLE
	escenario._on_bola_fuego_hud()
	comprobar(escenario.seleccionando_bola_fuego, "El botón permite seleccionar objetivo.")
	escenario._on_bola_fuego_hud()
	comprobar(not escenario.seleccionando_bola_fuego and ficha.usos_bola_fuego == 1, "Cancelar no consume el uso.")
	var vida := npc.vida_actual
	var semilla := 1
	while semilla < 100:
		seed(semilla)
		if randf() < 0.5:
			break
		semilla += 1
	seed(semilla)
	var acierto: ResultadoAccion = escenario.ejecutar_bola_fuego(npc)
	comprobar(acierto.exitosa and npc.vida_actual == vida - 1, "Impacta con un daño inicial de fuego.")
	comprobar(npc.obtener_estado(&"quemado") != null and npc.obtener_estado(&"quemado").ticks_pendientes == 3, "La probabilidad favorable aplica Quemado estándar.")
	comprobar(npc.sprite_personaje.material == npc.material_quemado and is_instance_valid(npc.particulas_quemado), "Quemado tiñe al enemigo y muestra las mismas llamas que al jugador.")
	comprobar(npc.reproductor_audio.stream == npc.SONIDO_QUEMADURA, "Quemado reproduce el sonido del jugador al aplicarse.")
	comprobar(ficha.usos_bola_fuego == 0 and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == principal - 1, "Gasta una acción principal y un uso.")
	comprobar(not escenario.ejecutar_bola_fuego(npc).exitosa, "No se repite antes de descansar.")
	var estado_npc_quemado := npc.obtener_estado_persistente()
	npc.retirar_estado(&"quemado")
	comprobar(npc.sprite_personaje.material == null and npc.particulas_quemado == null, "Al retirarse Quemado desaparecen tinte y llamas.")
	comprobar(npc.restaurar_estado_persistente(estado_npc_quemado) == &"" and npc.sprite_personaje.material == npc.material_quemado and is_instance_valid(npc.particulas_quemado), "Cargar un enemigo quemado recupera el efecto visual.")
	npc.reproductor_audio.stream = null
	npc.consumir_tick_estado(&"quemado")
	comprobar(npc.obtener_estado(&"quemado") != null and is_instance_valid(npc.particulas_quemado) and npc.reproductor_audio.stream == npc.SONIDO_QUEMADURA, "Un pulso de Quemado mantiene las llamas y repite el sonido.")
	npc.retirar_estado(&"quemado")
	ficha.usos_bola_fuego = 1
	ficha.iniciar_turno()
	semilla = 1
	while semilla < 100:
		seed(semilla)
		if randf() >= 0.5:
			break
		semilla += 1
	seed(semilla)
	vida = npc.vida_actual
	escenario._on_bola_fuego_hud()
	escenario._seleccionar_objetivo_bola_fuego(destino, null)
	comprobar(npc.vida_actual == vida - 1 and npc.obtener_estado(&"quemado") == null, "El otro resultado de la probabilidad causa daño sin Quemado.")
	comprobar(npc.sprite_personaje.material == null and npc.particulas_quemado == null, "Si no aplica Quemado no aparecen llamas.")
	comprobar(not escenario.seleccionando_bola_fuego and ficha.usos_bola_fuego == 0, "Seleccionar el enemigo desde el mapa ejecuta la habilidad.")
	var estado := ficha.obtener_estado_persistente()
	comprobar(estado["usos_bola_fuego"] == 0, "El uso agotado se guarda.")
	ficha.usos_bola_fuego = 1
	comprobar(ficha.restaurar_estado_persistente(estado) == &"" and ficha.usos_bola_fuego == 0, "La carga restaura el uso.")
	var viejo := estado.duplicate(true)
	viejo.erase("usos_bola_fuego")
	comprobar(ficha.restaurar_estado_persistente(viejo) == &"" and ficha.usos_bola_fuego == 1, "Guardados antiguos inician con uso.")
	var corrupto := estado.duplicate(true)
	corrupto["usos_bola_fuego"] = 2
	comprobar(ficha.validar_estado_persistente(corrupto) != &"", "Se rechaza un contador inválido.")
	ficha.usos_bola_fuego = 0
	comprobar(ficha.descansar_en_campamento() == &"" and ficha.usos_bola_fuego == 1, "Descansar recupera Bola de fuego.")
	npc.aplicar_o_renovar_estado(&"quemado", 1.0, 2, 2)
	npc.recibir_danio(npc.vida_actual)
	comprobar(npc.esta_muerto() and npc.sprite_personaje.material == null and npc.particulas_quemado == null, "El cadáver deja de mostrar llamas.")
	escena.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Bola de fuego: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
