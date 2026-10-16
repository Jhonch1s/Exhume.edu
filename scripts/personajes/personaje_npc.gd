@tool
class_name PersonajeNPC
extends Interactuable

## Instancia viva de un personaje no jugador en el mundo.
## La definición contiene valores base; este nodo contiene identidad y estado de instancia.

@export_category("Identidad del personaje")
@export var nombre_unico: String = ""

@export_category("Estado de instancia")
@export_range(0, 999, 1) var vida_actual: int = 0
@export var atributos_actuales: Dictionary[StringName, int] = {}
@export_range(0, 99, 1) var nivel_actual: int = 0

@onready var sprite_personaje: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var punto_dialogo: Marker2D = get_node_or_null("PuntoDialogo") as Marker2D


signal danio_recibido(cantidad: int, vida_restante: int)
signal derrotado
signal combate_iniciado(npc: PersonajeNPC)

const SONIDO_ESPADA_1: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ataque/Sword Swing 1_3.wav")
const SONIDO_ESPADA_2: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ataque/Sword Swing 1_4.wav")

var reproductor_audio: AudioStreamPlayer2D
var reproductor_proximidad: AudioStreamPlayer2D
var temporizador_proximidad: Timer


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
		if vida_actual <= 0:
			vida_actual = perfil.vida_maxima
		if atributos_actuales.is_empty():
			atributos_actuales = {
				&"fuerza": perfil.fuerza,
				&"destreza": perfil.destreza,
				&"voluntad": perfil.voluntad,
			}
		if nivel_actual <= 0:
			nivel_actual = perfil.nivel

	if not Engine.is_editor_hint():
		_inicializar_audio_npc()
		coordenada_cambiada.connect(_on_coordenada_cambiada)


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


func recibir_danio(cantidad: int, _fuente: Object = null) -> int:
	if cantidad <= 0 or vida_actual <= 0:
		return 0
	var anterior := vida_actual
	vida_actual = maxi(0, vida_actual - cantidad)
	var aplicado := anterior - vida_actual
	if aplicado > 0:
		reproducir_gemido_dolor()
		danio_recibido.emit(aplicado, vida_actual)
		if vida_actual == 0:
			derrotado.emit()
	return aplicado


func obtener_nombre_interaccion() -> String:
	if not nombre_unico.strip_edges().is_empty():
		return nombre_unico.strip_edges()
	return super.obtener_nombre_interaccion()


func permite_caminar_interactuable() -> bool:
	return false


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	var perfil := obtener_definicion_personaje()
	if vida_actual > 0:
		opciones.append(OpcionAccion.crear_habilitada(
			&"atacar",
			TiposInteraccion.TipoAccion.INTERACTUAR,
			&"interaccion.atacar",
			self,
			{},
			20
		))
	if perfil == null or not perfil.puede_dialogar:
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
	if opcion != null and (String(opcion.id).begins_with("hablar:") or opcion.id == &"atacar"):
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func obtener_dialogo_por_accion(id_accion: StringName) -> DialogoNPC:
	if not String(id_accion).begins_with("hablar:"):
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
	if contexto.id_accion == &"atacar":
		if vida_actual <= 0:
			return &"personaje_derrotado"
		return &""
	if not String(contexto.id_accion).begins_with("hablar:"):
		return &"accion_no_admitida"
	if obtener_dialogo_por_accion(contexto.id_accion) == null:
		return &"dialogo_no_disponible"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.resolver_accion(contexto)
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if contexto.id_accion == &"atacar":
		reproducir_sonido_ataque_espada()
		combate_iniciado.emit(self)
		var vida_previa := vida_actual
		var danio_aplicado := recibir_danio(4, contexto.actor)
		return ResultadoAccion.crear_exito(
			[&"personaje.atacado"],
			[],
			[{
				&"objetivo_id": id_instancia,
				&"propiedad": &"vida_actual",
				&"anterior": vida_previa,
				&"nueva": vida_actual,
				&"danio": danio_aplicado,
			}]
		)
	return ResultadoAccion.crear_exito()


func contiene_punto_visual(punto_global: Vector2) -> bool:
	return (
		is_instance_valid(sprite_personaje)
		and sprite_personaje.texture != null
		and sprite_personaje.is_visible_in_tree()
		and sprite_personaje.is_pixel_opaque(sprite_personaje.to_local(punto_global))
	)


func obtener_definicion_personaje() -> DefinicionPersonaje:
	return definicion as DefinicionPersonaje
