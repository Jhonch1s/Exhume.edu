extends SceneTree

class ContenidoPrueba:
	extends RefCounted
	var id: StringName

	func _init(id_inicial: StringName) -> void:
		id = id_inicial

	func obtener_id_reaccion() -> StringName:
		return id


class SuperficiePrueba extends ContenidoPrueba:
	func obtener_turnos_restantes_superficie() -> int:
		return 4


func _init() -> void:
	var tablero := TableroGrid.new()
	var celda := Celda.new(&"lava", true, 2, Celda.EstadoVisibilidad.VISIBLE)
	celda.coste_movimiento_adicional = 1
	celda.penalizacion_peligro_ruta = 2.0
	celda.ocupantes.append(ContenidoPrueba.new(&"actor_b"))
	celda.interactuables.append(ContenidoPrueba.new(&"puerta_a"))
	celda.efectos_superficie.append(SuperficiePrueba.new(&"humo_c"))
	celda.reaccion_terreno = ContenidoPrueba.new(&"lava")
	tablero.datos[Vector2i(2, 3)] = celda
	var texto := InspectorCeldaDesarrollo.new().describir(tablero, Vector2i(2, 3))
	assert(texto.contains("coord=(2, 3) zona=lava altura=2 visibilidad=VISIBLE"))
	assert(texto.contains("ocupantes=[actor_b]"))
	assert(texto.contains("interactuables=[puerta_a]"))
	assert(texto.contains("superficies=[humo_c(turnos=4)]"))
	assert(texto.contains("terreno=lava"))
	assert(InspectorCeldaDesarrollo.new().describir(tablero, Vector2i.ZERO).ends_with("inexistente"))
	print("InspectorCeldaDesarrollo: 6 comprobaciones correctas.")
	quit()
