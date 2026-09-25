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

@export_category("Relación con el jugador")
@export var actitud_inicial_jugador: ActitudInicialJugador = ActitudInicialJugador.NEUTRAL
@export var actitud_hacia_jugador_fija: bool = false

@export_category("Capacidades")
@export var puede_dialogar: bool = false
@export var puede_combatir: bool = false
@export var puede_tener_inventario: bool = false

@export_category("Presentación")
@export var textura_mapa: Texture2D
@export var orientacion_mapa_inicial: OrientacionMapa = OrientacionMapa.ABAJO_DERECHA
@export var offset_sprite_mapa: Vector2 = Vector2(0.0, -32.0)
@export_category("Dialogos")
@export var ilustracion_dialogo: Texture2D
@export var dialogos: Array[DialogoNPC] = []
