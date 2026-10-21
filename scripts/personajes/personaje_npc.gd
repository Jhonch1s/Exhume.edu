@tool
class_name PersonajeNPC
extends Interactuable

## Instancia viva de un personaje no jugador en el mundo.
## La definición contiene valores base; este nodo contiene identidad y estado de instancia.

signal puntos_vida_cambiados(actual: int, maximo: int)
signal derrota_cambiada(derrotado: bool)
signal muerte_por_danio(fuente: Object)
signal estado_cambiado(clave: StringName, estado: EstadoActor)

@export_category("Identidad del personaje")
@export var nombre_unico: String = ""

@export_category("Estado inicial de la instancia")
@export_range(-1, 999, 1) var vida_inicial: int = -1
@export var atributos_iniciales: Dictionary[StringName, int] = {}
@export_range(0, 99, 1) var nivel_inicial: int = 0

@export_category("Botín")
@export var contenido_inicial: Array[EntradaInventarioInicial] = []
@export var presentacion_botin: DefinicionCofre = preload("res://scenes/interactuables/cofres/cofre_pequeno.tres")

var _inventario: Inventario

var estado_personaje: EstadoPersonajeNPC
## Se reconstruye desde rondas al cargar; no es la relación persistente.
var bando_encuentro: int = GestorRondas.Bando.NEUTRAL
var en_oposicion_encuentro: bool:
	get:
		return bando_encuentro == GestorRondas.Bando.OPONENTE
	set(valor):
		bando_encuentro = GestorRondas.Bando.OPONENTE if valor else GestorRondas.Bando.NEUTRAL
var _origen_inicial: Variant = null
var motor_dados: MotorDados = MotorDados.new()
var aplicador_efectos: AplicadorEfectos = AplicadorEfectos.new()
var movimiento := MovimientoPorCasillas.new()
var esta_moviendose: bool:
	get:
		return movimiento.esta_moviendose
@export_range(0.01, 2.0, 0.01) var velocidad_paso: float = 0.2
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

@onready var sprite_personaje: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var punto_dialogo: Marker2D = get_node_or_null("PuntoDialogo") as Marker2D


signal danio_recibido(cantidad: int, vida_restante: int)
signal derrotado
signal combate_iniciado(npc: PersonajeNPC)

const SONIDO_ESPADA_1: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ataque/Sword Swing 1_3.wav")
const SONIDO_ESPADA_2: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ataque/Sword Swing 1_4.wav")
const SONIDO_QUEMADURA: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/fuego quemadura.wav")
const PARTICULAS_QUEMADO: PackedScene = preload("res://scenes/efectos_superficie/particulas_quemado.tscn")
const SHADER_QUEMADO: Shader = preload("res://assets/ui/shaders/quemado.gdshader")

var reproductor_audio: AudioStreamPlayer2D
var reproductor_proximidad: AudioStreamPlayer2D
var temporizador_proximidad: Timer
var particulas_quemado: Node2D
var material_quemado: ShaderMaterial


func _ready() -> void:
	if definicion is DefinicionPersonaje:
		var perfil := definicion as DefinicionPersonaje
		_actualizar_representacion(true)
		if Engine.is_editor_hint():
			return
		_asegurar_estado()
		_actualizar_visual_quemado()
		if perfil.puede_tener_inventario:
			obtener_inventario()
		_inicializar_audio_npc()
		if not coordenada_cambiada.is_connected(_on_coordenada_cambiada):
			coordenada_cambiada.connect(_on_coordenada_cambiada)


func _actualizar_representacion(inicializar: bool = false) -> void:
	var perfil := obtener_definicion_personaje()
	if perfil == null or not is_instance_valid(sprite_personaje):
		return
	var muerto := vida_inicial == 0 if Engine.is_editor_hint() else esta_muerto()
	var usa_cadaver := muerto and perfil.textura_cadaver != null
	var textura := perfil.textura_cadaver if usa_cadaver else perfil.textura_mapa
	if textura == null:
		return
	var cambiar_frame := inicializar or sprite_personaje.texture != textura
	sprite_personaje.texture = textura
	sprite_personaje.hframes = 1 if usa_cadaver else 2
	sprite_personaje.vframes = 1 if usa_cadaver else 2
	if cambiar_frame:
		sprite_personaje.frame = 0 if usa_cadaver else perfil.orientacion_mapa_inicial
	sprite_personaje.offset = perfil.offset_sprite_mapa


