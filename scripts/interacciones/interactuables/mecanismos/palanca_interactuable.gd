@tool
class_name PalancaInteractuable
extends Interactuable

@export_category("Relacion de mecanismo")
@export var ids_receptores_mecanismo: Array[StringName] = []

@export var activada: bool = false:
	set(valor):
		activada = valor
		_actualizar_representacion()

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_actualizar_representacion()


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	for indice in range(opciones.size() - 1, -1, -1):
		if opciones[indice].tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
			opciones.remove_at(indice)
	opciones.append(OpcionAccion.crear_habilitada(
		&"accionar",
		TiposInteraccion.TipoAccion.INTERACTUAR,
		&"interaccion.accionar",
		self,
		{},
		10
	))
	return opciones


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion != null and opcion.tipo == TiposInteraccion.TipoAccion.INTERACTUAR:
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func admite_reaccion_dirigida(tipo: TiposInteraccion.TipoAccion) -> bool:
	return tipo == TiposInteraccion.TipoAccion.IMPACTAR


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return super.validar_accion(contexto)
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo == TiposInteraccion.TipoAccion.IMPACTAR:
		if (
			contexto.objetivo_impacto != self
			or contexto.item == null
			or &"impacto" not in contexto.etiquetas
		):
			return &"impacto_no_dirigido"
	elif (
		contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR
		or contexto.id_accion != &"accionar"
	):
		return &"accion_no_admitida"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	var datos := definicion as DefinicionPalanca
	if datos == null or not datos.es_valida():
		return &"palanca_no_configurada"
	var receptores: Variant = _obtener_receptores_mecanismo(not activada)
	if receptores is StringName:
		return receptores
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var anterior := activada
	var nueva := not activada
	var mensajes: Array[StringName] = []
	var cambios: Array[Dictionary] = []
	var receptores: Variant = _obtener_receptores_mecanismo(nueva)
	if receptores is StringName:
		return ResultadoAccion.crear_bloqueo(receptores)
	for receptor: Interactuable in receptores:
		var resultado_receptor: Variant = receptor.call(
			&"aplicar_cambio_mecanismo", id_instancia, nueva
		)
		if not resultado_receptor is ResultadoAccion:
			return ResultadoAccion.crear_fallo(&"resultado_receptor_mecanismo_invalido")
		if not resultado_receptor.exitosa:
			return resultado_receptor
		mensajes.append_array(resultado_receptor.mensajes)
		cambios.append_array(resultado_receptor.cambios_estado)
	activada = nueva
	mensajes.push_front(&"palanca.activada" if activada else &"palanca.desactivada")
	cambios.push_front({
		&"objetivo_id": id_instancia,
		&"propiedad": &"activada",
		&"anterior": anterior,
		&"nueva": activada,
	})
	return ResultadoAccion.crear_exito(
		mensajes,
		[],
		cambios
	)


func _obtener_receptores_mecanismo(activa: bool) -> Variant:
	var receptores: Array[Interactuable] = []
	if ids_receptores_mecanismo.is_empty():
		return receptores
	if tablero == null:
		return &"tablero_mecanismo_no_configurado"

	var ids := ids_receptores_mecanismo.duplicate()
	ids.sort()
	var ids_vistos: Dictionary[StringName, bool] = {}
	for id_receptor in ids:
		if id_receptor == &"":
			return &"id_receptor_mecanismo_vacio"
		if ids_vistos.has(id_receptor):
			return &"id_receptor_mecanismo_duplicado"
		ids_vistos[id_receptor] = true
		var receptor := tablero.obtener_interactuable(id_receptor)
		if receptor == null:
			return &"receptor_mecanismo_inexistente"
		if (
			not receptor.has_method(&"validar_cambio_mecanismo")
			or not receptor.has_method(&"aplicar_cambio_mecanismo")
		):
			return &"receptor_mecanismo_incompatible"
		var motivo_receptor: Variant = receptor.call(
			&"validar_cambio_mecanismo", id_instancia, activa
		)
		if not motivo_receptor is StringName:
			return &"contrato_receptor_mecanismo_invalido"
		if motivo_receptor != &"":
			return motivo_receptor
		receptores.append(receptor)
	return receptores


func _actualizar_representacion() -> void:
	if not is_instance_valid(sprite):
		return
	var datos := definicion as DefinicionPalanca
	if datos == null or datos.textura == null:
		sprite.visible = false
		return
	sprite.visible = true
	sprite.texture = datos.textura
	sprite.region_enabled = true
	sprite.region_rect = datos.region_activada if activada else datos.region_desactivada
	sprite.position = datos.desplazamiento_sprite
