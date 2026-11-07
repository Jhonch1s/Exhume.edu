class_name AccionPicotazoGuardian
extends AccionAtaqueNPC


func validar_accion(contexto: ContextoAccion) -> StringName:
	var motivo := super.validar_accion(contexto)
	if motivo != &"":
		return motivo
	var npc := contexto.actor as PersonajeNPC
	if npc.obtener_definicion_personaje().estilo_combate != DefinicionPersonaje.EstiloCombate.GUARDIAN:
		return &"npc_no_combatiente"
	if npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) != 2:
		return &"picotazo_ya_usado"
	if EfectosEquipo.base(objetivo, "fuerza") < 1 or EfectosEquipo.base(objetivo, "fuerza") > 5:
		return &"atributo_prueba_invalido"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var resultado := super.resolver_accion(contexto)
	if not resultado.exitosa or &"combate.npc_ataque_acertado" not in resultado.mensajes or not objetivo.puede_actuar() or contexto.actor.obtener_estado(&"recarga_petrificacion") != null:
		return resultado
	var salvacion := EfectosEquipo.resolver_prueba(motor_dados, objetivo, "fuerza", TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG)
	if not salvacion.valida:
		return resultado
	var mensajes := resultado.mensajes
	var cambios := resultado.cambios_estado
	if salvacion.exitosa:
		mensajes.append(&"guardian.petrificacion_resistida")
	else:
		cambios.append(objetivo.aplicar_o_renovar_estado(&"petrificado", 1.0, 1, 1, contexto.actor))
		contexto.actor.aplicar_o_renovar_estado(&"recarga_petrificacion", 1.0, 3, 3)
		objetivo.solicitar_interrupcion()
		mensajes.append(&"guardian.petrificado")
	var final := ResultadoAccion.crear_exito(mensajes, resultado.efectos_aplicados, cambios)
	final = final.con_tirada(resultado.tirada).con_tirada_defensa(resultado.tirada_defensa).con_tirada_dano(resultado.tirada_dano)
	final.tirada_adicional = salvacion
	return final
