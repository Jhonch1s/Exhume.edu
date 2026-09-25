@tool
class_name PersonajeNPC
extends Interactuable

## Instancia viva de un personaje no jugador en el mundo.
## La definición contiene valores base; este nodo contiene identidad y estado de instancia.

@export_category("Identidad del personaje")
@export var nombre_unico: String = ""

@export_category("Estado de instancia")
@export_range(0, 999, 1) var vida_actual: int = 0
@export var atributos_actuales: Dictionary[StringName, int] = {}
@export_range(0, 99, 1) var nivel_actual: int = 0

@onready var sprite_personaje: Sprite2D = $Sprite2D
@onready var punto_dialogo: Marker2D = $PuntoDialogo


func _ready() -> void:
	if definicion is DefinicionPersonaje:
		var perfil := definicion as DefinicionPersonaje
		if sprite_personaje != null and perfil.textura_mapa != null:
			sprite_personaje.texture = perfil.textura_mapa
			sprite_personaje.hframes = 2
			sprite_personaje.vframes = 2
			sprite_personaje.frame = perfil.orientacion_mapa_inicial
			sprite_personaje.offset = perfil.offset_sprite_mapa
		if Engine.is_editor_hint():
			return
		if vida_actual <= 0:
			vida_actual = perfil.vida_maxima
		if atributos_actuales.is_empty():
			atributos_actuales = {
				&"fuerza": perfil.fuerza,
				&"destreza": perfil.destreza,
				&"voluntad": perfil.voluntad,
			}
		if nivel_actual <= 0:
			nivel_actual = perfil.nivel


func obtener_nombre_interaccion() -> String:
	if not nombre_unico.strip_edges().is_empty():
		return nombre_unico.strip_edges()
	return super.obtener_nombre_interaccion()


func permite_caminar_interactuable() -> bool:
	return false


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	var perfil := obtener_definicion_personaje()
	if perfil == null or not perfil.puede_dialogar:
		return opciones
	for dialogo in perfil.dialogos:
		if dialogo == null or not dialogo.es_valido():
			continue
		var texto_opcion := (
			&"interaccion.hablar" if perfil.dialogos.size() == 1
			else StringName("Hablar: " + dialogo.titulo)
		)
		opciones.append(OpcionAccion.crear_habilitada(
			StringName("hablar:" + String(dialogo.id_dialogo)),
			TiposInteraccion.TipoAccion.INTERACTUAR,
			texto_opcion,
			self,
			{},
			10
		))
	return opciones


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion != null and String(opcion.id).begins_with("hablar:"):
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func obtener_dialogo_por_accion(id_accion: StringName) -> DialogoNPC:
	if not String(id_accion).begins_with("hablar:"):
		return null
	var perfil := obtener_definicion_personaje()
	if perfil == null or not perfil.puede_dialogar:
		return null
	for dialogo in perfil.dialogos:
		if (
			dialogo != null
			and dialogo.es_valido()
			and id_accion == StringName("hablar:" + String(dialogo.id_dialogo))
		):
			return dialogo
	return null


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.validar_accion(contexto)
	if contexto.objetivo != self or contexto.celda_objetivo != coordenada_mapa:
		return &"objetivo_no_coincide"
	if not String(contexto.id_accion).begins_with("hablar:"):
		return &"accion_no_admitida"
	if obtener_dialogo_por_accion(contexto.id_accion) == null:
		return &"dialogo_no_disponible"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return ResultadoAccion.crear_exito()


func contiene_punto_visual(punto_global: Vector2) -> bool:
	return (
		is_instance_valid(sprite_personaje)
		and sprite_personaje.texture != null
		and sprite_personaje.is_visible_in_tree()
		and sprite_personaje.is_pixel_opaque(sprite_personaje.to_local(punto_global))
	)


func obtener_definicion_personaje() -> DefinicionPersonaje:
	return definicion as DefinicionPersonaje
