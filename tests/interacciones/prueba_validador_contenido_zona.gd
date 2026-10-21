extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	var capa := zona.get_node("CapaSuelo") as TileMapLayer
	var validador := ValidadorContenidoZona.new()

	_comprobar(validador.validar(zona, tablero, capa).is_empty(), "Zona1 debe ser valida.")
	var guia := zona.get_node("Interactuables/Guias/Libro_01") as Interactuable
	var ruta_visual := guia.ruta_visual_resaltable
	guia.ruta_visual_resaltable = NodePath("")
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "visual_resaltable_invalido"), "Debe detectar un sprite sin ruta.")
	guia.ruta_visual_resaltable = ruta_visual
	var sprite := guia.get_node(ruta_visual) as Sprite2D
	var textura := sprite.texture
	sprite.texture = null
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "visual_resaltable_invalido"), "Debe detectar un sprite sin textura.")
	sprite.texture = textura
	var color := guia.color_resaltado
	guia.color_resaltado = Color.TRANSPARENT
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "resaltado_invisible"), "Debe detectar un contorno invisible.")
	guia.color_resaltado = color
	var ruta_fog := guia.ruta_fog_oculto
	guia.ruta_fog_oculto = ^"SpriteInexistente"
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "mascara_fog_invalida"), "Debe detectar una mascara de niebla ausente.")
	guia.ruta_fog_oculto = ruta_fog

	var palanca := zona.get_node(
		"Interactuables/Mecanismos/Palanca_03_m03"
	) as PalancaInteractuable
	var puerta := zona.get_node(
		"Interactuables/Puertas/Puerta_04_m03"
	) as Interactuable
	var humo := zona.get_node("EfectosSuperficie/HumoVeneno") as Node
	var id_puerta := puerta.id_instancia
	puerta.id_instancia = palanca.id_instancia
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "id_interactuable_duplicado"), "Debe detectar IDs duplicados.")
	puerta.id_instancia = id_puerta

	var definicion_puerta := puerta.definicion
	puerta.definicion = null
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "definicion_interactuable_invalida"), "Debe detectar definiciones ausentes.")
	puerta.definicion = definicion_puerta

	var relaciones := palanca.ids_receptores_mecanismo.duplicate()
	palanca.ids_receptores_mecanismo = [&"receptor_inexistente"]
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "receptor_mecanismo_inexistente"), "Debe detectar relaciones ausentes.")
	palanca.ids_receptores_mecanismo = relaciones

	var id_humo: StringName = humo.get("id_instancia")
	humo.set("id_instancia", &"")
	_comprobar(_contiene(validador.validar(zona, tablero, capa), "id_superficie_vacio"), "Debe detectar superficies sin ID.")
	humo.set("id_instancia", id_humo)

	tablero.queue_free()
	zona.queue_free()
	_finalizar()


func _contiene(errores: Array[String], codigo: String) -> bool:
	for error in errores:
		if error.begins_with(codigo):
			return true
	return false


func _finalizar() -> void:
	if _fallos.is_empty():
		print("ValidadorContenidoZona: 9 grupos correctos.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
