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
	snapshot["items_suelo"] = contenido_dinamico.obtener_items_suelo(tablero)
	snapshot["superficies"] = contenido_dinamico.obtener_superficies(tablero)
	snapshot["rondas"] = gestor_rondas.obtener_estado_persistente() if gestor_rondas != null else null
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
	var motivo := interactuables.validar_restauracion(snapshot, tablero, id_zona)
	if motivo != &"":
		return motivo
	motivo = ficha.validar_estado_persistente(snapshot.get("ficha"))
	if motivo != &"":
		return motivo
	var coordenada: Array = snapshot["ficha"]["coordenada"]
	if not tablero.es_celda_valida(Vector2i(coordenada[0], coordenada[1])):
		return &"coordenada_ficha_fuera_del_tablero"
	var ids_inventario: Dictionary[String, bool] = {}
	for item: Dictionary in snapshot["ficha"]["inventario"]:
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
	if gestor_rondas == null:
		return &"" if snapshot.get("rondas") == null else &"gestor_rondas_ausente"
	return gestor_rondas.validar_estado_persistente(snapshot.get("rondas"))


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
	interactuables.restaurar(snapshot, tablero, id_zona)
	contenido_dinamico.restaurar(snapshot["items_suelo"], snapshot["superficies"], tablero)
	var coordenada_anterior := ficha.coordenada_mapa
	ficha.restaurar_estado_persistente(snapshot["ficha"])
	tablero.liberar_celda(coordenada_anterior, ficha)
	tablero.ocupar_celda(ficha.coordenada_mapa, ficha)
	conocimiento.restaurar_estado_persistente(snapshot["conocimiento"])
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
