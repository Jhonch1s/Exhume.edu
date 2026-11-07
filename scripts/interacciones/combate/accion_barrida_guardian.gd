class_name AccionBarridaGuardian
extends RefCounted

const ID := &"barrida_guardian"

var objetivo: Object
var encuentro: GestorRondas
var motor_dados := MotorDados.new()
var aplicador_efectos := AplicadorEfectos.new()


func _init(blanco: Object, rondas: GestorRondas = null) -> void:
	objetivo = blanco
	encuentro = rondas


func construir_contexto(npc: PersonajeNPC) -> ContextoAccion:
	var destino: Vector2i = objetivo.coordenada_mapa
	var origen := npc.obtener_celda_mas_cercana(destino)
	if objetivo is Interactuable:
		destino = objetivo.obtener_celda_mas_cercana(origen)
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR, npc, origen,
		destino, self, null, ID, [], {}, 1.0, {},
		TiposInteraccion.TipoLineaEfecto.FISICA,
		{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
		TiposInteraccion.PoliticaCobro.AL_INTENTAR, null, ID, -1, &"", null,
		TiposInteraccion.MetricaAlcance.MANHATTAN
	)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR or contexto.id_accion != ID:
		return &"accion_no_admitida"
	var npc := contexto.actor as PersonajeNPC
	if npc == null or not npc.puede_actuar() or npc.obtener_estado(&"caido") != null or npc.obtener_estado(&"aturdido") != null:
		return &"actor_no_puede_atacar"
	var perfil := npc.obtener_definicion_personaje()
	if perfil == null or not perfil.puede_combatir or perfil.estilo_combate != DefinicionPersonaje.EstiloCombate.GUARDIAN:
		return &"npc_no_combatiente"
	if npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) != 1:
		return &"barrida_fuera_de_orden"
	if not is_instance_valid(objetivo) or not (objetivo is Ficha or objetivo is PersonajeNPC) or not objetivo.puede_actuar():
		return &"objetivo_derrotado"
	if encuentro != null:
		if not encuentro.son_oponentes(npc, objetivo):
			return &"npc_no_hostil"
	elif not objetivo is Ficha or not npc.se_opone_al_jugador():
		return &"npc_no_hostil"
	if EfectosEquipo.base(objetivo, "destreza") < 1 or EfectosEquipo.base(objetivo, "destreza") > 5:
		return &"atributo_prueba_invalido"
	if not npc.ocupa_coordenada(contexto.origen) or (not objetivo.ocupa_coordenada(contexto.celda_objetivo) if objetivo is Interactuable else contexto.celda_objetivo != objetivo.coordenada_mapa) or contexto.alcance_maximo != 1.0 or contexto.item != null or contexto.tipo_linea_efecto != TiposInteraccion.TipoLineaEfecto.FISICA or contexto.metrica_alcance != TiposInteraccion.MetricaAlcance.MANHATTAN or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0} or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR or contexto.id_evento != ID:
		return &"contexto_ataque_invalido"
	if npc.tablero == null or ValidadorEspacialTablero.new(npc.tablero).validar_linea_visual(contexto.origen, contexto.celda_objetivo) != &"":
		return &"objetivo_no_visible"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var tirada := EfectosEquipo.resolver_prueba(motor_dados, objetivo, "destreza", TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG)
	if not tirada.valida:
		return ResultadoAccion.crear_fallo(tirada.motivo)
	if tirada.exitosa:
		return ResultadoAccion.crear_exito([&"guardian.barrida_evitada"]).con_tirada(tirada)
	var solicitud := SolicitudEfecto.new(&"caido", &"estado", objetivo, ID, 1.0, 1, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, contexto.actor)
	var aplicado: Variant = aplicador_efectos.aplicar(solicitud)
	if aplicado is StringName:
		return ResultadoAccion.crear_fallo(aplicado).con_tirada(tirada)
	objetivo.solicitar_interrupcion()
	return ResultadoAccion.crear_exito([&"guardian.barrida"], [aplicado]).con_tirada(tirada)
