extends "res://tests/interacciones/escena_npc_hostil.gd"

const ESCENA_TERROR := preload("res://scenes/personajes/terror_nocturno.tscn")


func _ready() -> void:
	cantidad_enemigos = 1
	_ruta_guardado = "user://prueba_terror_nocturno.json"
	await super._ready()
	_mostrar_estado("Terror Nocturno: K/C para guardar/cargar.")


func _crear_enemigo(zona: Node2D, capa_suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	var enemigo := ESCENA_TERROR.instantiate() as PersonajeNPC
	enemigo.id_instancia = StringName("terror_nocturno_prueba_%d" % numero)
	zona.get_node("Interactuables/Personajes").add_child(enemigo)
	enemigo.global_position = capa_suelo.to_global(capa_suelo.map_to_local(coordenada))
	if not tablero.registrar_interactuable(coordenada, enemigo):
		enemigo.queue_free()
		return false
	_enemigos.append(enemigo)
	enemigo.actualizar_presentacion_visibilidad(tablero.obtener_celda(coordenada).visibilidad)
	return true
