class_name PersistenciaPartida
extends RefCounted

var interactuables := PersistenciaInteractuables.new()
var contenido_dinamico := PersistenciaContenidoDinamico.new()
var archivos := ArchivoPartida.new()


func crear_snapshot(
	tablero: TableroGrid,
	id_zona: StringName,
	ficha: Ficha,
	conocimiento: RegistroConocimiento,
	gestor_rondas: GestorRondas = null
) -> Dictionary:
	if ficha == null or not is_instance_valid(ficha) or conocimiento == null:
		return {}
	var snapshot := interactuables.crear_snapshot(tablero, id_zona)
	if snapshot.is_empty():
		return {}
	snapshot["ficha"] = ficha.obtener_estado_persistente()
	snapshot["conocimiento"] = conocimiento.obtener_estado_persistente()
	snapshot["memoria_narrativa"] = EstadoPartida.obtener_estado_persistente()
	snapshot["items_suelo"] = contenido_dinamico.obtener_items_suelo(tablero)
	snapshot["superficies"] = contenido_dinamico.obtener_superficies(tablero)
	snapshot["rondas"] = gestor_rondas.obtener_estado_persistente() if gestor_rondas != null else null
	snapshot["celdas_exploradas"] = _obtener_exploracion(tablero)
	return (
		snapshot if validar_restauracion(
			snapshot, tablero, id_zona, ficha, conocimiento, gestor_rondas
		) == &""
		else {}
	)


func validar_restauracion(
	snapshot: Dictionary,
	tablero: TableroGrid,
	id_zona: StringName,
	ficha: Ficha,
	conocimiento: RegistroConocimiento,
	gestor_rondas: GestorRondas = null
) -> StringName:
	if ficha == null or not is_instance_valid(ficha) or conocimiento == null:
		return &"partida_guardada_invalida"
	if not snapshot.get("en_campamento", false) is bool:
		return &"campamento_guardado_invalido"
	var motivo := interactuables.validar_restauracion(snapshot, tablero, id_zona)
	if motivo != &"":
		return motivo
	if snapshot.has("celdas_exploradas"):
		motivo = _validar_exploracion(snapshot["celdas_exploradas"], tablero)
		if motivo != &"":
			return motivo
	motivo = ficha.validar_estado_persistente(snapshot.get("ficha"))
	if motivo != &"":
		return motivo
	motivo = _validar_habilidades_mundo(snapshot, tablero)
	if motivo != &"":
		return motivo
	if snapshot.get("en_campamento", false) and (snapshot.get("rondas") != null or snapshot["ficha"]["pv_actual"] <= 0):
		return &"campamento_guardado_invalido"
	var coordenada: Array = snapshot["ficha"]["coordenada"]
	if not tablero.es_celda_valida(Vector2i(coordenada[0], coordenada[1])):
		return &"coordenada_ficha_fuera_del_tablero"
	motivo = interactuables.validar_posiciones(
		snapshot, tablero, Vector2i(coordenada[0], coordenada[1])
	)
	if motivo != &"":
		return motivo
	var ids_inventario: Dictionary[String, bool] = {}
	for item: Dictionary in snapshot["ficha"]["inventario"]:
		ids_inventario[item["id"]] = true
	for equipado: Dictionary in snapshot["ficha"].get("equipo", []):
		ids_inventario[equipado["item"]["id"]] = true
	for datos_interactuable: Dictionary in snapshot["interactuables"]:
		var entidad := tablero.obtener_interactuable(
			StringName(datos_interactuable["id"])
		)
		if entidad is PersonajeNPC:
			var objetivo: Variant = datos_interactuable["estado"].get("objetivo_recordado_id")
			if objetivo != null and not tablero.obtener_interactuable(StringName(objetivo)) is PersonajeNPC:
				return &"memoria_npc_guardada_invalida"
			var recuerdo: Variant = datos_interactuable["estado"].get("ultima_posicion_conocida")
			if recuerdo is Array and not tablero.es_celda_valida(Vector2i(int(recuerdo[0]), int(recuerdo[1]))):
				return &"memoria_npc_fuera_del_tablero"
			var origen: Variant = datos_interactuable["estado"].get("coordenada_origen")
			if origen is Array and not tablero.es_celda_valida(Vector2i(int(origen[0]), int(origen[1]))):
				return &"origen_npc_fuera_del_tablero"
		if not (entidad is CofreInteractuable or entidad is PersonajeNPC):
			continue
		for item: Dictionary in datos_interactuable["estado"].get("inventario", []):
			if ids_inventario.has(item["id"]):
				return &"id_item_guardado_duplicado"
			ids_inventario[item["id"]] = true
	motivo = contenido_dinamico.validar(
		snapshot.get("items_suelo"),
		snapshot.get("superficies"),
		tablero,
		ids_inventario
	)
	if motivo != &"":
		return motivo
	motivo = conocimiento.validar_estado_persistente(snapshot.get("conocimiento"))
	if motivo != &"":
		return motivo
	if snapshot["version"] == PersistenciaInteractuables.VERSION_ANTERIOR:
		if snapshot.has("memoria_narrativa"):
			return &"memoria_narrativa_guardada_invalida"
	else:
		motivo = EstadoPartida.validar_estado_persistente(snapshot.get("memoria_narrativa"))
		if motivo != &"":
			return motivo
	if gestor_rondas == null:
		return &"" if snapshot.get("rondas") == null else &"gestor_rondas_ausente"
	var rondas: Variant = snapshot.get("rondas")
	if rondas is Dictionary and rondas.has("bandos"):
		var bandos: Variant = rondas["bandos"]
		if not bandos is Dictionary or bandos.get(String(ficha.obtener_id_actor())) != GestorRondas.Bando.JUGADOR:
			return &"bandos_guardados_invalidos"
		for id_actor in bandos:
			if id_actor == String(ficha.obtener_id_actor()):
				continue
			var npc := tablero.obtener_interactuable(StringName(id_actor)) as PersonajeNPC if id_actor is String else null
			if npc == null or npc.obtener_definicion_personaje() == null or not npc.obtener_definicion_personaje().puede_combatir:
				return &"bandos_guardados_invalidos"
	return gestor_rondas.validar_estado_persistente(snapshot.get("rondas"))


