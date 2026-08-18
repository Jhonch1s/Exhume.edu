extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	var coordenada_lava := Vector2i.ZERO
	var encontro_lava := false
	for coordenada in tablero.datos:
		if tablero.datos[coordenada].zona == &"lava":
			coordenada_lava = coordenada
			encontro_lava = true
			break
	_comprobar(encontro_lava, "Zona1 debe contener lava.")

	if encontro_lava:
		var celda := tablero.obtener_celda(coordenada_lava)
		var ficha := Ficha.new()
		root.add_child(ficha)
		var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
		)
		_comprobar(reacciones.size() == 1, "La lava debe publicar una reacción de terreno.")
		var gestor := GestorAcciones.new()
		root.add_child(gestor)
		var vida_inicial := ficha.pv_actual
		var resultado := ResolverReaccionesCelda.new(gestor).resolver(
			TiposInteraccion.TipoAccion.ENTRAR,
			ficha,
			coordenada_lava + Vector2i.LEFT,
			coordenada_lava,
			reacciones
		)
		_comprobar(ficha.pv_actual == vida_inicial - 2, "La lava debe aplicar dos puntos de daño.")
		_comprobar(
			resultado.efectos_aplicados.size() == 1
				and resultado.efectos_aplicados[0].clave == &"lava",
			"El daño de lava debe quedar confirmado por el aplicador común."
		)
		gestor.queue_free()
		ficha.queue_free()

	tablero.queue_free()
	zona.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("LavaSistemaEfectos: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
