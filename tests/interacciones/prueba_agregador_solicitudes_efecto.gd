extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_deduplicacion()
	_probar_identidades_independientes()
	_probar_rechazo_atomico()
	if _fallos.is_empty():
		print("AgregadorSolicitudesEfecto: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_deduplicacion() -> void:
	var actor := RefCounted.new()
	var fuente_fuerte := RefCounted.new()
	var solicitudes: Array[SolicitudEfecto] = [
		SolicitudEfecto.new(&"veneno", &"estado", actor, &"entrar_1", 1.0, 5),
		SolicitudEfecto.new(&"veneno", &"estado", actor, &"entrar_1", 2.0, 7, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, fuente_fuerte),
	]
	var resultado := AgregadorSolicitudesEfecto.new().agregar(solicitudes)
	_comprobar(resultado.valido and resultado.solicitudes.size() == 1, "Debe deduplicar la misma clave, objetivo y evento.")
	if resultado.solicitudes.size() == 1:
		var agregada := resultado.solicitudes[0]
		_comprobar(agregada.magnitud == 2.0, "Debe conservar la mayor magnitud.")
		_comprobar(agregada.duracion == 7, "Debe renovar al máximo sin sumar duración.")
		_comprobar(agregada.fuente == fuente_fuerte, "Debe conservar la fuente de la mayor magnitud.")
	_comprobar(solicitudes[0].duracion == 5, "No debe modificar las solicitudes originales.")
	var copia := resultado.solicitudes
	var cantidad := copia.size()
	copia.clear()
	_comprobar(resultado.solicitudes.size() == cantidad, "El resultado debe devolver copias de su colección.")


func _probar_identidades_independientes() -> void:
	var actor_a := RefCounted.new()
	var actor_b := RefCounted.new()
	var solicitudes: Array[SolicitudEfecto] = [
		SolicitudEfecto.new(&"veneno", &"estado", actor_a, &"entrar_1"),
		SolicitudEfecto.new(&"fuego", &"dano", actor_a, &"entrar_1"),
		SolicitudEfecto.new(&"veneno", &"estado", actor_b, &"entrar_1"),
		SolicitudEfecto.new(&"veneno", &"estado", actor_a, &"entrar_2"),
	]
	var resultado := AgregadorSolicitudesEfecto.new().agregar(solicitudes)
	_comprobar(resultado.valido and resultado.solicitudes.size() == 4, "Claves, objetivos o eventos distintos deben coexistir.")
	_comprobar(resultado.solicitudes[0] == solicitudes[0], "Debe conservar el orden de primera aparición.")


func _probar_rechazo_atomico() -> void:
	var actor := RefCounted.new()
	var solicitudes: Array[SolicitudEfecto] = [
		SolicitudEfecto.new(&"veneno", &"estado", actor, &"entrar_1"),
		SolicitudEfecto.new(&"", &"estado", actor, &"entrar_1"),
	]
	var resultado := AgregadorSolicitudesEfecto.new().agregar(solicitudes)
	_comprobar(not resultado.valido, "Una solicitud inválida debe rechazar el lote.")
	_comprobar(resultado.solicitudes.is_empty(), "El rechazo no debe devolver un lote parcial.")


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
