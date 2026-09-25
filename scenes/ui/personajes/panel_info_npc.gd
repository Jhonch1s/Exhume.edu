class_name PanelInfoNPC
extends PanelContainer

@onready var etiqueta_nombre: Label = $Margen/Contenido/Cabecera/Nombre
@onready var etiqueta_nivel: Label = $Margen/Contenido/Cabecera/Nivel
@onready var barra_vida: ProgressBar = $Margen/Contenido/BarraVida/Progreso
@onready var etiqueta_vida: Label = $Margen/Contenido/BarraVida/Vida

var personaje_actual: PersonajeNPC
var datos_mostrados: Array = []


func mostrar_personaje(personaje: PersonajeNPC) -> void:
	if personaje == null or not is_instance_valid(personaje):
		ocultar()
		return
	var definicion := personaje.obtener_definicion_personaje()
	var vida_maxima := definicion.vida_maxima if definicion != null else 0
	var datos: Array = [
		personaje.obtener_nombre_interaccion(),
		personaje.nivel_actual,
		personaje.vida_actual,
		vida_maxima,
	]
	if personaje_actual != personaje or datos_mostrados != datos:
		personaje_actual = personaje
		datos_mostrados = datos
		etiqueta_nombre.text = datos[0]
		etiqueta_nivel.text = "Nivel %d" % datos[1]
		barra_vida.max_value = maxi(1, vida_maxima)
		barra_vida.value = clampi(personaje.vida_actual, 0, vida_maxima)
		etiqueta_vida.text = "%d / %d PV" % [personaje.vida_actual, vida_maxima]
	visible = true


func ocultar() -> void:
	personaje_actual = null
	datos_mostrados.clear()
	visible = false
