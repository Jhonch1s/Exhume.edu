class_name DefinicionPersonaje
extends DefinicionInteractuable

## Plantilla compartida por los personajes de un mismo tipo.
## Los valores concretos se dejan para los recursos .tres de cada personaje.

enum ActitudInicialJugador {
	NEUTRAL,
	AMISTOSA,
	HOSTIL,
}

## Orden de frames para hojas de sprites 2x2:
## fila 0: abajo derecha, abajo izquierda;
## fila 1: arriba izquierda, arriba derecha.
enum OrientacionMapa {
	ABAJO_DERECHA,
	ABAJO_IZQUIERDA,
	ARRIBA_IZQUIERDA,
	ARRIBA_DERECHA,
}

@export_category("Atributos y supervivencia")
@export_range(0, 99, 1) var fuerza: int = 0
@export_range(0, 99, 1) var destreza: int = 0
@export_range(0, 99, 1) var voluntad: int = 0
@export_range(0, 999, 1) var vida_maxima: int = 0
@export_range(1, 99, 1) var nivel: int = 1
@export_range(0, 999999, 1) var experiencia_recompensa_derrota: int = 0
@export var iniciativa_base: int = 0

@export_category("Relación con el jugador")
## Vacío significa sin facción; no reúne a los demás NPC sin facción.
@export var faccion_id: StringName = &""
@export var actitud_inicial_jugador: ActitudInicialJugador = ActitudInicialJugador.NEUTRAL
@export var actitud_hacia_jugador_fija: bool = false

@export_category("Capacidades")
@export var puede_dialogar: bool = false
@export var puede_combatir: bool = false
@export var puede_tener_inventario: bool = false

@export_category("Detección del jugador")
@export_range(0, 20, 1) var radio_agro: int = 4

@export_category("Recursos de combate")
## -1 conserva DES + 3; un valor mayor o igual a cero fija los puntos por turno.
@export_range(-1, 102, 1) var movimiento_fijo: int = -1
@export_range(0, 9, 1) var acciones_principales_por_turno: int = 1
@export_range(0, 9, 1) var acciones_adicionales_por_turno: int = 1
@export_range(0, 9, 1) var reacciones_por_turno: int = 1

@export_category("Presentación")
@export var textura_mapa: Texture2D
@export var retrato_turno: Texture2D
## Imagen única, sin frames; si falta se conserva el sprite actual del personaje.
@export var textura_cadaver: Texture2D
@export var orientacion_mapa_inicial: OrientacionMapa = OrientacionMapa.ABAJO_DERECHA
@export var offset_sprite_mapa: Vector2 = Vector2(0.0, -32.0)
@export_category("Dialogos")
@export var ilustracion_dialogo: Texture2D
@export var dialogos: Array[DialogoNPC] = []

func calcular_movimiento(destreza_actual: int) -> int:
	return movimiento_fijo if movimiento_fijo >= 0 else RecursosTurnoActor.calcular_movimiento(destreza_actual)

@export_category("Audio")
@export var sonidos_pasos: Array[AudioStream] = []
@export var sonidos_dolor: Array[AudioStream] = []
@export var sonidos_proximidad: Array[AudioStream] = []
@export_range(50.0, 1000.0, 10.0) var radio_audio_proximidad: float = 380.0

const PASOS_MONSTRUO_DEFECTO: Array[AudioStream] = [
	preload("res://assets/sonidos/sonidos finales/sonido monstro/Monster Walking 01.wav"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/Monster Walking 03.wav"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/Monster Big Walking 2_05.wav"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/Monster Big Walking 2_07.wav"),
]

const DOLOR_MONSTRUO_DEFECTO: Array[AudioStream] = [
	preload("res://assets/sonidos/sonidos finales/sonido monstro/hit 14 eahh (weak).mp3"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/hit 17 ouw (weak).mp3"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/hit 5 ah (weak).mp3"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/holler 82 fast yell (strong).mp3"),
]

const PROXIMIDAD_MONSTRUO_DEFECTO: Array[AudioStream] = [
	preload("res://assets/sonidos/sonidos finales/sonido monstro/huff 6 exhale inhale exhale (weak).mp3"),
	preload("res://assets/sonidos/sonidos finales/sonido monstro/holler 117 short burst (strong).wav"),
	preload("res://assets/sonidos/enemigo/munstro con cadenas.wav"),
]


func obtener_sonido_paso_aleatorio() -> AudioStream:
	var lista := sonidos_pasos if not sonidos_pasos.is_empty() else PASOS_MONSTRUO_DEFECTO
	return lista.pick_random() if not lista.is_empty() else null


func obtener_sonido_dolor_aleatorio() -> AudioStream:
	var lista := sonidos_dolor if not sonidos_dolor.is_empty() else DOLOR_MONSTRUO_DEFECTO
	return lista.pick_random() if not lista.is_empty() else null


func obtener_sonido_proximidad_aleatorio() -> AudioStream:
	var lista := sonidos_proximidad if not sonidos_proximidad.is_empty() else PROXIMIDAD_MONSTRUO_DEFECTO
	return lista.pick_random() if not lista.is_empty() else null
