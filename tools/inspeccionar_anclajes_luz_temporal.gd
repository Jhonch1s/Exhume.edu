extends SceneTree


func _init() -> void:
	var escena := load("res://scenes/Zona1/zona_1.tscn") as PackedScene
	var zona := escena.instantiate()
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	var centros: Array[Vector2i] = [
		Vector2i(7, -5), Vector2i(22, 10), Vector2i(57, 5), Vector2i(57, 12)
	]
	for centro in centros:
		print("CENTRO ", centro)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var coord: Vector2i = centro + Vector2i(dx, dy)
				var celda: Celda = tablero.obtener_celda(coord)
				if celda == null:
					print("  ", coord, " hueco")
				else:
					print("  ", coord, " zona=", celda.zona, " camina=", celda.caminable, " bloquea=", celda.bloquea_vision)
	tablero.free()
	zona.free()
	quit()
