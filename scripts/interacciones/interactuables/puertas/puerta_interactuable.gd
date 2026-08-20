class_name PuertaInteractuable
extends Interactuable

@export var bloqueada: bool = true
@export var abierta: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if abierta:
		bloqueada = false
	_actualizar_representacion()


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	if not bloqueada:
		_eliminar_uso_item(opciones)
	var id_accion: StringName = &"cerrar" if abierta else &"abrir"
	var texto: StringName = &"interaccion.cerrar" if abierta else &"interaccion.abrir"
	if bloqueada:
		opciones.append(OpcionAccion.crear_bloqueada(
			id_accion,
			TiposInteraccion.TipoAccion.INTERACTUAR,
			texto,
			self,
			&"puerta_bloqueada",
			{},
			10
		))
	else:
		opciones.append(OpcionAccion.crear_habilitada(
			id_accion,
			TiposInteraccion.TipoAccion.INTERACTUAR,
			texto,
			self,
			{},
			10
		))
	return opciones


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion != null and opcion.tipo == TiposInteraccion.TipoAccion.INTERACTUAR:
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func permite_caminar_interactuable() -> bool:
	return abierta


func bloquea_vision_interactuable() -> bool:
	return not abierta


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return super.validar_accion(contexto)
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	var datos := definicion as DefinicionPuerta
	if datos == null or not datos.es_valida():
		return &"puerta_no_configurada"
	if contexto.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		var motivo_item := super.validar_accion(contexto)
		if motivo_item != &"":
			return motivo_item
		return &"" if bloqueada else &"puerta_ya_desbloqueada"
	if contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return &"accion_no_admitida"
	if contexto.id_accion == &"abrir":
		if abierta:
			return &"puerta_ya_abierta"
		return &"puerta_bloqueada" if bloqueada else &""
	if contexto.id_accion == &"cerrar":
		return &"" if abierta else &"puerta_ya_cerrada"
	return &"accion_no_admitida"


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if contexto.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		return _resolver_uso_item(contexto)

	var estado_anterior := abierta
	abierta = contexto.id_accion == &"abrir"
	_actualizar_representacion()
	presencia_cambiada.emit()
	return ResultadoAccion.crear_exito(
		[&"puerta.abierta" if abierta else &"puerta.cerrada"],
		[],
		[{
			&"objetivo_id": id_instancia,
			&"propiedad": &"abierta",
			&"anterior": estado_anterior,
			&"nueva": abierta,
		}]
	)


func _resolver_uso_item(contexto: ContextoAccion) -> ResultadoAccion:
	var llave := contexto.item.definicion as DefinicionLlave
	if &"llave" not in contexto.etiquetas or llave == null:
		return ResultadoAccion.crear_fallo(&"item_no_es_llave")
	var datos := definicion as DefinicionPuerta
	if llave.patron_cerradura != datos.patron_cerradura:
		return ResultadoAccion.crear_fallo(&"llave_incompatible")
	var estado_anterior := bloqueada
	bloqueada = false
	return ResultadoAccion.crear_exito(
		[&"puerta.desbloqueada"],
		[],
		[{
			&"objetivo_id": id_instancia,
			&"propiedad": &"bloqueada",
			&"anterior": estado_anterior,
			&"nueva": bloqueada,
		}]
	)


func _eliminar_uso_item(opciones: Array[OpcionAccion]) -> void:
	for indice in range(opciones.size() - 1, -1, -1):
		if opciones[indice].tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
			opciones.remove_at(indice)


func _actualizar_representacion() -> void:
	if not is_instance_valid(sprite):
		return
	var datos := definicion as DefinicionPuerta
	if datos == null or datos.textura == null:
		sprite.visible = false
		return
	sprite.visible = true
	sprite.texture = datos.textura
	sprite.region_enabled = true
	sprite.region_rect = datos.region_abierta if abierta else datos.region_cerrada
	sprite.position = datos.desplazamiento_sprite
