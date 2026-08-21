class_name TrampaSuperficie
extends Interactuable

enum Presentacion {
	OCULTA,
	INDICIO,
	VISIBLE,
}

@export_category("Disparo automatico")
@export var escena_superficie: PackedScene = preload(
	"res://scenes/efectos_superficie/HumoVeneno.tscn"
)
@export_range(0, 8, 1) var radio: int = 1
@export var interrumpe_al_activar: bool = true

@export_category("Percepcion")
@export var presentacion: Presentacion = Presentacion.INDICIO
@export_range(0.0, 1.0, 0.05) var opacidad_indicio: float = 0.7

var activada: bool = false


func _ready() -> void:
	_actualizar_presentacion()


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	return []


func es_objetivo_impacto_perceptible() -> bool:
	return presentacion != Presentacion.OCULTA


func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
	return tipo in [
		TiposInteraccion.TipoAccion.ENTRAR,
		TiposInteraccion.TipoAccion.IMPACTAR,
	] and not activada


func obtener_reacciones_encadenadas(
	tipo: TiposInteraccion.TipoAccion
) -> Array[Object]:
	var trampas: Array[Object] = []
	if tipo not in [
		TiposInteraccion.TipoAccion.ENTRAR,
		TiposInteraccion.TipoAccion.IMPACTAR,
	] or tablero == null:
		return trampas
	for direccion in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var celda := tablero.obtener_celda(coordenada_mapa + direccion)
		if celda == null:
			continue
		for interactuable in celda.interactuables.duplicate():
			if interactuable is TrampaSuperficie and interactuable != self:
				trampas.append(interactuable)
	trampas.sort_custom(func(a, b): return String(a.id_instancia) < String(b.id_instancia))
	return trampas


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo not in [
		TiposInteraccion.TipoAccion.ENTRAR,
		TiposInteraccion.TipoAccion.IMPACTAR,
	]:
		return &"accion_no_admitida"
	if contexto.tipo == TiposInteraccion.TipoAccion.IMPACTAR:
		if contexto.item == null or &"impacto" not in contexto.etiquetas:
			return &"impacto_incoherente"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	if tablero == null or escena_superficie == null:
		return &"trampa_no_configurada"
	if activada:
		return &"trampa_ya_activada"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var afectadas := tablero.desplegar_efecto_superficie(
		escena_superficie,
		coordenada_mapa,
		radio,
		StringName("%s_superficie" % id_instancia)
	)
	if afectadas.is_empty():
		return ResultadoAccion.crear_fallo(&"superficie_no_desplegada")
	activada = true
	_actualizar_presentacion()
	var cambios: Array[Dictionary] = []
	for coord in afectadas:
		cambios.append({
			"tipo": &"superficie_desplegada",
			"coordenada": coord,
		})
	return ResultadoAccion.crear_exito(
		[&"trampa.superficie_activada"],
		[],
		cambios,
		{},
		interrumpe_al_activar
	)


func _actualizar_presentacion() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null:
		return
	sprite.region_rect.position.x = 64.0 if activada else 0.0
	match presentacion:
		Presentacion.OCULTA:
			sprite.modulate.a = 0.0
		Presentacion.INDICIO:
			sprite.modulate.a = opacidad_indicio
		Presentacion.VISIBLE:
			sprite.modulate.a = 1.0
