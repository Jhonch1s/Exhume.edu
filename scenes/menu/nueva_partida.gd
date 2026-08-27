extends Control

signal volver_solicitado
signal excursion_solicitada(datos: Dictionary)

const RETRATO_INICIAL := preload("res://assets/ui/panels/new_game/nadie.png")
const SHADER_REVELADO := preload("res://assets/ui/shaders/revelado_quemado.gdshader")
const RETRATOS := {
	"Guerrero": preload("res://assets/ui/panels/new_game/knight.jpg"),
	"Ladrón": preload("res://assets/ui/panels/new_game/rogue.png"),
	"Mago": preload("res://assets/ui/panels/new_game/mage.png"),
}
const CLASE_POR_ATRIBUTO := {&"fuerza": "Guerrero", &"destreza": "Ladrón", &"voluntad": "Mago"}
const ORIGENES := ["Mina Ciénaga", "Bastión Solitario", "Cripta Apócrifa", "Páramo Ceniciento"]

@onready var rigs: Array[Control] = [$RigIzquierdo, $RigCentral, $RigDerecho]
@onready var piezas_por_rig: Array[Array] = [
	[$RigIzquierdo/Encabezado, $RigIzquierdo/Atributos, $RigIzquierdo/Volver],
	[$RigCentral/Ficha],
	[$RigDerecho/Ritual, $RigDerecho/ComenzarRig],
]
@onready var cadenas_por_rig: Array[Array] = [
	$RigIzquierdo/Cadenas.get_children(),
	$RigCentral/Cadenas.get_children(),
	$RigDerecho/Cadenas.get_children(),
]
@onready var valores := {
	&"fuerza": $RigIzquierdo/Atributos/Margen/Contenido/Fuerza/Valor,
	&"destreza": $RigIzquierdo/Atributos/Margen/Contenido/Destreza/Valor,
	&"voluntad": $RigIzquierdo/Atributos/Margen/Contenido/Voluntad/Valor,
}
@onready var botones_tirada := {
	&"fuerza": $RigIzquierdo/Atributos/Margen/Contenido/Fuerza/Tirar,
	&"destreza": $RigIzquierdo/Atributos/Margen/Contenido/Destreza/Tirar,
	&"voluntad": $RigIzquierdo/Atributos/Margen/Contenido/Voluntad/Tirar,
}
@onready var estado_atributos: Label = $RigIzquierdo/Atributos/Margen/Contenido/Estado
@onready var zona_dado: Label = $RigIzquierdo/Atributos/Margen/Contenido/ZonaTirada/MarginContainer/Texto
@onready var retrato: TextureRect = $RigCentral/Ficha/Margen/Contenido/IlustracionClase
@onready var nombre: LineEdit = $RigCentral/Ficha/Margen/Contenido/Nombre
@onready var titulo_aventurero: LineEdit = $RigCentral/Ficha/Margen/Contenido/TituloAventurero
@onready var resumen_pv: Label = $RigCentral/Ficha/Margen/Contenido/Resumen/PV
@onready var resumen_clase: Label = $RigCentral/Ficha/Margen/Contenido/Resumen/Clase
@onready var resumen_origen: Label = $RigCentral/Ficha/Margen/Contenido/Origen
@onready var eleccion_empate: HBoxContainer = $RigCentral/Ficha/Margen/Contenido/EleccionEmpate
@onready var botones_clase := {
	"Guerrero": $RigCentral/Ficha/Margen/Contenido/EleccionEmpate/Guerrero,
	"Ladrón": $RigCentral/Ficha/Margen/Contenido/EleccionEmpate/Ladron,
	"Mago": $RigCentral/Ficha/Margen/Contenido/EleccionEmpate/Mago,
}
@onready var paneles_origen: Array[PanelContainer] = [
	$RigDerecho/Ritual/Margen/Contenido/Origenes/OrigenI,
	$RigDerecho/Ritual/Margen/Contenido/Origenes/OrigenII,
	$RigDerecho/Ritual/Margen/Contenido/Origenes/OrigenIII,
	$RigDerecho/Ritual/Margen/Contenido/Origenes/OrigenIV,
]
@onready var relicario: Button = $RigDerecho/Ritual/Margen/Contenido/Relicario
@onready var estado_origen: Label = $RigDerecho/Ritual/Margen/Contenido/Estado
@onready var comenzar: Button = $RigDerecho/ComenzarRig/Tabla/Comenzar

