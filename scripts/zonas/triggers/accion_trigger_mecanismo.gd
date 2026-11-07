@tool
class_name AccionTriggerMecanismo
extends AccionTrigger

## ID de una puerta u otro receptor del contrato de mecanismos.
@export var id_receptor: StringName
@export var activar: bool = true
## Perfil de GestorVFX que se percibe desde el umbral al cambiar el mecanismo.
@export var efecto_visual: StringName


func validar_configuracion() -> String:
	return "Asigna el ID del receptor del mecanismo." if id_receptor == &"" else ""


func ejecutar(escenario: Node, trigger: TriggerMapa) -> StringName:
	var receptor: Interactuable = escenario.tablero.obtener_interactuable(id_receptor)
	if receptor == null:
		return &"receptor_mecanismo_inexistente"
	if not receptor.has_method(&"validar_cambio_mecanismo") or not receptor.has_method(&"aplicar_cambio_mecanismo"):
		return &"receptor_mecanismo_incompatible"
	var motivo: Variant = receptor.call(&"validar_cambio_mecanismo", trigger.id_trigger, activar)
	if not motivo is StringName:
		return &"contrato_receptor_mecanismo_invalido"
	if motivo != &"":
		return motivo
	var resultado: Variant = receptor.call(&"aplicar_cambio_mecanismo", trigger.id_trigger, activar)
	if not resultado is ResultadoAccion:
		return &"resultado_receptor_mecanismo_invalido"
	if not resultado.exitosa:
		return resultado.motivo
	if efecto_visual != &"" and not resultado.cambios_estado.is_empty():
		escenario.gestor_vfx.solicitar(efecto_visual, escenario.ficha_jugador.global_position)
	return &""
