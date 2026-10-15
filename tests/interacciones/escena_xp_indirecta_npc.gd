extends "res://tests/interacciones/escena_facciones_npc.gd"

@export_range(1, 4, 1) var objetivo_prueba: int = 1
@export var agro_automatico: bool = true


func _ready() -> void:
	vida_combatientes = 1
	inicio_hostil = agro_automatico
	await super._ready()
	_ruta_guardado = "user://prueba_xp_indirecta_npc.json"
	_mostrar_estado("XP indirecta: agro automático configurable en Inspector. 1 veneno, 2 quemado, 3 explosión, 4 daño sin autor. F6 reinicia.")


func _crear_enemigo(zona: Node2D, suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	if not super._crear_enemigo(zona, suelo, tablero, coordenada, numero):
		return false
	if numero == 2 and agro_automatico:
		var npc: PersonajeNPC = _enemigos.back()
		npc.obtener_definicion_personaje().actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.HOSTIL
		npc.estado_personaje = null
	return true


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode not in [KEY_B, KEY_1, KEY_2, KEY_3, KEY_4]:
		super._input(event)
		return
	if _escenario == null or _enemigos.size() < objetivo_prueba or _escenario.interaccion_modal_activa or _escenario._hay_actor_moviendose():
		return
	var npc := _enemigos[objetivo_prueba - 1]
	if npc.esta_muerto():
		_mostrar_estado("El objetivo ya es cadáver: no vuelve a conceder XP. C carga; F6 reinicia.")
		return
	match event.keycode:
		KEY_B:
			_escenario._iniciar_combate(npc)
		KEY_1, KEY_2:
			npc.aplicar_o_renovar_estado(&"veneno" if event.keycode == KEY_1 else &"quemado", 1, 1, 1)
		KEY_3:
			for solicitud in Explosion.crear_solicitudes(_escenario.tablero, npc.coordenada_mapa, 0, 1, &"xp_manual_explosion"):
				_escenario.servicio_turnos.aplicador_efectos.aplicar(solicitud)
		KEY_4:
			npc.recibir_danio(1)
	_mostrar_estado("Prueba aplicada a %s. Veneno/quemado se resuelven al finalizar su turno." % npc.nombre_unico)
	get_viewport().set_input_as_handled()


func _mostrar_estado(detalle: String) -> void:
	super._mostrar_estado(detalle)
	if _estado != null:
		_estado.text += "\nXP INDIRECTA | Agro automático: %s | Objetivo %d | B: encuentro | 1: veneno | 2: quemado | 3: explosión | 4: daño sin autor" % ["sí" if agro_automatico else "no", objetivo_prueba]
