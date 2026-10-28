class_name PantallaMuerte
extends CanvasLayer

signal reiniciar_solicitado
signal cargar_solicitado
signal menu_principal_solicitado

const SONIDO_HAS_MUERTO: AudioStream = preload("res://assets/sonidos/narrador/has muerto.mp3")
const SONIDO_TENSION: AudioStream = preload("res://assets/sonidos/tension/Tension.wav")
const RUTA_GUARDADO: String = "user://partida.json"

@onready var fondo_negro: ColorRect = $FondoNegro
@onready var niebla_roja: TextureRect = $FondoNegro/NieblaRoja
@onready var contenedor_central: VBoxContainer = $FondoNegro/ContenedorCentral
@onready var etiqueta_titulo: Label = $FondoNegro/ContenedorCentral/TituloMuerte
@onready var etiqueta_subtitulo: Label = $FondoNegro/ContenedorCentral/SubtituloMuerte
@onready var imagen_personalizada: TextureRect = $FondoNegro/ContenedorCentral/ImagenMuertePersonalizada
@onready var boton_reiniciar: Button = $FondoNegro/ContenedorCentral/Botonera/BotonVolverJugar
@onready var boton_cargar: Button = $FondoNegro/ContenedorCentral/Botonera/BotonCargar
@onready var reproductor_tension: AudioStreamPlayer = $AudioTensionMuerte
@onready var reproductor_narrador: AudioStreamPlayer = $AudioNarradorMuerte

var _mostrada: bool = false
var guardado_previo_permitido: bool = false


func _ready() -> void:
	visible = false
	fondo_negro.modulate.a = 0.0
	boton_reiniciar.pressed.connect(func(): reiniciar_solicitado.emit())
	boton_cargar.pressed.connect(func():
		if puede_cargar_partida():
			cargar_solicitado.emit()
	)
	_actualizar_estado_boton_cargar()


func puede_cargar_partida() -> bool:
	if not guardado_previo_permitido:
		return false
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return false
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		return false
	var contenido := archivo.get_as_text()
	archivo.close()
	var json := JSON.new()
	if json.parse(contenido) != OK or not json.data is Dictionary:
		return false
	var datos: Dictionary = json.data
	if not datos.has("ficha") or datos.get("ficha") == null:
		return false
	# Solo se permite cargar si se guardó previamente en la fogata / campamento
	return bool(datos.get("guardado_en_fogata", false)) or bool(datos.get("en_campamento", false))


func _actualizar_estado_boton_cargar() -> void:
	var puede_cargar := puede_cargar_partida()
	if is_instance_valid(boton_cargar):
		boton_cargar.disabled = not puede_cargar
		boton_cargar.modulate = Color(1.0, 1.0, 1.0, 1.0) if puede_cargar else Color(1.0, 1.0, 1.0, 0.35)
		boton_cargar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if puede_cargar else Control.CURSOR_FORBIDDEN
		if not puede_cargar:
			boton_cargar.tooltip_text = "No has guardado partida previamente en la fogata"
		else:
			boton_cargar.tooltip_text = "Cargar partida guardada en la fogata"


func mostrar_muerte(guardado_realizado: bool = false) -> void:
	if _mostrada:
		return
	_mostrada = true
	guardado_previo_permitido = guardado_realizado
	visible = true
	fondo_negro.modulate.a = 0.0
	_actualizar_estado_boton_cargar()
	
	_reproducir_audios_muerte()
	
	var tween := create_tween()
	tween.tween_property(fondo_negro, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	boton_reiniciar.grab_focus()


func _reproducir_audios_muerte() -> void:
	if is_instance_valid(reproductor_tension):
		reproductor_tension.volume_db = -2.0
		reproductor_tension.stream = SONIDO_TENSION
		reproductor_tension.play()
	
	if is_instance_valid(reproductor_narrador):
		# Volumen alto para que resalte claramente sobre cualquier otro sonido
		reproductor_narrador.volume_db = 3.5
		reproductor_narrador.stream = SONIDO_HAS_MUERTO
		reproductor_narrador.play()


func asignar_imagen_muerte(textura: Texture2D) -> void:
	if imagen_personalizada != null and textura != null:
		imagen_personalizada.texture = textura
		imagen_personalizada.visible = true