var posiciones_base: Array[Vector2] = []
var rotaciones_base: Dictionary[Control, float] = {}
var atributos: Dictionary[StringName, int] = {}
var clase := ""
var origen := ""
var marcador_relicario: Label


func _ready() -> void:
	for rig in rigs:
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
	for atributo: StringName in botones_tirada:
		botones_tirada[atributo].pressed.connect(_tirar_atributo.bind(atributo))
	for nombre_clase: String in botones_clase:
		botones_clase[nombre_clase].pressed.connect(_elegir_clase.bind(nombre_clase))
	nombre.text_changed.connect(func(_texto: String) -> void: _actualizar_comenzar())
	relicario.pressed.connect(_sortear_origen)
	comenzar.pressed.connect(_solicitar_excursion)
	retrato.texture = RETRATO_INICIAL
	_actualizar_comenzar()


func _tirar_atributo(atributo: StringName) -> void:
	botones_tirada[atributo].disabled = true
	var resultado := 0
	while resultado == 0 or resultado == 1 or resultado == 6:
		resultado = randi_range(1, 6)
		zona_dado.text = "PLACEHOLDER DADO\n[ %d ]" % resultado
		await get_tree().create_timer(0.55).timeout
		if resultado == 1 or resultado == 6:
			zona_dado.text = "PLACEHOLDER DADO\n[ %d ] — REPITE" % resultado
			await get_tree().create_timer(0.4).timeout
	atributos[atributo] = resultado
	valores[atributo].text = str(resultado)
	zona_dado.text = "PLACEHOLDER DADO\nRESULTADO: %d" % resultado
	estado_atributos.text = "%d de 3 atributos resueltos" % atributos.size()
	if atributos.size() == 3:
		resolver_clase()
	_actualizar_comenzar()


func resolver_clase() -> void:
	var mayor: int = atributos.values().max()
	var candidatas: Array[String] = []
	for atributo: StringName in atributos:
		if atributos[atributo] == mayor:
			candidatas.append(CLASE_POR_ATRIBUTO[atributo])
	if candidatas.size() == 1:
		_elegir_clase(candidatas[0])
		return
	eleccion_empate.show()
	resumen_clase.text = "CLASE: ELIGE ENTRE LOS EMPATES"
	for nombre_clase: String in botones_clase:
		botones_clase[nombre_clase].visible = nombre_clase in candidatas


func _elegir_clase(nueva_clase: String) -> void:
	clase = nueva_clase
	_revelar_retrato(RETRATOS[clase])
	resumen_clase.text = "CLASE: %s" % clase.to_upper()
	resumen_pv.text = "PV MÁXIMOS: %d" % _pv_maximos()
	eleccion_empate.hide()
	_actualizar_comenzar()


func _revelar_retrato(nuevo_retrato: Texture2D) -> void:
	var material_quemado := ShaderMaterial.new()
	material_quemado.shader = SHADER_REVELADO
	material_quemado.set_shader_parameter(&"retrato_nuevo", nuevo_retrato)
	material_quemado.set_shader_parameter(&"avance", 0.0)
	retrato.material = material_quemado
	var tween := create_tween()
	tween.tween_method(
		func(valor: float) -> void: material_quemado.set_shader_parameter(&"avance", valor),
		0.0,
		1.05,
		0.9
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		retrato.texture = nuevo_retrato
		retrato.material = null
	)


