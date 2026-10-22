class_name EquipoActor
extends RefCounted

signal cambiado
var ranuras: Dictionary = {}
const ETIQUETAS := [["cabeza", "casco"], ["amuleto", "collar"], ["pecho", "armadura"], ["arma", "arrojable"], ["escudo", "luz"], ["guantes"], ["botas"], ["anillo"], ["luz"]]


static func compatible(item: ItemInstancia, ranura: int) -> bool:
	if item == null or not item.es_valida() or ranura < 0 or ranura >= ETIQUETAS.size():
		return false
	for etiqueta in ETIQUETAS[ranura]:
		if StringName(etiqueta) in item.definicion.etiquetas:
			return true
	return (ranura == 3 and item.definicion.id_definicion == &"piedra") or (ranura == 8 and item.definicion.id_definicion == &"antorcha")


func equipar(inventario: Inventario, id: StringName, ranura: int) -> StringName:
	var item := inventario.obtener_por_id(id)
	if not compatible(item, ranura):
		return &"equipo_incompatible"
	for equipado: ItemInstancia in ranuras.values():
		if equipado.id_instancia == id:
			return &"item_ya_equipado"
	var anterior: ItemInstancia = ranuras.get(ranura)
	if anterior != null and inventario.obtener_por_id(anterior.id_instancia) != null:
		return &"id_item_duplicado"
	inventario.retirar(id)
	if anterior != null:
		inventario.agregar(anterior)
	ranuras[ranura] = item
	cambiado.emit()
	return &""


func desequipar(inventario: Inventario, ranura: int) -> StringName:
	var item: ItemInstancia = ranuras.get(ranura)
	if item == null:
		return &"ranura_vacia"
	var resultado := inventario.agregar(item)
	if not resultado.exitosa:
		return resultado.motivo
	ranuras.erase(ranura)
	cambiado.emit()
	return &""


func obtener_peso() -> float:
	var peso := 0.0
	for item: ItemInstancia in ranuras.values():
		peso += item.obtener_peso_total()
	return peso


func obtener_estado_persistente() -> Array[Dictionary]:
	var datos: Array[Dictionary] = []
	for ranura: int in ranuras:
		var temporal := Inventario.new()
		temporal.agregar(ranuras[ranura])
		datos.append({"ranura": ranura, "item": temporal.obtener_estado_persistente()[0]})
	return datos


func validar_estado_persistente(datos: Variant, mochila: Array = []) -> StringName:
	if not datos is Array or datos.size() > 9:
		return &"equipo_guardado_invalido"
	var ids: Array = []
	var ocupadas: Array = []
	for item: Dictionary in mochila:
		ids.append(item.get("id"))
	for dato: Variant in datos:
		if not dato is Dictionary or not EfectosEquipo.entero(dato.get("ranura"), 0, 8) or not dato.get("item") is Dictionary:
			return &"equipo_guardado_invalido"
		if ocupadas.has(int(dato.ranura)) or ids.has(dato.item.get("id")):
			return &"equipo_guardado_duplicado"
		var temporal := Inventario.new()
		var motivo := temporal.restaurar_estado_persistente([dato.item])
		if motivo != &"":
			return motivo
		if not compatible(temporal.obtener_contenido()[0], int(dato.ranura)):
			return &"equipo_guardado_incompatible"
		ocupadas.append(int(dato.ranura))
		ids.append(dato.item.id)
	return &""


func restaurar_estado_persistente(datos: Array) -> StringName:
	var motivo := validar_estado_persistente(datos)
	if motivo != &"":
		return motivo
	ranuras.clear()
	for dato: Dictionary in datos:
		var temporal := Inventario.new()
		temporal.restaurar_estado_persistente([dato.item])
		ranuras[int(dato.ranura)] = temporal.obtener_contenido()[0]
	cambiado.emit()
	return &""
