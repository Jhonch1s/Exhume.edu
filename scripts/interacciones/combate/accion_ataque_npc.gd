class_name AccionAtaqueNPC
extends RefCounted

## Primer ataque automático del NPC: sólo adyacente y sin regla de defensa.

var ficha: Ficha
var motor_dados := MotorDados.new()
var aplicador_efectos := AplicadorEfectos.new()


func _init(ficha_objetivo: Ficha) -> void:
	ficha = ficha_objetivo


func construir_contexto(npc: PersonajeNPC) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		npc,
		npc.coordenada_mapa,
		ficha.coordenada_mapa,
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
	if npc.obtener_actitud_hacia_jugador() != DefinicionPersonaje.ActitudInicialJugador.HOSTIL:
		return &"npc_no_hostil"
	if ficha == null or not is_instance_valid(ficha) or not ficha.puede_actuar():
		return &"objetivo_derrotado"
	var fuerza: int = npc.atributos_actuales.get(&"fuerza", 0)
	if fuerza < 1 or fuerza > 5:
		return &"atributo_prueba_invalido"
	if (
		contexto.origen != npc.coordenada_mapa
		or contexto.celda_objetivo != ficha.coordenada_mapa
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
	var npc := contexto.actor as PersonajeNPC
	var fuerza: int = npc.atributos_actuales.get(&"fuerza", 0)
	var prueba := motor_dados.resolver_prueba(
		fuerza, [], [], TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.SOLO_LOG
	)
	if not prueba.valida:
		return ResultadoAccion.crear_fallo(prueba.motivo)
	if not prueba.exitosa:
		return ResultadoAccion.crear_exito([&"combate.npc_ataque_fallido"]).con_tirada(prueba)
	var solicitud := SolicitudEfecto.new(
		&"ataque_basico_npc", &"dano", ficha, contexto.id_evento,
		1.0, 0, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, npc
	)
	var efecto: Variant = aplicador_efectos.aplicar(solicitud)
	if efecto is StringName:
		return ResultadoAccion.crear_fallo(efecto).con_tirada(prueba)
	return ResultadoAccion.crear_exito(
		[&"combate.npc_ataque_acertado"], [efecto]
	).con_tirada(prueba)
