class_name ResolverAtaqueBasico
extends RefCounted

## Regla común: ataque con FUE y esquiva automática con DES, sin gastar reacción.


static func validar_atributos(atacante: Object, defensor: Object) -> StringName:
	var fuerza: int = atacante.obtener_fuerza()
	var destreza: int = defensor.obtener_destreza()
	if fuerza < 1 or fuerza > 5 or destreza < 1 or destreza > 5:
		return &"atributo_prueba_invalido"
	return &""


static func probabilidad_de_dano(fuerza: int, destreza_defensor: int) -> float:
	if fuerza < 1 or fuerza > 5 or destreza_defensor < 1 or destreza_defensor > 5:
		return 0.0
	# Cada d6 acierta con 1..atributo; el daño exige ataque acertado y esquiva fallida.
	return float(fuerza * (6 - destreza_defensor)) / 36.0


static func resolver(
	contexto: ContextoAccion,
	defensor: Object,
	motor_dados: MotorDados,
	aplicador_efectos: AplicadorEfectos
) -> ResultadoAccion:
	var motivo := validar_atributos(contexto.actor, defensor)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var es_jugador := contexto.actor is Ficha
	var prefijo := "combate." if es_jugador else "combate.npc_"
	var ataque := motor_dados.resolver_prueba(
		contexto.actor.obtener_fuerza(), [], [],
		TiposTirada.Origen.SOLICITADA if es_jugador else TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.PRIMER_PLANO if es_jugador else TiposTirada.Presentacion.SOLO_LOG
	)
	if not ataque.valida:
		return ResultadoAccion.crear_fallo(ataque.motivo)
	if not ataque.exitosa:
		return ResultadoAccion.crear_exito(
			[StringName(prefijo + "ataque_fallido")]
		).con_tirada(ataque)
	var esquiva := motor_dados.resolver_prueba(
		defensor.obtener_destreza(), [], [],
		TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
	)
	if not esquiva.valida:
		return ResultadoAccion.crear_fallo(esquiva.motivo).con_tirada(ataque)
	if esquiva.exitosa:
		return ResultadoAccion.crear_exito(
			[StringName(prefijo + "ataque_esquivado")]
		).con_tirada(ataque).con_tirada_defensa(esquiva)
	var solicitud := SolicitudEfecto.new(
		contexto.id_accion, &"dano", defensor,
		contexto.id_evento if contexto.id_evento != &"" else contexto.id_accion,
		1.0, 0, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, contexto.actor
	)
	var efecto: Variant = aplicador_efectos.aplicar(solicitud)
	if efecto is StringName:
		return ResultadoAccion.crear_fallo(efecto).con_tirada(ataque).con_tirada_defensa(esquiva)
	return ResultadoAccion.crear_exito(
		[StringName(prefijo + "ataque_acertado")], [efecto]
	).con_tirada(ataque).con_tirada_defensa(esquiva)
