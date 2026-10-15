extends "res://tests/interacciones/escena_npc_hostil.gd"


func _ready() -> void:
	cantidad_enemigos = 1
	radio_vision_enemigos = 0
	await super._ready()
	_ruta_guardado = "user://prueba_dialogo_tirada_npc.json"
	_mostrar_estado("DIÁLOGO CON TIRADA | Hablar → Intentar convencerlo [VOL].\nHaz clic en el dado, cierra el panel y continúa la respuesta.\nK/C fuera de modales | F6 reinicia | Sin premios ni cambios de relación.")


func _crear_enemigo(zona: Node2D, suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	if not super._crear_enemigo(zona, suelo, tablero, coordenada, numero):
		return false
	var npc: PersonajeNPC = _enemigos.back()
	var perfil := npc.obtener_definicion_personaje()
	perfil.id_definicion = &"custodio_prueba_tirada"
	perfil.puede_combatir = false
	perfil.puede_dialogar = true
	perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.NEUTRAL
	perfil.ilustracion_dialogo = DEFINICION_TROMPO.ilustracion_dialogo
	var tema := DialogoNPC.new()
	tema.id_dialogo = &"tirada"
	tema.titulo = "Convencer al custodio"
	tema.recurso = preload("res://dialogues/personajes/prueba_tirada.dialogue")
	perfil.dialogos = [tema]
	npc.nombre_unico = "Custodio de prueba"
	npc.estado_personaje = null
	return true
