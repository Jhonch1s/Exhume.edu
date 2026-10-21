extends SceneTree

var _fallos: Array[String] = []
var _casos := 0
var _tablero: TableroGrid
var _fov: FOVManager
var _capa: TileMapLayer
var _a: FuenteLuzInteractuable
var _b: FuenteLuzInteractuable
var _npc: PersonajeNPC


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_tablero = TableroGrid.new()
	root.add_child(_tablero)
	for x in range(-2, 21):
		for y in range(-2, 3):
			_tablero.datos[Vector2i(x, y)] = Celda.new()
	_capa = TileMapLayer.new()
	_capa.tile_set = load("res://assets/tile_sets/fog/cave_fog.tres")
	root.add_child(_capa)
	_fov = FOVManager.new()
	root.add_child(_fov)
	_a = _crear_luz(&"a", Vector2i(7, 0), 2, 1)
	_b = _crear_luz(&"b", Vector2i(9, 0), 4, 0)
	_crear_luz(&"c", Vector2i(13, 0), 4, 0)
	_npc = load("res://scenes/personajes/npc.tscn").instantiate()
	_npc.id_instancia = &"npc_ampliado"
	root.add_child(_npc)
	_tablero.registrar_interactuable(Vector2i(9, 0), _npc)
	_reiniciar(Vector2i.ZERO)
	_probar_extension_y_cadena()
	var antes := _visibilidad()
	var invertidas := _tablero.datos.duplicate()
	var claves: Array = invertidas.keys()
	claves.reverse()
	_tablero.datos.clear()
	for coord: Vector2i in claves:
		_tablero.datos[coord] = invertidas[coord]
	_reiniciar(Vector2i.ZERO)
	_comprobar(_visibilidad() == antes, "El orden de recorrido de fuentes no permite cadenas ni cambia el resultado.")
	_a.encendida = false
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.EXPLORADO and not _npc.visible, "Apagar la fuente directa conserva terreno recordado sin NPC ni ampliación de B.")
	_comprobar(_estado(12) == Celda.EstadoVisibilidad.OCULTO, "Recordar la segunda fuente no la convierte en origen de ampliación.")
	_a.encendida = true
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.VISIBLE and _npc.visible, "Volver a encender restaura percepción ampliada inmediatamente.")
	_fov.actualizar_vision(Vector2i(3, 0), 1)
	_comprobar(_estado(12) == Celda.EstadoVisibilidad.VISIBLE and _estado(13) == Celda.EstadoVisibilidad.VISIBLE, "Acercar la ficha permite que B, ahora en alcance normal, amplíe su propia luz.")
	_comprobar(_estado(17) == Celda.EstadoVisibilidad.OCULTO, "C vista gracias a B tampoco encadena una tercera ampliación.")
	_fov.actualizar_vision(Vector2i(-1, 0), 1)
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.EXPLORADO and not _npc.visible, "Alejarse del alcance normal de A retira ampliación y oculta al NPC.")
	_comprobar(_fov.iluminacion_fuentes_percibidas.is_empty(), "Las fuentes fuera de alcance no aportan ampliación aunque sigan encendidas.")
	_probar_obstaculos()
	_probar_superficie_luminosa()
	for nodo in [_a, _b, _npc, _fov, _capa, _tablero]:
		nodo.queue_free()
	for nodo in root.get_children():
		if nodo is FuenteLuzInteractuable:
			nodo.queue_free()
	await process_frame
	for fallo in _fallos:
		push_error(fallo)
	print("AmpliacionFuentes: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _probar_extension_y_cadena() -> void:
	_comprobar(_estado(7) == Celda.EstadoVisibilidad.VISIBLE, "Fuente A se percibe directamente a siete casillas.")
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.VISIBLE and _npc.visible, "Su luz permite ver celda y NPC a nueve casillas.")
	_comprobar(_b.visible, "Fuente B a nueve casillas puede verse gracias a A.")
	_comprobar(_estado(12) == Celda.EstadoVisibilidad.OCULTO and _fov.iluminacion_actual.has(Vector2i(12, 0)), "La fuente B vista por ampliación no descubre su área fuera de A.")
	_comprobar(_fov.iluminacion_actual[Vector2i(10, 0)] == FOVManager.NivelLuz.LUZ and _estado(10) == Celda.EstadoVisibilidad.EXPLORADO, "La luz plena de B no convierte en visible la penumbra ampliada de A.")
	_comprobar(not _fov.iluminacion_actual.has(Vector2i(3, 0)) and _estado(3) == Celda.EstadoVisibilidad.OCULTO, "Percibir una fuente no descubre el tramo oscuro intermedio.")
	_comprobar(_estado(17) == Celda.EstadoVisibilidad.OCULTO, "No se descubre el extremo de una cadena de tres fuentes.")
	_comprobar(not SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(_tablero, Vector2i(9, 0)).is_empty(), "La ampliación entrega objetivos al selector existente.")


