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

	fuente.free()
	_finalizar()


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
