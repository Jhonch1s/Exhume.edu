extends SceneTree

class TableroRegistroFallido extends TableroGrid:
	func registrar_item_suelo(_coord: Vector2i, _item: ItemSuelo) -> bool:
		return false

const ESCENARIO_SIN_RENDER := preload("res://tests/soporte/escenario_sin_render.gd")
var fallos: Array[String] = []
var casos := 0
var escenario: Node
var ficha: Ficha
var definicion: DefinicionAntorcha


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	escenario = (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	escenario.set_script(ESCENARIO_SIN_RENDER)
	root.add_child(escenario)
	for intento in 240:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	escenario.set_process(false)
	ficha = escenario.ficha_jugador
	definicion = load("res://assets/items/antorcha/antorcha.tres")
	escenario.panel_inventario_equipo.cerrar()
	escenario.interaccion_modal_activa = false
	_probar_ciclo()
	_probar_pilas()
	_probar_transferencias_parciales()
	_probar_persistencia()
	_probar_compatibilidad()
	escenario.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Desgaste de antorchas: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func _limpiar() -> void:
	ficha.inventario = Inventario.new()
	ficha.equipo.ranuras.clear()


func _crear(id: StringName, pasos: Array[int]) -> ItemInstancia:
	var item := ItemInstancia.new(id, definicion, pasos.size())
	item.pasos_antorchas = pasos.duplicate()
	comprobar(ficha.inventario.agregar(item).exitosa, "Se agrega %s." % id)
	return item


func _soltar(item: ItemInstancia, cantidad: int = -1, nuevo_id: StringName = &"", ranura: int = -1) -> ResultadoAccion:
	return escenario.gestor_acciones.procesar_accion(escenario.transferidor_items.construir_contexto_soltar(
		ficha, item, ficha.coordenada_mapa, ficha.coordenada_mapa, cantidad, nuevo_id, ranura
	))


func _recoger(id: StringName, cantidad: int = -1, nuevo_id: StringName = &"") -> ResultadoAccion:
	var suelo: ItemSuelo = escenario.tablero.obtener_item_suelo(id)
	return escenario.gestor_acciones.procesar_accion(escenario.transferidor_items.construir_contexto_recoger(
		ficha, suelo, ficha.coordenada_mapa, cantidad, nuevo_id
	))


func _probar_ciclo() -> void:
	_limpiar()
	var antorcha := _crear(&"ciclo_usada", [9])
	for vuelta in 3:
		comprobar(_soltar(antorcha).exitosa, "Se suelta la antorcha usada.")
		comprobar(not ficha.consumir_paso_antorcha() and ficha.pasos_antorcha_actual == 0, "Caminar sin antorchas no cambia la que está en el suelo.")
		comprobar(_recoger(antorcha.id_instancia).exitosa and ficha.pasos_antorcha_actual == 9 - vuelta, "Recoger conserva los pasos, sin recargar.")
		ficha.consumir_paso_antorcha()
	comprobar(antorcha.pasos_antorchas == [6], "Tres ciclos solo gastan tres pasos.")
	var nueva := _crear(&"a_nueva_antes_en_orden", [80])
	comprobar(ficha.obtener_pila_antorcha_activa() == antorcha and ficha.pasos_antorcha_actual == 6, "Agregar una pila nueva no reemplaza la que está en uso.")
	ficha.inventario.transferir_a(Inventario.new(), nueva.id_instancia)
	comprobar(ficha.equipo.equipar(ficha.inventario, antorcha.id_instancia, 8) == &"", "Se equipa la antorcha usada.")
	comprobar(_soltar(antorcha, -1, &"", 8).exitosa, "Se suelta desde el equipo sin modificar desgaste.")
	var otro := Ficha.new()
	var suelo: ItemSuelo = escenario.tablero.obtener_item_suelo(antorcha.id_instancia)
	comprobar(escenario.transferidor_items.recoger(escenario.transferidor_items.construir_contexto_recoger(
		otro, suelo, ficha.coordenada_mapa
	)).exitosa and otro.pasos_antorcha_actual == 6, "Otro portador recibe la antorcha con seis pasos.")
	otro.free()


func _probar_pilas() -> void:
	_limpiar()
	var primera := _crear(&"pila_a", [9, 80])
	var segunda := _crear(&"pila_b", [14, 80])
	comprobar(ficha.inventario.combinar(segunda.id_instancia, primera.id_instancia).exitosa, "Se combinan dos pilas usadas.")
	comprobar(primera.pasos_antorchas == [9, 14, 80, 80], "La combinación conserva todas las duraciones.")
	var separada := ficha.inventario.separar(primera.id_instancia, 2, &"pila_separada")
	comprobar(separada.exitosa and separada.item.pasos_antorchas == [9, 14] and primera.pasos_antorchas == [80, 80], "Separar mueve el desgaste sin duplicarlo.")
	comprobar(ficha.inventario.combinar(separada.item.id_instancia, primera.id_instancia).exitosa, "Se recombina la pila separada.")
	ficha.pasos_antorcha_actual = 1
	comprobar(ficha.consumir_paso_antorcha() and primera.pasos_antorchas == [14, 80, 80], "Agotar la primera conserva la segunda usada.")
	comprobar(ficha.pasos_antorcha_actual == 14, "La siguiente antorcha no se restaura a ochenta.")
	var datos := ficha.inventario.obtener_estado_persistente()
	var copia := Inventario.new()
	comprobar(copia.restaurar_estado_persistente(JSON.parse_string(JSON.stringify(datos))) == &"", "El inventario restaura las duraciones de todas las unidades.")
	comprobar(copia.obtener_por_id(primera.id_instancia).pasos_antorchas == [14, 80, 80], "El guardado de la pila conserva las unidades usadas.")


func _probar_transferencias_parciales() -> void:
	_limpiar()
	var pila := _crear(&"parcial_origen", [7, 20, 80])
	comprobar(_soltar(pila, 2, &"parcial_suelo").exitosa, "Se sueltan dos unidades de la pila.")
	var suelo: ItemSuelo = escenario.tablero.obtener_item_suelo(&"parcial_suelo")
	comprobar(suelo.item.pasos_antorchas == [7, 20] and pila.pasos_antorchas == [80], "Soltar parcialmente mueve las duraciones correctas.")
	comprobar(_recoger(&"parcial_suelo", 1, &"parcial_recogida").exitosa, "Se recoge una unidad del suelo.")
	comprobar(suelo.item.pasos_antorchas == [20], "La unidad restante en el suelo conserva veinte pasos.")
	var recogida := ficha.inventario.obtener_por_id(&"parcial_recogida")
	comprobar(recogida.pasos_antorchas == [7], "La unidad recogida conserva siete pasos.")
	var antes := recogida.pasos_antorchas.duplicate()
	var otro_inventario := Inventario.new()
	comprobar(ficha.inventario.transferir_a(otro_inventario, recogida.id_instancia).exitosa and recogida.pasos_antorchas == antes, "Transferir a otro inventario conserva desgaste.")
	ficha.inventario.capacidad = ficha.inventario.obtener_contenido().size()
	comprobar(not _recoger(&"parcial_suelo").exitosa and suelo.item.pasos_antorchas == [20], "Recoger con mochila llena no altera la antorcha del suelo.")
	ficha.inventario.capacidad = -1
	var rollback := _crear(&"rollback_antorchas", [6, 30, 80])
	var tablero := TableroRegistroFallido.new()
	tablero.datos[Vector2i.ZERO] = Celda.new()
	var transferidor := TransferidorItems.new(tablero)
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(transferidor.construir_contexto_soltar(
		ficha, rollback, Vector2i.ZERO, Vector2i.ZERO, 1, &"rollback_parcial"
	))
	comprobar(not resultado.exitosa and rollback.pasos_antorchas == [6, 30, 80], "Un fallo al soltar restaura combustible y orden de la pila.")
	comprobar(ficha.inventario.obtener_por_id(&"rollback_parcial") == null, "El rollback no duplica la antorcha separada.")
	gestor.free()
	tablero.free()


func _probar_persistencia() -> void:
	_limpiar()
	var mochila := _crear(&"guardar_mochila", [11, 80])
	var suelo := _crear(&"guardar_suelo", [5, 18])
	var equipo := _crear(&"guardar_equipo", [23])
	comprobar(_soltar(suelo).exitosa, "Se deja la antorcha usada en el suelo antes de guardar.")
	ficha.equipo.equipar(ficha.inventario, equipo.id_instancia, 8)
	var persistencia: PersistenciaPartida = escenario.persistencia_partida
	var snapshot := persistencia.crear_snapshot(escenario.tablero, escenario.obtener_id_zona(), ficha, escenario.registro_conocimiento, escenario.gestor_rondas)
	comprobar(not snapshot.is_empty(), "Se crea una partida válida con desgaste en mochila, equipo y suelo.")
	if snapshot.is_empty():
		return
	var json: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	mochila.pasos_antorchas[0] = 80
	equipo.pasos_antorchas[0] = 80
	suelo.pasos_antorchas[0] = 80
	comprobar(persistencia.restaurar(json, escenario.tablero, escenario.obtener_id_zona(), ficha, escenario.registro_conocimiento, escenario.gestor_rondas) == &"", "Se restaura la partida desde JSON.")
	comprobar(ficha.inventario.obtener_por_id(mochila.id_instancia).pasos_antorchas == [11, 80], "Se restaura desgaste de mochila.")
	comprobar(ficha.equipo.ranuras[8].pasos_antorchas == [23], "Se restaura desgaste de equipo.")
	var restaurada: ItemSuelo = escenario.tablero.obtener_item_suelo(suelo.id_instancia)
	comprobar(restaurada.item.pasos_antorchas == [5, 18], "Se restaura desgaste del suelo.")
	comprobar(_recoger(suelo.id_instancia).exitosa and ficha.pasos_antorcha_actual == 5, "Recoger después de cargar tampoco recarga.")
	for pasos: Variant in [[81, 80], [0, 80], [1.5, 80], [11], "once"]:
		var corrupto := json.duplicate(true)
		corrupto["ficha"]["inventario"][0]["pasos_antorchas"] = pasos
		comprobar(persistencia.validar_restauracion(corrupto, escenario.tablero, escenario.obtener_id_zona(), ficha, escenario.registro_conocimiento, escenario.gestor_rondas) != &"", "Se rechaza desgaste inválido.")


func _probar_compatibilidad() -> void:
	_limpiar()
	_crear(&"legacy_antorchas", [9, 80])
	var anterior := ficha.obtener_estado_persistente()
	for dato: Dictionary in anterior["inventario"]:
		dato.erase("pasos_antorchas")
	comprobar(ficha.restaurar_estado_persistente(JSON.parse_string(JSON.stringify(anterior))) == &"" and ficha.pasos_antorcha_actual == 9, "Un guardado anterior migra su contador de nueve pasos.")
	comprobar(ficha.inventario.obtener_por_id(&"legacy_antorchas").pasos_antorchas == [9, 80], "La migración no gasta ni renueva los repuestos.")
	_limpiar()
	var larga := definicion.duplicate() as DefinicionAntorcha
	larga.magnitudes = larga.magnitudes.duplicate()
	larga.magnitudes[&"duracion"] = 120.0
	comprobar(ResourceSaver.save(larga, "user://antorcha_larga_desgaste_test.tres") == OK, "Se prepara una antorcha de duración personalizada.")
	larga = load("user://antorcha_larga_desgaste_test.tres") as DefinicionAntorcha
	var item := ItemInstancia.new(&"larga", larga)
	comprobar(ficha.inventario.agregar(item).exitosa and ficha.pasos_antorcha_actual == 120, "Se respeta duración personalizada de ciento veinte pasos.")
	var datos: Dictionary = JSON.parse_string(JSON.stringify(ficha.obtener_estado_persistente()))
	comprobar(ficha.restaurar_estado_persistente(datos) == &"" and ficha.pasos_antorcha_actual == 120, "La duración personalizada también se guarda y carga.")


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append("Fallo [%d]: %s" % [casos, mensaje])
