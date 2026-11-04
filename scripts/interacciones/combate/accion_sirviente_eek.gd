class_name AccionSirvienteEek
extends RefCounted

const MORDIDA := &"mordida_venenosa"
const TELARANA := &"lanzar_telarana"
const ALCANCE_TELARANA := 3

var objetivo: Object
var encuentro: GestorRondas
var motor_dados := MotorDados.new()
var aplicador_efectos := AplicadorEfectos.new()


func _init(actor_objetivo: Object, gestor: GestorRondas = null) -> void:
	objetivo = actor_objetivo
	encuentro = gestor


func construir_contexto(npc: PersonajeNPC, habilidad: StringName) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		npc, npc.coordenada_mapa, objetivo.coordenada_mapa, self,
		null, habilidad, [], {}, ALCANCE_TELARANA if habilidad == TELARANA else 1.0,
		{}, TiposInteraccion.TipoLineaEfecto.FISICA,
		{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
		TiposInteraccion.PoliticaCobro.AL_INTENTAR, null, habilidad, -1, &"", null,
		TiposInteraccion.MetricaAlcance.CUADRICULA if habilidad == TELARANA else TiposInteraccion.MetricaAlcance.MANHATTAN
	)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR or contexto.id_accion not in [MORDIDA, TELARANA]:
		return &"accion_no_admitida"
	var npc := contexto.actor as PersonajeNPC
	if npc == null or not npc.puede_actuar() or npc.obtener_estado(&"caido") != null:
		return &"actor_no_puede_atacar"
	var perfil := npc.obtener_definicion_personaje()
	if perfil == null or not perfil.puede_combatir or perfil.estilo_combate != DefinicionPersonaje.EstiloCombate.SIRVIENTE_EEK:
		return &"npc_no_combatiente"
	if not is_instance_valid(objetivo) or not (objetivo is Ficha or objetivo is PersonajeNPC) or not objetivo.puede_actuar():
		return &"objetivo_derrotado"
	if encuentro != null:
		if not encuentro.son_oponentes(npc, objetivo):
			return &"npc_no_hostil"
	elif not objetivo is Ficha or not npc.se_opone_al_jugador():
		return &"npc_no_hostil"
	var atributo := "destreza" if contexto.id_accion == TELARANA else "fuerza"
	if EfectosEquipo.base(objetivo, atributo) < 1 or EfectosEquipo.base(objetivo, atributo) > 5:
		return &"atributo_prueba_invalido"
	var alcance := ALCANCE_TELARANA if contexto.id_accion == TELARANA else 1
	if (
		contexto.origen != npc.coordenada_mapa or contexto.celda_objetivo != objetivo.coordenada_mapa
		or contexto.alcance_maximo != float(alcance) or contexto.item != null
		or contexto.tipo_linea_efecto != TiposInteraccion.TipoLineaEfecto.FISICA
		or contexto.metrica_alcance != (TiposInteraccion.MetricaAlcance.CUADRICULA if contexto.id_accion == TELARANA else TiposInteraccion.MetricaAlcance.MANHATTAN)
		or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0}
		or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR
		or contexto.id_evento != contexto.id_accion
	):
		return &"contexto_ataque_invalido"
	if npc.tablero == null or not npc.puede_ver_actor(objetivo, ValidadorEspacialTablero.new(npc.tablero)):
		return &"objetivo_no_visible"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var es_telarana := contexto.id_accion == TELARANA
	var salvacion := EfectosEquipo.resolver_prueba(
		motor_dados, objetivo, "destreza" if es_telarana else "fuerza",
		TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
	)
	if not salvacion.valida:
		return ResultadoAccion.crear_fallo(salvacion.motivo)
	if salvacion.exitosa:
		return ResultadoAccion.crear_exito([
			&"eek.telarana_evitada" if es_telarana else &"eek.mordida_resistida"
		]).con_tirada(salvacion)
	var cantidad := motor_dados.resolver(
		[{&"cantidad": 1, &"caras": 3 if es_telarana else 6, &"signo": 1}],
		0, TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
	)
	if not cantidad.valida:
		return ResultadoAccion.crear_fallo(cantidad.motivo).con_tirada(salvacion)
	var solicitud := SolicitudEfecto.new(
		&"inmovilizado" if es_telarana else MORDIDA,
		&"estado" if es_telarana else &"dano", objetivo, contexto.id_evento,
		1.0 if es_telarana else float(cantidad.total_efectivo + 3),
		cantidad.total_efectivo if es_telarana else 0,
		TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, contexto.actor
	)
	var aplicado: Variant = aplicador_efectos.aplicar(solicitud)
	if aplicado is StringName:
		return ResultadoAccion.crear_fallo(aplicado).con_tirada(salvacion)
	if es_telarana:
		objetivo.solicitar_interrupcion()
	var resultado := ResultadoAccion.crear_exito([
		&"eek.telarana_inmoviliza" if es_telarana else &"eek.mordida"
	], [aplicado]).con_tirada(salvacion)
	return resultado.con_tirada_duracion(cantidad) if es_telarana else resultado.con_tirada_dano(cantidad)
