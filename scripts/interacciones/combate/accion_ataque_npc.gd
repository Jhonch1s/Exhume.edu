class_name AccionAtaqueNPC
extends RefCounted

## Ataque automático adyacente del NPC, con la misma regla de esquiva del jugador.

var objetivo: Object
var encuentro: GestorRondas
var motor_dados := MotorDados.new()
var aplicador_efectos := AplicadorEfectos.new()


func _init(actor_objetivo: Object, gestor: GestorRondas = null) -> void:
	objetivo = actor_objetivo
	encuentro = gestor


func construir_contexto(npc: PersonajeNPC) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		npc,
		npc.coordenada_mapa,
		objetivo.coordenada_mapa,
		self,
		null,
		&"ataque_basico_npc",
		[],
		{},
		1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
		TiposInteraccion.PoliticaCobro.AL_INTENTAR,
		null,
		&"ataque_basico_npc"
	)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR or contexto.id_accion != &"ataque_basico_npc":
		return &"accion_no_admitida"
	var npc := contexto.actor as PersonajeNPC
	if npc == null or not is_instance_valid(npc) or not npc.puede_actuar():
		return &"actor_no_puede_atacar"
	var perfil := npc.obtener_definicion_personaje()
	if perfil == null or not perfil.puede_combatir:
		return &"npc_no_combatiente"
	if objetivo == null or not is_instance_valid(objetivo) or not (objetivo is Ficha or objetivo is PersonajeNPC) or not objetivo.puede_actuar():
		return &"objetivo_derrotado"
	if encuentro != null and not encuentro.son_oponentes(npc, objetivo):
		return &"npc_no_hostil"
	if encuentro == null and (not objetivo is Ficha or not npc.se_opone_al_jugador()):
		return &"npc_no_hostil"
	var motivo_atributos := ResolverAtaqueBasico.validar_atributos(npc, objetivo)
	if motivo_atributos != &"":
		return motivo_atributos
	if (
		contexto.origen != npc.coordenada_mapa
		or contexto.celda_objetivo != objetivo.coordenada_mapa
		or contexto.alcance_maximo != 1.0
		or contexto.item != null
		or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0}
		or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR
	):
		return &"contexto_ataque_invalido"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return ResolverAtaqueBasico.resolver(contexto, objetivo, motor_dados, aplicador_efectos)
