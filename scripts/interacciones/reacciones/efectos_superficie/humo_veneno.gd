class_name HumoVeneno
extends Node2D

@export var id_instancia: StringName = &""
@export var prioridad_reaccion: int = 0
@export var interrumpe_al_entrar: bool = true
@export_range(0, 99, 1) var coste_movimiento_adicional: int = 1
@export_range(1, 99, 1) var ticks_veneno: int = 2
@export_range(1, 99, 1) var dano_por_tick: int = 1
@export_range(1, 99, 1) var duracion_superficie: int = 10

var tablero: TableroGrid
var coordenada_mapa: Vector2i


func configurar_id_instancia(nuevo_id: StringName) -> void:
	id_instancia = nuevo_id


func configurar_registro(tablero_inicial: TableroGrid, coordenada: Vector2i) -> void:
	tablero = tablero_inicial
	coordenada_mapa = coordenada


func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
	return tipo == TiposInteraccion.TipoAccion.ENTRAR


func obtener_id_reaccion() -> StringName:
	return id_instancia


func obtener_coordenada_reaccion() -> Vector2i:
	return coordenada_mapa


func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
	return prioridad_reaccion


func obtener_coste_movimiento_adicional(_actor: Object = null) -> int:
	return coste_movimiento_adicional


func obtener_familia_superficie() -> StringName:
	return &"humo_veneno"


func obtener_duracion_superficie() -> int:
	return duracion_superficie


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.ENTRAR:
		return &"accion_no_admitida"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return ResultadoAccion.crear_exito(
		[],
		[],
		[],
		{},
		interrumpe_al_entrar,
		false,
		[SolicitudEfecto.new(
			&"veneno",
			&"estado",
			contexto.actor,
			contexto.id_evento,
			float(dano_por_tick),
			ticks_veneno,
			TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
			self
		)]
	)