func _validar_habilidades_mundo(snapshot: Dictionary, tablero: TableroGrid) -> StringName:
	var datos: Dictionary = snapshot["ficha"].get("habilidades_nivel_dos", {})
	var agarrado: String = datos.get("agarre_objetivo", "")
	if agarrado != "":
		var encontrado := false
		for entidad: Dictionary in snapshot["interactuables"]:
			if entidad["id"] != agarrado:
				continue
			if not tablero.obtener_interactuable(StringName(agarrado)) is PersonajeNPC or entidad["estado"].get("vida_actual", 0) <= 0 or snapshot["ficha"]["pv_actual"] <= 0:
				return &"agarre_guardado_invalido"
			var origen: Array = snapshot["ficha"]["coordenada"]
			var destino: Array = entidad["coordenada"]
			if absi(int(origen[0]) - int(destino[0])) + absi(int(origen[1]) - int(destino[1])) != 1:
				return &"agarre_guardado_invalido"
			encontrado = true
		if not encontrado:
			return &"agarre_guardado_invalido"
	for id: String in datos.get("senuelos", {}):
		var coord: Array = datos["senuelos"][id]
		if not tablero.obtener_interactuable(StringName(id)) is PersonajeNPC or not tablero.es_celda_valida(Vector2i(coord[0], coord[1])):
			return &"senuelo_guardado_invalido"
	return &""


func restaurar(
	snapshot: Dictionary,
	tablero: TableroGrid,
	id_zona: StringName,
	ficha: Ficha,
	conocimiento: RegistroConocimiento,
	gestor_rondas: GestorRondas = null
) -> StringName:
	var motivo := validar_restauracion(
		snapshot, tablero, id_zona, ficha, conocimiento, gestor_rondas
	)
	if motivo != &"":
		return motivo
	motivo = interactuables.restaurar(snapshot, tablero, id_zona)
	if motivo != &"":
		return motivo
	contenido_dinamico.restaurar(snapshot["items_suelo"], snapshot["superficies"], tablero)
	var coordenada_anterior := ficha.coordenada_mapa
	ficha.restaurar_estado_persistente(snapshot["ficha"])
	tablero.liberar_celda(coordenada_anterior, ficha)
	tablero.ocupar_celda(ficha.coordenada_mapa, ficha)
	conocimiento.restaurar_estado_persistente(snapshot["conocimiento"])
	if snapshot.has("celdas_exploradas"):
		for celda: Celda in tablero.datos.values():
			celda.visibilidad = Celda.EstadoVisibilidad.OCULTO
		for coord: Array in snapshot["celdas_exploradas"]:
			tablero.datos[Vector2i(coord[0], coord[1])].visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	EstadoPartida.restaurar_estado_persistente(
		{"trompo_conocido": false}
		if snapshot["version"] == PersistenciaInteractuables.VERSION_ANTERIOR
		else snapshot["memoria_narrativa"]
	)
	return (
		gestor_rondas.restaurar_estado_persistente(snapshot["rondas"])
		if gestor_rondas != null else &""
	)


func guardar_archivo(
	ruta: String,
	tablero: TableroGrid,
	id_zona: StringName,
	ficha: Ficha,
	conocimiento: RegistroConocimiento,
	gestor_rondas: GestorRondas = null
) -> StringName:
	var snapshot := crear_snapshot(
		tablero, id_zona, ficha, conocimiento, gestor_rondas
	)
	return archivos.guardar(ruta, snapshot)


func cargar_archivo(
	ruta: String,
	tablero: TableroGrid,
	id_zona: StringName,
	ficha: Ficha,
	conocimiento: RegistroConocimiento,
	gestor_rondas: GestorRondas = null
) -> StringName:
	var snapshot: Variant = archivos.cargar(ruta)
	if snapshot is StringName:
		return snapshot
	return restaurar(
		snapshot, tablero, id_zona, ficha, conocimiento, gestor_rondas
	)


func _obtener_exploracion(tablero: TableroGrid) -> Array[Array]:
	var coordenadas: Array[Vector2i] = []
	for coord: Vector2i in tablero.datos:
		if tablero.datos[coord].visibilidad != Celda.EstadoVisibilidad.OCULTO:
			coordenadas.append(coord)
	coordenadas.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x or (a.x == b.x and a.y < b.y))
	var datos: Array[Array] = []
	for coord in coordenadas:
		datos.append([coord.x, coord.y])
	return datos


func _validar_exploracion(datos: Variant, tablero: TableroGrid) -> StringName:
	if not datos is Array:
		return &"exploracion_guardada_invalida"
	var vistos: Dictionary[Vector2i, bool] = {}
	for coord: Variant in datos:
		if not coord is Array or coord.size() != 2:
			return &"exploracion_guardada_invalida"
		for componente: Variant in coord:
			if not (componente is int or (componente is float and is_finite(componente) and componente == roundf(componente))):
				return &"exploracion_guardada_invalida"
		var posicion := Vector2i(coord[0], coord[1])
		if not tablero.es_celda_valida(posicion) or vistos.has(posicion):
			return &"exploracion_guardada_invalida"
		vistos[posicion] = true
	return &""
