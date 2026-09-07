class_name GeometriaGrid
extends RefCounted


static func trazar_linea(origen: Vector2i, destino: Vector2i) -> Array[Vector2i]:
	var puntos: Array[Vector2i] = []
	var dx: int = absi(destino.x - origen.x)
	var dy: int = -absi(destino.y - origen.y)
	var paso_x: int = 1 if origen.x < destino.x else -1
	var paso_y: int = 1 if origen.y < destino.y else -1
	var error: int = dx + dy
	var actual: Vector2i = origen

	while true:
		puntos.append(actual)
		if actual == destino:
			break
		var error_doble: int = 2 * error
		if error_doble >= dy:
			error += dy
			actual.x += paso_x
		if error_doble <= dx:
			error += dx
			actual.y += paso_y

	return puntos


static func flancos_paso_diagonal(
	origen: Vector2i,
	destino: Vector2i
) -> Array[Vector2i]:
	if origen.x == destino.x or origen.y == destino.y:
		return []
	return [
		Vector2i(destino.x, origen.y),
		Vector2i(origen.x, destino.y),
	]
