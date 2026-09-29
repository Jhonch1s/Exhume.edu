@tool
class_name PersonajeNPC
extends Interactuable

## Instancia viva de un personaje no jugador en el mundo.
## La definición contiene valores base; este nodo contiene identidad y estado de instancia.

signal puntos_vida_cambiados(actual: int, maximo: int)
signal derrota_cambiada(derrotado: bool)

@export_category("Identidad del personaje")
@export var nombre_unico: String = ""

@export_category("Estado inicial de la instancia")
@export_range(-1, 999, 1) var vida_inicial: int = -1
@export var atributos_iniciales: Dictionary[StringName, int] = {}
@export_range(0, 99, 1) var nivel_inicial: int = 0

var estado_personaje: EstadoPersonajeNPC
var motor_dados: MotorDados = MotorDados.new()
var aplicador_efectos: AplicadorEfectos = AplicadorEfectos.new()
var vida_actual: int:
	get:
		var estado := _asegurar_estado()
		return estado.vida_actual if estado != null else 0
	set(valor):
		var estado := _asegurar_estado()
		if estado != null:
			var anterior := estado.vida_actual
			estado.vida_actual = clampi(valor, 0, estado.definicion.vida_maxima)
			_notificar_cambio_vida(anterior, estado.vida_actual)
var atributos_actuales: Dictionary[StringName, int]:
	get:
		var estado := _asegurar_estado()
		return estado.atributos_actuales if estado != null else {}
	set(valor):
		var estado := _asegurar_estado()
		if estado != null:
			estado.atributos_actuales = valor.duplicate()
var nivel_actual: int:
	get:
		var estado := _asegurar_estado()
		return estado.nivel_actual if estado != null else 0
	set(valor):
		var estado := _asegurar_estado()
		if estado != null:
			estado.nivel_actual = valor

@onready var sprite_personaje: Sprite2D = $Sprite2D
@onready var punto_dialogo: Marker2D = $PuntoDialogo


func _ready() -> void:
	if definicion is DefinicionPersonaje:
		var perfil := definicion as DefinicionPersonaje
		if sprite_personaje != null and perfil.textura_mapa != null:
			sprite_personaje.texture = perfil.textura_mapa
			sprite_personaje.hframes = 2
			sprite_personaje.vframes = 2
			sprite_personaje.frame = perfil.orientacion_mapa_inicial
			sprite_personaje.offset = perfil.offset_sprite_mapa
		if Engine.is_editor_hint():
			return
		_asegurar_estado()


func _asegurar_estado() -> EstadoPersonajeNPC:
	if estado_personaje == null:
		estado_personaje = _crear_estado_inicial()
	return estado_personaje


func _crear_estado_inicial() -> EstadoPersonajeNPC:
	if not definicion is DefinicionPersonaje:
		return null
	return EstadoPersonajeNPC.new(
		definicion as DefinicionPersonaje,
		vida_inicial,
		atributos_iniciales,
		nivel_inicial
	)


func esta_derrotado() -> bool:
	var estado := _asegurar_estado()
	return estado != null and estado.esta_derrotado()


func puede_actuar() -> bool:
	return not esta_derrotado()


func obtener_id_actor() -> StringName:
	return id_instancia


func obtener_iniciativa() -> int:
	var perfil := obtener_definicion_personaje()
	return perfil.iniciativa_base if perfil != null else 0


func iniciar_turno() -> void:
	var estado := _asegurar_estado()
	if estado != null and estado.recursos_turno != null:
		estado.recursos_turno.reponer()


func obtener_recurso_turno(clave: StringName) -> int:
	var estado := _asegurar_estado()
	return estado.recursos_turno.obtener(clave) if estado != null and estado.recursos_turno != null else -1


func validar_coste_turno(clave: StringName, cantidad: int) -> StringName:
	var estado := _asegurar_estado()
	if estado == null or estado.recursos_turno == null:
		return &"recurso_turno_no_soportado"
	return estado.recursos_turno.validar_consumo(clave, cantidad)


