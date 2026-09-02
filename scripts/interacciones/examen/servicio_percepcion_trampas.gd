class_name ServicioPercepcionTrampas
extends RefCounted

const RADIO := 4

var tablero: TableroGrid
var registro_conocimiento: RegistroConocimiento
var validador_espacial: ValidadorEspacialTablero
var motor_dados: MotorDados


func _init(
	tablero_inicial: TableroGrid,
	registro_inicial: RegistroConocimiento,
	validador_inicial: ValidadorEspacialTablero,
	motor_inicial: MotorDados = null
) -> void:
	tablero = tablero_inicial
	registro_conocimiento = registro_inicial
	validador_espacial = validador_inicial
	motor_dados = motor_inicial if motor_inicial != null else MotorDados.new()


func evaluar(actor: Object) -> Array[ResultadoAccion]:
	var resultados: Array[ResultadoAccion] = []
	if not _actor_valido(actor):
		return resultados
	var ids: Array[StringName] = []
	ids.assign(tablero.interactuables_por_id.keys())
	ids.sort_custom(func(a, b): return String(a) < String(b))
	for id_objetivo in ids:
		var trampa := tablero.obtener_interactuable(id_objetivo) as TrampaSuperficie
		if not _puede_intentar(actor, trampa):
			continue
		registro_conocimiento.registrar_intento_percepcion(
			actor.call(&"obtener_id_observador"), id_objetivo
		)
		var tirada := motor_dados.resolver_prueba(
			actor.call(&"obtener_voluntad"),
			[],
			[],
			TiposTirada.Origen.AUTOMATICA,
			TiposTirada.Presentacion.SOLO_LOG
		)
		if not tirada.valida:
			resultados.append(ResultadoAccion.crear_bloqueo(tirada.motivo))
			continue
		if tirada.exitosa:
			trampa.descubrir()
			resultados.append(ResultadoAccion.crear_exito(
				[&"trampa.detectada"],
				[],
				[{
					&"objetivo_id": trampa.id_instancia,
					&"propiedad": &"estado",
					&"nueva": TrampaSuperficie.Estado.DESCUBIERTA,
				}]
			).con_tirada(tirada))
		else:
			resultados.append(ResultadoAccion.crear_exito(
				[&"trampa.no_detectada"]
			).con_tirada(tirada))
	return resultados


func _actor_valido(actor: Object) -> bool:
	return (
		tablero != null
		and registro_conocimiento != null
		and validador_espacial != null
		and actor is Ficha
		and is_instance_valid(actor)
		and actor.call(&"obtener_id_observador") is StringName
		and actor.call(&"obtener_id_observador") != &""
		and actor.has_method(&"obtener_voluntad")
		and actor.call(&"obtener_voluntad") is int
		and actor.call(&"obtener_voluntad") >= 1
		and actor.call(&"obtener_voluntad") <= 5
	)


func _puede_intentar(actor: Object, trampa: TrampaSuperficie) -> bool:
	if (
		trampa == null
		or trampa.estado != TrampaSuperficie.Estado.OCULTA
		or registro_conocimiento.intento_percepcion_realizado(
			actor.call(&"obtener_id_observador"), trampa.id_instancia
		)
	):
		return false
	var origen: Vector2i = actor.get(&"coordenada_mapa")
	var delta := trampa.coordenada_mapa - origen
	if maxi(absi(delta.x), absi(delta.y)) > RADIO:
		return false
	var celda := tablero.obtener_celda(trampa.coordenada_mapa)
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return false
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		actor,
		origen,
		trampa.coordenada_mapa,
		trampa,
		null,
		&"",
		[],
		{},
		float(RADIO),
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL,
		{},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		null,
		&"percepcion_trampa",
		-1,
		&"",
		null,
		TiposInteraccion.MetricaAlcance.CUADRICULA
	)
	return validador_espacial.validar_linea_efecto(contexto) == &""
