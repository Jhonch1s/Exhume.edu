extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var definicion_antorcha := load("res://assets/items/antorcha/antorcha.tres") as DefinicionItem
	var definicion_racion := load("res://assets/items/racion/racion.tres") as DefinicionItem
	comprobar(definicion_antorcha != null, "Definición de antorcha cargada correctamente.")
	comprobar(definicion_racion != null, "Definición de ración cargada correctamente.")

	# Instanciar EscenarioBase (PruebaGuerrero para tener contexto completo)
	var ruta_escena := "res://scenes/pruebas_habilidades/PruebaLadron.tscn"
	var escena := (load(ruta_escena) as PackedScene).instantiate()
	root.add_child(escena)
	var escenario = escena.get_node("EscenarioBase")

	for intento in 240:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break

	var ficha: Ficha = escenario.ficha_jugador
	var hud: HUD = escenario.hud
	comprobar(ficha != null and hud != null, "Escenario, Ficha y HUD inicializados.")

	# 1. Verificar estructura de las 4 casillas de ítems rápidos
	comprobar(hud.items_rapidos.size() == 4, "El HUD contiene exactamente 4 casillas de ítems rápidos.")
	for i in hud.items_rapidos.size():
		var casilla := hud.items_rapidos[i]
		comprobar(casilla is CasillaItemRapido, "La ranura %d es de tipo CasillaItemRapido." % (i + 1))
		comprobar(hud.items_rapidos_asignados[i] == null, "La ranura %d inicia vacía." % (i + 1))

	# 2. Agregar antorchas y raciones al inventario
	var item_antorchas := ItemInstancia.new(&"antorchas_test", definicion_antorcha, 3)
	var item_raciones := ItemInstancia.new(&"raciones_test", definicion_racion, 2)
	ficha.inventario.agregar(item_antorchas)
	ficha.inventario.agregar(item_raciones)
	ficha.raciones = 2
	hud.actualizar_desde_ficha()

	# 3. Probar Drag & Drop hacia las casillas del HUD
	var ranura_1: CasillaItemRapido = hud.items_rapidos[0]
	var datos_arrastre_antorcha := {
		"tipo": "item_inventario",
		"item": item_antorchas,
		"origen_indice": 0,
		"es_equipo": false,
		"tipo_equipo": -1
	}
	comprobar(ranura_1._can_drop_data(Vector2.ZERO, datos_arrastre_antorcha), "Ranura 1 acepta drop de ítem de inventario.")
	ranura_1._drop_data(Vector2.ZERO, datos_arrastre_antorcha)

	comprobar(hud.items_rapidos_asignados[0] == item_antorchas, "Ranura 1 tiene asignado el ítem de antorchas.")
	var icono_1 := ranura_1.get_node("Icono") as TextureRect
	var cantidad_1 := ranura_1.get_node("Cantidad") as Label
	comprobar(icono_1.texture == definicion_antorcha.icono and icono_1.visible, "Ranura 1 muestra el icono de la antorcha.")
	comprobar(cantidad_1.text == "3", "Ranura 1 muestra la cantidad 3.")

	# Asignar raciones a ranura 2
	var ranura_2: CasillaItemRapido = hud.items_rapidos[1]
	var datos_arrastre_racion := {
		"tipo": "item_inventario",
		"item": item_raciones,
		"origen_indice": 1,
		"es_equipo": false,
		"tipo_equipo": -1
	}
	ranura_2._drop_data(Vector2.ZERO, datos_arrastre_racion)
	comprobar(hud.items_rapidos_asignados[1] == item_raciones, "Ranura 2 tiene asignado el ítem de raciones.")
	var icono_2 := ranura_2.get_node("Icono") as TextureRect
	var cantidad_2 := ranura_2.get_node("Cantidad") as Label
	comprobar(icono_2.texture == definicion_racion.icono and icono_2.visible, "Ranura 2 muestra el icono de la ración.")
	comprobar(cantidad_2.text == "2", "Ranura 2 muestra la cantidad 2.")

	# 4. Probar uso de antorcha (renovar cuando está parcialmente gastada)
	ficha.pasos_antorcha_actual = 20
	ranura_1.pressed.emit() # Clic en ranura 1
	comprobar(ficha.pasos_antorcha_actual == Ficha.PASOS_MAX_ANTORCHA, "Usar antorcha renueva pasos al máximo (%d)." % Ficha.PASOS_MAX_ANTORCHA)
	comprobar(item_antorchas.cantidad == 2, "La pila de antorchas se redujo a 2.")
	comprobar(cantidad_1.text == "2", "El HUD muestra cantidad 2 tras consumir una antorcha.")

	# 5. Probar uso de ración (recuperar salud)
	ficha.recibir_danio(10)
	var pv_antes := ficha.pv_actual
	ranura_2.pressed.emit() # Clic en ranura 2
	comprobar(ficha.pv_actual > pv_antes, "Consumir ración recuperó salud al héroe.")
	comprobar(item_raciones.cantidad == 1, "La pila de raciones se redujo a 1.")
	comprobar(cantidad_2.text == "", "Cantidad no se muestra cuando es 1.")

	# 6. Probar que al llegar a 0 la pila se limpia automáticamente la ranura del HUD
	ficha.recibir_danio(5)
	ranura_2.pressed.emit() # Consume la última ración
	comprobar(ficha.inventario.obtener_por_id(item_raciones.id_instancia) == null, "La última ración fue retirada del inventario.")
	comprobar(hud.items_rapidos_asignados[1] == null, "La ranura 2 del HUD se limpió al agotarse la pila.")
	comprobar(icono_2.texture == null and not icono_2.visible, "El icono de la ranura 2 se ocultó tras limpiarse.")
	comprobar(cantidad_2.text == "", "El texto de cantidad de la ranura 2 quedó vacío.")

	# 7. Probar atajo de teclado 5 (activa la primera ranura de objetos)
	ficha.pasos_antorcha_actual = 15
	var tecla_5 := InputEventKey.new()
	tecla_5.keycode = KEY_5
	tecla_5.pressed = true
	escenario._activar_atajo_numerico(tecla_5)
	comprobar(ficha.pasos_antorcha_actual == Ficha.PASOS_MAX_ANTORCHA, "El atajo de teclado 5 activó la ranura 1 y renovó la antorcha.")
	comprobar(item_antorchas.cantidad == 1, "La antorcha consumió 1 unidad mediante atajo numérico.")

	# 8. Probar desasignación con clic derecho
	ranura_1.click_derecho_solicitado.emit(0)
	comprobar(hud.items_rapidos_asignados[0] == null, "Clic derecho desasignó la ranura 1.")
	comprobar(icono_1.texture == null and not icono_1.visible, "El icono de la ranura 1 se limpió tras clic derecho.")

	# 9. Poción genérica: tirar 1d6 al usar, consumir una unidad y registrar el resultado.
	var definicion_pocion := DefinicionItem.new()
	definicion_pocion.id_definicion = &"pocion_curativa"
	definicion_pocion.nombre = "Poción curativa"
	definicion_pocion.etiquetas = [&"consumible"]
	definicion_pocion.apilable = true
	definicion_pocion.cantidad_maxima = 6
	definicion_pocion.magnitudes = {&"recuperacion_pv": 0.0, &"recuperacion_pv_dados": 1.0, &"recuperacion_pv_caras": 6.0}
	var pocion := ItemInstancia.new(&"pocion_1d6_test", definicion_pocion, 2)
	comprobar(ficha.inventario.agregar(pocion).exitosa, "La poción con dados entra en el inventario.")
	var datos_pocion := datos_arrastre_racion.duplicate()
	datos_pocion.item = pocion
	hud.items_rapidos[2]._drop_data(Vector2.ZERO, datos_pocion)
	ficha.recibir_danio(ficha.pv_actual - 1)
	var antes_pocion := ficha.pv_actual
	hud.items_rapidos[2].pressed.emit()
	comprobar(ficha.pv_actual - antes_pocion >= 1 and ficha.pv_actual - antes_pocion <= 6, "La poción recupera entre 1 y 6 PV.")
	comprobar(pocion.cantidad == 1, "Una tirada consume una sola poción.")
	comprobar(ficha.raciones == 0, "La poción no altera el contador de raciones.")
	var entradas: Array[EntradaRegistroNarrativo] = escenario.registro_narrativo.obtener_entradas_visibles()
	comprobar(entradas[-1].mensaje.contains("Tirada de curación: 1d6 = %d." % (ficha.pv_actual - antes_pocion)), "El registro muestra la fórmula y el resultado aplicado de la tirada.")
	ficha.curar(ficha.pv_max)
	ficha.recibir_danio(1)
	hud.items_rapidos[2].pressed.emit()
	comprobar(ficha.pv_actual == ficha.pv_max, "La curación con dados respeta los PV máximos.")
	comprobar(ficha.inventario.obtener_por_id(pocion.id_instancia) == null and hud.items_rapidos_asignados[2] == null, "Al consumir la última poción se limpian inventario y HUD.")
	for valores in [[0.0, 6.0], [1.5, 6.0], [1.0, 1.0], [1.0, 101.0]]:
		definicion_pocion.magnitudes[&"recuperacion_pv_dados"] = valores[0]
		definicion_pocion.magnitudes[&"recuperacion_pv_caras"] = valores[1]
		comprobar(not definicion_pocion.es_valida(), "Se rechaza configuración de dados inválida: %s." % str(valores))
	var pocion_exportada := ItemInstancia.new(&"pocion_exportada_test", load("res://assets/items/forja/pocion_1/pocion_1.tres") as DefinicionItem, 2)
	comprobar(ficha.inventario.agregar(pocion_exportada).exitosa, "La poción exportada entra en la mochila.")
	var panel_inventario: PanelInventarioEquipo = escenario.panel_inventario_equipo
	panel_inventario.abrir(ficha)
	panel_inventario._al_seleccionar_item_mochila(pocion_exportada)
	comprobar(not panel_inventario.boton_usar.disabled and panel_inventario.boton_usar.text.contains("Pocion"), "La mochila ofrece Usar para la poción.")
	panel_inventario.boton_usar.pressed.emit()
	comprobar(pocion_exportada.cantidad == 2 and not panel_inventario.visible, "A vida completa, no consume la poción y cierra la mochila.")
	ficha.recibir_danio(6)
	var vida_previa := ficha.pv_actual
	panel_inventario.abrir(ficha)
	panel_inventario._al_seleccionar_item_mochila(pocion_exportada)
	panel_inventario.boton_usar.pressed.emit()
	comprobar(ficha.pv_actual > vida_previa and pocion_exportada.cantidad == 1, "Usar desde la mochila cura 1d6 y consume una unidad.")

	escena.queue_free()
	await process_frame

	for fallo in fallos:
		push_error(fallo)
	print("Pruebas de items rápidos del HUD: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append("Fallo [%d]: %s" % [casos, mensaje])
