extends SceneTree

class ReceptorImpactoPrueba extends RefCounted:
	var id: StringName
	var coordenada: Vector2i
	var destino: TiposInteraccion.DestinoItem
	var solo_directo: bool
	var resoluciones: int = 0
	var ultimo_contexto: ContextoAccion

	func _init(
		id_inicial: StringName,
		coordenada_inicial: Vector2i,
		destino_inicial: TiposInteraccion.DestinoItem,
		solo_directo_inicial: bool = true
	) -> void:
		id = id_inicial
		coordenada = coordenada_inicial
		destino = destino_inicial
		solo_directo = solo_directo_inicial

	func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
		return tipo == TiposInteraccion.TipoAccion.IMPACTAR

	func obtener_id_reaccion() -> StringName:
		return id

	func obtener_coordenada_reaccion() -> Vector2i:
		return coordenada

	func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
		return 0

	func validar_accion(contexto: ContextoAccion) -> StringName:
		if contexto.tipo != TiposInteraccion.TipoAccion.IMPACTAR:
			return &"accion_no_admitida"
		if solo_directo and contexto.objetivo_impacto != self:
			return &"impacto_no_dirigido"
		if (
			contexto.item == null
			or &"impacto" not in contexto.etiquetas
			or contexto.cantidad_item != 1
		):
			return &"impacto_incoherente"
		return &""

	func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
		var motivo := validar_accion(contexto)
		if motivo != &"":
			return ResultadoAccion.crear_bloqueo(motivo)
		resoluciones += 1
		ultimo_contexto = contexto
		return ResultadoAccion.crear_exito(
			[&"impacto.resuelto"], [], [], {}, false, false, [], destino
		)


class TableroRegistroFallido extends TableroGrid:
	func registrar_item_suelo(_coord: Vector2i, _item_suelo: ItemSuelo) -> bool:
		return false


var _fallos: Array[String] = []


func _init() -> void:
	_probar_caida_en_piso_con_objetivo_disponible()
	_probar_objetivo_elegido_y_consumo()
	_probar_conservacion()
	_probar_bloqueo_y_rollback()
	_probar_primera_colision()
	_probar_alcance_diagonal()

	if _fallos.is_empty():
		print("LanzarItemLogico: 6 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_caida_en_piso_con_objetivo_disponible() -> void:
	var entorno := _crear_entorno()
	var receptor := ReceptorImpactoPrueba.new(
		&"absorbedor", Vector2i.RIGHT, TiposInteraccion.DestinoItem.CONSUMIR
	)
	entorno.tablero.obtener_celda(Vector2i.RIGHT).interactuables.append(receptor)
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_lanzar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i.RIGHT,
		&"piedra_lanzada"
	)
	var resultado: ResultadoAccion = entorno.gestor.procesar_accion(contexto)
	var suelo: ItemSuelo = entorno.tablero.obtener_item_suelo(&"piedra_lanzada")
	_comprobar(
		resultado.exitosa
		and resultado.destino_item == TiposInteraccion.DestinoItem.DEJAR_EN_CELDA
		and receptor.resoluciones == 0,
		"Elegir el piso debe omitir el impacto directo y dejar caer la unidad."
	)
	_comprobar(
		entorno.item.cantidad == 2
		and suelo != null
		and suelo.item.cantidad == 1
		and suelo.item.id_instancia == &"piedra_lanzada",
		"La pila origen debe conservar identidad y la unidad caída debe recibir otra."
	)
	_liberar(entorno)


