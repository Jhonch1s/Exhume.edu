@tool
class_name FuenteLuzInteractuable
extends Interactuable

signal estado_luz_cambiado(encendida: bool)

@export_category("Fuente de luz")
@export var encendida: bool = true:
	set(valor):
		if encendida == valor:
			return
		encendida = valor
		_actualizar_representacion()
		estado_luz_cambiado.emit(encendida)

@onready var sprite: Sprite2D = $Sprite2D
@onready var reproductor_audio: AudioStreamPlayer2D = (
	get_node_or_null(^"AudioStreamPlayer2D") as AudioStreamPlayer2D
)


func _ready() -> void:
	_actualizar_representacion()


func obtener_definicion_luz() -> DefinicionFuenteLuz:
	return definicion as DefinicionFuenteLuz


func obtener_estado_persistente() -> Dictionary:
	return {"encendida": encendida}


func validar_estado_persistente(estado: Dictionary) -> StringName:
	if estado.size() != 1 or not estado.has("encendida") or not estado["encendida"] is bool:
		return &"estado_fuente_luz_invalido"
	return &""


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo == &"":
		encendida = estado["encendida"]
	return motivo


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(_actor)
	var id_accion: StringName = &"apagar" if encendida else &"encender"
	var texto: StringName = &"interaccion.apagar" if encendida else &"interaccion.encender"
	opciones.append(OpcionAccion.crear_habilitada(
		id_accion,
		TiposInteraccion.TipoAccion.INTERACTUAR,
		texto,
		self,
		{},
		10
	))
	return opciones


func obtener_fragmentos_informacion() -> Array[FragmentoInformacion]:
	var fragmentos := super.obtener_fragmentos_informacion()
	var datos := obtener_definicion_luz()
	if datos == null:
		return fragmentos
	for indice in range(fragmentos.size()):
		if fragmentos[indice].id_fragmento != &"identidad":
			continue
		var informacion_basica := fragmentos[indice].duplicate(true) as FragmentoInformacion
		informacion_basica.id_mensaje = (
			datos.mensaje_basico_encendida if encendida
			else datos.mensaje_basico_apagada
		)
		fragmentos[indice] = informacion_basica
	return fragmentos


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if (
		opcion != null
		and opcion.tipo == TiposInteraccion.TipoAccion.INTERACTUAR
		and opcion.id in [&"encender", &"apagar"]
	):
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_invalido"
	if contexto.tipo in [
		TiposInteraccion.TipoAccion.EXAMINAR,
		TiposInteraccion.TipoAccion.USAR_ITEM,
	]:
		return super.validar_accion(contexto)
	if contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return &"tipo_accion_no_admitido"
	if contexto.id_accion == &"apagar":
		return &"" if encendida else &"fuente_luz_ya_apagada"
	if contexto.id_accion == &"encender":
		return &"" if not encendida else &"fuente_luz_ya_encendida"
	return &"accion_no_admitida"


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo in [
		TiposInteraccion.TipoAccion.EXAMINAR,
		TiposInteraccion.TipoAccion.USAR_ITEM,
	]:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)

	var estado_anterior := encendida
	encendida = contexto.id_accion == &"encender"
	_reproducir_sonido_estado()
	return ResultadoAccion.crear_exito(
		[&"fuente_luz.encendida" if encendida else &"fuente_luz.apagada"],
		[],
		[{
			&"objetivo_id": id_instancia,
			&"propiedad": &"encendida",
			&"anterior": estado_anterior,
			&"nueva": encendida,
		}]
	)


func obtener_sonido_ambiente() -> AudioStream:
	var datos := obtener_definicion_luz()
	if datos == null or not encendida:
		return null
	return datos.sonido_ambiente


func _reproducir_sonido_estado() -> void:
	if Engine.is_editor_hint() or not is_instance_valid(reproductor_audio):
		return
	var datos := obtener_definicion_luz()
	if datos == null:
		return
	reproductor_audio.stream = datos.sonido_encender if encendida else datos.sonido_apagar
	if reproductor_audio.stream != null:
		reproductor_audio.play()


func _actualizar_representacion() -> void:
	if not is_instance_valid(sprite):
		return
	var datos := obtener_definicion_luz()
	if datos == null or datos.textura == null:
		sprite.visible = false
		return
	sprite.visible = true
	sprite.texture = datos.textura
	sprite.region_enabled = true
	sprite.region_rect = datos.region_encendida if encendida else datos.region_apagada
	sprite.position = datos.desplazamiento_sprite
