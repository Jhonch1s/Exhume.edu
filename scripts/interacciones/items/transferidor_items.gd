class_name TransferidorItems
extends RefCounted

var tablero: TableroGrid


func _init(tablero_inicial: TableroGrid) -> void:
	tablero = tablero_inicial


func construir_contexto_recoger(
	actor: Object,
	item_suelo: ItemSuelo,
	origen: Vector2i,
	cantidad: int = -1,
	id_resultante: StringName = &""
) -> ContextoAccion:
	var destino: Variant = item_suelo.coordenada_mapa if item_suelo != null else null
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.RECOGER,
		actor,
		origen,
		destino,
		item_suelo,
		item_suelo.item if item_suelo != null else null,
		&"",
		[],
		{},
		1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		null,
		&"",
		cantidad,
		id_resultante
	)


func validar_recoger(contexto: ContextoAccion) -> StringName:
	if (
		contexto == null
		or contexto.tipo != TiposInteraccion.TipoAccion.RECOGER
		or not contexto.objetivo is ItemSuelo
	):
		return &"contexto_recoger_invalido"
	var item_suelo := contexto.objetivo as ItemSuelo
	if contexto.item != item_suelo.item:
		return &"item_contexto_incoherente"
	if contexto.actor == null or not contexto.actor.has_method(&"obtener_inventario"):
		return &"actor_sin_inventario"
	var inventario: Variant = contexto.actor.call(&"obtener_inventario")
	if not inventario is Inventario:
		return &"actor_sin_inventario"
	if tablero == null or tablero.validar_retiro_item_suelo(item_suelo) != &"":
		return &"item_suelo_no_registrado"
	var motivo_cantidad := _validar_cantidad_transferencia(
		item_suelo.item,
		contexto.cantidad_item,
		contexto.id_item_resultante
	)
	if motivo_cantidad != &"":
		return motivo_cantidad
	if contexto.cantidad_item == -1 or contexto.cantidad_item == item_suelo.item.cantidad:
		return inventario.validar_agregado(item_suelo.item)
	if tablero.items_suelo_por_id.has(contexto.id_item_resultante):
		return &"id_item_duplicado"
	var parcial := ItemInstancia.new(
		contexto.id_item_resultante,
		item_suelo.item.definicion,
		contexto.cantidad_item
	)
	return inventario.validar_agregado(parcial)


