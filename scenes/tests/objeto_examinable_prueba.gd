extends Node2D

var coordenada_mapa: Vector2i = Vector2i.ZERO
var fue_examinado: bool = false


func inicializar(coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	coordenada_mapa = coordenada_inicial
	global_position = capa.map_to_local(coordenada_mapa)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto.tipo != TiposInteraccion.TipoAccion.EXAMINAR:
		return &"accion_no_admitida"
	if contexto.objetivo != self:
		return &"objetivo_no_coincide"
	return &""


func resolver_accion(_contexto: ContextoAccion) -> ResultadoAccion:
	var valor_anterior := fue_examinado
	fue_examinado = true
	queue_redraw()
	var cambios: Array[Dictionary] = [{
		&"propiedad": &"fue_examinado",
		&"valor_anterior": valor_anterior,
		&"valor_nuevo": fue_examinado,
	}]
	return ResultadoAccion.crear_exito(
		[&"examinar.objeto_prueba_observado"],
		[],
		cambios
	)


func reiniciar() -> void:
	fue_examinado = false
	queue_redraw()


func _draw() -> void:
	var color := Color(0.25, 0.9, 0.45) if fue_examinado else Color(1.0, 0.65, 0.15)
	var rombo := PackedVector2Array([
		Vector2(0, -34),
		Vector2(13, -21),
		Vector2(0, -8),
		Vector2(-13, -21),
	])
	var contorno := rombo.duplicate()
	contorno.append(rombo[0])
	draw_colored_polygon(rombo, color)
	draw_polyline(contorno, Color(0.08, 0.08, 0.08), 2.0, true)
