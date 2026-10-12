extends Node

var _pasos_dados: int = 0


class EscenarioSinRender:
	extends "res://scenes/escenario_base/escenario_base.gd"

	func capturar_textura(_angulo: float, _jugador: String) -> ImageTexture:
		return ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))

	func _inicializar_audio_ambiente() -> void:
		pass


func _ready() -> void:
	call_deferred("_comprobar")


func _comprobar() -> void:
	var escena := load("res://tests/interacciones/escena_npc_hostil.tscn").instantiate() as Node2D
	escena.set("radio_vision_enemigos", 0)
	var escenario := escena.get_node("Escenario")
	escenario.set_script(EscenarioSinRender)
	escenario.set("intervalo_exploracion_npc", 0.3)
	add_child(escena)
	var tablero := escenario.get("tablero") as TableroGrid
	var npc: PersonajeNPC
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		npc = tablero.obtener_interactuable(&"npc_hostil_prueba_001") as PersonajeNPC
		if npc != null:
			break
	if npc == null or not npc.obtener_patrulla().esta_configurada():
		push_error("La ruta guardada no se configuró al cargar la escena.")
		get_tree().quit(1)
		return
	var ficha := escenario.get("ficha_jugador") as Ficha
	var origen_npc := npc.coordenada_mapa
	var origen_jugador := ficha.coordenada_mapa
	var movimiento_jugador := ficha.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
	npc.movimiento.paso_dado.connect(_registrar_paso)
	var movimiento_por_ciclo := npc.obtener_definicion_personaje().calcular_movimiento(npc.obtener_destreza())
	var avanzo := false
	for _intento in range(80):
		await get_tree().create_timer(0.05).timeout
		if npc.coordenada_mapa != origen_npc and _pasos_dados > movimiento_por_ciclo:
			avanzo = true
			break
	if not avanzo or ficha.coordenada_mapa != origen_jugador or ficha.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) != movimiento_jugador:
		push_error("El NPC debe continuar en varios ciclos sin mover al jugador ni consumir su turno.")
		get_tree().quit(1)
		return
	if int(escenario.get("_turnos_exploracion_pendientes")) > 1:
		push_error("Se acumularon avances de exploración atrasados.")
		get_tree().quit(1)
		return
	escenario.set("en_combate", true)
	escenario.call("_cancelar_exploracion_npc")
	await get_tree().create_timer(0.7).timeout
	var posicion_combate := npc.coordenada_mapa
	await get_tree().create_timer(0.7).timeout
	if npc.esta_moviendose or npc.coordenada_mapa != posicion_combate or int(escenario.get("_turnos_exploracion_pendientes")) != 0:
		push_error("El reloj de exploración debe detenerse en combate.")
		get_tree().quit(1)
		return
	escenario.set("en_combate", false)
	avanzo = false
	for _intento in range(80):
		await get_tree().create_timer(0.05).timeout
		if npc.coordenada_mapa != posicion_combate:
			avanzo = true
			break
	if not avanzo:
		push_error("La patrulla debe reanudarse al salir de combate.")
		get_tree().quit(1)
		return
	escenario.set_process(false)
	escenario.call("_cancelar_exploracion_npc")
	await get_tree().create_timer(0.7).timeout
	escena.queue_free()
	await get_tree().process_frame
	print("ExploracionNPCAutonoma: ruta conservada, varios ciclos con jugador quieto, cola limitada y pausa/reanudación por combate correctos.")
	get_tree().quit(0)


func _registrar_paso(_coordenada: Vector2i) -> void:
	_pasos_dados += 1
