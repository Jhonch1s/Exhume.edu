extends Control

signal nueva_excursion_presionada
signal continuar_presionado
signal opciones_presionadas
signal salir_presionado

@export_group("Animación de entrada")
@export_range(0.2, 2.0, 0.05) var duracion_caida: float = 0.70
@export_range(0.0, 50.0, 1.0) var sobrepaso: float = 22.0
@export_range(0.0, 30.0, 1.0) var rebote: float = 10.0
@export_range(0.0, 8.0, 0.1) var inclinacion_inicial: float = 2.5

@export_group("Reaccion secundaria")
@export_range(0.0, 2.0, 0.05) var intensidad_reaccion: float = 1.0
@export_range(0.0, 0.15, 0.01) var retraso_entre_niveles: float = 0.04

@export_group("Balanceo ambiental")
@export_range(0.0, 3.0, 0.05) var amplitud_balanceo_colas: float = 0.75
@export_range(1.0, 6.0, 0.1) var duracion_balanceo_colas: float = 3.2

@onready var rig_colgante: Control = $RigColgante
@onready var piezas_colgantes: Array[Control] = [
	$RigColgante/Carteles/CartelLogo,
	$RigColgante/Carteles/NuevaExcursion,
	$RigColgante/Carteles/Continuar,
	$RigColgante/Carteles/Opciones,
	$RigColgante/Carteles/Salir,
]
@onready var cola_izquierda: Control = $RigColgante/Cadenas/ColaIzquierdaRig
@onready var cola_derecha: Control = $RigColgante/Cadenas/ColaDerechaRig
@onready var nueva_excursion: TablaMenuOpcion = $RigColgante/Carteles/NuevaExcursion
@onready var continuar: TablaMenuOpcion = $RigColgante/Carteles/Continuar
@onready var opciones: TablaMenuOpcion = $RigColgante/Carteles/Opciones
@onready var salir: TablaMenuOpcion = $RigColgante/Carteles/Salir

var posicion_final_y: float
var rotaciones_base: Dictionary[Control, float] = {}
var balanceo_colas_activo: bool = false
var tiempo_balanceo_colas: float = 0.0


func _ready() -> void:
	set_process(false)

	# menu se movera desde el punto superior entre las cadenas.
	rig_colgante.pivot_offset = Vector2(rig_colgante.size.x * 0.5, 0.0)

	for pieza in piezas_colgantes:
		pieza.pivot_offset = pieza.size * 0.5
		rotaciones_base[pieza] = pieza.rotation_degrees

	nueva_excursion.presionado.connect(nueva_excursion_presionada.emit)
	continuar.presionado.connect(continuar_presionado.emit)
	opciones.presionado.connect(opciones_presionadas.emit)
	salir.presionado.connect(salir_presionado.emit)

	# esperamos a que Godot termine de calcular el layout.
	call_deferred("reproducir_entrada")


func _process(delta: float) -> void:
	if not balanceo_colas_activo:
		return

	tiempo_balanceo_colas += delta
	var fase_izquierda := TAU * tiempo_balanceo_colas / duracion_balanceo_colas
	var fase_derecha := TAU * tiempo_balanceo_colas / (duracion_balanceo_colas * 1.13)
	cola_izquierda.rotation_degrees = sin(fase_izquierda) * amplitud_balanceo_colas
	cola_derecha.rotation_degrees = -sin(fase_derecha) * amplitud_balanceo_colas * 0.85


func reproducir_entrada() -> Signal:
	_detener_balanceo_colas()
	posicion_final_y = rig_colgante.position.y

	# Comienza afuera de la pantalla.
	rig_colgante.position.y = -rig_colgante.size.y - 80.0
	rig_colgante.rotation_degrees = -inclinacion_inicial

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Primero: caída acelerada y como rebote sobrepaso.
	tween.tween_property(
		rig_colgante,
		"position:y",
		posicion_final_y + sobrepaso,
		duracion_caida
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(
		rig_colgante,
		"rotation_degrees",
		1.8,
		duracion_caida
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# El impacto activa la reaccion de cada cartel mientras el rig rebota.
	tween.tween_callback(_reproducir_reaccion_secundaria)

	# Segundo: rebote hacia arriba.
	tween.tween_property(
		rig_colgante,
		"position:y",
		posicion_final_y - rebote,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		rig_colgante,
		"rotation_degrees",
		-0.9,
		0.12
	)

	# Tercero: asentamiento.
	tween.tween_property(
		rig_colgante,
		"position:y",
		posicion_final_y,
		0.20
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		rig_colgante,
		"rotation_degrees",
		0.0,
		0.26
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween.finished


func _reproducir_reaccion_secundaria() -> void:
	for indice in piezas_colgantes.size():
		var pieza := piezas_colgantes[indice]
		var rotacion_base := rotaciones_base[pieza]
		# Cada nivel pierde un 18 % de fuerza y alterna direccion.
		var magnitud := 1.2 * pow(0.82, indice)
		var direccion := 1.0 if indice % 2 == 0 else -1.0
		var amplitud := magnitud * direccion * intensidad_reaccion
		var tween_pieza := create_tween()
		tween_pieza.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_pieza.tween_interval(indice * retraso_entre_niveles)
		tween_pieza.tween_property(
			pieza,
			"rotation_degrees",
			rotacion_base + amplitud,
			0.09
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_pieza.tween_property(
			pieza,
			"rotation_degrees",
			rotacion_base - amplitud * 0.45,
			0.13
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_pieza.tween_property(
			pieza,
			"rotation_degrees",
			rotacion_base,
			0.20
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_sacudir_colas()


func _sacudir_colas() -> void:
	_detener_balanceo_colas()

	var tween_izquierda := create_tween()
	tween_izquierda.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_izquierda.tween_interval(0.08)
	tween_izquierda.tween_property(
		cola_izquierda,
		"rotation_degrees",
		-3.2 * intensidad_reaccion,
		0.11
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_izquierda.tween_property(
		cola_izquierda,
		"rotation_degrees",
		1.4 * intensidad_reaccion,
		0.16
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_izquierda.tween_property(
		cola_izquierda,
		"rotation_degrees",
		0.0,
		0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var tween_derecha := create_tween()
	tween_derecha.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_derecha.tween_interval(0.12)
	tween_derecha.tween_property(
		cola_derecha,
		"rotation_degrees",
		4.2 * intensidad_reaccion,
		0.13
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_derecha.tween_property(
		cola_derecha,
		"rotation_degrees",
		-1.8 * intensidad_reaccion,
		0.19
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_derecha.tween_property(
		cola_derecha,
		"rotation_degrees",
		0.0,
		0.30
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_derecha.finished.connect(_iniciar_balanceo_colas)


func _iniciar_balanceo_colas() -> void:
	tiempo_balanceo_colas = 0.0
	balanceo_colas_activo = amplitud_balanceo_colas > 0.0
	set_process(balanceo_colas_activo)


func _detener_balanceo_colas() -> void:
	balanceo_colas_activo = false
	tiempo_balanceo_colas = 0.0
	set_process(false)
	cola_izquierda.rotation_degrees = 0.0
	cola_derecha.rotation_degrees = 0.0