func actualizar_presentacion_visibilidad(estado: int) -> void:
	super.actualizar_presentacion_visibilidad(estado)
	visible = estado == Celda.EstadoVisibilidad.VISIBLE


func obtener_presentacion_inventario() -> DefinicionCofre:
	return presentacion_botin


func _crear_inventario_inicial() -> Inventario:
	var perfil := obtener_definicion_personaje()
	if perfil == null or not perfil.puede_tener_inventario:
		return null
	if (
		id_instancia == &"" or presentacion_botin == null
		or presentacion_botin.columnas < 1 or presentacion_botin.filas < 1
	):
		push_error("Botín de %s: inventario no configurado." % id_instancia)
		return null
	var preparado := Inventario.new()
	preparado.capacidad = presentacion_botin.columnas * presentacion_botin.filas
	for indice in range(contenido_inicial.size()):
		var entrada := contenido_inicial[indice]
		if entrada == null:
			push_error("Botín de %s: entrada inicial vacía." % id_instancia)
			return null
		var resultado := preparado.agregar(ItemInstancia.new(
			StringName("%s:contenido:%d" % [id_instancia, indice]),
			entrada.definicion, entrada.cantidad
		))
		if not resultado.exitosa:
			push_error("Botín de %s: %s" % [id_instancia, resultado.motivo])
			return null
	return preparado


func obtener_inventario() -> Inventario:
	if _inventario == null:
		_inventario = _crear_inventario_inicial()
	return _inventario


func _asegurar_estado() -> EstadoPersonajeNPC:
	if estado_personaje == null:
		estado_personaje = _crear_estado_inicial()
		if estado_personaje != null:
			estado_personaje.coordenada_origen = _origen_inicial
			estado_personaje.estados_temporales.estado_cambiado.connect(_on_estado_temporal_cambiado)
	return estado_personaje


func configurar_registro(tablero_inicial: TableroGrid, coordenada_inicial: Vector2i) -> void:
	super.configurar_registro(tablero_inicial, coordenada_inicial)
	var patrulla := obtener_patrulla()
	if patrulla != null:
		var motivo := patrulla.configurar(tablero_inicial)
		if motivo != &"":
			push_warning("Patrulla de %s desactivada: %s" % [id_instancia, motivo])
	if _origen_inicial == null:
		_origen_inicial = coordenada_inicial
	var estado := _asegurar_estado()
	if estado != null and patrulla != null and patrulla.esta_configurada():
		estado.habilitar_movimiento()
	if estado != null and estado.coordenada_origen == null:
		estado.coordenada_origen = _origen_inicial


func obtener_coordenada_origen() -> Variant:
	var estado := _asegurar_estado()
	return estado.coordenada_origen if estado != null else null


func obtener_patrulla() -> PatrullaNPC:
	return get_node_or_null(^"Patrulla") as PatrullaNPC


func _on_estado_temporal_cambiado(clave: StringName, estado: EstadoActor) -> void:
	if clave == &"quemado":
		_actualizar_visual_quemado()
	estado_cambiado.emit(clave, estado)


func _actualizar_visual_quemado() -> void:
	if not is_instance_valid(sprite_personaje):
		return
	var quemado := obtener_estado(&"quemado") != null and not esta_muerto()
	if quemado:
		if material_quemado == null:
			material_quemado = ShaderMaterial.new()
			material_quemado.shader = SHADER_QUEMADO
		sprite_personaje.material = material_quemado
		if not is_instance_valid(particulas_quemado):
			particulas_quemado = PARTICULAS_QUEMADO.instantiate() as Node2D
			sprite_personaje.add_child(particulas_quemado)
	else:
		sprite_personaje.material = null
		if is_instance_valid(particulas_quemado):
			particulas_quemado.queue_free()
			particulas_quemado = null


func obtener_estado(clave: StringName) -> EstadoActor:
	var estado := _asegurar_estado()
	return estado.estados_temporales.obtener_estado(clave) if estado != null else null


func obtener_claves_estado() -> Array[StringName]:
	var estado := _asegurar_estado()
	return estado.estados_temporales.obtener_claves_estado() if estado != null else []


