class_name MovimientoPorCasillas
extends RefCounted

## Capacidad por instancia. El actor aporta permisos, costes y presentación;
## los callbacks mantienen el registro del mundo y procesan sus reacciones.
signal paso_dado(coordenada: Vector2i)
signal movimiento_terminado(interrumpido: bool)

var esta_moviendose: bool = false
var interrupcion_solicitada: bool = false
var pasos_completados: int = 0


func solicitar_interrupcion() -> void:
	if esta_moviendose:
		interrupcion_solicitada = true


func mover_por_camino(
	actor: Node2D,
	camino: Array[Vector2i],
	capa: TileMapLayer,
	preparar_paso: Callable,
	confirmar_paso: Callable,
	cancelar_paso: Callable,
	procesar_salida: Callable = Callable(),
	procesar_entrada: Callable = Callable(),
	calcular_coste_paso: Callable = Callable(),
	avanzar_turno: Callable = Callable(),
	en_combate: bool = false,
	recalcular_camino: Callable = Callable(),
	destino_final: Variant = null
) -> bool:
	if (
		(camino.is_empty() and not (destino_final is Vector2i and recalcular_camino.is_valid()))
		or esta_moviendose or not is_instance_valid(actor)
		or not is_instance_valid(capa) or not actor.is_inside_tree()
		or not actor.puede_actuar() or not actor.puede_moverse()
		or not preparar_paso.is_valid() or not confirmar_paso.is_valid()
		or not cancelar_paso.is_valid()
	):
		return false
	esta_moviendose = true
	interrupcion_solicitada = false
	pasos_completados = 0
	var interrumpido := false
	var objetivo: Vector2i = destino_final if destino_final is Vector2i else camino.back()
	var ruta: Array[Vector2i] = camino.duplicate()
	var indice := 0
	while true:
		if not is_instance_valid(actor) or not actor.is_inside_tree():
			interrumpido = true
			break
		var origen: Vector2i = actor.coordenada_mapa
		if origen == objetivo:
			break
		if (
			interrupcion_solicitada or not actor.puede_actuar() or not actor.puede_moverse()
		):
			interrumpido = true
			break
		if recalcular_camino.is_valid() and actor.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) <= 0:
			interrumpido = true
			break
		if indice >= ruta.size():
			if not recalcular_camino.is_valid():
				interrumpido = true
				break
			var nueva_ruta: Variant = recalcular_camino.call(origen, objetivo, actor)
			if not nueva_ruta is Array[Vector2i]:
				interrumpido = true
				break
			ruta = nueva_ruta
			indice = 0
			if ruta.is_empty():
				interrumpido = true
				break
		var destino := ruta[indice]
		if destino == origen:
			indice += 1
			continue
		if absi(destino.x - origen.x) + absi(destino.y - origen.y) != 1:
			interrumpido = true
			break
		var coste := 1
		if calcular_coste_paso.is_valid():
			var calculado: Variant = calcular_coste_paso.call(origen, destino, actor)
			if not calculado is int or calculado < 1:
				interrumpido = true
				break
			coste = calculado
		if not actor.validar_paso_movimiento(coste):
			interrumpido = true
			break
		if actor.validar_coste_turno(RecursosTurnoActor.MOVIMIENTO, coste) != &"":
			if en_combate or not avanzar_turno.is_valid():
				interrumpido = true
				break
			if not await avanzar_turno.call(actor):
				interrumpido = true
				break
			if (
				interrupcion_solicitada or not actor.puede_actuar() or not actor.puede_moverse()
				or actor.validar_coste_turno(RecursosTurnoActor.MOVIMIENTO, coste) != &""
			):
				interrumpido = true
				break
		if not preparar_paso.call(origen, destino, actor):
			if recalcular_camino.is_valid():
				ruta.clear()
				indice = 0
				continue
			interrumpido = true
			break
		actor.orientar_paso_movimiento(origen, destino)
		var liberar_reserva := cancelar_paso.bind(destino, actor)
		actor.tree_exiting.connect(liberar_reserva, CONNECT_ONE_SHOT)
		var tween := actor.create_tween()
		tween.tween_property(actor, "global_position", capa.to_global(capa.map_to_local(destino)), actor.calcular_duracion_paso(coste))
		await tween.finished
		if not is_instance_valid(actor) or not actor.is_inside_tree():
			interrumpido = true
			break
		if actor.tree_exiting.is_connected(liberar_reserva):
			actor.tree_exiting.disconnect(liberar_reserva)
		if procesar_salida.is_valid():
			procesar_salida.call(origen, destino, actor)
		if not confirmar_paso.call(origen, destino, actor):
			cancelar_paso.call(destino, actor)
			actor.global_position = capa.to_global(capa.map_to_local(origen))
			interrumpido = true
			break
		actor.coordenada_mapa = destino
		actor.consumir_paso_movimiento(coste)
		pasos_completados += 1
		indice += 1
		if procesar_entrada.is_valid():
			procesar_entrada.call(origen, destino, actor)
		paso_dado.emit(destino)
		if interrupcion_solicitada or not actor.puede_actuar() or not actor.puede_moverse():
			interrumpido = true
			break
	esta_moviendose = false
	interrupcion_solicitada = false
	movimiento_terminado.emit(interrumpido)
	return not interrumpido
