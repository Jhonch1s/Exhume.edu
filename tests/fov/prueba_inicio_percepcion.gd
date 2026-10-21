extends SceneTree

const RUTA := "user://prueba_inicio_percepcion.json"
var _fallos: Array[String] = []
var _casos := 0


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	for ruta in ["res://scenes/Zona1/zona_1.tscn", "res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"]:
		var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
		escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
		escenario.get_node("Zona").free()
		var zona = load(ruta).instantiate()
		zona.name = "Zona"
		escenario.add_child(zona)
		root.add_child(escenario)
		for intento in 200:
			await process_frame
			if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
				break
		escenario.set_process(false)
		_comprobar(escenario.ficha_jugador != null and escenario.gestor_vision.tiene_vision_calculada, "La zona inicia con percepción calculada: " + ruta)
		if escenario.ficha_jugador == null:
			escenario.queue_free()
			continue
		var origen: Vector2i = escenario.ficha_jugador.coordenada_mapa
		var iluminadas_lejanas := 0
		var conocidas_sin_fuente := 0
		var iluminadas_lejanas_ocultas := 0
		var conocidas_sin_linea := 0
		var sin_mascara := 0
		var estados := [0, 0, 0]
		for coord: Vector2i in escenario.tablero.datos:
			var celda: Celda = escenario.tablero.datos[coord]
			var fuera := (coord - origen).length_squared() > 49
			estados[celda.visibilidad] += 1
			if fuera and escenario.gestor_vision.iluminacion_actual.has(coord):
				iluminadas_lejanas += 1
				if celda.visibilidad == Celda.EstadoVisibilidad.OCULTO:
					iluminadas_lejanas_ocultas += 1
			if celda.visibilidad != Celda.EstadoVisibilidad.OCULTO:
				if fuera and not escenario.gestor_vision.iluminacion_fuentes_percibidas.has(coord):
					conocidas_sin_fuente += 1
				if escenario.validador_espacial.validar_linea_visual(origen, coord) != &"":
					conocidas_sin_linea += 1
			if celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE and escenario.capa_oscuridad.get_cell_source_id(coord) < 0:
				sin_mascara += 1
		_comprobar(iluminadas_lejanas > 0, "La zona ofrece luces lejanas para comprobar el límite.")
		_comprobar(conocidas_sin_fuente == 0, "Al iniciar, lo conocido fuera de alcance procede de una fuente percibida directamente.")
		_comprobar(iluminadas_lejanas_ocultas > 0, "Las fuentes ajenas a percepción directa no revelan todo el mapa.")
		_comprobar(conocidas_sin_linea == 0, "Al iniciar, todo lo conocido tiene línea visual desde ficha.")
		_comprobar(sin_mascara == 0, "Lo oculto y explorado conservan capa de niebla.")
		var antes := _visibilidad(escenario.tablero)
		var revision: int = escenario.gestor_vision.revision_vision
		var camara: CamaraEscenario = escenario.camera_2d
		var vista := Vector2(1920, 1080)
		camara.actualizar(0.1, escenario.ficha_jugador.global_position, vista, vista / 2.0, true)
		camara.actualizar(0.1, escenario.ficha_jugador.global_position, vista, Vector2(1919, 540), true)
		_comprobar(camara.libre, "Se activa cámara libre en la zona.")
		for extremo in [camara.limites.position, camara.limites.end, Vector2(camara.limites.end.x, camara.limites.position.y), Vector2(camara.limites.position.x, camara.limites.end.y)]:
			camara.global_position = extremo
			camara.actualizar(0.1, escenario.ficha_jugador.global_position, vista, vista / 2.0, true)
		_comprobar(_visibilidad(escenario.tablero) == antes and escenario.gestor_vision.revision_vision == revision, "Recorrer extremos con cámara libre no añade conocimiento ni recalcula percepción.")
		var guardado: StringName = escenario.guardar_partida(RUTA)
		var carga: StringName = escenario.cargar_partida(RUTA) if guardado == &"" else guardado
		_comprobar(guardado == &"" and carga == &"", "Guardar y cargar la zona desde cámara libre: %s guardar=%s cargar=%s." % [ruta, guardado, carga])
		_comprobar(_visibilidad(escenario.tablero) == antes and escenario.gestor_vision.ultimo_centro_jugador == origen, "La carga conserva conocimiento y límite desde posición guardada.")
		await process_frame
		_comprobar(_visibilidad(escenario.tablero) == antes, "La carga no revela terreno en el frame siguiente.")
		print("InicioPercepcion: ", ruta, " oculto/explorado/visible=", estados, " iluminadas_lejanas_ocultas=", iluminadas_lejanas_ocultas)
		escenario.queue_free()
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	for fallo in _fallos:
		push_error(fallo)
	print("InicioPercepcion: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _visibilidad(tablero: TableroGrid) -> Dictionary:
	var estados := {}
	for coord: Vector2i in tablero.datos:
		estados[coord] = tablero.datos[coord].visibilidad
	return estados


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