func retirar_estado(clave: StringName) -> bool:
	var estado := _asegurar_estado()
	return estado != null and estado.estados_temporales.retirar_estado(clave)


func aplicar_o_renovar_estado(
	clave: StringName, magnitud: float, duracion_total: int, ticks_pendientes: int,
	fuente: Object = null, terminos_dano_tick: Array[Dictionary] = []
) -> Dictionary:
	var estado := _asegurar_estado()
	var resultado := (
		estado.estados_temporales.aplicar_o_renovar_estado(
			clave, magnitud, duracion_total, ticks_pendientes, fuente, terminos_dano_tick
		) if estado != null else {}
	)
	if clave == &"quemado" and not resultado.is_empty():
		_reproducir_sonido_quemadura()
	return resultado


func consumir_tick_estado(clave: StringName) -> Dictionary:
	var estado := _asegurar_estado()
	var resultado := estado.estados_temporales.consumir_tick_estado(clave) if estado != null else {}
	if clave == &"quemado" and not resultado.is_empty():
		_reproducir_sonido_quemadura()
	return resultado


func _crear_estado_inicial() -> EstadoPersonajeNPC:
	if not definicion is DefinicionPersonaje:
		return null
	return EstadoPersonajeNPC.new(
		definicion as DefinicionPersonaje,
		vida_inicial,
		atributos_iniciales,
		nivel_inicial,
		obtener_patrulla() != null and obtener_patrulla().esta_configurada()
	)


func esta_derrotado() -> bool:
	return esta_muerto()


func esta_muerto() -> bool:
	var estado := _asegurar_estado()
	return estado != null and estado.esta_muerto()


func puede_actuar() -> bool:
	return not esta_derrotado()


func puede_moverse() -> bool:
	return (
		puede_actuar() and obtener_estado(&"enredado") == null
		and obtener_estado(&"caido") == null
		and obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) >= 0
	)


func validar_paso_movimiento(coste: int) -> bool:
	var estado := _asegurar_estado()
	return (
		estado != null and estado.recursos_turno != null and coste >= 1
		and coste <= estado.recursos_turno.obtener_maximo(RecursosTurnoActor.MOVIMIENTO)
	)


func consumir_paso_movimiento(coste: int) -> void:
	consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, coste)


func orientar_paso_movimiento(origen: Vector2i, destino: Vector2i) -> void:
	if sprite_personaje == null:
		return
	match destino - origen:
		Vector2i.RIGHT:
			sprite_personaje.frame = DefinicionPersonaje.OrientacionMapa.ABAJO_DERECHA
		Vector2i.DOWN:
			sprite_personaje.frame = DefinicionPersonaje.OrientacionMapa.ABAJO_IZQUIERDA
		Vector2i.LEFT:
			sprite_personaje.frame = DefinicionPersonaje.OrientacionMapa.ARRIBA_IZQUIERDA
		Vector2i.UP:
			sprite_personaje.frame = DefinicionPersonaje.OrientacionMapa.ARRIBA_DERECHA


func calcular_duracion_paso(coste: int) -> float:
	return velocidad_paso * (2.0 if coste > 1 else 1.0)


func solicitar_interrupcion() -> void:
	movimiento.solicitar_interrupcion()


func mover_por_camino(
	camino: Array[Vector2i], preparar_paso: Callable, confirmar_paso: Callable,
	cancelar_paso: Callable, procesar_salida: Callable, procesar_entrada: Callable,
	calcular_coste_paso: Callable, recalcular_camino: Callable = Callable(),
	destino_final: Variant = null
) -> bool:
	return await movimiento.mover_por_camino(
		self, camino, tablero.capa_referencia, preparar_paso, confirmar_paso,
		cancelar_paso, procesar_salida, procesar_entrada, calcular_coste_paso,
		Callable(), true, recalcular_camino, destino_final
	)


func admite_restaurar_posicion() -> bool:
	return true


func permite_caminar_estado_guardado(estado: Dictionary) -> bool:
	if estado.is_empty():
		# Un snapshot v1 restaura el estado inicial, no los PV vivos actuales.
		var inicial := _crear_estado_inicial()
		return inicial != null and inicial.esta_derrotado()
	return int(estado["vida_actual"]) == 0