func _probar_objetivo_elegido_y_consumo() -> void:
	var entorno := _crear_entorno()
	var posterior := ReceptorImpactoPrueba.new(
		&"a_conserva",
		Vector2i.RIGHT,
		TiposInteraccion.DestinoItem.CONSERVAR_EN_INVENTARIO,
		false
	)
	var elegido := ReceptorImpactoPrueba.new(
		&"z_consume", Vector2i.RIGHT, TiposInteraccion.DestinoItem.CONSUMIR
	)
	entorno.tablero.obtener_celda(Vector2i.RIGHT).interactuables.assign([
		posterior, elegido
	])
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_lanzar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i.RIGHT,
		&"piedra_consumida",
		elegido
	)
	var resultado: ResultadoAccion = entorno.gestor.procesar_accion(contexto)
	_comprobar(
		resultado.exitosa
		and resultado.destino_item == TiposInteraccion.DestinoItem.CONSUMIR
		and elegido.resoluciones == 1
		and posterior.resoluciones == 1,
		"El objetivo elegido debe resolverse primero y fijar el primer destino explícito."
	)
	_comprobar(
		entorno.item.cantidad == 2 and entorno.tablero.items_suelo_por_id.is_empty(),
		"Consumir debe retirar una unidad sin crear ItemSuelo."
	)
	_liberar(entorno)


func _probar_conservacion() -> void:
	var entorno := _crear_entorno()
	var receptor := ReceptorImpactoPrueba.new(
		&"devuelve",
		Vector2i.RIGHT,
		TiposInteraccion.DestinoItem.CONSERVAR_EN_INVENTARIO
	)
	entorno.tablero.obtener_celda(Vector2i.RIGHT).interactuables.append(receptor)
	var resultado: ResultadoAccion = entorno.gestor.procesar_accion(
		entorno.transferidor.construir_contexto_lanzar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			Vector2i.RIGHT,
			&"piedra_no_usada",
			receptor
		)
	)
	_comprobar(
		resultado.exitosa
		and resultado.destino_item == TiposInteraccion.DestinoItem.CONSERVAR_EN_INVENTARIO
		and entorno.item.cantidad == 3
		and entorno.ficha.inventario.obtener_por_id(entorno.item.id_instancia) == entorno.item,
		"Conservar debe dejar intactas referencia, ID y cantidad."
	)
	_liberar(entorno)


func _probar_bloqueo_y_rollback() -> void:
	var entorno := _crear_entorno()
	entorno.item.definicion.etiquetas.erase(&"arrojable")
	var bloqueado: ResultadoAccion = entorno.gestor.procesar_accion(
		entorno.transferidor.construir_contexto_lanzar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			Vector2i.RIGHT,
			&"piedra_bloqueada"
		)
	)
	_comprobar(
		bloqueado.motivo == &"item_no_arrojable" and entorno.item.cantidad == 3,
		"Un bloqueo previo no debe modificar el inventario."
	)
	_liberar(entorno)

	entorno = _crear_entorno()
	entorno.item.definicion.reaccion_impacto = ReaccionImpactoSuperficie.new()
	bloqueado = entorno.gestor.procesar_accion(
		entorno.transferidor.construir_contexto_lanzar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			Vector2i.RIGHT,
			&"piedra_reaccion_invalida"
		)
	)
	_comprobar(
		bloqueado.motivo == &"reaccion_impacto_item_no_configurada"
		and entorno.item.cantidad == 3
		and entorno.tablero.efectos_superficie_por_id.is_empty(),
		"Una reacción propia inválida debe bloquear antes de modificar mundo o inventario."
	)
	_liberar(entorno)

	var tablero_fallido := TableroRegistroFallido.new()
	entorno = _crear_entorno(tablero_fallido)
	var fallido: ResultadoAccion = entorno.gestor.procesar_accion(
		entorno.transferidor.construir_contexto_lanzar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			Vector2i.RIGHT,
			&"piedra_fallida"
		)
	)
	_comprobar(
		fallido.motivo == &"registro_item_suelo_fallido"
		and entorno.item.cantidad == 3
		and entorno.ficha.inventario.obtener_contenido() == [entorno.item],
		"El fallo al colocar debe recomponer exactamente la pila original."
	)
	_liberar(entorno)


