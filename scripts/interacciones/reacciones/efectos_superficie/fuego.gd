class_name Fuego
extends Node2D

@export var id_instancia: StringName = &""
@export var prioridad_reaccion: int = 0
@export var interrumpe_al_entrar: bool = true
@export_range(0, 99, 1) var coste_movimiento_adicional: int = 1
@export_range(1, 99, 1) var ticks_quemado: int = 3
@export_range(1, 99, 1) var cantidad_dados_tick: int = 1
@export_range(2, 99, 1) var caras_dado_tick: int = 2
@export_range(1, 99, 1) var duracion_superficie: int = 7
@export_range(0, 32, 1) var radio_luz: int = 2
@export_range(0, 16, 1) var radio_penumbra: int = 1

var tablero: TableroGrid
var coordenada_mapa: Vector2i
var _turnos_restantes: int = -1


func configurar_id_instancia(nuevo_id: StringName) -> void:
	id_instancia = nuevo_id


func configurar_registro(tablero_inicial: TableroGrid, coordenada: Vector2i) -> void:
	tablero = tablero_inicial
	coordenada_mapa = coordenada
	if _turnos_restantes < 0:
		_turnos_restantes = duracion_superficie


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
	return &"fuego"


func esta_encendida() -> bool:
	return true


func obtener_radio_luz() -> int:
	return radio_luz


func obtener_radio_penumbra() -> int:
	return radio_penumbra


func luz_atraviesa_muros() -> bool:
	return false


func obtener_duracion_superficie() -> int:
	return duracion_superficie


func obtener_turnos_restantes_superficie() -> int:
	return _turnos_restantes


func consumir_turno_superficie() -> int:
	_turnos_restantes = maxi(0, _turnos_restantes - 1)
	return _turnos_restantes


func restaurar_turnos_restantes_superficie(turnos: int) -> StringName:
	if turnos <= 0 or turnos > duracion_superficie:
		return &"duracion_superficie_guardada_invalida"
	_turnos_restantes = turnos
	return &""


func obtener_escena_al_expirar() -> PackedScene:
	return preload("res://scenes/efectos_superficie/Humo.tscn")


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.ENTRAR:
		return &"accion_no_admitida"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	var motivo_dados := MotorDados.new().validar_cantidad(
		_terminos_dano_tick(),
		0,
		TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.SOLO_LOG
	)
	if motivo_dados != &"":
		return motivo_dados
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
		[crear_solicitud_quemado(contexto.actor, contexto.id_evento)]
	)


func crear_solicitud_quemado(
	objetivo: Object,
	id_evento: StringName
) -> SolicitudEfecto:
	return SolicitudEfecto.new(
		&"quemado",
		&"estado",
		objetivo,
		id_evento,
		0.0,
		ticks_quemado,
		TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
		self,
		_terminos_dano_tick()
	)


func _terminos_dano_tick() -> Array[Dictionary]:
	return [{
		&"cantidad": cantidad_dados_tick,
		&"caras": caras_dado_tick,
		&"signo": 1,
	}]