func obtener_id_actor() -> StringName:
	return id_instancia


func obtener_iniciativa() -> int:
	var perfil := obtener_definicion_personaje()
	return perfil.iniciativa_base if perfil != null else 0


func obtener_fuerza() -> int:
	return atributos_actuales.get(&"fuerza", 0)


func obtener_destreza() -> int:
	return atributos_actuales.get(&"destreza", 0)


func obtener_voluntad() -> int:
	return atributos_actuales.get(&"voluntad", 0)


func puede_detectar_jugador(jugador: Ficha, validador: ValidadorEspacialTablero) -> bool:
	var perfil := obtener_definicion_personaje()
	if (
		perfil == null or not perfil.puede_combatir or perfil.radio_agro <= 0
		or not puede_actuar() or jugador == null or not jugador.puede_actuar()
		or validador == null
		or not se_opone_al_jugador()
	):
		return false
	return puede_ver_actor(jugador, validador)


func puede_ver_actor(actor: Object, validador: ValidadorEspacialTablero, radio_maximo: int = -1) -> bool:
	if actor is Ficha and actor.turnos_oculto > 0:
		return false
	return actor != null and puede_ver_coordenada(actor.coordenada_mapa, validador, radio_maximo)


func puede_ver_coordenada(
	coordenada: Vector2i, validador: ValidadorEspacialTablero, radio_maximo: int = -1
) -> bool:
	var perfil := obtener_definicion_personaje()
	if perfil == null or perfil.radio_agro <= 0 or not puede_actuar() or validador == null:
		return false
	var radio := perfil.radio_agro if radio_maximo < 0 else mini(perfil.radio_agro, radio_maximo)
	if Vector2(coordenada - coordenada_mapa).length_squared() > radio * radio:
		return false
	return validador.validar_linea_visual(coordenada_mapa, coordenada) == &""


func obtener_ultima_posicion_conocida() -> Variant:
	var estado := _asegurar_estado()
	return estado.ultima_posicion_conocida if estado != null else null


func recordar_posicion_jugador(coordenada: Vector2i) -> void:
	var estado := _asegurar_estado()
	if estado != null:
		estado.ultima_posicion_conocida = coordenada
		estado.objetivo_recordado_id = &""
	var patrulla := obtener_patrulla()
	if patrulla != null:
		patrulla.cancelar_espera()


func olvidar_posicion_jugador() -> void:
	var estado := _asegurar_estado()
	if estado != null:
		estado.ultima_posicion_conocida = null
		estado.objetivo_recordado_id = &""


func recordar_objetivo(objetivo: Object, coordenada: Vector2i) -> void:
	recordar_posicion_jugador(coordenada)
	if objetivo is PersonajeNPC:
		_asegurar_estado().objetivo_recordado_id = objetivo.obtener_id_actor()


func obtener_id_objetivo_recordado() -> StringName:
	var estado := _asegurar_estado()
	return estado.objetivo_recordado_id if estado != null else &""


func comparte_faccion(otro: PersonajeNPC) -> bool:
	var perfil := obtener_definicion_personaje()
	var otro_perfil := otro.obtener_definicion_personaje() if otro != null else null
	return perfil != null and otro_perfil != null and perfil.faccion_id != &"" and perfil.faccion_id == otro_perfil.faccion_id


func agotar_recursos_turno() -> void:
	for clave in RecursosTurnoActor.CLAVES:
		var restante := obtener_recurso_turno(clave)
		if restante > 0:
			consumir_recurso_turno(clave, restante)


func iniciar_turno() -> void:
	if not puede_actuar():
		return
	var estado := _asegurar_estado()
	if estado != null and estado.recursos_turno != null:
		estado.recursos_turno.reponer(estado.definicion.calcular_movimiento(obtener_destreza()))


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


func recibir_danio(cantidad: int, fuente: Object = null) -> int:
	var estado := _asegurar_estado()
	if estado == null:
		return 0
	var anterior := estado.vida_actual
	var aplicado := estado.recibir_danio(cantidad)
	_notificar_cambio_vida(anterior, estado.vida_actual)
	if aplicado > 0:
		reproducir_gemido_dolor()
		danio_recibido.emit(aplicado, estado.vida_actual)
		if estado.vida_actual == 0:
			derrotado.emit()
	if anterior > 0 and estado.vida_actual == 0:
		muerte_por_danio.emit(fuente)
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
	if actual == 0:
		solicitar_interrupcion()
		olvidar_posicion_jugador()
		agotar_recursos_turno()
	_actualizar_representacion()
	_actualizar_visual_quemado()
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


