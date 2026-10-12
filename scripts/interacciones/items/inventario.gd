class_name Inventario
extends RefCounted

var _contenido: Array[ItemInstancia] = []
var capacidad: int = -1


func obtener_estado_persistente() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in _contenido:
		items.append({
			"id": String(item.id_instancia),
			"definicion_id": String(item.definicion.id_definicion),
			"definicion_path": item.definicion.resource_path,
			"cantidad": item.cantidad,
		})
	return items


func validar_estado_persistente(datos: Variant) -> StringName:
	if not datos is Array:
		return &"inventario_guardado_invalido"
	if capacidad >= 0 and datos.size() > capacidad:
		return &"inventario_guardado_excede_capacidad"
	var ids: Dictionary[String, bool] = {}
	for entrada: Variant in datos:
		if not entrada is Dictionary:
			return &"inventario_guardado_invalido"
		var id_item: Variant = entrada.get("id")
		var id_definicion: Variant = entrada.get("definicion_id")
		var ruta: Variant = entrada.get("definicion_path")
		var cantidad: Variant = entrada.get("cantidad")
		if (
			not id_item is String or id_item.is_empty() or ids.has(id_item)
			or not id_definicion is String or id_definicion.is_empty()
			or not ruta is String or not ruta.begins_with("res://")
			or not ResourceLoader.exists(ruta)
			or not (cantidad is int or (cantidad is float and is_finite(cantidad) and cantidad == roundf(cantidad)))
		):
			return &"inventario_guardado_invalido"
		var perfil := ResourceLoader.load(ruta) as DefinicionItem
		var item := ItemInstancia.new(StringName(id_item), perfil, int(cantidad))
		if perfil == null or String(perfil.id_definicion) != id_definicion or not item.es_valida():
			return &"definicion_item_guardada_invalida"
		ids[id_item] = true
	return &""


func restaurar_estado_persistente(datos: Variant) -> StringName:
	var motivo := validar_estado_persistente(datos)
	if motivo != &"":
		return motivo
	var preparado: Array[ItemInstancia] = []
	for entrada: Dictionary in datos:
		preparado.append(ItemInstancia.new(
			StringName(entrada["id"]),
			ResourceLoader.load(entrada["definicion_path"]) as DefinicionItem,
			int(entrada["cantidad"])
		))
	_contenido = preparado
	_ordenar()
	return &""


func obtener_contenido() -> Array[ItemInstancia]:
	return _contenido.duplicate()	


func obtener_por_id(id_instancia: StringName) -> ItemInstancia:
	for item in _contenido:
		if item.id_instancia == id_instancia:
			return item
	return null

func esta_lleno() -> bool:
	return capacidad >= 0 and _contenido.size() >= capacidad

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
		
	if esta_lleno():
		return &"inventario_lleno"
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


func consumir_unidad(id_instancia: StringName) -> bool:
	var item := obtener_por_id(id_instancia)
	if item == null:
		return false
	if item.cantidad == 1:
		_contenido.erase(item)
	else:
		item._establecer_cantidad(item.cantidad - 1)
	return true


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
	if esta_lleno():
		return ResultadoOperacionInventario.crear_fallo(&"inventario_lleno") ##basta de tantos mensajes loko
	

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
	
func transferir_a(
	destino: Inventario,
	id_item: StringName
) -> ResultadoOperacionInventario:
	if destino == null or destino == self:
		return ResultadoOperacionInventario.crear_fallo(
			&"inventario_destino_invalido"
		)

	var item := obtener_por_id(id_item)
	if item == null:
		return ResultadoOperacionInventario.crear_fallo(&"item_no_encontrado")

	var resultado := destino.agregar(item)
	if resultado.exitosa:
		_contenido.erase(item)

	return resultado
