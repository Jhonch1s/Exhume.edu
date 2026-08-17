extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	var coordenada := Vector2i(3, 4)
	tablero.datos[coordenada] = Celda.new()
	var selector := SelectorObjetivosInteraccion.new()

	var objetivo_b := _crear_interactuable(&"objetivo_b")
	var objetivo_a := _crear_interactuable(&"objetivo_a")
	var contenido_no_interactuable := Node.new()
	tablero.datos[coordenada].interactuables.assign([
		objetivo_b,
		contenido_no_interactuable,
		objetivo_a,
	])

	_comprobar(
		selector.obtener_objetivos_perceptibles(tablero, coordenada).is_empty(),
		"Una celda oculta no debe publicar objetivos perceptibles."
	)
	tablero.datos[coordenada].visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	_comprobar(
		selector.obtener_objetivos_perceptibles(tablero, coordenada).is_empty(),
		"Una celda solo explorada no debe publicar objetivos perceptibles."
	)

	tablero.datos[coordenada].visibilidad = Celda.EstadoVisibilidad.VISIBLE
	var objetivos := selector.obtener_objetivos_perceptibles(tablero, coordenada)
	_comprobar(objetivos.size() == 2, "La celda visible debe devolver todos los objetivos válidos.")
	if objetivos.size() == 2:
		_comprobar(
			objetivos[0] == objetivo_a and objetivos[1] == objetivo_b,
			"Los objetivos deben ordenarse por ID estable."
		)
	_comprobar(
		selector.obtener_objetivos_perceptibles(tablero, Vector2i.ZERO).is_empty(),
		"Una coordenada inexistente debe devolver una colección vacía."
	)
	_probar_estado_seleccion(tablero, coordenada, objetivo_a, objetivo_b)

	for contenido in tablero.datos[coordenada].interactuables:
		if contenido is Node:
			contenido.free()
	tablero.free()
	_finalizar()


func _probar_estado_seleccion(
	_tablero: TableroGrid,
	coordenada: Vector2i,
	objetivo_a: Interactuable,
	objetivo_b: Interactuable
) -> void:
	var estado := EstadoSeleccionObjetivos.new()
	var objetivo_unico: Array[Interactuable] = [objetivo_b]
	_comprobar(
		estado.iniciar(coordenada, objetivo_unico),
		"Un clic lógico sobre un objetivo perceptible debe iniciar la selección."
	)
	_comprobar(
		estado.objetivo_seleccionado == objetivo_b,
		"Un único objetivo debe quedar seleccionado."
	)
	var seleccion_congelada: Interactuable = estado.objetivo_seleccionado
	_comprobar(
		estado.objetivo_seleccionado == seleccion_congelada,
		"Consultar una selección debe conservar el objetivo confirmado."
	)

	var objetivos_multiples: Array[Interactuable] = [objetivo_b, objetivo_a]
	_comprobar(
		estado.iniciar(coordenada, objetivos_multiples),
		"Una celda con varios objetivos debe iniciar una selección pendiente."
	)
	_comprobar(
		estado.objetivo_seleccionado == null
		and estado.objetivos_pendientes.size() == 2,
		"Varios objetivos no deben seleccionar automáticamente el primero."
	)
	var objetivo_ajeno := _crear_interactuable(&"ajeno")
	_comprobar(
		not estado.seleccionar(objetivo_ajeno),
		"No debe aceptarse un objetivo ajeno a la selección pendiente."
	)
	objetivo_ajeno.free()
	_comprobar(
		estado.seleccionar(objetivo_a)
		and estado.objetivo_seleccionado == objetivo_a
		and estado.objetivos_pendientes.is_empty(),
		"La selección explícita debe aceptar uno de los objetivos pendientes."
	)
	estado.limpiar()
	_comprobar(
		estado.objetivo_seleccionado == null
		and estado.objetivos_pendientes.is_empty()
		and estado.celda_seleccionada == null,
		"Limpiar debe retirar toda la selección lógica."
	)


func _crear_interactuable(id: StringName) -> Interactuable:
	var interactuable := Interactuable.new()
	interactuable.id_instancia = id
	var definicion := DefinicionInteractuable.new()
	definicion.id_definicion = &"definicion_prueba"
	definicion.nombre = "Objetivo de prueba"
	definicion.perfil_observacion = PerfilObservacion.new()
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = &"identidad"
	fragmento.id_mensaje = &"prueba.identidad"
	definicion.fragmentos_informacion = [fragmento]
	interactuable.definicion = definicion
	return interactuable


func _finalizar() -> void:
	if _fallos.is_empty():
		print("SelectorObjetivosInteraccion: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
