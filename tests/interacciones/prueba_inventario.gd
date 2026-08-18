extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_contratos_basicos()
	_probar_agregado_consulta_y_retiro()
	_probar_combinacion_explicita()
	_probar_separacion_y_retiro_parcial()
	_probar_fallos_atomicos()
	_probar_inventario_de_ficha()

	if _fallos.is_empty():
		print("Inventario: 6 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_contratos_basicos() -> void:
	var piedras := _crear_definicion(&"piedra", true, 10)
	_comprobar(piedras.es_valida(), "Una definición mínima completa debe ser válida.")
	_comprobar(
		ItemInstancia.new(&"piedras_a", piedras, 10).es_valida(),
		"Una pila dentro del máximo debe ser válida."
	)
	_comprobar(
		not ItemInstancia.new(&"", piedras, 1).es_valida(),
		"Una instancia sin ID debe ser inválida."
	)
	_comprobar(
		not ItemInstancia.new(&"piedras_b", piedras, 0).es_valida(),
		"Una cantidad cero debe ser inválida."
	)
	var espada := _crear_definicion(&"espada", false, 1)
	_comprobar(
		not ItemInstancia.new(&"espada_a", espada, 2).es_valida(),
		"Un item no apilable no debe admitir varias unidades."
	)
	piedras.etiquetas = [&"solido", &"solido"]
	_comprobar(not piedras.es_valida(), "Las etiquetas duplicadas deben rechazarse.")


func _probar_agregado_consulta_y_retiro() -> void:
	var inventario := Inventario.new()
	var piedras := _crear_definicion(&"piedra", true, 10)
	var b := ItemInstancia.new(&"piedras_b", piedras, 2)
	var a := ItemInstancia.new(&"piedras_a", piedras, 3)
	_comprobar(inventario.agregar(b).exitosa, "Debe agregar una instancia válida.")
	_comprobar(inventario.agregar(a).exitosa, "Debe admitir otra pila sin combinarla.")
	_comprobar(
		inventario.obtener_contenido() == [a, b],
		"El contenido debe ordenarse por ID sin apilar automáticamente."
	)
	_comprobar(
		inventario.obtener_por_definicion(&"piedra") == [a, b],
		"La búsqueda por definición debe conservar el orden determinista."
	)
	var copia := inventario.obtener_contenido()
	copia.clear()
	_comprobar(
		inventario.obtener_contenido().size() == 2,
		"Consultar el contenido debe devolver una copia defensiva."
	)
	var retirado := inventario.retirar(&"piedras_a")
	_comprobar(
		retirado.exitosa and retirado.item == a and retirado.cantidad == 3,
		"Retirar toda una pila debe conservar su referencia, ID y cantidad."
	)
	_comprobar(
		inventario.obtener_por_id(&"piedras_a") == null,
		"La pila retirada no debe permanecer en el inventario."
	)


func _probar_combinacion_explicita() -> void:
	var inventario := Inventario.new()
	var piedras := _crear_definicion(&"piedra", true, 10)
	var origen := ItemInstancia.new(&"piedras_origen", piedras, 3)
	var destino := ItemInstancia.new(&"piedras_destino", piedras, 4)
	inventario.agregar(origen)
	inventario.agregar(destino)
	var resultado := inventario.combinar(origen.id_instancia, destino.id_instancia)
	_comprobar(resultado.exitosa, "Dos pilas compatibles deben combinarse explícitamente.")
	_comprobar(
		resultado.item == destino
		and resultado.cantidad == 3
		and resultado.id_origen == &"piedras_origen"
		and resultado.id_destino == &"piedras_destino",
		"El resultado debe describir exactamente la combinación."
	)
	_comprobar(destino.cantidad == 7, "La pila destino debe recibir la cantidad completa.")
	_comprobar(
		inventario.obtener_por_id(&"piedras_origen") == null,
		"La identidad de la pila absorbida debe retirarse."
	)


func _probar_separacion_y_retiro_parcial() -> void:
	var inventario := Inventario.new()
	var piedras := _crear_definicion(&"piedra", true, 10)
	var original := ItemInstancia.new(&"piedras_original", piedras, 8)
	inventario.agregar(original)
	var separacion := inventario.separar(&"piedras_original", 3, &"piedras_separadas")
	_comprobar(
		separacion.exitosa
		and original.cantidad == 5
		and separacion.item.cantidad == 3,
		"Separar debe conservar el ID original y crear la cantidad solicitada."
	)
	var retiro := inventario.retirar(&"piedras_original", 2, &"piedras_retiradas")
	_comprobar(
		retiro.exitosa
		and original.cantidad == 3
		and retiro.item.id_instancia == &"piedras_retiradas"
		and retiro.item.cantidad == 2,
		"El retiro parcial debe producir una instancia separada y determinista."
	)
	_comprobar(
		inventario.obtener_por_id(&"piedras_retiradas") == null,
		"La porción retirada no debe quedar dentro del inventario."
	)


func _probar_fallos_atomicos() -> void:
	var inventario := Inventario.new()
	var piedras := _crear_definicion(&"piedra", true, 5)
	var piedras_a := ItemInstancia.new(&"piedras_a", piedras, 4)
	var piedras_b := ItemInstancia.new(&"piedras_b", piedras, 2)
	var espada := ItemInstancia.new(
		&"espada",
		_crear_definicion(&"espada", false, 1)
	)
	inventario.agregar(piedras_a)
	inventario.agregar(piedras_b)
	inventario.agregar(espada)

	_comprobar(
		inventario.agregar(ItemInstancia.new(&"piedras_a", piedras, 1)).motivo
		== &"id_item_duplicado",
		"Agregar un ID duplicado debe bloquearse."
	)
	_comprobar(
		inventario.combinar(&"piedras_a", &"piedras_b").motivo
		== &"cantidad_maxima_superada",
		"Combinar por encima del máximo debe fallar por completo."
	)
	_comprobar(
		inventario.combinar(&"espada", &"piedras_b").motivo == &"pilas_incompatibles",
		"Instancias incompatibles no deben combinarse."
	)
	_comprobar(
		inventario.separar(&"piedras_a", 0, &"nueva").motivo == &"cantidad_invalida"
		and inventario.separar(&"piedras_a", 4, &"nueva").motivo == &"cantidad_invalida"
		and inventario.retirar(&"piedras_a", 2, &"piedras_b").motivo
		== &"id_item_duplicado",
		"Cantidades inválidas e IDs nuevos duplicados deben rechazarse."
	)
	_comprobar(
		piedras_a.cantidad == 4
		and piedras_b.cantidad == 2
		and inventario.obtener_contenido().size() == 3,
		"Todos los fallos deben dejar contenido y cantidades intactos."
	)


func _probar_inventario_de_ficha() -> void:
	var ficha := Ficha.new()
	_comprobar(ficha.inventario != null, "Cada ficha debe contener un inventario lógico.")
	ficha.free()


func _crear_definicion(
	id_definicion: StringName,
	apilable: bool,
	cantidad_maxima: int
) -> DefinicionItem:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = id_definicion
	definicion.nombre = String(id_definicion).capitalize()
	definicion.etiquetas = [&"solido"]
	definicion.apilable = apilable
	definicion.cantidad_maxima = cantidad_maxima
	return definicion


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
