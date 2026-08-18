class_name Inventario
extends RefCounted

var _contenido: Array[ItemInstancia] = []


func obtener_contenido() -> Array[ItemInstancia]:
	return _contenido.duplicate()


func obtener_por_id(id_instancia: StringName) -> ItemInstancia:
	for item in _contenido:
		if item.id_instancia == id_instancia:
			return item
	return null


func obtener_por_definicion(id_definicion: StringName) -> Array[ItemInstancia]:
	var encontrados: Array[ItemInstancia] = []
	for item in _contenido:
		if item.definicion.id_definicion == id_definicion:
			encontrados.append(item)
	return encontrados


func validar_agregado(item: ItemInstancia) -> StringName:
	if item == null or not item.es_valida():
		return &"item_invalido"
	if obtener_por_id(item.id_instancia) != null:
		return &"id_item_duplicado"
	return &""


func agregar(item: ItemInstancia) -> ResultadoOperacionInventario:
	var motivo := validar_agregado(item)
	if motivo != &"":
		return ResultadoOperacionInventario.crear_fallo(motivo)
	_contenido.append(item)
	_ordenar()
	return ResultadoOperacionInventario.crear_exito(
		item,
		item.cantidad,
		&"",
		item.id_instancia
	)


func validar_retiro(
	id_instancia: StringName,
	cantidad: int = -1,
	nuevo_id: StringName = &""
) -> StringName:
	var item := obtener_por_id(id_instancia)
	if item == null:
		return &"item_no_encontrado"
	if cantidad == -1 or cantidad == item.cantidad:
		return &""
	if cantidad <= 0 or cantidad > item.cantidad:
		return &"cantidad_invalida"
	if nuevo_id == &"":
		return &"id_item_nuevo_vacio"
	if obtener_por_id(nuevo_id) != null:
		return &"id_item_duplicado"
	return &""


func retirar(
	id_instancia: StringName,
	cantidad: int = -1,
	nuevo_id: StringName = &""
) -> ResultadoOperacionInventario:
	var motivo := validar_retiro(id_instancia, cantidad, nuevo_id)
	if motivo != &"":
		return ResultadoOperacionInventario.crear_fallo(motivo)
	var item := obtener_por_id(id_instancia)
	if cantidad == -1 or cantidad == item.cantidad:
		_contenido.erase(item)
		return ResultadoOperacionInventario.crear_exito(
			item,
			item.cantidad,
			item.id_instancia
		)

	item._establecer_cantidad(item.cantidad - cantidad)
	var retirado := ItemInstancia.new(nuevo_id, item.definicion, cantidad)
	return ResultadoOperacionInventario.crear_exito(
		retirado,
		cantidad,
		item.id_instancia,
		retirado.id_instancia
	)


func combinar(
	id_origen: StringName,
	id_destino: StringName
) -> ResultadoOperacionInventario:
	var origen := obtener_por_id(id_origen)
	var destino := obtener_por_id(id_destino)
	if origen == null or destino == null:
		return ResultadoOperacionInventario.crear_fallo(&"item_no_encontrado")
	if origen == destino:
		return ResultadoOperacionInventario.crear_fallo(&"pilas_identicas")
	if (
		not origen.definicion.apilable
		or origen.definicion.id_definicion != destino.definicion.id_definicion
	):
		return ResultadoOperacionInventario.crear_fallo(&"pilas_incompatibles")
	if origen.cantidad + destino.cantidad > destino.definicion.cantidad_maxima:
		return ResultadoOperacionInventario.crear_fallo(&"cantidad_maxima_superada")

	var cantidad_movida := origen.cantidad
	destino._establecer_cantidad(destino.cantidad + cantidad_movida)
	_contenido.erase(origen)
	return ResultadoOperacionInventario.crear_exito(
		destino,
		cantidad_movida,
		origen.id_instancia,
		destino.id_instancia
	)


func separar(
	id_origen: StringName,
	cantidad: int,
	nuevo_id: StringName
) -> ResultadoOperacionInventario:
	var origen := obtener_por_id(id_origen)
	if origen == null:
		return ResultadoOperacionInventario.crear_fallo(&"item_no_encontrado")
	if not origen.definicion.apilable:
		return ResultadoOperacionInventario.crear_fallo(&"item_no_apilable")
	if cantidad <= 0 or cantidad >= origen.cantidad:
		return ResultadoOperacionInventario.crear_fallo(&"cantidad_invalida")
	if nuevo_id == &"":
		return ResultadoOperacionInventario.crear_fallo(&"id_item_nuevo_vacio")
	if obtener_por_id(nuevo_id) != null:
		return ResultadoOperacionInventario.crear_fallo(&"id_item_duplicado")

	origen._establecer_cantidad(origen.cantidad - cantidad)
	var separado := ItemInstancia.new(nuevo_id, origen.definicion, cantidad)
	_contenido.append(separado)
	_ordenar()
	return ResultadoOperacionInventario.crear_exito(
		separado,
		cantidad,
		origen.id_instancia,
		separado.id_instancia
	)


func _ordenar() -> void:
	_contenido.sort_custom(func(a: ItemInstancia, b: ItemInstancia):
		return String(a.id_instancia) < String(b.id_instancia)
	)
