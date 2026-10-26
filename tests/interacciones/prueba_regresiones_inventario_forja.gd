extends SceneTree

class TableroRegistroFallido extends TableroGrid:
	func registrar_item_suelo(_coord: Vector2i, _item: ItemSuelo) -> bool:
		return false

var fallos: Array[String] = []
var casos := 0
var escenario: Node
var ficha: Ficha


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escena := (load("res://scenes/pruebas_habilidades/PruebaLadron.tscn") as PackedScene).instantiate()
	root.add_child(escena)
	escenario = escena.get_node("EscenarioBase")
	for intento in 240:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	ficha = escenario.ficha_jugador
	escena.set_process(false)
	escenario.set_process(false)
	escenario.panel_inventario_equipo.cerrar()
	escenario.interaccion_modal_activa = false
	_probar_rapidos()
	_probar_caidas()
	_probar_rollback_equipo()
	escena.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Regresiones inventario/Forja: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func _crear(id: StringName, etiquetas: Array[StringName], magnitudes: Dictionary[StringName, float] = {}) -> ItemInstancia:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = id
	definicion.nombre = String(id)
	definicion.etiquetas = etiquetas
	definicion.magnitudes = magnitudes
	var item := ItemInstancia.new(id, definicion)
	comprobar(ficha.inventario.agregar(item).exitosa, "Se agrega %s." % id)
	return item


func _usar(item: ItemInstancia) -> void:
	escenario.hud.items_rapidos_asignados[0] = item
	escenario.hud.items_rapidos[0].pressed.emit()


func _probar_rapidos() -> void:
	for lista in [[&"arrojable"], [&"arrojable", &"consumible"]]:
		var etiquetas: Array[StringName] = []
		etiquetas.assign(lista)
		var bomba := _crear(StringName("arrojable_%d" % casos), etiquetas, {&"recuperacion_pv": 5.0})
		var pv := ficha.pv_actual
		_usar(bomba)
		comprobar(escenario.item_lanzamiento_pendiente == bomba, "El HUD prepara el lanzamiento incluso si el arrojable también cura.")
		comprobar(ficha.inventario.obtener_por_id(bomba.id_instancia) == bomba and ficha.pv_actual == pv, "Preparar lanzamiento no consume ni cura.")
		escenario._cancelar_lanzamiento()
	var sin_efecto := _crear(&"consumible_sin_efecto", [&"consumible"])
	_usar(sin_efecto)
	comprobar(ficha.inventario.obtener_por_id(sin_efecto.id_instancia) == sin_efecto, "La etiqueta consumible no basta para gastar un objeto.")
	var racion := _crear(&"racion", [&"consumible"], {
		&"recuperacion_pv": 0.0, &"recuperacion_pv_dados": 1.0, &"recuperacion_pv_caras": 6.0,
	})
	ficha.curar(ficha.pv_max)
	ficha.recibir_danio(ficha.pv_max - 1)
	ficha.raciones = 2
	_usar(racion)
	comprobar(ficha.pv_actual >= 2 and ficha.pv_actual <= 7, "La ración recupera 1d6 PV.")
	comprobar(ficha.raciones == 1 and ficha.inventario.obtener_por_id(racion.id_instancia) == null, "La ración descuenta una unidad y una provisión.")
	var pocion := _crear(&"pocion_saturada", [&"consumible"], {
		&"recuperacion_pv": 6.0, &"recuperacion_pv_dados": 1.0, &"recuperacion_pv_caras": 6.0,
	})
	ficha.curar(ficha.pv_max)
	ficha.recibir_danio(1)
	_usar(pocion)
	var entradas: Array[EntradaRegistroNarrativo] = escenario.registro_narrativo.obtener_entradas_visibles()
	var mensaje := entradas[-1].mensaje
	var tirado := int(mensaje.get_slice(" = ", 1).get_slice(".", 0))
	comprobar(tirado >= 7 and tirado <= 12 and mensaje.contains("Recuperas 1 PV."), "El registro separa 1d6+6 tirado de 1 PV recuperado.")
	comprobar(ficha.pv_actual == ficha.pv_max and ficha.raciones == 1, "La poción limita PV y conserva provisiones.")
	comprobar(escenario.hud.items_rapidos_asignados[0] == null, "El HUD limpia la última poción.")
	for antorcha in ficha.inventario.obtener_por_definicion(&"antorcha"):
		ficha.inventario.retirar(antorcha.id_instancia)
	var def_antorcha := (load("res://assets/items/antorcha/antorcha.tres") as DefinicionAntorcha).duplicate() as DefinicionAntorcha
	def_antorcha.magnitudes = def_antorcha.magnitudes.duplicate()
	def_antorcha.magnitudes[&"duracion"] = 12.0
	var ultima := ItemInstancia.new(&"ultima_antorcha", def_antorcha)
	comprobar(ficha.inventario.agregar(ultima).exitosa, "Se agrega la última antorcha.")
	comprobar(ficha.pasos_antorcha_actual == 12, "La antorcha nueva tiene toda su duración propia.")
	_usar(ultima)
	comprobar(ficha.pasos_antorcha_actual == 12 and ficha.obtener_antorcha_activa() != null, "La última antorcha enciende con su duración configurada.")
	comprobar(ficha.inventario.obtener_por_id(ultima.id_instancia) == ultima, "La antorcha encendida se conserva hasta agotarse.")
	_usar(ultima)
	comprobar(ficha.pasos_antorcha_actual == 12 and ficha.obtener_cantidad_antorchas() == 1, "No se desperdicia una antorcha a duración máxima.")
	ficha.pasos_antorcha_actual = 5
	_usar(ultima)
	comprobar(ficha.pasos_antorcha_actual == 5 and ficha.obtener_cantidad_antorchas() == 1, "Sin repuesto se conserva la antorcha parcialmente gastada.")
	var repuesto := ItemInstancia.new(&"antorcha_repuesto", def_antorcha)
	ficha.inventario.agregar(repuesto)
	_usar(repuesto)
	comprobar(ficha.pasos_antorcha_actual == 12 and ficha.obtener_cantidad_antorchas() == 1, "Renovar descarta la encendida y activa el repuesto.")
	ficha.pasos_antorcha_actual = 1
	comprobar(not ficha.consumir_paso_antorcha() and ficha.obtener_cantidad_antorchas() == 0, "La última antorcha se consume al agotarse.")


