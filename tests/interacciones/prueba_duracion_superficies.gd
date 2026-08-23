extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var tablero := TableroGrid.new()
	var contenedor := Node2D.new()
	root.add_child(tablero)
	root.add_child(contenedor)
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.datos[Vector2i.RIGHT] = Celda.new()
	var humo := Humo.new()
	humo.id_instancia = &"a_humo"
	humo.duracion_superficie = 1
	var fuego := Fuego.new()
	fuego.id_instancia = &"b_fuego"
	fuego.duracion_superficie = 2
	contenedor.add_child(humo)
	contenedor.add_child(fuego)
	tablero.registrar_efecto_superficie(Vector2i.ZERO, humo)
	tablero.registrar_efecto_superficie(Vector2i.RIGHT, fuego)
	var procesador := ProcesadorSuperficies.new(tablero)

	var primera := procesador.procesar_fin_ronda()
	_comprobar(
		primera.cambios_estado.map(func(cambio): return cambio[&"id_superficie"])
		== [&"a_humo", &"b_fuego"],
		"Las superficies deben procesarse por ID estable."
	)
	_comprobar(
		not tablero.efectos_superficie_por_id.has(&"a_humo")
		and fuego.obtener_turnos_restantes_superficie() == 1,
		"Humo debe expirar y fuego debe conservar una ronda."
	)

	var segunda := procesador.procesar_fin_ronda()
	var humo_resultante := tablero.efectos_superficie_por_id.get(
		&"b_fuego_humo"
	) as Humo
	_comprobar(
		segunda.exitosa
		and not tablero.efectos_superficie_por_id.has(&"b_fuego")
		and humo_resultante != null,
		"Fuego debe transformarse en humo al expirar."
	)
	_comprobar(
		humo_resultante.obtener_turnos_restantes_superficie() == 10
		and tablero.obtener_celda(Vector2i.RIGHT).bloquea_vision_efectiva(),
		"El humo nuevo debe comenzar completo y bloquear visión."
	)

	for efecto in tablero.efectos_superficie_por_id.values():
		tablero.retirar_efecto_superficie(efecto)
		efecto.queue_free()
	tablero.queue_free()
	contenedor.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("DuracionSuperficies: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
