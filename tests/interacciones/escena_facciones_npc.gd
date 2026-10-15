extends "res://tests/interacciones/escena_npc_hostil.gd"

## Dos modos manuales: agresión al neutral o amenaza hostil contra el jugador.
@export var inicio_hostil: bool = false
@export_range(1, 15, 1) var vida_combatientes: int = 15
var _detalle := ""


func _ready() -> void:
	cantidad_enemigos = 5
	radio_vision_enemigos = 0
	await super._ready()
	_ruta_guardado = "user://prueba_facciones_npc_hostil.json" if inicio_hostil else "user://prueba_facciones_npc_neutral.json"
	_mostrar_estado("F6 reinicia. El slot normal no se modifica.")


func _crear_enemigo(zona: Node2D, suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	if numero == 4:
		var candidatas: Array[Vector2i] = []
		candidatas.assign(tablero.datos.keys())
		candidatas.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
		var encontrada := false
		for candidata in candidatas:
			var distancia := Vector2(candidata - _enemigos[0].coordenada_mapa).length_squared()
			if distancia >= 144 and distancia <= 225 and tablero.puede_entrar(candidata) and tablero.obtener_celda(candidata).interactuables.is_empty():
				coordenada = candidata
				encontrada = true
				break
		if not encontrada:
			return false
	if not super._crear_enemigo(zona, suelo, tablero, coordenada, numero):
		return false
	var npc: PersonajeNPC = _enemigos.back()
	var perfil: DefinicionPersonaje = npc.obtener_definicion_personaje()
	perfil.id_definicion = StringName("facciones_prueba_%d" % numero)
	perfil.vida_maxima = vida_combatientes
	perfil.fuerza = 1
	perfil.destreza = 1
	perfil.movimiento_fijo = -1
	perfil.radio_agro = 7
	perfil.experiencia_recompensa_derrota = 50
	perfil.faccion_id = &"guardia_prueba" if numero in [1, 2, 4] else &""
	perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.AMISTOSA if numero == 3 else DefinicionPersonaje.ActitudInicialJugador.NEUTRAL
	if numero == 1 and inicio_hostil:
		perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.HOSTIL
	perfil.actitud_hacia_jugador_fija = numero == 2
	if numero == 5:
		npc.definicion = DEFINICION_TROMPO.duplicate(true)
	npc.nombre_unico = ["Guardia", "Compañero fijo", "Amistoso", "Compañero lejano", "Trompo (excepción)"][numero - 1]
	npc.estado_personaje = null
	npc.sprite_personaje.modulate = [Color(1, 0.8, 0.4), Color(1, 0.8, 0.4), Color(0.5, 0.9, 1), Color(1, 0.8, 0.4), Color.WHITE][numero - 1]
	return true


func _process(_delta: float) -> void:
	_mostrar_estado(_detalle)


func _mostrar_estado(detalle: String) -> void:
	_detalle = detalle
	if _estado == null:
		return
	var texto := "FACCIONES | Inicio %s | Clic izquierdo: acciones | Clic derecho: mover\n" % ("hostil" if inicio_hostil else "neutral")
	texto += "Guardia + compañero fijo + lejano: misma facción | Amistoso: sin facción\n"
	texto += "V: campos de visión visibles | K: guardar | C: cargar en reposo\n"
	texto += "Ajustar inicio_hostil/vida_combatientes en Inspector y reiniciar F6\n"
	if _escenario != null and _escenario.ficha_jugador != null:
		texto += "Jugador: %d XP acumulada (50 XP por combatiente derrotado)\n" % _escenario.ficha_jugador.experiencia_acumulada
	for npc in _enemigos:
		texto += "%s: %s, puntos %d, %d PV, %s, celda %s\n" % [
			npc.nombre_unico, npc.obtener_definicion_personaje().faccion_id,
			npc.obtener_puntos_actitud(), npc.vida_actual,
			["fuera", "aliado", "oponente"][npc.bando_encuentro], npc.coordenada_mapa,
		]
	_estado.text = texto + detalle
