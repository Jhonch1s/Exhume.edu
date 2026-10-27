class_name DefinicionItem
extends Resource

@export_category("Identidad")
@export var id_definicion: StringName = &""
@export var nombre: String = ""
@export var icono: Texture2D
@export var escena_mundo: PackedScene

@export_category("Presentacion")
@export_multiline var descripcion_base: String = ""
@export var ilustracion_examen: Texture2D

@export_category("Semantica")
@export var etiquetas: Array[StringName] = []
@export var magnitudes: Dictionary[StringName, float] = {}
@export var reaccion_impacto: Resource
@export var efectos_equipo: Array[Dictionary] = []
@export var clases_permitidas: Array[StringName] = []
@export var requiere_dos_manos: bool = false

@export_category("Apilado")
@export var apilable: bool = false
@export_range(1, 999, 1) var cantidad_maxima: int = 1

@export_category("Audio")
@export var sonido_recoger: AudioStream
@export var sonido_impacto: AudioStream

const SONIDO_RECOGER_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/Collect.wav")
const SONIDO_ROCK_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/Rock 1.wav")
const SONIDO_LLAVE_DEFECTO: AudioStream = preload("res://assets/sonidos/lleves y candados/788310__realsquink__key-pickup.wav")
const SONIDO_POCION_DEFECTO: AudioStream = preload("res://assets/sonidos/posiones/Potion and Alchemy 01.wav")


func obtener_sonido_recoger() -> AudioStream:
	if sonido_recoger != null:
		return sonido_recoger
	if &"llave" in etiquetas or String(id_definicion).contains("llave"):
		return SONIDO_LLAVE_DEFECTO
	if &"pocion" in etiquetas or String(id_definicion).contains("pocion"):
		return SONIDO_POCION_DEFECTO
	return SONIDO_RECOGER_DEFECTO


func obtener_sonido_impacto() -> AudioStream:
	if sonido_impacto != null:
		return sonido_impacto
	if &"mineral" in etiquetas or &"contundente" in etiquetas or id_definicion == &"piedra":
		return SONIDO_ROCK_DEFECTO
	return null


func obtener_peso() -> float:
	return magnitudes.get(&"peso", 0.5)


func resolver_curacion(motor: MotorDados = null, valor_defecto: int = 0) -> int:
	var base := int(magnitudes.get(&"recuperacion_pv", float(valor_defecto)))
	var cantidad := int(magnitudes.get(&"recuperacion_pv_dados", 0.0))
	if cantidad == 0:
		return base
	if not es_valida():
		return 0
	if motor == null:
		motor = MotorDados.new()
	var tirada := motor.resolver([{
		&"cantidad": cantidad,
		&"caras": int(magnitudes[&"recuperacion_pv_caras"]),
		&"signo": 1,
	}], 0, TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG)
	return base + tirada.total_efectivo if tirada.valida else 0


func obtener_formula_curacion(valor_defecto: int = 0) -> String:
	var base := int(magnitudes.get(&"recuperacion_pv", float(valor_defecto)))
	var cantidad := int(magnitudes.get(&"recuperacion_pv_dados", 0.0))
	if cantidad == 0:
		return str(base)
	var formula := "%dd%d" % [cantidad, int(magnitudes.get(&"recuperacion_pv_caras", 0.0))]
	return formula + ("+%d" % base if base > 0 else "")


func es_valida() -> bool:
	if not EfectosEquipo.validar(efectos_equipo):
		return false
	if id_definicion == &"" or nombre.is_empty() or cantidad_maxima < 1:
		return false
	if not apilable and cantidad_maxima != 1:
		return false
	var etiquetas_vistas: Dictionary[StringName, bool] = {}
	for etiqueta in etiquetas:
		if etiqueta == &"" or etiquetas_vistas.has(etiqueta):
			return false
		etiquetas_vistas[etiqueta] = true
	var clases_vistas: Dictionary[StringName, bool] = {}
	for clase_permitida in clases_permitidas:
		if clase_permitida not in [&"Guerrero", &"Ladrón", &"Mago"] or clases_vistas.has(clase_permitida):
			return false
		clases_vistas[clase_permitida] = true
	if requiere_dos_manos and &"arma" not in etiquetas:
		return false
	for clave in magnitudes:
		var valor := magnitudes[clave]
		if clave == &"" or not is_finite(valor):
			return false
		if clave != &"temperatura" and valor < 0.0:
			return false
	if magnitudes.has(&"recuperacion_pv_dados") or magnitudes.has(&"recuperacion_pv_caras"):
		var cantidad: float = magnitudes.get(&"recuperacion_pv_dados", 0.0)
		var caras: float = magnitudes.get(&"recuperacion_pv_caras", 0.0)
		if cantidad != floor(cantidad) or cantidad < 1 or cantidad > 9:
			return false
		if caras != floor(caras) or caras < 2 or caras > 100:
			return false
	if magnitudes.has(&"dano_arma_dados") or magnitudes.has(&"dano_arma_caras"):
		var cantidad: float = magnitudes.get(&"dano_arma_dados", 0.0)
		var caras: float = magnitudes.get(&"dano_arma_caras", 0.0)
		if cantidad != floor(cantidad) or cantidad < 1 or cantidad > 9:
			return false
		if caras != floor(caras) or caras < 2 or caras > 100:
			return false
		if &"arma" not in etiquetas:
			return false
	return true
