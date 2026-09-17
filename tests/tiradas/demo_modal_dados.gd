extends Control

@onready var panel: PanelResultadoAccion = $PanelResultadoAccion
@onready var boton_prueba: Button = $Centro/Contenido/LanzarPrueba

var motor := MotorDados.new()


func _ready() -> void:
	boton_prueba.pressed.connect(_lanzar_prueba)
	panel.cerrado.connect(func(): boton_prueba.grab_focus())
	boton_prueba.grab_focus()


func _lanzar_prueba() -> void:
	var resultado := motor.resolver_prueba(
		3,
		[&"demostracion"],
		[],
		TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.PRIMER_PLANO,
		[{&"fuente": &"amuleto", &"valor": 2}]
	)
	panel.mostrar_tirada("Prueba de Destreza", resultado)
