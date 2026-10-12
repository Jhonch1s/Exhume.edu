extends "res://tests/interacciones/escena_npc_hostil.gd"

## Reutiliza la escena manual de combate, con tres relaciones distintas y sin rutas.
var _detalle: String = ""


func _ready() -> void:
	cantidad_enemigos = 3
	radio_vision_enemigos = 4
	await super._ready()
	_ruta_guardado = "user://prueba_actitud_npc.json"
	_mostrar_estado("F6 reinicia; el slot normal de partida no se modifica.")


func _crear_enemigo(
	zona: Node2D, capa_suelo: TileMapLayer, tablero: TableroGrid,
	coordenada: Vector2i, numero: int
) -> bool:
	if not super._crear_enemigo(zona, capa_suelo, tablero, coordenada, numero):
		return false
	var npc: PersonajeNPC = _enemigos.back()
	var perfil := npc.obtener_definicion_personaje()
	perfil.id_definicion = StringName("actitud_prueba_%d" % numero)
	perfil.vida_maxima = 15
	perfil.fuerza = 1
	perfil.destreza = 1
	perfil.movimiento_fijo = -1
	perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.NEUTRAL
	perfil.actitud_hacia_jugador_fija = numero != 1
	perfil.puede_combatir = numero != 3
	perfil.puede_dialogar = true
	perfil.ilustracion_dialogo = DEFINICION_TROMPO.ilustracion_dialogo
	var tema := DialogoNPC.new()
	tema.id_dialogo = &"actitud"
	tema.titulo = "Relación"
	tema.recurso = preload("res://dialogues/personajes/prueba_actitud.dialogue")
	perfil.dialogos = [tema]
	npc.nombre_unico = ["Neutral dinámico", "Neutral fijo combatiente", "Trompo (excepción)"][numero - 1]
	if numero == 3:
		var trompo := DEFINICION_TROMPO.duplicate(true) as DefinicionPersonaje
		trompo.dialogos = [tema]
		npc.definicion = trompo
	npc.estado_personaje = null
	npc.sprite_personaje.modulate = Color(0.6, 0.9, 1.0) if numero == 1 else Color.WHITE
	return true


func _process(_delta: float) -> void:
	_mostrar_estado(_detalle)


func _mostrar_estado(detalle: String) -> void:
	_detalle = detalle
	if _estado == null:
		return
	var texto := "ACTITUD NPC | Clic izquierdo: acciones | Clic derecho: mover\n"
	texto += "Hablar: +1/-1 | Atacar: -2 incluso fallado/esquivado | K: guardar | C: cargar\n"
	texto += "Hostil <= -3 | Amistoso >= +3 | Escapa de visión 4 para cerrar defensa\n"
	for npc in _enemigos:
		var actitud: String = ["neutral", "amistosa", "hostil"][npc.obtener_actitud_hacia_jugador()]
		texto += "%s: %d puntos, %s, %d PV%s\n" % [
			npc.nombre_unico, npc.obtener_puntos_actitud(), actitud, npc.vida_actual,
			", oposición en encuentro" if npc.en_oposicion_encuentro else ""
		]
	_estado.text = texto + detalle
