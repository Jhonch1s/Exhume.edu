class_name DecisorCombateNPC
extends BTPlayer

## LimboAI selecciona una intención. El escenario ejecuta y vuelve a consultar.
const ARBOL := preload("res://recursos/ia/combate_npc.tres")


func _init() -> void:
	behavior_tree = ARBOL
	update_mode = BTPlayer.MANUAL


func elegir(
	npc: PersonajeNPC, objetivo: Ficha, tablero: TableroGrid,
	buscador: PathFindingManager, objetivo_visible: bool,
	perseguir_recuerdo: bool = false
) -> Dictionary:
	var recuerdo: Variant = npc.obtener_ultima_posicion_conocida()
	var objetivo_conocido := objetivo_visible or (perseguir_recuerdo and recuerdo != null)
	var posicion_objetivo: Variant = objetivo.coordenada_mapa if objetivo_visible else recuerdo
	var adyacente := false
	if objetivo_conocido:
		var distancia: Vector2i = npc.coordenada_mapa - posicion_objetivo
		adyacente = absi(distancia.x) + absi(distancia.y) == 1
	var camino: Array[Vector2i] = []
	var enredado := npc.obtener_estado(&"enredado") != null
	var caido := npc.obtener_estado(&"caido") != null
	if objetivo_conocido and not adyacente and npc.puede_moverse() and npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) > 0:
		camino = _camino_acercamiento(npc, posicion_objetivo, tablero, buscador)
	var busqueda_terminada := false
	var regresando := false
	var destino: Variant = null
	var patrulla := npc.obtener_patrulla()
	var patrullando := (
		not perseguir_recuerdo and not objetivo_conocido and recuerdo == null
		and patrulla != null and patrulla.esta_configurada()
	)
	var esperando_patrulla := patrullando and patrulla.esta_esperando()
	if not objetivo_conocido and not enredado and not caido:
		destino = recuerdo if recuerdo != null else (
			patrulla.obtener_destino() if patrullando else npc.obtener_coordenada_origen()
		)
		regresando = recuerdo == null
		if recuerdo != null and recuerdo == npc.coordenada_mapa:
			busqueda_terminada = true
		elif destino != null and destino != npc.coordenada_mapa and not esperando_patrulla:
			var ruta := buscador.calcular_camino(npc.coordenada_mapa, destino, tablero.datos, npc)
			camino = buscador.limitar_camino_por_movimiento(
				ruta, tablero.datos, npc, npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
			)
			if patrullando and camino.is_empty():
				var celda_destino := tablero.obtener_celda(destino)
				if celda_destino != null:
					for ocupante in celda_destino.interactuables:
						var otro := ocupante as PersonajeNPC
						if otro == null or not otro.puede_moverse() or otro.esta_moviendose:
							continue
						var otra_patrulla := otro.obtener_patrulla()
						if otra_patrulla == null or otra_patrulla.obtener_destino() != npc.coordenada_mapa:
							continue
						# Sólo uno cede; el punto de patrulla sigue pendiente.
						if String(npc.id_instancia) < String(otro.id_instancia):
							camino = _camino_acercamiento(npc, npc.coordenada_mapa, tablero, buscador)
							if camino.size() > 1:
								destino = camino.back()
						break
	# La rama de liberación se elige aunque no quede acción: el ejecutor pasa.
	blackboard.set_var(&"esta_enredado", enredado and not caido)
	blackboard.set_var(&"puede_atacar", objetivo_visible and not enredado and not caido and adyacente and npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) > 0)
	blackboard.set_var(&"puede_acercarse", objetivo_conocido and camino.size() > 1)
	var puede_recorrer: bool = (
		not objetivo_conocido and not enredado and not caido
		and destino != null and destino != npc.coordenada_mapa
		and npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) > 0
	)
	blackboard.set_var(&"puede_buscar", puede_recorrer and not regresando and not patrullando)
	blackboard.set_var(&"puede_regresar", puede_recorrer and regresando and not patrullando)
	blackboard.set_var(&"esperando_patrulla", esperando_patrulla and not enredado and not caido)
	blackboard.set_var(&"punto_patrulla_alcanzado", patrullando and not esperando_patrulla and not enredado and not caido and destino == npc.coordenada_mapa)
	blackboard.set_var(&"puede_patrullar", puede_recorrer and patrullando and not esperando_patrulla)
	blackboard.set_var(&"busqueda_terminada", busqueda_terminada)
	blackboard.set_var(&"decision", &"")
	blackboard.set_var(&"traza", [])
	restart()
	update(0.0)
	return {
		"decision": blackboard.get_var(&"decision", &"terminar_turno"),
		"camino": camino, "objetivo_visible": objetivo_visible, "destino": destino,
	}


func _camino_acercamiento(
	npc: PersonajeNPC, objetivo: Vector2i, tablero: TableroGrid,
	buscador: PathFindingManager
) -> Array[Vector2i]:
	var mejor: Array[Vector2i] = []
	var mejor_peso := INF
	# Orden estable: los empates no cambian entre evaluaciones o cargas.
	for direccion in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var destino: Vector2i = objetivo + direccion
		var camino := buscador.calcular_camino(npc.coordenada_mapa, destino, tablero.datos, npc)
		if camino.size() < 2:
			continue
		var peso := 0.0
		for indice in range(1, camino.size()):
			peso += tablero.obtener_celda(camino[indice]).calcular_peso_ruta(npc)
		if peso < mejor_peso:
			mejor = camino
			mejor_peso = peso
	return buscador.limitar_camino_por_movimiento(
		mejor, tablero.datos, npc,
		npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
	)
