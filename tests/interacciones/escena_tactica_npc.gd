extends "res://tests/interacciones/escena_facciones_npc.gd"

const BOMBA := preload("res://assets/items/bomba_humo/bomba_humo.tres")
@export_range(1, 15, 1) var vida_guardia: int = 4
@export_range(0, 10, 1) var bombas_guardia: int = 2


func _ready() -> void:
	inicio_hostil = true
	await super._ready()
	_ruta_guardado = "user://prueba_tactica_npc.json"
	_mostrar_estado("IA táctica: selección de objetivos. Huida y humo automático pendientes. Ajustar vida_guardia/bombas_guardia y F6. Slot propio.")


func _crear_enemigo(zona: Node2D, suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	if not super._crear_enemigo(zona, suelo, tablero, coordenada, numero):
		return false
	if numero == 1:
		var npc: PersonajeNPC = _enemigos.back()
		npc.obtener_definicion_personaje().radio_agro = 12
		npc.vida_inicial = vida_guardia
		if bombas_guardia > 0:
			var entrada := EntradaInventarioInicial.new()
			entrada.definicion = BOMBA
			entrada.cantidad = bombas_guardia
			npc.contenido_inicial.append(entrada)
			npc._inventario = null
	return true


func _mostrar_estado(detalle: String) -> void:
	super._mostrar_estado(detalle)
	if _estado != null and not _enemigos.is_empty():
		var inventario := _enemigos[0].obtener_inventario()
		var cantidad := 0
		if inventario != null:
			for item in inventario.obtener_por_definicion(&"bomba_humo"):
				cantidad += item.cantidad
		_estado.text += "\nTÁCTICA | Bombas en inventario: %d (sin uso automático) | Huida pendiente | Liberarse primero" % cantidad
