extends SceneTree

class ReceptorExplosionPrueba extends RefCounted:
	var tablero: TableroGrid

	func _init(tablero_inicial: TableroGrid) -> void:
		tablero = tablero_inicial

	func validar_accion(_contexto: ContextoAccion) -> StringName:
		return &""

	func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
		return ResultadoAccion.crear_exito(
			[], [], [], {}, false, false,
			Explosion.crear_solicitudes(
				tablero, Vector2i.ZERO, 1, 2, contexto.id_evento, self
			)
		)


var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	_probar_danio_reutilizable()
	_probar_explosion_radial_sin_duplicados()
	await process_frame
	if _fallos.is_empty():
		print("DanioYExplosion: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_danio_reutilizable() -> void:
	var ficha := Ficha.new()
	root.add_child(ficha)
	var aplicador := AplicadorEfectos.new()
	for datos in [
		[&"fuego", &"lava"],
		[&"explosion", &"trampa"],
		[&"impacto", &"proyectil"],
	]:
		var fuente := RefCounted.new()
		var solicitud := SolicitudEfecto.new(
			datos[0], &"dano", ficha, datos[1], 1.0, 0,
			TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
			fuente
		)
		var resultado: Variant = aplicador.aplicar(solicitud)
		_comprobar(resultado is ResultadoEfectoAplicado, "Toda fuente debe reutilizar el mismo aplicador de daño.")
	_comprobar(ficha.pv_actual == ficha.pv_max - 3, "Lava, trampa e impacto deben descontar vida.")
	ficha.queue_free()


func _probar_explosion_radial_sin_duplicados() -> void:
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	for coord in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(1, 1)]:
		tablero.datos[coord] = Celda.new()
	var centro := Ficha.new()
	var adyacente := Ficha.new()
	var diagonal := Ficha.new()
	root.add_child(centro)
	root.add_child(adyacente)
	root.add_child(diagonal)
	tablero.ocupar_celda(Vector2i.ZERO, centro)
	tablero.ocupar_celda(Vector2i(1, 0), adyacente)
	tablero.ocupar_celda(Vector2i(1, 1), diagonal)

	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var receptor_a := ReceptorExplosionPrueba.new(tablero)
	var receptor_b := ReceptorExplosionPrueba.new(tablero)
	var resultado := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		centro,
		Vector2i(-1, 0),
		Vector2i.ZERO,
		[
			ReaccionCelda.new(
				TiposInteraccion.CategoriaReaccion.INTERACTUABLE,
				0,
				&"explosion_a",
				receptor_a
			),
			ReaccionCelda.new(
				TiposInteraccion.CategoriaReaccion.INTERACTUABLE,
				1,
				&"explosion_b",
				receptor_b
			),
		]
	)

	_comprobar(resultado.solicitudes_efecto.size() == 2, "La explosión Manhattan debe alcanzar centro y adyacente.")
	_comprobar(resultado.efectos_aplicados.size() == 2, "Cada objetivo debe recibir un único daño por evento.")
	_comprobar(centro.pv_actual == centro.pv_max - 2, "El centro debe recibir un solo impacto.")
	_comprobar(adyacente.pv_actual == adyacente.pv_max - 2, "El adyacente debe recibir un solo impacto.")
	_comprobar(diagonal.pv_actual == diagonal.pv_max, "La diagonal debe quedar fuera del radio Manhattan uno.")

	centro.queue_free()
	adyacente.queue_free()
	diagonal.queue_free()
	gestor.queue_free()
	tablero.queue_free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
