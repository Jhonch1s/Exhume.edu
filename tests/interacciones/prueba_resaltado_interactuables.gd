extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var escena := load(
		"res://scenes/interactuables/fuentes_luz/fuente_luz_interactuable.tscn"
	) as PackedScene
	var fuente := escena.instantiate() as FuenteLuzInteractuable
	fuente.definicion = load(
		"res://assets/interactuables/luces/antorcha_pie.tres"
	) as DefinicionFuenteLuz
	root.add_child(fuente)
	await process_frame

	_comprobar(not fuente.esta_resaltado(), "El resaltado debe comenzar inactivo.")
	fuente.establecer_resaltado(true)
	var resaltador := fuente.resaltador_outline
	_comprobar(resaltador != null, "La API debe crear el resaltador visual bajo demanda.")
	_comprobar(fuente.esta_resaltado(), "La API debe activar el resaltado.")
	_comprobar(
		resaltador.get_child_count() == 1,
		"El outline debe usar una representación programática, sin nodos preparados en la escena."
	)

	var copia := resaltador.get_child(0) as Sprite2D
	_comprobar(copia != null and copia.visible, "La copia de outline debe quedar visible.")
	_comprobar(
		copia.texture == fuente.sprite.texture,
		"El outline debe reutilizar la textura existente."
	)
	_comprobar(
		copia.region_enabled and copia.region_rect == fuente.sprite.region_rect,
		"El outline debe reutilizar la región actual del atlas."
	)
	var material := copia.material as ShaderMaterial
	_comprobar(
		material != null
		and material.shader != null
		and "void fragment()" in material.shader.code,
		"El contorno debe generarse mediante shader creado por código."
	)

	var region_encendida := copia.region_rect
	fuente.encendida = false
	await process_frame
	_comprobar(
		copia.region_rect == fuente.sprite.region_rect
		and copia.region_rect != region_encendida,
		"El outline debe seguir la región al apagar la fuente."
	)

	fuente.establecer_resaltado(false)
	_comprobar(
		not fuente.esta_resaltado() and not copia.visible,
		"Desactivar el resaltado debe ocultarlo sin alterar la fuente."
	)
	_comprobar(
		not fuente.encendida,
		"El resaltado debe ser puramente visual y no modificar el estado mecánico."
	)
	var velas := load(
		"res://assets/interactuables/luces/vela_02.tres"
	) as DefinicionFuenteLuz
	_comprobar(velas.es_valida(), "La definición de velas debe ser válida.")
	fuente.definicion = velas
	fuente._actualizar_representacion()
	_comprobar(
		fuente.sprite.region_rect == Rect2(64, 0, 64, 32)
		and fuente.sprite.position == Vector2.ZERO,
		"Las velas apagadas deben conservar su base alineada."
	)
	fuente.encendida = true
	_comprobar(
		fuente.sprite.region_rect == Rect2(64, 32, 64, 42)
		and fuente.sprite.position == Vector2(0, -5),
		"La llama debe ampliar la región hacia arriba sin desplazar su base."
	)

	fuente.free()
	await _probar_guias()
	_finalizar()


func _probar_guias() -> void:
	for tipo in ["libro", "hojas", "estandarte", "cartel"]:
		var guia := (load("res://scenes/interactuables/guias/%s_interactuable.tscn" % tipo) as PackedScene).instantiate() as Interactuable
		root.add_child(guia)
		_comprobar_outline_guia(guia, "Escena reutilizable de %s" % tipo)
		guia.free()
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	for guia in zona.get_node("Interactuables/Guias").get_children():
		_comprobar_outline_guia(guia as Interactuable, "Zona1/%s" % guia.name)
	zona.free()
	await process_frame


func _comprobar_outline_guia(guia: Interactuable, contexto: String) -> void:
	var visual := guia.get_node_or_null(guia.ruta_visual_resaltable) as Sprite2D
	_comprobar(visual != null, "%s debe referenciar su sprite para resaltar." % contexto)
	guia.establecer_resaltado(true)
	var outline := guia.resaltador_outline
	_comprobar(outline != null and guia.esta_resaltado(), "%s debe activar el contorno." % contexto)
	if outline != null:
		_comprobar(outline.color_outline == Color.WHITE and outline.grosor == 1.0,
			"%s debe usar contorno blanco de un píxel." % contexto)
		var copia := outline.get_child(0) as Sprite2D
		_comprobar(copia.visible and copia.texture == visual.texture and copia.region_rect == visual.region_rect,
			"%s debe resaltar la región de su variante visual." % contexto)
	guia.establecer_resaltado(false)
	_comprobar(not guia.esta_resaltado(), "%s debe permitir retirar el contorno." % contexto)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("ResaltadoInteractuables: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