func obtener_puntos_actitud() -> int:
	var estado := _asegurar_estado()
	return estado.obtener_puntos_actitud() if estado != null else 0


## Operación compartida por acciones y mutaciones de Dialogue Manager.
func modificar_actitud_hacia_jugador(delta: int) -> int:
	var estado := _asegurar_estado()
	return estado.modificar_actitud_hacia_jugador(delta) if estado != null else 0


func obtener_resultado_prueba_dialogo(id_prueba: StringName) -> Variant:
	var estado := _asegurar_estado()
	return estado.resultados_pruebas_dialogo.get(id_prueba) if estado != null else null


func recordar_resultado_prueba_dialogo(id_prueba: StringName, exito: bool) -> void:
	var estado := _asegurar_estado()
	if estado != null:
		estado.resultados_pruebas_dialogo[id_prueba] = exito


func se_opone_al_jugador() -> bool:
	if bando_encuentro != GestorRondas.Bando.NEUTRAL:
		return en_oposicion_encuentro
	return obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.HOSTIL


func obtener_estado_persistente() -> Dictionary:
	var estado := _asegurar_estado()
	var datos := estado.obtener_estado_persistente() if estado != null else {}
	var inventario := obtener_inventario()
	if not datos.is_empty() and inventario != null:
		datos["inventario"] = inventario.obtener_estado_persistente()
	var patrulla := obtener_patrulla()
	if not datos.is_empty() and patrulla != null and patrulla.esta_configurada():
		datos["patrulla"] = patrulla.obtener_estado_persistente()
	return datos


func validar_estado_persistente(datos: Dictionary) -> StringName:
	var estado := estado_personaje
	if estado == null:
		estado = _crear_estado_inicial()
	if estado == null:
		return &"definicion_npc_invalida"
	var datos_actor := datos.duplicate()
	datos_actor.erase("patrulla")
	datos_actor.erase("inventario")
	var motivo := estado.validar_estado_persistente(datos_actor)
	if motivo == &"" and (estado.definicion.puede_tener_inventario or datos.has("inventario")):
		var inventario := _crear_inventario_inicial()
		if inventario == null:
			return &"inventario_npc_no_configurado"
		if datos.has("inventario"):
			motivo = inventario.validar_estado_persistente(datos["inventario"])
	if motivo != &"" or not datos.has("patrulla"):
		return motivo
	var patrulla := obtener_patrulla()
	return patrulla.validar_estado_persistente(datos["patrulla"]) if patrulla != null else &"patrulla_guardada_invalida"


func restaurar_estado_persistente(datos: Dictionary) -> StringName:
	var anterior := vida_actual
	if datos.is_empty():
		# Los guardados v1 no tenían estado de NPC.
		estado_personaje = null
		_inventario = null
		if _asegurar_estado() == null:
			return &"definicion_npc_invalida"
		var patrulla_inicial := obtener_patrulla()
		if patrulla_inicial != null:
			patrulla_inicial.restaurar_estado_persistente()
		_notificar_cambio_vida(anterior, vida_actual)
		_actualizar_visual_quemado()
		return &""
	var estado := _asegurar_estado()
	var motivo := validar_estado_persistente(datos)
	if motivo != &"":
		return motivo
	var datos_actor := datos.duplicate()
	datos_actor.erase("patrulla")
	datos_actor.erase("inventario")
	motivo = estado.restaurar_estado_persistente(datos_actor)
	if motivo == &"":
		# Los guardados anteriores al botín recuperan el contenido inicial.
		_inventario = _crear_inventario_inicial()
		if datos.has("inventario"):
			_inventario.restaurar_estado_persistente(datos["inventario"])
		var patrulla := obtener_patrulla()
		if patrulla != null:
			patrulla.restaurar_estado_persistente(datos.get("patrulla", {}))
		if not datos.has("coordenada_origen"):
			estado.coordenada_origen = _origen_inicial
		_notificar_cambio_vida(anterior, vida_actual)
		_actualizar_visual_quemado()
	return motivo