func _punto(coord: Vector2i) -> Vector2:
	var capa: TileMapLayer = escenario.zona_actual.get_node("CapaSuelo")
	return escenario.get_canvas_transform() * capa.to_global(capa.map_to_local(coord))


func _anillo(id: StringName) -> ItemInstancia:
	var item := _crear(id, [&"anillo"])
	item.definicion.efectos_equipo = [{"tipo": "atributo", "atributo": "fuerza", "valor": 1}]
	comprobar(ficha.equipo.equipar(ficha.inventario, id, 7) == &"", "Se equipa el anillo.")
	return item


func _probar_caidas() -> void:
	var origen := Vector2i(99, 100)
	ficha.coordenada_mapa = origen
	for delta in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.ONE]:
		escenario.tablero.datos[origen + delta] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	var anillo := _anillo(&"anillo_diagonal")
	escenario.panel_inventario_equipo.abrir(ficha)
	var casilla_anillo := escenario.panel_inventario_equipo.ranuras_equipo_nodos[7] as CasillaInventario
	escenario.panel_inventario_equipo._mostrar_tooltip(casilla_anillo)
	var limite_inventario := escenario.hud.get_node("HUDRoot/SeccionesHUD/SeccionJugador/Retrato") as Control
	var tooltip_inventario: PanelContainer = escenario.panel_inventario_equipo.tooltip_flotante
	comprobar(tooltip_inventario != null and tooltip_inventario.get_global_rect().end.y <= limite_inventario.get_global_rect().position.y, "El hover del inventario queda encima del HUD.")
	escenario.panel_inventario_equipo.cerrar()
	escenario._on_item_inventario_soltado_al_suelo(anillo, 7, true, _punto(origen + Vector2i.ONE))
	var suelo: ItemSuelo = escenario.tablero.obtener_item_suelo(anillo.id_instancia)
	comprobar(suelo != null and suelo.item == anillo, "Un cursor diagonal elige una caída dentro de alcance.")
	comprobar(not ficha.equipo.ranuras.has(7) and ficha.inventario.obtener_por_id(anillo.id_instancia) == null, "El anillo pasa una sola vez del equipo al suelo.")
	comprobar(ficha.obtener_fuerza() == ficha.fue, "Soltar elimina el bono equipado.")
	anillo.definicion.ilustracion_examen = ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	var opciones := suelo.obtener_opciones_accion(ficha)
	comprobar(opciones.size() == 2 and opciones[0].id == &"examinar" and opciones[1].id == &"recoger", "El suelo ofrece Examinar y Recoger.")
	var contexto_examen := ConstructorContextoAccion.new().construir_desde_opcion(opciones[0], ficha, origen, suelo.coordenada_mapa) as ContextoAccion
	var resultado_examen: ResultadoAccion = escenario.gestor_acciones.procesar_accion(contexto_examen)
	comprobar(resultado_examen.exitosa and suelo.item == anillo, "Examinar el ítem del suelo no lo recoge ni exige movimiento.")
	escenario._presentar_resultado_contextual(anillo.definicion.nombre, resultado_examen, contexto_examen)
	comprobar(escenario.panel_examen_ilustrado.visible and escenario.panel_examen_ilustrado.imagen.texture == anillo.definicion.ilustracion_examen, "Inspeccionar el suelo abre la ilustración.")
	var ventana_examen := escenario.panel_examen_ilustrado.get_node("Ventana") as Control
	var limite_hud := escenario.hud.get_node("HUDRoot/SeccionesHUD/SeccionJugador/Retrato") as Control
	comprobar(ventana_examen.get_global_rect().end.y <= limite_hud.get_global_rect().position.y, "La ilustración queda encima del HUD.")
	escenario.panel_examen_ilustrado.ocultar()
	var lleno := _anillo(&"anillo_mochila_llena")
	ficha.inventario.capacidad = ficha.inventario.obtener_contenido().size()
	comprobar(ficha.inventario.esta_lleno(), "La mochila está llena.")
	escenario._on_item_inventario_soltado_al_suelo(lleno, 7, true, _punto(origen))
	suelo = escenario.tablero.obtener_item_suelo(lleno.id_instancia)
	comprobar(suelo != null and suelo.item == lleno and not ficha.equipo.ranuras.has(7), "Con mochila llena se transfiere la misma pieza al suelo.")
	comprobar(ficha.inventario.obtener_contenido().size() == ficha.inventario.capacidad, "La caída no altera la mochila llena.")
	ficha.inventario.capacidad = -1
	var bloqueado := _anillo(&"anillo_caida_bloqueada")
	for delta in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		escenario.tablero.datos[origen + delta].caminable = false
	escenario._on_item_inventario_soltado_al_suelo(bloqueado, 7, true, _punto(origen))
	comprobar(ficha.equipo.ranuras.get(7) == bloqueado and ficha.obtener_fuerza() == ficha.fue + 1, "Sin destino válido se conservan pieza y bono.")
	comprobar(escenario.tablero.obtener_item_suelo(bloqueado.id_instancia) == null, "Una caída bloqueada no duplica la pieza.")