func consumir_recurso_turno(clave: StringName, cantidad: int) -> bool:
	var estado := _asegurar_estado()
	return (
		estado != null
		and estado.recursos_turno != null
		and estado.recursos_turno.consumir(clave, cantidad)
	)


func recibir_danio(cantidad: int, _fuente: Object = null) -> int:
	var estado := _asegurar_estado()
	if estado == null:
		return 0
	var anterior := estado.vida_actual
	var aplicado := estado.recibir_danio(cantidad)
	_notificar_cambio_vida(anterior, estado.vida_actual)
	return aplicado


func curar(cantidad: int, _fuente: Object = null) -> int:
	var estado := _asegurar_estado()
	if estado == null:
		return 0
	var anterior := estado.vida_actual
	var aplicado := estado.curar(cantidad)
	_notificar_cambio_vida(anterior, estado.vida_actual)
	return aplicado


func _notificar_cambio_vida(anterior: int, actual: int) -> void:
	if anterior == actual:
		return
	puntos_vida_cambiados.emit(actual, estado_personaje.definicion.vida_maxima)
	if (anterior == 0) != (actual == 0):
		derrota_cambiada.emit(actual == 0)
		presencia_cambiada.emit()


func obtener_actitud_hacia_jugador() -> int:
	var estado := _asegurar_estado()
	return estado.obtener_actitud_hacia_jugador() if estado != null else 0


func establecer_actitud_hacia_jugador(nueva_actitud: int) -> bool:
	var estado := _asegurar_estado()
	return estado != null and estado.establecer_actitud_hacia_jugador(nueva_actitud)


func obtener_estado_persistente() -> Dictionary:
	var estado := _asegurar_estado()
	return estado.obtener_estado_persistente() if estado != null else {}


func validar_estado_persistente(datos: Dictionary) -> StringName:
	var estado := estado_personaje
	if estado == null:
		estado = _crear_estado_inicial()
	return (
		estado.validar_estado_persistente(datos)
		if estado != null else &"definicion_npc_invalida"
	)


func restaurar_estado_persistente(datos: Dictionary) -> StringName:
	var anterior := vida_actual
	if datos.is_empty():
		# Los guardados v1 no tenían estado de NPC.
		estado_personaje = null
		if _asegurar_estado() == null:
			return &"definicion_npc_invalida"
		_notificar_cambio_vida(anterior, vida_actual)
		return &""
	var estado := _asegurar_estado()
	var motivo := (
		estado.restaurar_estado_persistente(datos)
		if estado != null else &"definicion_npc_invalida"
	)
	if motivo == &"":
		_notificar_cambio_vida(anterior, vida_actual)
	return motivo


func obtener_nombre_interaccion() -> String:
	if not nombre_unico.strip_edges().is_empty():
		return nombre_unico.strip_edges()
	return super.obtener_nombre_interaccion()