func _inicializar_audio_npc() -> void:
	if reproductor_audio == null:
		reproductor_audio = AudioStreamPlayer2D.new()
		reproductor_audio.name = "AudioNPC"
		reproductor_audio.max_distance = 600.0
		add_child(reproductor_audio)
	if reproductor_proximidad == null:
		reproductor_proximidad = AudioStreamPlayer2D.new()
		reproductor_proximidad.name = "AudioProximidadNPC"
		reproductor_proximidad.max_distance = 450.0
		add_child(reproductor_proximidad)
	if temporizador_proximidad == null:
		temporizador_proximidad = Timer.new()
		temporizador_proximidad.name = "TimerProximidadNPC"
		temporizador_proximidad.one_shot = true
		temporizador_proximidad.timeout.connect(_on_temporizador_proximidad_timeout)
		add_child(temporizador_proximidad)
		_programar_proximidad()


func _programar_proximidad() -> void:
	if is_instance_valid(temporizador_proximidad) and vida_actual > 0:
		temporizador_proximidad.start(randf_range(14.0, 32.0))


func _on_temporizador_proximidad_timeout() -> void:
	if vida_actual > 0:
		reproducir_sonido_proximidad()
	_programar_proximidad()


func _on_coordenada_cambiada(_anterior: Vector2i, _nueva: Vector2i) -> void:
	reproducir_paso_monstruo()


func mover_a_coordenada(nueva_coordenada: Vector2i) -> void:
	var anterior := coordenada_mapa
	coordenada_mapa = nueva_coordenada
	_ajustar_al_centro_celda()
	coordenada_cambiada.emit(anterior, nueva_coordenada)


func reproducir_paso_monstruo() -> void:
	_inicializar_audio_npc()
	var perfil := obtener_definicion_personaje()
	if perfil != null and is_instance_valid(reproductor_audio):
		var sonido := perfil.obtener_sonido_paso_aleatorio()
		if sonido != null:
			reproductor_audio.stream = sonido
			reproductor_audio.volume_db = -8.0
			reproductor_audio.pitch_scale = randf_range(0.9, 1.1)
			reproductor_audio.play()


func reproducir_gemido_dolor() -> void:
	_inicializar_audio_npc()
	var perfil := obtener_definicion_personaje()
	if perfil != null and is_instance_valid(reproductor_audio):
		var sonido := perfil.obtener_sonido_dolor_aleatorio()
		if sonido != null:
			reproductor_audio.stream = sonido
			reproductor_audio.volume_db = -4.0
			reproductor_audio.pitch_scale = randf_range(0.95, 1.05)
			reproductor_audio.play()


func _reproducir_sonido_quemadura() -> void:
	_inicializar_audio_npc()
	if is_instance_valid(reproductor_audio):
		reproductor_audio.stream = SONIDO_QUEMADURA
		reproductor_audio.volume_db = -6.0
		reproductor_audio.play()


func reproducir_sonido_proximidad() -> void:
	_inicializar_audio_npc()
	var perfil := obtener_definicion_personaje()
	if perfil != null and is_instance_valid(reproductor_proximidad):
		var sonido := perfil.obtener_sonido_proximidad_aleatorio()
		if sonido != null and not reproductor_proximidad.playing:
			reproductor_proximidad.stream = sonido
			reproductor_proximidad.volume_db = -10.0
			reproductor_proximidad.pitch_scale = randf_range(0.95, 1.05)
			reproductor_proximidad.play()


func reproducir_sonido_ataque_espada() -> void:
	_inicializar_audio_npc()
	if is_instance_valid(reproductor_audio):
		reproductor_audio.stream = SONIDO_ESPADA_1 if randf() < 0.5 else SONIDO_ESPADA_2
		reproductor_audio.volume_db = -4.0
		reproductor_audio.pitch_scale = randf_range(0.95, 1.05)
		reproductor_audio.play()


func obtener_nombre_interaccion() -> String:
	var nombre := super.obtener_nombre_interaccion()
	if not nombre_unico.strip_edges().is_empty():
		nombre = nombre_unico.strip_edges()
	return "Cadáver de %s" % nombre if esta_muerto() else nombre


