class_name PalancaInteractuable
extends Interactuable

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


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return super.validar_accion(contexto)
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return &"accion_no_admitida"
	if contexto.id_accion != &"accionar":
		return &"accion_no_admitida"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	var datos := definicion as DefinicionPalanca
	if datos == null or not datos.es_valida():
		return &"palanca_no_configurada"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var anterior := activada
	activada = not activada
	return ResultadoAccion.crear_exito(
		[&"palanca.activada" if activada else &"palanca.desactivada"],
		[],
		[{
			&"objetivo_id": id_instancia,
			&"propiedad": &"activada",
			&"anterior": anterior,
			&"nueva": activada,
		}]
	)


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
