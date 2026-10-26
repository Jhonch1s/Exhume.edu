class_name ResolverAtaqueBasico
extends RefCounted

## Regla común: ataque con FUE y esquiva automática con DES, sin gastar reacción.


static func validar_atributos(atacante: Object, defensor: Object) -> StringName:
	var fuerza := EfectosEquipo.base(atacante, "fuerza")
	var destreza := EfectosEquipo.base(defensor, "destreza")
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
	var ataque := EfectosEquipo.resolver_prueba(
		motor_dados, contexto.actor, "fuerza",
		TiposTirada.Origen.SOLICITADA if es_jugador else TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.PRIMER_PLANO if es_jugador else TiposTirada.Presentacion.SOLO_LOG, "ataque"
	)
	if not ataque.valida:
		return ResultadoAccion.crear_fallo(ataque.motivo)
	if not ataque.exitosa:
		return ResultadoAccion.crear_exito(
			[StringName(prefijo + "ataque_fallido")]
		).con_tirada(ataque)
	var esquiva := EfectosEquipo.resolver_prueba(
		motor_dados, defensor, "destreza",
		TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG, "esquiva"
	)
	if not esquiva.valida:
		return ResultadoAccion.crear_fallo(esquiva.motivo).con_tirada(ataque)
	if esquiva.exitosa:
		return ResultadoAccion.crear_exito(
			[StringName(prefijo + "ataque_esquivado")]
		).con_tirada(ataque).con_tirada_defensa(esquiva)
	var tirada_dano := motor_dados.resolver(
		EfectosEquipo.terminos_dano_armas(contexto.actor), 1,
		TiposTirada.Origen.SOLICITADA if es_jugador else TiposTirada.Origen.AUTOMATICA,
		TiposTirada.Presentacion.PRIMER_PLANO if es_jugador else TiposTirada.Presentacion.SOLO_LOG
	)
	if not tirada_dano.valida:
		return ResultadoAccion.crear_fallo(tirada_dano.motivo).con_tirada(ataque).con_tirada_defensa(esquiva)
	var solicitud := SolicitudEfecto.new(
		contexto.id_accion, &"dano", defensor,
		contexto.id_evento if contexto.id_evento != &"" else contexto.id_accion,
		float(tirada_dano.total_efectivo + EfectosEquipo.bono_fuerza_dano(contexto.actor) + EfectosEquipo.bono_dano(contexto.actor, true)), 0, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, contexto.actor
	)
	var efecto: Variant = aplicador_efectos.aplicar(solicitud)
	if efecto is StringName:
		return ResultadoAccion.crear_fallo(efecto).con_tirada(ataque).con_tirada_defensa(esquiva)
	if es_jugador and efecto.magnitud > 0:
		contexto.actor.golpe_conectado.emit(defensor)
	var efectos: Array = [efecto]
	if efecto.magnitud > 0:
		efectos.append_array(EfectosEquipo.aplicar_impacto(contexto.actor, defensor, true, motor_dados, aplicador_efectos, contexto.id_evento))
	return ResultadoAccion.crear_exito(
		[StringName(prefijo + "ataque_acertado")], efectos
	).con_tirada(ataque).con_tirada_defensa(esquiva).con_tirada_dano(tirada_dano)


static func probabilidad_entre_actores(atacante: Object, defensor: Object) -> float:
	return _probabilidad_prueba(atacante, "fuerza", "ataque") * (1.0 - _probabilidad_prueba(defensor, "destreza", "esquiva"))


static func _probabilidad_prueba(actor: Object, atributo: String, prueba: String) -> float:
	var valor := EfectosEquipo.base(actor, atributo) + EfectosEquipo.bono_atributo(actor, atributo)
	var p := float(clampi(valor, 1, 5)) / 6.0
	var balance := EfectosEquipo.fuentes(actor, atributo, prueba, "ventaja").size() - EfectosEquipo.fuentes(actor, atributo, prueba, "desventaja").size()
	return 1.0 - pow(1.0 - p, 2) if balance > 0 else p * p if balance < 0 else p
