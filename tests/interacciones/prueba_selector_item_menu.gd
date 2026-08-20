extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var actor := Ficha.new()
	var item_b := _crear_item(&"item_b", "Martillo", 1)
	var item_a := _crear_item(&"item_a", "Clavos", 3)
	actor.inventario.agregar(item_b)
	actor.inventario.agregar(item_a)
	var objetivo := Interactuable.new()
	objetivo.id_instancia = &"mecanismo_prueba"
	objetivo.definicion = DefinicionInteractuable.new()
	objetivo.definicion.id_definicion = &"mecanismo"
	objetivo.definicion.nombre = "Mecanismo"

	var opciones := objetivo.obtener_opciones_accion(actor)
	_comprobar(
		opciones.size() == 1
		and opciones[0].tipo == TiposInteraccion.TipoAccion.USAR_ITEM,
		"Un objetivo debe ofrecer Usar item cuando el actor tiene inventario."
	)
	var catalogo := load(
		"res://assets/interactuables/mensajes_interacciones.tres"
	) as CatalogoMensajesInteraccion
	var entradas := AdaptadorMenuContextual.new().construir_entradas_items(
		actor.inventario.obtener_contenido(), catalogo
	)
	_comprobar(
		entradas.size() == 3
		and entradas[0].item == item_a
		and entradas[0].texto == "Clavos ×3"
		and entradas[1].item == item_b
		and entradas[2].tipo == EntradaMenuContextual.TipoEntrada.CANCELAR,
		"El selector debe reutilizar el orden del inventario, mostrar cantidad y Cancelar."
	)

	var escena := load(
		"res://scenes/ui/interacciones/menu_contextual_interacciones.tscn"
	) as PackedScene
	var menu := escena.instantiate() as MenuContextualInteracciones
	root.add_child(menu)
	await process_frame
	var elegido: Array[ItemInstancia] = []
	menu.item_elegido.connect(func(item: ItemInstancia): elegido.append(item))
	menu.mostrar("¿Qué item quieres usar?", entradas, Vector2.ZERO)
	menu.obtener_botones()[0].pressed.emit()
	_comprobar(
		elegido == [item_a],
		"El menú debe devolver la misma instancia seleccionada sin resolverla."
	)
	menu.ocultar()
	menu.free()
	actor.free()
	objetivo.free()
	_finalizar()


func _crear_item(id: StringName, nombre: String, cantidad: int) -> ItemInstancia:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = StringName("def_%s" % id)
	definicion.nombre = nombre
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	return ItemInstancia.new(id, definicion, cantidad)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("SelectorItemMenu: 3 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