func _probar_obstaculos() -> void:
	_a.definicion.atraviesa_muros = true
	var humo := Humo.new()
	humo.configurar_id_instancia(&"humo_ampliacion")
	root.add_child(humo)
	_tablero.registrar_efecto_superficie(Vector2i(8, 0), humo)
	_reiniciar(Vector2i.ZERO)
	_comprobar(_estado(7) == Celda.EstadoVisibilidad.VISIBLE and _fov.iluminacion_actual.has(Vector2i(9, 0)) and _estado(9) == Celda.EstadoVisibilidad.OCULTO, "Fuente percibida no revela detrás de humo aunque su luz lo atraviese.")
	_tablero.retirar_efecto_superficie(humo)
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.VISIBLE, "Retirar humo devuelve la ampliación con línea visual.")
	_tablero.registrar_efecto_superficie(Vector2i(4, 0), humo)
	_reiniciar(Vector2i.ZERO)
	_comprobar(_fov.iluminacion_actual.has(Vector2i(9, 2)) and _estado(9, 2) == Celda.EstadoVisibilidad.OCULTO, "Fuente bloqueada desde ficha no amplía ni una celda iluminada con otra línea despejada.")
	_comprobar(_fov.iluminacion_fuentes_percibidas.is_empty(), "El origen de luz también necesita línea visual directa.")
	_tablero.retirar_efecto_superficie(humo)
	humo.queue_free()


func _probar_superficie_luminosa() -> void:
	_a.encendida = false
	var fuego := Fuego.new()
	fuego.configurar_id_instancia(&"fuego_ampliacion")
	root.add_child(fuego)
	_tablero.registrar_efecto_superficie(Vector2i(7, 0), fuego)
	_reiniciar(Vector2i.ZERO)
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.VISIBLE, "Las superficies de fuego también amplían cuando se perciben directamente.")
	_tablero.retirar_efecto_superficie(fuego)
	_comprobar(_estado(9) == Celda.EstadoVisibilidad.EXPLORADO and not _npc.visible, "Retirar el fuego retira su ampliación sin revelar por fuentes recordadas.")
	fuego.queue_free()


func _crear_luz(id: StringName, coord: Vector2i, radio: int, penumbra: int) -> FuenteLuzInteractuable:
	var fuente := (load("res://scenes/interactuables/fuentes_luz/fuente_luz_interactuable.tscn") as PackedScene).instantiate() as FuenteLuzInteractuable
	fuente.id_instancia = id
	fuente.definicion = load("res://assets/interactuables/luces/antorcha_pie.tres").duplicate(true)
	fuente.definicion.radio_luz = radio
	fuente.definicion.radio_penumbra = penumbra
	root.add_child(fuente)
	_tablero.registrar_interactuable(coord, fuente)
	return fuente


func _reiniciar(origen: Vector2i) -> void:
	_fov.inicializar(_capa, _tablero)
	_fov.actualizar_vision(origen, 1)


func _estado(x: int, y: int = 0) -> int:
	return _tablero.obtener_celda(Vector2i(x, y)).visibilidad


func _visibilidad() -> Dictionary:
	var estados := {}
	for coord: Vector2i in _tablero.datos:
		estados[coord] = _tablero.datos[coord].visibilidad
	return estados


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
