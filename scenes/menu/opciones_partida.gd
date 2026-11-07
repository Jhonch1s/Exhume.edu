extends Control

signal volver_solicitado_opciones

const SONIDO_CADENAS_MENU: AudioStream = preload("res://assets/sonidos/varios/editados/cadenas menu.wav")

@onready var sliderVolumen: HSlider = $RigUnico/Opciones/Margen/ContenidOpciones/VolumenSeccion/SliderVolume
@onready var textoVolumen: Label = $RigUnico/Opciones/Margen/ContenidOpciones/VolumenSeccion/valorVolumen
@onready var pantalla: CheckButton = $RigUnico/Opciones/Margen/ContenidOpciones/Pantalla
@onready var slider_sacudida: HSlider = $RigUnico/Opciones/Margen/ContenidOpciones/Sacudida/SliderSacudida
@onready var texto_sacudida: Label = $RigUnico/Opciones/Margen/ContenidOpciones/Sacudida/ValorSacudida
@onready var botonVolver: Button = $RigUnico/Volver/BotonVolver

@onready var rig: Control = $RigUnico

@onready var piezas_por_rig: Array[Array] = [
	[$RigUnico/Opciones, $RigUnico/Volver]
] 

@onready var cadenas_por_rig: Array[Array] = [
	$RigUnico/Cadenas.get_children()
]


var posiciones_base: Array[Vector2] = []
var rotaciones_base: Dictionary[Control, float] = {}

func _ready() -> void:
	posiciones_base.append(rig.position)
	
	# Configurar los valores del Slider (de 0.0 a 1.0)
	sliderVolumen.min_value = 0.0
	sliderVolumen.max_value = 1.0
	sliderVolumen.step = 0.05
	
	# Reflejar las preferencias actuales.
	sliderVolumen.value = Preferencias.volumen
	_actualizar_texto_volumen(sliderVolumen.value)
	
	
	sliderVolumen.value_changed.connect(_on_slider_value_change)
	pantalla.button_pressed = Preferencias.pantalla_completa
	pantalla.toggled.connect(_on_pantalla_toggled)
	slider_sacudida.value = Preferencias.sacudida
	_actualizar_sacudida(Preferencias.sacudida)
	slider_sacudida.value_changed.connect(_on_sacudida_changed)
	posiciones_base.append(rig.position)
	rig.pivot_offset = Vector2(rig.size.x * 0.5, 0.0)
	for piezas in piezas_por_rig:
		for pieza: Control in piezas:
			pieza.pivot_offset = pieza.size * 0.5
			rotaciones_base[pieza] = pieza.rotation_degrees
	for cadenas in cadenas_por_rig:
		for cadena: Control in cadenas:
			cadena.pivot_offset = Vector2(cadena.size.x * 0.5, 0.0)
			rotaciones_base[cadena] = cadena.rotation_degrees


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_slider_value_change(valor: float) -> void:
	Preferencias.volumen = valor
	Preferencias.aplicar_volumen()
	Preferencias.guardar()
	_actualizar_texto_volumen(valor)

func _on_pantalla_toggled(activa: bool) -> void:
	Preferencias.pantalla_completa = activa
	Preferencias.aplicar_pantalla()
	Preferencias.guardar()

func _on_sacudida_changed(valor: float) -> void:
	Preferencias.sacudida = valor
	Preferencias.guardar()
	_actualizar_sacudida(valor)

func _actualizar_sacudida(valor: float) -> void:
	texto_sacudida.text = "%d%%" % int(valor * 100)


func _actualizar_texto_volumen(valor: float) -> void:
	# Muestra el porcentaje de 0% a 100% en el Label
	var porcentaje := int(valor * 100)
	textoVolumen.text = "%d%%" % porcentaje


func _on_boton_pressed() -> void:
	volver_solicitado_opciones.emit()
	
func _reproducir_sonido_cadenas() -> void:
	if not is_inside_tree():
		return
	var rep := get_node_or_null("AudioCadenasMenu") as AudioStreamPlayer
	if rep == null:
		rep = AudioStreamPlayer.new()
		rep.name = "AudioCadenasMenu"
		rep.stream = SONIDO_CADENAS_MENU
		rep.volume_db = -4.0
		add_child(rep)
	rep.pitch_scale = randf_range(0.97, 1.03)
	rep.play()


func reproducir_entrada() -> Signal:
	show()
	_reproducir_sonido_cadenas()
	# Caída inicial desde arriba con pequeña inclinación
	rig.position.y = -rig.size.y - 100.0
	rig.rotation_degrees = -2.5
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Caída libre acelerada
	tween.tween_property(rig, "position:y", posiciones_base[0].y + 22.0, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(rig, "rotation_degrees", 1.8, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# Sacudida física de cadenas y piezas al caer en su posición
	tween.tween_callback(_sacudir_rig)
	
	# Rebote elástico
	tween.tween_property(rig, "position:y", posiciones_base[0].y - 10.0, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(rig, "rotation_degrees", -0.9, 0.12)
	
	tween.tween_property(rig, "position:y", posiciones_base[0].y, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(rig, "rotation_degrees", 0.0, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	return tween.finished


func _sacudir_rig() -> void:
	# Animación de bamboleo leve para piezas
	for indice in piezas_por_rig[0].size():
		var pieza: Control = piezas_por_rig[0][indice]
		var amplitud := 1.4 * pow(0.82, indice) * (1.0 if indice % 2 == 0 else -1.0)
		var tween := create_tween()
		tween.tween_interval(indice * 0.04)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza] + amplitud, 0.09)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza] - amplitud * 0.45, 0.13)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza], 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Animación de inercia/bamboleo para las cadenas del rig único
	for indice in cadenas_por_rig[0].size():
		var cadena: Control = cadenas_por_rig[0][indice]
		var direccion := 1.0 if indice % 2 == 0 else -1.0
		var tween := create_tween()
		tween.tween_interval(0.04 + indice * 0.015)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena] + 3.2 * direccion, 0.11)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena] - 1.4 * direccion, 0.16)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena], 0.24) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func reproducir_salida() -> Signal:
	var tween := create_tween()
	# Eleva el rig fuera de pantalla hacia arriba
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(rig, "position:y", -rig.size.y - 100.0, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween.finished
	
