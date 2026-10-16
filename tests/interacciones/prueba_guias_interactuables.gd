extends SceneTree

const CartelScript := preload("res://scripts/interacciones/interactuables/guias/cartel_interactuable.gd")
const LibroScript := preload("res://scripts/interacciones/interactuables/guias/libro_interactuable.gd")
const HojasScript := preload("res://scripts/interacciones/interactuables/guias/hojas_interactuable.gd")
const EstandarteScript := preload("res://scripts/interacciones/interactuables/guias/estandarte_interactuable.gd")

func _init() -> void:
	print("--- INICIANDO PRUEBAS DE GUIAS INTERACTUABLES ---")
	
	# 1. Cargar escenas
	var escena_cartel := load("res://scenes/interactuables/guias/cartel_interactuable.tscn") as PackedScene
	assert(escena_cartel != null, "Escena de Cartel debe existir")
	var escena_libro := load("res://scenes/interactuables/guias/libro_interactuable.tscn") as PackedScene
	assert(escena_libro != null, "Escena de Libro debe existir")
	var escena_hojas := load("res://scenes/interactuables/guias/hojas_interactuable.tscn") as PackedScene
	assert(escena_hojas != null, "Escena de Hojas debe existir")
	var escena_estandarte := load("res://scenes/interactuables/guias/estandarte_interactuable.tscn") as PackedScene
	assert(escena_estandarte != null, "Escena de Estandarte debe existir")
	print("[OK] Escenas instanciables")

	# 2. Instanciar y verificar definiciones e ilustraciones
	var cartel = escena_cartel.instantiate()
	root.add_child(cartel)
	assert(cartel.definicion != null, "Cartel tiene definicion")
	assert(cartel.definicion.es_valida(), "Cartel definicion valida")
	assert(cartel.definicion.ilustracion_examen != null, "Cartel tiene ilustracion de examen")
	assert(cartel.definicion.obtener_sonido_examen() != null, "Cartel tiene sonido de examen")

	var libro = escena_libro.instantiate()
	root.add_child(libro)
	assert(libro.definicion != null, "Libro tiene definicion")
	assert(libro.definicion.es_valida(), "Libro definicion valida")
	assert(libro.definicion.ilustracion_examen != null, "Libro tiene ilustracion de examen")
	assert(libro.definicion.obtener_sonido_examen() != null, "Libro tiene sonido de examen")

	var hojas = escena_hojas.instantiate()
	root.add_child(hojas)
	assert(hojas.definicion != null, "Hojas tiene definicion")
	assert(hojas.definicion.es_valida(), "Hojas definicion valida")
	assert(hojas.definicion.ilustracion_examen != null, "Hojas tiene ilustracion de examen")
	assert(hojas.definicion.obtener_sonido_examen() != null, "Hojas tiene sonido de examen")

	var estandarte = escena_estandarte.instantiate()
	root.add_child(estandarte)
	assert(estandarte.definicion != null, "Estandarte tiene definicion")
	assert(estandarte.definicion.es_valida(), "Estandarte definicion valida")
	assert(estandarte.definicion.ilustracion_examen != null, "Estandarte tiene ilustracion de examen")
	assert(estandarte.definicion.obtener_sonido_examen() != null, "Estandarte tiene sonido de examen")
	print("[OK] Definiciones, ilustraciones y sonidos correctos")

	# 3. Variantes visuales
	cartel.orientacion = CartelScript.Orientacion.PARED_DERECHA
	var sprite_cartel := cartel.get_node("Sprite2D") as Sprite2D
	assert(sprite_cartel.region_rect == Rect2(100, 31, 23, 31), "Variante cartel pared derecha")

	libro.variante = LibroScript.Variante.ABIERTO_1
	var sprite_libro := libro.get_node("Sprite2D") as Sprite2D
	assert(sprite_libro.region_rect == Rect2(64, 0, 64, 32), "Variante libro abierto 1")

	hojas.variante = HojasScript.Variante.VARIANTE_2
	var sprite_hojas := hojas.get_node("Sprite2D") as Sprite2D
	assert(sprite_hojas.region_rect == Rect2(64, 64, 64, 32), "Variante hojas 2")

	estandarte.orientacion = EstandarteScript.Orientacion.DERECHA
	var sprite_estandarte := estandarte.get_node("Sprite2D") as Sprite2D
	assert(sprite_estandarte.region_rect == Rect2(192, 32, 64, 64), "Variante estandarte derecha")
	print("[OK] Actualizacion de regiones por variante correcta")

	# 4. Modificacion de texto independiente
	cartel.texto_examen = "Texto unico para este cartel especifico"
	cartel.titulo_examen = "Aviso de Peligro"
	assert(cartel.obtener_texto_examen() == "Texto unico para este cartel especifico", "Texto personalizado funciona")
	assert(cartel.obtener_nombre_interaccion() == "Aviso de Peligro", "Titulo personalizado funciona")

	# 5. Registro en tablero y examen funcional
	var tablero := TableroGrid.new()
	for x in range(5):
		for y in range(5):
			var celda := Celda.new()
			celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
			tablero.datos[Vector2i(x, y)] = celda
	root.add_child(tablero)

	var reg_conocimiento := RegistroConocimiento.new()
	var serv_examen := ServicioExamen.new(tablero, reg_conocimiento)
	tablero.configurar_servicio_examen(serv_examen)

	cartel.id_instancia = &"cartel_test"
	assert(tablero.registrar_interactuable(Vector2i(2, 2), cartel), "Registro en tablero")

	# Opciones de accion
	var opciones: Array = cartel.obtener_opciones_accion(null)
	var tiene_examinar := false
	for op in opciones:
		if op.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
			tiene_examinar = true
	assert(tiene_examinar, "Cartel ofrece opcion de examinar")

	# Limpieza
	cartel.free()
	libro.free()
	hojas.free()
	estandarte.free()
	tablero.free()

	print("[OK] Examen y registro en tablero completados con exito")
	print("--- TODAS LAS PRUEBAS DE GUIAS PASARON EXITOSAMENTE ---")
	quit(0)
