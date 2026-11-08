extends SceneTree

const RUTA := "user://partida.json"
const PRISION := "res://scenes/Prision/prision.tscn"
const TEMPLO := "res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"
var fallos: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_probar")


func _esperar_escenario(anterior: int = 0) -> Node:
	for intento in 600:
		await process_frame
		if current_scene != null and current_scene.get_instance_id() != anterior and current_scene.get("escenario_preparado") == true:
			return current_scene
	return null


func _probar() -> void:
	if FileAccess.file_exists(RUTA):
		push_error("Ejecuta esta prueba con un directorio de usuario aislado.")
		quit(1)
		return
	change_scene_to_file(PRISION)
	var escenario := await _esperar_escenario()
	if escenario == null:
		push_error("No se pudo iniciar Prisión")
		quit(1)
		return
	escenario.ficha_jugador.nombre = "Ada"
	_comprobar(escenario.guardar_partida() == &"", "Guardar en Prisión")
	var original := FileAccess.get_file_as_string(RUTA)
	_comprobar(EstadoPartida.establecer_aventurero({
		"nombre": "Nueva", "titulo": "la Nueva", "clase": "Mago",
		"origen": "Cripta", "fuerza": 3, "destreza": 3, "voluntad": 3,
	}) and FileAccess.get_file_as_string(RUTA) == original, "Preparar una partida nueva conserva el archivo anterior")
	EstadoPartida.aventurero_pendiente.clear()
	EstadoPartida.guardado_en_fogata_realizado = false
	var anterior := escenario.get_instance_id()
	change_scene_to_file(TEMPLO)
	escenario = await _esperar_escenario(anterior)
	_comprobar(escenario != null and FileAccess.get_file_as_string(RUTA) == original, "Abrir otra zona no borra el guardado")
	if escenario != null:
		anterior = escenario.get_instance_id()
		escenario._mostrar_pantalla_muerte()
		escenario._ejecutar_carga_tras_muerte()
		escenario = await _esperar_escenario(anterior)
		_comprobar(escenario != null and escenario.zona_actual.scene_file_path == PRISION and escenario.ficha_jugador.nombre == "Ada", "Cargar tras morir en otra zona restaura zona y ficha")
	if escenario != null:
		change_scene_to_file("res://scenes/menu/personajes.tscn")
		await process_frame
		await process_frame
		EstadoPartida.guardado_en_fogata_realizado = false
		current_scene._on_personaje_pressed()
		escenario = await _esperar_escenario()
		_comprobar(escenario != null and escenario.zona_actual.scene_file_path == PRISION and escenario.ficha_jugador.nombre == "Ada", "Continuar restaura el guardado sin marca en memoria")
	var archivo := FileAccess.open(RUTA, FileAccess.WRITE)
	archivo.store_string("{invalido")
	archivo.close()
	_comprobar(EstadoPartida.preparar_carga() != &"" and FileAccess.get_file_as_string(RUTA) == "{invalido", "Un archivo inválido se rechaza sin borrarlo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	for fallo in fallos:
		push_error(fallo)
	print("Continuar partida: %s" % ("correcto" if fallos.is_empty() else "%d fallos" % fallos.size()))
	quit(0 if fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)
