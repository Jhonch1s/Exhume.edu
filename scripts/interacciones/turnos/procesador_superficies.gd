class_name ProcesadorSuperficies
extends RefCounted

var tablero: TableroGrid


func _init(tablero_inicial: TableroGrid) -> void:
	tablero = tablero_inicial


func validar() -> StringName:
	if tablero == null or not is_instance_valid(tablero):
		return &"tablero_superficies_invalido"
	var ids_resultantes: Dictionary[StringName, bool] = {}
	for id_efecto in _ids_ordenados():
		var efecto: Object = tablero.efectos_superficie_por_id[id_efecto]
		if (
			efecto == null
			or not is_instance_valid(efecto)
			or not efecto.has_method(&"obtener_turnos_restantes_superficie")
			or not efecto.has_method(&"consumir_turno_superficie")
			or not efecto.has_method(&"obtener_coordenada_reaccion")
		):
			return &"contrato_superficie_temporal_invalido"
		var restantes: Variant = efecto.call(&"obtener_turnos_restantes_superficie")
		var coordenada: Variant = efecto.call(&"obtener_coordenada_reaccion")
		if not restantes is int or restantes <= 0 or not coordenada is Vector2i:
			return &"estado_superficie_temporal_invalido"
		if restantes != 1 or not efecto.has_method(&"obtener_escena_al_expirar"):
			continue
		var escena: Variant = efecto.call(&"obtener_escena_al_expirar")
		var id_resultante := StringName("%s_humo" % id_efecto)
		if (
			not escena is PackedScene
			or efecto.get_parent() == null
			or tablero.efectos_superficie_por_id.has(id_resultante)
			or ids_resultantes.has(id_resultante)
		):
			return &"transformacion_superficie_invalida"
		ids_resultantes[id_resultante] = true
	return &""


func procesar_fin_ronda() -> ResultadoAccion:
	var motivo := validar()
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var cambios: Array[Dictionary] = []
	for id_efecto in _ids_ordenados():
		var efecto: Object = tablero.efectos_superficie_por_id[id_efecto]
		var restantes: int = efecto.call(&"consumir_turno_superficie")
		var cambio: Dictionary = {
			&"tipo": &"superficie_tick",
			&"id_superficie": id_efecto,
			&"turnos_restantes": restantes,
			&"expirada": restantes == 0,
		}
		if restantes == 0:
			var id_resultante := _expirar(efecto, id_efecto)
			if id_resultante != &"":
				cambio[&"id_superficie_resultante"] = id_resultante
		cambios.append(cambio)
	return ResultadoAccion.crear_exito([], [], cambios)


func _expirar(efecto: Object, id_efecto: StringName) -> StringName:
	var coordenada: Vector2i = efecto.call(&"obtener_coordenada_reaccion")
	var padre: Node = efecto.get_parent()
	var posicion: Vector2 = (
		(efecto as Node2D).global_position if efecto is Node2D else Vector2.ZERO
	)
	var escena: PackedScene = null
	if efecto.has_method(&"obtener_escena_al_expirar"):
		escena = efecto.call(&"obtener_escena_al_expirar") as PackedScene
	tablero.retirar_efecto_superficie(efecto)
	if efecto is Node:
		efecto.queue_free()
	if escena == null:
		return &""
	var reemplazo := escena.instantiate() as Node2D
	var id_resultante := StringName("%s_humo" % id_efecto)
	reemplazo.call(&"configurar_id_instancia", id_resultante)
	padre.add_child(reemplazo)
	reemplazo.global_position = posicion
	if not tablero.registrar_efecto_superficie(coordenada, reemplazo):
		reemplazo.queue_free()
		return &""
	return id_resultante


func _ids_ordenados() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(tablero.efectos_superficie_por_id.keys())
	ids.sort_custom(func(a, b): return String(a) < String(b))
	return ids