func _probar_primera_colision() -> void:
	var entorno := _crear_entorno()
	entorno.tablero.obtener_celda(Vector2i.RIGHT).altura = 2
	var resultado: ResultadoAccion = entorno.gestor.procesar_accion(
		entorno.transferidor.construir_contexto_lanzar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			Vector2i(2, 0),
			&"piedra_colision"
		)
	)
	var suelo: ItemSuelo = entorno.tablero.obtener_item_suelo(&"piedra_colision")
	_comprobar(
		resultado.exitosa
		and suelo != null
		and suelo.coordenada_mapa == Vector2i.ZERO
		and resultado.cambios_estado[-1][&"coordenada_impacto"] == Vector2i.RIGHT
		and resultado.cambios_estado[-1][&"hubo_colision"],
		"El obstáculo intermedio debe recibir el impacto y la unidad caer en la celda anterior."
	)
	_liberar(entorno)


func _probar_alcance_diagonal() -> void:
	var entorno := _crear_entorno()
	var destino := Vector2i(10, 10)
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_lanzar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		destino,
		&"piedra_diagonal"
	)
	var resultado: ResultadoAccion = entorno.gestor.procesar_accion(
		contexto
	)
	var suelo: ItemSuelo = entorno.tablero.obtener_item_suelo(&"piedra_diagonal")
	_comprobar(
		contexto.alcance_maximo == 10.0
		and resultado.exitosa
		and suelo != null
		and suelo.coordenada_mapa == destino,
		"FUE tres debe permitir diez celdas diagonales o rectas."
	)
	_liberar(entorno)

	entorno = _crear_entorno()
	entorno.ficha.fue = 0
	contexto = entorno.transferidor.construir_contexto_lanzar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i(7, 7),
		&"piedra_alcance_minimo"
	)
	resultado = entorno.gestor.procesar_accion(contexto)
	_comprobar(
		contexto.alcance_maximo == 7.0 and resultado.exitosa,
		"Un actor con fuerza cero debe conservar siete celdas base."
	)
	_liberar(entorno)


func _crear_entorno(tablero_inicial: TableroGrid = null) -> Dictionary:
	var tablero := tablero_inicial if tablero_inicial != null else TableroGrid.new()
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.datos[Vector2i.RIGHT] = Celda.new()
	tablero.datos[Vector2i(2, 0)] = Celda.new()
	for paso in range(1, 13):
		tablero.datos[Vector2i(paso, paso)] = Celda.new()
	var ficha := Ficha.new()
	ficha.coordenada_mapa = Vector2i.ZERO
	tablero.datos[Vector2i.ZERO].ocupantes.append(ficha)
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"piedra"
	definicion.nombre = "Piedra"
	definicion.etiquetas = [&"solido", &"contundente", &"arrojable"]
	definicion.magnitudes = {&"peso": 3.0}
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	var item := ItemInstancia.new(&"piedras", definicion, 3)
	ficha.inventario.agregar(item)
	var gestor := GestorAcciones.new()
	var transferidor := TransferidorItems.new(tablero, gestor)
	tablero.configurar_transferidor_items(transferidor)
	return {
		&"tablero": tablero,
		&"ficha": ficha,
		&"item": item,
		&"gestor": gestor,
		&"transferidor": transferidor,
	}


func _liberar(entorno: Dictionary) -> void:
	var tablero := entorno.tablero as TableroGrid
	for celda in tablero.datos.values():
		for interactuable in celda.interactuables:
			if interactuable is ReceptorImpactoPrueba:
				interactuable.ultimo_contexto = null
		celda.interactuables.clear()
	for item_suelo in tablero.items_suelo_por_id.values():
		item_suelo.configurar_transferidor_items(null)
	tablero._limpiar_items_suelo()
	(entorno.ficha as Ficha).free()
	(entorno.gestor as GestorAcciones).free()
	tablero.free()
	entorno.clear()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
