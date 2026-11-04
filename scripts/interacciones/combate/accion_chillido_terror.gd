class_name AccionChillidoTerror
extends RefCounted

const ID := &"chillido_terror"
var objetivo: Object
var encuentro: GestorRondas
var motor_dados := MotorDados.new()

func _init(blanco: Object, rondas: GestorRondas = null) -> void:
	objetivo = blanco
	encuentro = rondas

func construir_contexto(npc: PersonajeNPC) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR, npc, npc.coordenada_mapa,
		objetivo.coordenada_mapa, self, null, ID, [], {}, 3.0, {},
		TiposInteraccion.TipoLineaEfecto.VISUAL,
		{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
		TiposInteraccion.PoliticaCobro.AL_INTENTAR, null, ID, -1, &"", null,
		TiposInteraccion.MetricaAlcance.CUADRICULA
	)

func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self or contexto.id_accion != ID or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return &"accion_no_admitida"
	var npc := contexto.actor as PersonajeNPC
	if npc == null or not npc.puede_actuar() or npc.obtener_estado(&"aturdido") != null:
		return &"actor_no_puede_atacar"
	var perfil := npc.obtener_definicion_personaje()
	if perfil == null or not perfil.puede_combatir or perfil.estilo_combate != DefinicionPersonaje.EstiloCombate.TERROR_NOCTURNO:
		return &"npc_no_combatiente"
	if npc.obtener_estado(&"recarga_chillido") != null:
		return &"chillido_en_recarga"
	if not is_instance_valid(objetivo) or not (objetivo is Ficha or objetivo is PersonajeNPC) or not objetivo.puede_actuar():
		return &"objetivo_derrotado"
	if encuentro != null and not encuentro.son_oponentes(npc, objetivo):
		return &"npc_no_hostil"
	if encuentro == null and (not objetivo is Ficha or not npc.se_opone_al_jugador()):
		return &"npc_no_hostil"
	if EfectosEquipo.base(objetivo, "voluntad") < 1 or EfectosEquipo.base(objetivo, "voluntad") > 5:
		return &"atributo_prueba_invalido"
	if contexto.origen != npc.coordenada_mapa or contexto.celda_objetivo != objetivo.coordenada_mapa or contexto.alcance_maximo != 3.0 or contexto.tipo_linea_efecto != TiposInteraccion.TipoLineaEfecto.VISUAL or contexto.metrica_alcance != TiposInteraccion.MetricaAlcance.CUADRICULA or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0} or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR or contexto.item != null or contexto.id_evento != ID:
		return &"contexto_ataque_invalido"
	if npc.tablero == null or not npc.puede_ver_actor(objetivo, ValidadorEspacialTablero.new(npc.tablero)):
		return &"objetivo_no_visible"
	return &""

func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var tirada := EfectosEquipo.resolver_prueba(motor_dados, objetivo, "voluntad", TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG)
	if not tirada.valida:
		return ResultadoAccion.crear_fallo(tirada.motivo)
	contexto.actor.aplicar_o_renovar_estado(&"recarga_chillido", 1.0, 3, 3)
	if tirada.exitosa:
		return ResultadoAccion.crear_exito([&"terror.chillido_resistido"]).con_tirada(tirada)
	var cambio: Dictionary = objetivo.aplicar_o_renovar_estado(&"aturdido", 1.0, 1, 1, contexto.actor)
	if cambio.is_empty():
		return ResultadoAccion.crear_fallo(&"resultado_estado_invalido").con_tirada(tirada)
	objetivo.solicitar_interrupcion()
	return ResultadoAccion.crear_exito([&"terror.chillido_aturde"], [], [cambio]).con_tirada(tirada)
