@tool
extends ZonaExplorable

const GANZUA := preload("res://assets/items/ganzua_mecanica/ganzua_mecanica.tres")

var prueba_preparada := false


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_preparar_prueba.call_deferred()


func _preparar_prueba() -> void:
	while is_inside_tree():
		var escenario := get_parent()
		if escenario.has_method(&"spawnear_ficha_inicial") and escenario.escenario_preparado:
			var resultado: ResultadoOperacionInventario = escenario.ficha_jugador.inventario.agregar(
				ItemInstancia.new(&"prueba_roffa_ganzua", GANZUA)
			)
			assert(resultado.exitosa, "No se pudo agregar la ganzúa de prueba.")
			if not escenario.has_node("SecuenciaRoffa"):
				var controlador: Node = load("res://scripts/zonas/secuencia_roffa.gd").new()
				controlador.name = "SecuenciaRoffa"
				escenario.add_child(controlador)
			escenario.hud.actualizar_desde_ficha()
			prueba_preparada = true
			return
		await get_tree().process_frame
