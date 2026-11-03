class_name GestorTriggersMapa
extends RefCounted

signal trigger_activado(id_trigger: StringName)
signal accion_fallida(id_trigger: StringName, motivo: StringName)

var _triggers: Array[TriggerMapa] = []
var _pendientes: Array[TriggerMapa] = []
var _capa: TileMapLayer
var _id_zona: StringName
var _globo_activo: Node
var _ejecutando := false


func configurar(zona: Node, tablero: TableroGrid, id_zona: StringName) -> PackedStringArray:
	limpiar()
	_triggers.clear()
	_id_zona = id_zona
	_capa = zona.get_node_or_null(^"CapaSuelo") as TileMapLayer
	var errores := PackedStringArray()
	for nodo in zona.find_children("*", "TriggerMapa", true, false):
		var trigger := nodo as TriggerMapa
		var motivos := trigger.validar_configuracion(_capa, tablero)
		if motivos.is_empty():
			_triggers.append(trigger)
		else:
			for motivo in motivos:
				errores.append("%s: %s" % [trigger.name, motivo])
	_triggers.sort_custom(func(a: TriggerMapa, b: TriggerMapa): return String(a.id_trigger) < String(b.id_trigger))
	return errores


func registrar_paso(origen: Vector2i, destino: Vector2i, actor: Node2D) -> bool:
	if not actor is Ficha or actor.id_actor != &"jugador_principal" or not actor.puede_actuar():
		return false
	var agregado := false
	for trigger in _triggers:
		if not is_instance_valid(trigger) or not trigger.habilitado or _pendientes.has(trigger):
			continue
		if _consumido(trigger) or not trigger.detecta_paso(origen, destino, trigger.obtener_coordenada(_capa)):
			continue
		_pendientes.append(trigger)
		agregado = true
	if agregado:
		actor.solicitar_interrupcion()
	return agregado


func tiene_actividad() -> bool:
	return _ejecutando or not _pendientes.is_empty() or is_instance_valid(_globo_activo)


func esperar_globo(globo: Node) -> void:
	_globo_activo = globo


func procesar(escenario: Node) -> void:
	if not tiene_actividad():
		return
	if not is_instance_valid(escenario.ficha_jugador) or not escenario.ficha_jugador.puede_actuar():
		limpiar()
		return
	if _ejecutando or is_instance_valid(_globo_activo) or not escenario.puede_ejecutar_trigger_mapa():
		return
	var trigger: TriggerMapa = _pendientes.pop_front()
	if not is_instance_valid(trigger) or not trigger.habilitado or _consumido(trigger):
		return
	var motivo: StringName = &"accion_trigger_invalida"
	_ejecutando = true
	if trigger.accion != null and trigger.accion.validar_configuracion().is_empty():
		motivo = await trigger.accion.ejecutar(escenario, trigger)
	if motivo != &"":
		_ejecutando = false
		accion_fallida.emit(trigger.id_trigger, motivo)
		push_warning("Trigger %s: %s" % [trigger.id_trigger, motivo])
		return
	if trigger.frecuencia == TriggerMapa.Frecuencia.UNA_VEZ_POR_PARTIDA:
		EstadoPartida.consumir_trigger(_id_zona, trigger.id_trigger)
	_ejecutando = false
	trigger_activado.emit(trigger.id_trigger)


func limpiar() -> void:
	_pendientes.clear()
	if is_instance_valid(_globo_activo):
		_globo_activo.queue_free()
	_globo_activo = null


func _consumido(trigger: TriggerMapa) -> bool:
	return trigger.frecuencia == TriggerMapa.Frecuencia.UNA_VEZ_POR_PARTIDA and EstadoPartida.trigger_consumido(_id_zona, trigger.id_trigger)
