class_name Explosion
extends RefCounted


static func crear_solicitudes(
	tablero: TableroGrid,
	centro: Vector2i,
	radio: int,
	magnitud: int,
	id_evento: StringName,
	fuente: Object = null
) -> Array[SolicitudEfecto]:
	var solicitudes: Array[SolicitudEfecto] = []
	if tablero == null or radio < 0 or magnitud <= 0 or id_evento == &"":
		return solicitudes
	for y in range(-radio, radio + 1):
		for x in range(-radio, radio + 1):
			if absi(x) + absi(y) > radio:
				continue
			var celda := tablero.obtener_celda(centro + Vector2i(x, y))
			if celda == null:
				continue
			for objetivo in celda.ocupantes.duplicate():
				if (
					objetivo != null
					and is_instance_valid(objetivo)
					and objetivo.has_method(&"recibir_danio")
				):
					solicitudes.append(SolicitudEfecto.new(
						&"explosion",
						&"dano",
						objetivo,
						id_evento,
						float(magnitud),
						0,
						TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
						fuente
					))
	return solicitudes