func recoger(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_recoger(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var item_suelo := contexto.objetivo as ItemSuelo
	var inventario := contexto.actor.call(&"obtener_inventario") as Inventario
	var coordenada: Vector2i = item_suelo.coordenada_mapa
	if contexto.cantidad_item != -1 and contexto.cantidad_item < item_suelo.item.cantidad:
		return _recoger_parcial(contexto, item_suelo, inventario, coordenada)
	var agregado := inventario.agregar(item_suelo.item)
	if not agregado.exitosa:
		return ResultadoAccion.crear_fallo(agregado.motivo)
	if not tablero.retirar_item_suelo(item_suelo):
		var rollback := inventario.retirar(item_suelo.item.id_instancia)
		if not rollback.exitosa or rollback.item != item_suelo.item:
			return ResultadoAccion.crear_fallo(&"rollback_inventario_fallido")
		return ResultadoAccion.crear_fallo(&"retiro_item_suelo_fallido")

	var cambios: Array[Dictionary] = [{
		&"tipo": &"item_recogido",
		&"id_instancia": item_suelo.item.id_instancia,
		&"id_definicion": item_suelo.item.definicion.id_definicion,
		&"cantidad": item_suelo.item.cantidad,
		&"coordenada_origen": coordenada,
	}]
	return ResultadoAccion.crear_exito([&"item.recogido"], [], cambios)


func construir_contexto_soltar(
	actor: Object,
	item: ItemInstancia,
	origen: Vector2i,
	destino: Vector2i,
	cantidad: int = -1,
	id_resultante: StringName = &""
) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.SOLTAR,
		actor,
		origen,
		destino,
		self,
		item,
		&"",
		[],
		{},
		1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		null,
		&"",
		cantidad,
		id_resultante
	)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.SOLTAR:
		return &"accion_no_admitida"
	if contexto.objetivo != self or not contexto.item is ItemInstancia:
		return &"contexto_soltar_invalido"
	if contexto.actor == null or not contexto.actor.has_method(&"obtener_inventario"):
		return &"actor_sin_inventario"
	var inventario: Variant = contexto.actor.call(&"obtener_inventario")
	if not inventario is Inventario:
		return &"actor_sin_inventario"
	var inventario_tipado := inventario as Inventario
	var item := contexto.item as ItemInstancia
	if inventario_tipado.obtener_por_id(item.id_instancia) != item:
		return &"item_no_pertenece_inventario"
	var motivo_cantidad := _validar_cantidad_transferencia(
		item,
		contexto.cantidad_item,
		contexto.id_item_resultante
	)
	if motivo_cantidad != &"":
		return motivo_cantidad
	var motivo_retiro := inventario_tipado.validar_retiro(
		item.id_instancia,
		contexto.cantidad_item,
		contexto.id_item_resultante
	)
	if motivo_retiro != &"":
		return motivo_retiro
	if not contexto.tiene_celda_objetivo() or tablero == null:
		return &"celda_objetivo_invalida"
	var id_suelo := (
		item.id_instancia
		if contexto.cantidad_item == -1 or contexto.cantidad_item == item.cantidad
		else contexto.id_item_resultante
	)
	if tablero.items_suelo_por_id.has(id_suelo):
		return &"id_item_duplicado"
	return tablero.validar_colocacion_item_suelo(contexto.celda_objetivo, contexto.actor)


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var inventario := contexto.actor.call(&"obtener_inventario") as Inventario
	var item := contexto.item as ItemInstancia
	var retiro_total := (
		contexto.cantidad_item == -1 or contexto.cantidad_item == item.cantidad
	)
	var retirado := inventario.retirar(
		item.id_instancia,
		contexto.cantidad_item,
		contexto.id_item_resultante
	)
	if (
		not retirado.exitosa
		or (retiro_total and retirado.item != item)
		or (
			not retiro_total
			and (
				retirado.item == item
				or retirado.item.id_instancia != contexto.id_item_resultante
				or retirado.item.cantidad != contexto.cantidad_item
			)
		)
	):
		return ResultadoAccion.crear_fallo(&"retiro_inventario_fallido")

	var item_suelo := ItemSuelo.new(retirado.item)
	item_suelo.configurar_transferidor_items(self)
	if not tablero.registrar_item_suelo(contexto.celda_objetivo, item_suelo):
		if not _revertir_retiro(inventario, item, retirado.item):
			return ResultadoAccion.crear_fallo(&"rollback_inventario_fallido")
		return ResultadoAccion.crear_fallo(&"registro_item_suelo_fallido")

	var cambios: Array[Dictionary] = [{
		&"tipo": &"item_soltado",
		&"id_instancia": retirado.item.id_instancia,
		&"id_origen": item.id_instancia,
		&"id_definicion": item.definicion.id_definicion,
		&"cantidad": retirado.item.cantidad,
		&"coordenada_destino": contexto.celda_objetivo,
	}]
	return ResultadoAccion.crear_exito([&"item.soltado"], [], cambios)


func _recoger_parcial(
	contexto: ContextoAccion,
	item_suelo: ItemSuelo,
	inventario: Inventario,
	coordenada: Vector2i
) -> ResultadoAccion:
	var parcial := ItemInstancia.new(
		contexto.id_item_resultante,
		item_suelo.item.definicion,
		contexto.cantidad_item
	)
	var agregado := inventario.agregar(parcial)
	if not agregado.exitosa:
		return ResultadoAccion.crear_fallo(agregado.motivo)
	item_suelo.item._establecer_cantidad(
		item_suelo.item.cantidad - contexto.cantidad_item
	)
	var cambios: Array[Dictionary] = [{
		&"tipo": &"item_recogido",
		&"id_instancia": parcial.id_instancia,
		&"id_origen": item_suelo.item.id_instancia,
		&"id_definicion": parcial.definicion.id_definicion,
		&"cantidad": parcial.cantidad,
		&"coordenada_origen": coordenada,
	}]
	return ResultadoAccion.crear_exito([&"item.recogido"], [], cambios)


func _validar_cantidad_transferencia(
	item: ItemInstancia,
	cantidad: int,
	id_resultante: StringName
) -> StringName:
	if cantidad == -1 or cantidad == item.cantidad:
		return &"" if id_resultante == &"" else &"id_item_resultante_inesperado"
	if cantidad <= 0 or cantidad > item.cantidad:
		return &"cantidad_invalida"
	if not item.definicion.apilable:
		return &"item_no_apilable"
	if id_resultante == &"":
		return &"id_item_nuevo_vacio"
	if id_resultante == item.id_instancia:
		return &"id_item_duplicado"
	return &""


func _revertir_retiro(
	inventario: Inventario,
	original: ItemInstancia,
	retirado: ItemInstancia
) -> bool:
	var agregado := inventario.agregar(retirado)
	if not agregado.exitosa:
		return false
	if retirado == original:
		return true
	return inventario.combinar(retirado.id_instancia, original.id_instancia).exitosa