func obtener_fragmentos_informacion() -> Array[FragmentoInformacion]:
	var fragmentos := super.obtener_fragmentos_informacion()
	if esta_muerto():
		var muerte := FragmentoInformacion.new()
		muerte.id_fragmento = &"estado_muerte"
		muerte.id_mensaje = &"examen.npc.cadaver"
		muerte.se_recuerda = false
		fragmentos.append(muerte)
	return fragmentos


func permite_caminar_interactuable() -> bool:
	return esta_derrotado()


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	if esta_derrotado():
		var opciones_derrotado: Array[OpcionAccion] = []
		for opcion in opciones:
			if opcion.id == &"examinar":
				opciones_derrotado.append(opcion)
		if obtener_inventario() != null and _obtener_inventario_actor(actor) != null:
			opciones_derrotado.append(OpcionAccion.crear_habilitada(
				&"recoger_botin", TiposInteraccion.TipoAccion.INTERACTUAR,
				&"interaccion.recoger_botin", self
			))
		return opciones_derrotado
	var perfil := obtener_definicion_personaje()
	if perfil == null:
		return opciones
	if (
		perfil.puede_combatir
		and not esta_derrotado()
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
		String(opcion.id).begins_with("hablar:") or opcion.id in [&"ataque_basico", &"recoger_botin"]
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
	if contexto.id_accion == &"recoger_botin":
		if not esta_derrotado():
			return &"npc_no_derrotado"
		if obtener_inventario() == null:
			return &"inventario_npc_no_configurado"
		if _obtener_inventario_actor(contexto.actor) == null:
			return &"actor_sin_inventario"
		if contexto.alcance_maximo != 1.0 or not contexto.costes_solicitados.is_empty() or contexto.item != null:
			return &"contexto_botin_invalido"
		return &""
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
	if not contexto.actor is Ficha or not contexto.actor.puede_actuar():
		return &"actor_no_puede_atacar"
	var motivo_atributos := ResolverAtaqueBasico.validar_atributos(contexto.actor, self)
	if motivo_atributos != &"":
		return motivo_atributos
	if (
		contexto.alcance_maximo != 1.0
		or contexto.item != null
		or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0}
		or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR
	):
		return &"contexto_ataque_invalido"
	return &""


func _resolver_ataque_basico(contexto: ContextoAccion) -> ResultadoAccion:
	var resultado := ResolverAtaqueBasico.resolver(contexto, self, motor_dados, aplicador_efectos)
	if resultado.tirada == null:
		return resultado
	reproducir_sonido_ataque_espada()
	combate_iniciado.emit(self)
	# El intento cuenta también al fallar o ser esquivado; el daño no lo duplica.
	en_oposicion_encuentro = true
	var delta := modificar_actitud_hacia_jugador(EstadoPersonajeNPC.PENALIZACION_AGRESION)
	if delta == 0:
		return resultado
	var cambios := resultado.cambios_estado
	cambios.append({
		"id_instancia": id_instancia, "clave": &"puntos_actitud", "delta": delta,
		"valor": obtener_puntos_actitud(), "actitud": obtener_actitud_hacia_jugador(),
	})
	return ResultadoAccion.new(
		resultado.estado, resultado.motivo, resultado.mensajes, resultado.efectos_aplicados,
		cambios, resultado.costes_consumidos, resultado.interrumpe_movimiento,
		resultado.terminal, resultado.solicitudes_efecto, resultado.destino_item,
		resultado.tirada, resultado.tirada_defensa
	)


func resolver_golpe_extra_ataque_doble(contexto: ContextoAccion) -> ResultadoAccion:
	# El primer golpe ya pagó la acción principal; se repite únicamente la tirada.
	var motivo := _validar_ataque_basico(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return _resolver_ataque_basico(contexto)


func contiene_punto_visual(punto_global: Vector2) -> bool:
	return (
		is_instance_valid(sprite_personaje)
		and sprite_personaje.texture != null
		and sprite_personaje.is_visible_in_tree()
		and sprite_personaje.is_pixel_opaque(sprite_personaje.to_local(punto_global))
	)


func obtener_definicion_personaje() -> DefinicionPersonaje:
	return definicion as DefinicionPersonaje
