class_name ViajeEntreZonas
extends RefCounted

signal viaje_finalizado(escenario: Node)

var en_curso := false
var _zonas_visitadas: Dictionary = {}


func viajar(origen: Node, ruta: String, id_spawn: StringName) -> StringName:
	if en_curso or origen.en_combate or origen.es_escenario_de_descanso:
		return &"viaje_no_disponible"
	if not origen.puede_ejecutar_trigger_mapa():
		return &"viaje_accion_en_curso"
	if not ruta.begins_with("res://") or not ruta.ends_with(".tscn") or not ResourceLoader.exists(ruta, "PackedScene"):
		return &"escena_destino_invalida"
	var escena := load(ruta) as PackedScene
	if escena == null:
		return &"escena_destino_invalida"
	var instancia := escena.instantiate()
	if not instancia is Node2D:
		instancia.free()
		return &"zona_destino_invalida"
	var zona := instancia as Node2D
	var motivo := _validar_destino(zona, id_spawn)
	if motivo != &"":
		zona.free()
		return motivo
	var snapshot_origen: Dictionary = origen.persistencia_partida.crear_snapshot(
		origen.tablero, origen.obtener_id_zona(), origen.ficha_jugador, origen.registro_conocimiento
	)
	if snapshot_origen.is_empty():
		zona.free()
		return &"estado_origen_no_transferible"
	en_curso = true
	var nuevo := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	# Conserva las especializaciones del escenario (también el soporte sin render).
	nuevo.set_script(origen.get_script())
	nuevo.get_node("Zona").free()
	zona.name = "Zona"
	nuevo.add_child(zona)
	nuevo.preparando_viaje = true
	nuevo.id_spawn_inicial = id_spawn
	nuevo.datos_ficha_viaje = _ficha_para_viaje(snapshot_origen["ficha"])
	nuevo.nombreClase = origen.ficha_jugador.clase
	nuevo.viajes = self
	nuevo.visible = false
	nuevo.process_mode = Node.PROCESS_MODE_DISABLED
	nuevo.get_node("Camera2D").enabled = false
	var arbol := origen.get_tree()
	arbol.root.add_child(nuevo)
	for _intento in 600:
		if nuevo.escenario_preparado:
			break
		await arbol.process_frame
	if not nuevo.escenario_preparado or nuevo.ficha_jugador == null:
		nuevo.queue_free()
		en_curso = false
		return &"spawn_destino_no_disponible"
	var ruta_origen: String = origen.zona_actual.scene_file_path
	var guardado: Dictionary = (
		snapshot_origen if ruta == ruta_origen else _zonas_visitadas.get(ruta, {})
	).duplicate(true)
	if guardado.is_empty():
		guardado = nuevo.persistencia_partida.crear_snapshot(
			nuevo.tablero, nuevo.obtener_id_zona(), nuevo.ficha_jugador, nuevo.registro_conocimiento
		)
	if guardado.is_empty():
		motivo = &"estado_destino_invalido"
	else:
		guardado["ficha"] = nuevo.ficha_jugador.obtener_estado_persistente()
		guardado["conocimiento"] = snapshot_origen["conocimiento"]
		guardado["memoria_narrativa"] = EstadoPartida.obtener_estado_persistente()
		guardado["rondas"] = null
		motivo = nuevo.persistencia_partida.restaurar(
			guardado, nuevo.tablero, nuevo.obtener_id_zona(), nuevo.ficha_jugador, nuevo.registro_conocimiento
		)
	if motivo != &"":
		nuevo.queue_free()
		en_curso = false
		return motivo
	_zonas_visitadas[ruta_origen] = snapshot_origen
	_zonas_visitadas.erase(ruta)
	origen.visible = false
	origen.process_mode = Node.PROCESS_MODE_DISABLED
	for capa in ["CanvasLayer", "CanvasLayerModalDados", "FiltroCRT"]:
		origen.get_node(capa).visible = false
	nuevo.preparando_viaje = false
	nuevo.visible = true
	nuevo.process_mode = Node.PROCESS_MODE_INHERIT
	nuevo.get_node("CanvasLayer").visible = true
	nuevo.get_node("CanvasLayerModalDados").visible = true
	nuevo.get_node("FiltroCRT").visible = true
	nuevo.gestor_vision.reconstruir_niebla_restaurada()
	nuevo._actualizar_luz_al_cargar()
	nuevo._on_vida_jugador_cambiada(nuevo.ficha_jugador.pv_actual, nuevo.ficha_jugador.pv_max)
	nuevo.hud.actualizar_desde_ficha()
	nuevo.get_node("Camera2D").enabled = true
	nuevo.get_node("Camera2D").make_current()
	nuevo.centrar_camara_en_ficha()
	nuevo._inicializar_audio_ambiente()
	nuevo._inicializar_musica()
	nuevo._presentar_entrada_nueva_zona()
	arbol.current_scene = nuevo
	origen.queue_free()
	en_curso = false
	viaje_finalizado.emit(nuevo)
	return &""


func obtener_estado_persistente() -> Dictionary:
	return _zonas_visitadas.duplicate(true)


func validar_estado_persistente(datos: Variant) -> StringName:
	if not datos is Dictionary:
		return &"zonas_visitadas_invalidas"
	for ruta in datos:
		if not ruta is String or not ruta.begins_with("res://") or not ruta.ends_with(".tscn") or not ResourceLoader.exists(ruta, "PackedScene"):
			return &"zona_visitada_invalida"
		var estado: Variant = datos[ruta]
		var id_esperado: String = "zona1" if ruta == "res://scenes/Zona1/zona_1.tscn" else ruta
		if not estado is Dictionary or estado.has("zonas_visitadas") or estado.get("version") != PersistenciaInteractuables.VERSION or estado.get("zona_id") != id_esperado or estado.get("rondas") != null:
			return &"estado_zona_visitada_invalido"
		for campo in ["interactuables", "items_suelo", "superficies", "celdas_exploradas"]:
			if not estado.get(campo) is Array:
				return &"estado_zona_visitada_invalido"
	return &""


func restaurar_estado_persistente(datos: Variant) -> StringName:
	var motivo := validar_estado_persistente(datos)
	if motivo != &"":
		return motivo
	_zonas_visitadas = datos.duplicate(true)
	return &""


func _validar_destino(zona: Node2D, id_spawn: StringName) -> StringName:
	if not zona is ZonaExplorable or not zona.get_node_or_null("CapaSuelo") is TileMapLayer or not zona.get_node_or_null("CapaOscuridad") is TileMapLayer or not zona.get_node_or_null("CapaParedes") is CapaParedesOclusivas:
		return &"zona_destino_invalida"
	var coincidencias := 0
	for nodo in zona.find_children("*", "PuntoSpawnZona", true, false):
		if nodo.id_spawn == id_spawn:
			coincidencias += 1
	if coincidencias != 1:
		return &"spawn_destino_duplicado" if coincidencias > 1 else &"spawn_destino_inexistente"
	return &""


func _ficha_para_viaje(datos: Dictionary) -> Dictionary:
	var ficha := datos.duplicate(true)
	# Estas referencias y la continuidad de un recorrido pertenecen al mapa de origen.
	var habilidades: Dictionary = ficha.get("habilidades_nivel_dos", {})
	habilidades["agarre_objetivo"] = ""
	habilidades["agarre_pasos"] = 0
	habilidades["senuelos"] = {}
	habilidades["pasos_inercia"] = 0
	return ficha