func _probar_rollback_equipo() -> void:
	var tablero := TableroRegistroFallido.new()
	tablero.datos[Vector2i.ZERO] = Celda.new()
	var transferidor := TransferidorItems.new(tablero)
	var gestor := GestorAcciones.new()
	var item: ItemInstancia = ficha.equipo.ranuras[7]
	var contexto := transferidor.construir_contexto_soltar(ficha, item, Vector2i.ZERO, Vector2i.ZERO, -1, &"", 7)
	var resultado := gestor.procesar_accion(contexto)
	comprobar(resultado.motivo == &"registro_item_suelo_fallido", "Se informa el fallo inesperado de registro.")
	comprobar(ficha.equipo.ranuras.get(7) == item and ficha.obtener_fuerza() == ficha.fue + 1, "El rollback conserva instancia y efectos equipados.")
	comprobar(ficha.inventario.obtener_por_id(item.id_instancia) == null and tablero.items_suelo_por_id.is_empty(), "El rollback no duplica en mochila ni suelo.")
	var ajeno := transferidor.construir_contexto_soltar(ficha, item, Vector2i.ZERO, Vector2i.ZERO, -1, &"", 3)
	comprobar(gestor.procesar_accion(ajeno).motivo == &"item_no_pertenece_equipo", "Se rechaza una ranura que no contiene el objeto.")
	gestor.free()
	tablero.free()


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append("Fallo [%d]: %s" % [casos, mensaje])
