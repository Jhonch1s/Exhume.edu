extends SceneTree

class ReceptorUsoItemPrueba extends Interactuable:
	var usos: int = 0

	func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
		var motivo := super.validar_accion(contexto)
		if motivo != &"":
			return ResultadoAccion.crear_bloqueo(motivo)
		if &"herramienta" not in contexto.etiquetas or contexto.magnitudes.get(&"potencia") != 2.0:
			return ResultadoAccion.crear_fallo(&"capacidades_insuficientes")
		usos += 1
		return ResultadoAccion.crear_exito(
			[&"item.usado"],
			[],
			[{&"tipo": &"mecanismo_activado"}]
		)


var _fallos: Array[String] = []


func _init() -> void:
	_probar_uso_logico()
	_probar_revalidacion_de_propiedad()
	_probar_contexto_incoherente()

	if _fallos.is_empty():
		print("UsarItemContexto: 3 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_uso_logico() -> void:
	var entorno := _crear_entorno()
	var contexto: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
		entorno.opcion,
		entorno.actor,
		Vector2i.ZERO,
		Vector2i.RIGHT,
		entorno.item
	)
	_comprobar(
		contexto is ContextoAccion
		and contexto.tipo == TiposInteraccion.TipoAccion.USAR_ITEM
		and contexto.item == entorno.item
		and contexto.etiquetas == [&"herramienta"]
		and contexto.magnitudes == {&"potencia": 2.0}
		and contexto.alcance_maximo == 1.0
		and contexto.cantidad_item == 1,
		"El constructor debe transportar la instancia y sus capacidades."
	)
	var resultado := _procesar(contexto)
	_comprobar(
		resultado.exitosa and entorno.receptor.usos == 1,
		"GestorAcciones debe resolver USAR_ITEM sin conocer la combinación."
	)
	_comprobar(
		entorno.actor.inventario.obtener_por_id(entorno.item.id_instancia) == entorno.item
		and entorno.item.cantidad == 3,
		"8.1 debe conservar la pila y su cantidad."
	)
	_liberar(entorno)


func _probar_revalidacion_de_propiedad() -> void:
	var entorno := _crear_entorno()
	var contexto: ContextoAccion = ConstructorContextoAccion.new().construir_desde_opcion(
		entorno.opcion,
		entorno.actor,
		Vector2i.ZERO,
		Vector2i.RIGHT,
		entorno.item
	)
	entorno.actor.inventario.retirar(entorno.item.id_instancia)
	var resultado := _procesar(contexto)
	_comprobar(
		resultado.motivo == &"item_no_pertenece_inventario" and entorno.receptor.usos == 0,
		"La propiedad debe revalidarse inmediatamente antes de resolver."
	)
	_liberar(entorno)


func _probar_contexto_incoherente() -> void:
	var entorno := _crear_entorno()
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.USAR_ITEM,
		entorno.actor,
		Vector2i.ZERO,
		Vector2i.RIGHT,
		entorno.receptor,
		entorno.item,
		&"",
		[&"llave"],
		{&"potencia": 2.0},
		1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		null,
		&"",
		1
	)
	var resultado := _procesar(contexto)
	_comprobar(
		resultado.motivo == &"capacidades_item_incoherentes" and entorno.receptor.usos == 0,
		"El receptor debe rechazar capacidades distintas de la definición."
	)
	_liberar(entorno)


func _crear_entorno() -> Dictionary:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"herramienta_prueba"
	definicion.nombre = "Herramienta de prueba"
	definicion.etiquetas = [&"herramienta"]
	definicion.magnitudes = {&"potencia": 2.0}
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	var item := ItemInstancia.new(&"herramientas_prueba", definicion, 3)
	var actor := Ficha.new()
	actor.inventario.agregar(item)
	var receptor := ReceptorUsoItemPrueba.new()
	receptor.id_instancia = &"mecanismo_prueba"
	receptor.coordenada_mapa = Vector2i.RIGHT
	var opcion := OpcionAccion.crear_habilitada(
		&"usar_item",
		TiposInteraccion.TipoAccion.USAR_ITEM,
		&"interaccion.usar_item",
		receptor
	)
	return {
		&"actor": actor,
		&"item": item,
		&"receptor": receptor,
		&"opcion": opcion,
	}


func _procesar(contexto: ContextoAccion) -> ResultadoAccion:
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _liberar(entorno: Dictionary) -> void:
	(entorno.actor as Ficha).free()
	(entorno.receptor as ReceptorUsoItemPrueba).free()
	entorno.clear()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