func permite_caminar_interactuable() -> bool:
	return esta_derrotado()


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	if esta_derrotado():
		var opciones_derrotado: Array[OpcionAccion] = []
		for opcion in opciones:
			if opcion.id == &"examinar":
				opciones_derrotado.append(opcion)
		return opciones_derrotado
	var perfil := obtener_definicion_personaje()
	if perfil == null:
		return opciones
	if (
		perfil.puede_combatir
		and not esta_derrotado()
		and obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.HOSTIL
		and actor is Ficha
		and actor.puede_actuar()
	):
		opciones.append(OpcionAccion.crear_habilitada(
			&"ataque_basico",
			TiposInteraccion.TipoAccion.INTERACTUAR,
			&"interaccion.atacar",
			self,
			{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
			20,
			false,
			{},
			TiposInteraccion.TipoLineaEfecto.NINGUNA,
			TiposInteraccion.PoliticaCobro.AL_INTENTAR
		))
	if not perfil.puede_dialogar:
		return opciones
	for dialogo in perfil.dialogos:
		if dialogo == null or not dialogo.es_valido():
			continue
		var texto_opcion := (
			&"interaccion.hablar" if perfil.dialogos.size() == 1
			else StringName("Hablar: " + dialogo.titulo)
		)
		opciones.append(OpcionAccion.crear_habilitada(
			StringName("hablar:" + String(dialogo.id_dialogo)),
			TiposInteraccion.TipoAccion.INTERACTUAR,
			texto_opcion,
			self,
			{},
			10
		))
	return opciones


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion != null and (
		String(opcion.id).begins_with("hablar:") or opcion.id == &"ataque_basico"
	):
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func obtener_dialogo_por_accion(id_accion: StringName) -> DialogoNPC:
	if esta_derrotado() or not String(id_accion).begins_with("hablar:"):
		return null
	var perfil := obtener_definicion_personaje()
	if perfil == null or not perfil.puede_dialogar:
		return null
	for dialogo in perfil.dialogos:
		if (
			dialogo != null
			and dialogo.es_valido()
			and id_accion == StringName("hablar:" + String(dialogo.id_dialogo))
		):
			return dialogo
	return null


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.validar_accion(contexto)
	if contexto.objetivo != self or contexto.celda_objetivo != coordenada_mapa:
		return &"objetivo_no_coincide"
	if contexto.id_accion == &"ataque_basico":
		return _validar_ataque_basico(contexto)
	if not String(contexto.id_accion).begins_with("hablar:"):
		return &"accion_no_admitida"
	if esta_derrotado():
		return &"npc_derrotado"
	if obtener_dialogo_por_accion(contexto.id_accion) == null:
		return &"dialogo_no_disponible"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if contexto.id_accion == &"ataque_basico":
		return _resolver_ataque_basico(contexto)
	return ResultadoAccion.crear_exito()


func _validar_ataque_basico(contexto: ContextoAccion) -> StringName:
	var perfil := obtener_definicion_personaje()
	if perfil == null or not perfil.puede_combatir:
		return &"npc_no_combatiente"
	if esta_derrotado():
		return &"npc_derrotado"
	if obtener_actitud_hacia_jugador() != DefinicionPersonaje.ActitudInicialJugador.HOSTIL:
		return &"npc_no_hostil"
	if not contexto.actor is Ficha or not contexto.actor.puede_actuar():
		return &"actor_no_puede_atacar"
	if contexto.actor.obtener_fuerza() < 1 or contexto.actor.obtener_fuerza() > 5:
		return &"atributo_prueba_invalido"
	if (
		contexto.alcance_maximo != 1.0
		or contexto.item != null
		or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0}
		or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR
	):
		return &"contexto_ataque_invalido"
	return &""


func _resolver_ataque_basico(contexto: ContextoAccion) -> ResultadoAccion:
	var prueba := motor_dados.resolver_prueba(
		contexto.actor.obtener_fuerza(), [], [],
		TiposTirada.Origen.SOLICITADA, TiposTirada.Presentacion.PRIMER_PLANO
	)
	if not prueba.valida:
		return ResultadoAccion.crear_fallo(prueba.motivo)
	if not prueba.exitosa:
		return ResultadoAccion.crear_exito([&"combate.ataque_fallido"]).con_tirada(prueba)
	var solicitud := SolicitudEfecto.new(
		&"ataque_basico", &"dano", self, &"ataque_basico", 1.0,
		0, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, contexto.actor
	)
	var efecto: Variant = aplicador_efectos.aplicar(solicitud)
	if efecto is StringName:
		return ResultadoAccion.crear_fallo(efecto).con_tirada(prueba)
	return ResultadoAccion.crear_exito(
		[&"combate.ataque_acertado"], [efecto]
	).con_tirada(prueba)


func contiene_punto_visual(punto_global: Vector2) -> bool:
	return (
		is_instance_valid(sprite_personaje)
		and sprite_personaje.texture != null
		and sprite_personaje.is_visible_in_tree()
		and sprite_personaje.is_pixel_opaque(sprite_personaje.to_local(punto_global))
	)


func obtener_definicion_personaje() -> DefinicionPersonaje:
	return definicion as DefinicionPersonaje
