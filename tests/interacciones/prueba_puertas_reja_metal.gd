extends SceneTree

var fallos: Array[String] = []
var comprobaciones := 0


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_probar("izquierda", Vector2(48, 88), Vector2(71, 88))
	_probar("derecha", Vector2(15, 184), Vector2(150, 177))
	_probar_compatibilidad()
	for fallo in fallos:
		push_error(fallo)
	print("PuertasRejaMetal: %d comprobaciones, %d fallos." % [comprobaciones, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func _probar(orientacion: String, bisagra_cerrada: Vector2, bisagra_abierta: Vector2) -> void:
	var puerta := load("res://scenes/interactuables/puertas/puerta_reja_metal_%s.tscn" % orientacion).instantiate() as PuertaInteractuable
	puerta.id_instancia = StringName("reja_" + orientacion)
	root.add_child(puerta)
	var datos := puerta.definicion as DefinicionPuerta
	var fila := 0.0 if orientacion == "izquierda" else 96.0
	_comprobar(datos.region_cerrada.position == Vector2(0, fila) and datos.region_abierta.position == Vector2(64, fila), "%s: cerrada a la izquierda y abierta a la derecha de la misma fila del atlas" % orientacion)
	_comprobar(datos.es_valida() and not puerta.bloqueada, "%s: lista para abrir manualmente" % orientacion)
	var limites := Rect2(Vector2.ZERO, datos.textura.get_size())
	_comprobar(limites.encloses(datos.region_cerrada) and limites.encloses(datos.region_abierta), "%s: regiones dentro del atlas" % orientacion)
	_comprobar(puerta.sprite.scale == Vector2.ONE and puerta.sprite.region_rect == datos.region_cerrada, "%s: cerrada a escala original" % orientacion)
	var bisagra := _punto_local(puerta.sprite, bisagra_cerrada)
	var tablero := TableroGrid.new()
	for x in range(-1, 2):
		tablero.datos[Vector2i(x, 0)] = Celda.new()
	_comprobar(tablero.registrar_interactuable(Vector2i.ZERO, puerta), "%s: ocupa una sola celda" % orientacion)
	_comprobar(not tablero.puede_entrar(Vector2i.ZERO) and not tablero.obtener_celda(Vector2i.ZERO).bloquea_vision_efectiva() and tablero.obtener_celda(Vector2i.ZERO).bloquea_proyectiles_efectiva(), "%s: cerrada deja pasar luz y visión, manteniendo el bloqueo físico" % orientacion)
	_probar_luz_a_traves(tablero, orientacion)
	var actor := Node.new()
	var abrir := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, actor, Vector2i.RIGHT, Vector2i.ZERO, puerta, null, &"abrir")
	_comprobar(puerta.resolver_accion(abrir).exitosa and puerta.abierta, "%s: apertura real" % orientacion)
	_comprobar(_punto_local(puerta.sprite, bisagra_abierta).is_equal_approx(bisagra), "%s: bisagra inmóvil al abrir" % orientacion)
	var extremo_libre := _punto_local(puerta.sprite, Vector2(104, 72) if orientacion == "izquierda" else Vector2(117, 161))
	_comprobar(extremo_libre.x > bisagra.x if orientacion == "izquierda" else extremo_libre.x < bisagra.x, "%s: hoja abierta hacia la derecha en la fila superior y hacia la izquierda en la inferior" % orientacion)
	_comprobar(puerta.sprite.region_rect == datos.region_abierta and puerta.sprite.scale == Vector2.ONE, "%s: región abierta completa sin estrechar" % orientacion)
	_comprobar(tablero.puede_entrar(Vector2i.ZERO) and not tablero.obtener_celda(Vector2i.ZERO).bloquea_vision_efectiva() and puerta.obtener_coordenadas_ocupadas().size() == 1, "%s: el sobrante visual no bloquea celdas vecinas" % orientacion)
	if orientacion == "derecha":
		_comprobar(puerta.sprite.region_rect.size.x == 108 and datos.region_abierta.has_point(Vector2(150, 177)), "La reja abierta derecha incluye los píxeles que sobrepasan los 64 px.")
	var guardado := puerta.obtener_estado_persistente()
	var cerrar := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, actor, Vector2i.RIGHT, Vector2i.ZERO, puerta, null, &"cerrar")
	_comprobar(puerta.resolver_accion(cerrar).exitosa and puerta.sprite.position == datos.desplazamiento_sprite and _punto_local(puerta.sprite, bisagra_cerrada).is_equal_approx(bisagra), "%s: cierre sin acumular desplazamiento" % orientacion)
	_comprobar(puerta.restaurar_estado_persistente(guardado) == &"" and _punto_local(puerta.sprite, bisagra_abierta).is_equal_approx(bisagra), "%s: cargar restaura estado y alineación" % orientacion)
	puerta.free()
	tablero.free()
	actor.free()


func _punto_local(sprite: Sprite2D, punto_atlas: Vector2) -> Vector2:
	return sprite.position + punto_atlas - sprite.region_rect.position - sprite.region_rect.size / 2.0


func _probar_luz_a_traves(tablero: TableroGrid, orientacion: String) -> void:
	var fov := FOVManager.new()
	fov.datos_tablero = tablero.datos
	fov.proyectar_luz_fuente(Vector2i.LEFT, 2, 0)
	_comprobar(fov.iluminacion_actual.get(Vector2i.RIGHT, FOVManager.NivelLuz.OSCURIDAD) == FOVManager.NivelLuz.LUZ, "%s: la luz ilumina el otro lado de la reja cerrada" % orientacion)
	_comprobar(ValidadorEspacialTablero.new(tablero).validar_linea_visual(Vector2i.LEFT, Vector2i.RIGHT) == &"", "%s: hay visión a través de los barrotes" % orientacion)
	tablero.obtener_celda(Vector2i.ZERO).bloquea_vision = true
	fov.iluminacion_actual.clear()
	fov.proyectar_luz_fuente(Vector2i.LEFT, 2, 0)
	_comprobar(not fov.iluminacion_actual.has(Vector2i.RIGHT), "%s: una pared superpuesta sigue bloqueando la luz" % orientacion)
	tablero.obtener_celda(Vector2i.ZERO).bloquea_vision = false
	fov.free()


func _probar_compatibilidad() -> void:
	for ruta in [
		"res://assets/interactuables/puertas/puerta/puerta.tres",
		"res://assets/interactuables/puertas/puerta_madera_mecanismo/puerta_madera_mecanismo.tres",
		"res://assets/interactuables/puertas/puerta_madera_mecanismo/puerta_madera_mecanismo_derecha.tres",
	]:
		var puerta := load("res://scenes/interactuables/puertas/puerta_interactuable.tscn").instantiate() as PuertaInteractuable
		puerta.definicion = load(ruta)
		root.add_child(puerta)
		var datos := puerta.definicion as DefinicionPuerta
		_comprobar(datos.bloquea_vision_cerrada and puerta.bloquea_vision_interactuable(), "Las puertas anteriores cerradas conservan su opacidad: %s." % ruta)
		puerta.restaurar_estado_persistente({"abierta": true, "bloqueada": false})
		_comprobar(datos.desplazamiento_apertura == Vector2.ZERO and puerta.sprite.position == datos.desplazamiento_sprite, "Se conserva la alineación de %s." % ruta)
		puerta.free()


func _comprobar(correcto: bool, texto: String) -> void:
	comprobaciones += 1
	if not correcto:
		fallos.append(texto)