func _sortear_origen() -> void:
	var indice := randi_range(0, ORIGENES.size() - 1)
	relicario.disabled = true
	marcador_relicario = Label.new()
	marcador_relicario.text = "●\nRELICARIO"
	marcador_relicario.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcador_relicario.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marcador_relicario.add_theme_font_size_override(&"font_size", 20)
	marcador_relicario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcador_relicario.z_index = 20
	marcador_relicario.size = Vector2(150.0, 70.0)
	add_child(marcador_relicario)
	var destino := get_global_transform().affine_inverse() * (
		paneles_origen[indice].global_position + paneles_origen[indice].size * 0.5
	)
	marcador_relicario.position = Vector2(destino.x - 75.0, -90.0)
	var tween := create_tween()
	tween.tween_property(marcador_relicario, "position:y", destino.y - 35.0, 0.75) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	origen = ORIGENES[indice]
	estado_origen.text = "Origen: %s" % origen
	resumen_origen.text = "ORIGEN: %s" % origen.to_upper()
	for posicion in paneles_origen.size():
		paneles_origen[posicion].modulate = Color(1.0, 0.82, 0.52) if posicion == indice else Color.WHITE
	_actualizar_comenzar()


func _pv_maximos() -> int:
	var total := 0
	for valor: int in atributos.values():
		total += valor
	return total


func _actualizar_comenzar() -> void:
	comenzar.disabled = nombre.text.strip_edges().is_empty() or clase.is_empty() or origen.is_empty()


func _solicitar_excursion() -> void:
	excursion_solicitada.emit({
		"nombre": nombre.text.strip_edges(),
		"titulo": titulo_aventurero.text.strip_edges(),
		"fuerza": atributos[&"fuerza"],
		"destreza": atributos[&"destreza"],
		"voluntad": atributos[&"voluntad"],
		"pv_maximos": _pv_maximos(),
		"clase": clase,
		"origen": origen,
	})


func reproducir_entrada() -> Signal:
	show()
	var ultimo_tween: Tween
	for indice in rigs.size():
		var rig := rigs[indice]
		rig.position.y = -rig.size.y - 100.0
		rig.rotation_degrees = -2.5 if indice % 2 == 0 else 2.5
		var tween := create_tween()
		tween.tween_interval(indice * 0.1)
		tween.tween_property(rig, "position:y", posiciones_base[indice].y + 22.0, 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(rig, "rotation_degrees", 1.8, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_sacudir_rig.bind(indice))
		tween.tween_property(rig, "position:y", posiciones_base[indice].y - 10.0, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(rig, "rotation_degrees", -0.9, 0.12)
		tween.tween_property(rig, "position:y", posiciones_base[indice].y, 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(rig, "rotation_degrees", 0.0, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ultimo_tween = tween
	return ultimo_tween.finished


func _sacudir_rig(indice_rig: int) -> void:
	for indice in piezas_por_rig[indice_rig].size():
		var pieza: Control = piezas_por_rig[indice_rig][indice]
		var amplitud := 1.4 * pow(0.82, indice) * (1.0 if indice % 2 == 0 else -1.0)
		var tween := create_tween()
		tween.tween_interval(indice * 0.04)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza] + amplitud, 0.09)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza] - amplitud * 0.45, 0.13)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza], 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for indice in cadenas_por_rig[indice_rig].size():
		var cadena: Control = cadenas_por_rig[indice_rig][indice]
		var direccion := 1.0 if indice % 2 == 0 else -1.0
		var tween := create_tween()
		tween.tween_interval(0.04 + indice * 0.015)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena] + 3.2 * direccion, 0.11)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena] - 1.4 * direccion, 0.16)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena], 0.24) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func reproducir_salida() -> Signal:
	var tween := create_tween().set_parallel()
	for indice in rigs.size():
		var rig := rigs[indice]
		tween.tween_property(rig, "position:y", -rig.size.y - 100.0, 0.5) \
			.set_delay(indice * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween.finished


func _on_volver_pressed() -> void:
	volver_solicitado.emit()
