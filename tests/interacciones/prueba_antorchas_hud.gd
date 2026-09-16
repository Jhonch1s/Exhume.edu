extends Node


func _ready() -> void:
	var ficha := Ficha.new()
	add_child(ficha)
	var antorcha := load("res://assets/items/antorcha/antorcha.tres") as DefinicionItem
	if not ficha.inventario.agregar(ItemInstancia.new(&"antorchas_prueba", antorcha, 2)).exitosa:
		_fallar("No se pudieron agregar las antorchas de prueba.")
		return
	ficha.activar_antorcha_si_necesario()
	var hud := load("res://scenes/ui/hud/hud.tscn").instantiate() as HUD
	add_child(hud)
	hud.configurar_ficha(ficha)
	for clase in ["Guerrero", "Ladrón", "Mago"]:
		ficha.clase = clase
		hud.actualizar_desde_ficha()
		var nombre_archivo: String = "ladron" if clase == "Ladrón" else clase.to_lower()
		if not hud.retrato.texture.resource_path.ends_with("/%s.png" % nombre_archivo):
			_fallar("El retrato no corresponde a la clase %s." % clase)
			return
	ficha.aplicar_o_renovar_estado(&"quemado", 0.0, 3, 3, null, [{
		&"cantidad": 1, &"caras": 2, &"signo": 1,
	}])
	if (
		"1d2 de daño" not in hud.estados[0].tooltip_text
		or "3 turnos restantes" not in hud.estados[0].tooltip_text
		or (hud.estados[0].get_node("Icono") as Label).mouse_filter != Control.MOUSE_FILTER_IGNORE
	):
		_fallar("El tooltip de quemado no describe el daño o su duración.")
		return
	ficha.consumir_tick_estado(&"quemado")
	if "2 turnos restantes" not in hud.estados[0].tooltip_text:
		_fallar("El tooltip no actualizó los turnos restantes.")
		return
	ficha.aplicar_o_renovar_estado(&"veneno", 0.0, 2, 2, null, [{
		&"cantidad": 1, &"caras": 4, &"signo": 1,
	}])
	if (
		"1d4 de daño" not in hud.estados[1].tooltip_text
		or "2 turnos restantes" not in hud.estados[1].tooltip_text
	):
		_fallar("El tooltip de veneno no describe el daño o su duración.")
		return
	var cuadro := hud.estados[1].call(
		&"_make_custom_tooltip", hud.estados[1].tooltip_text
	) as PanelContainer
	if cuadro == null:
		_fallar("El estado no crea el tooltip con el marco del HUD.")
		return
	cuadro.free()
	ficha.consumir_tick_estado(&"veneno")
	if "1 turno restante" not in hud.estados[1].tooltip_text:
		_fallar("El tooltip de veneno no actualizó la duración.")
		return
	if ficha.pasos_antorcha_actual != 80 or "×2" not in hud.items_rapidos[0].text:
		_fallar("El HUD no muestra las dos antorchas iniciales.")
		return
	ficha.pasos_antorcha_actual = 1
	if not ficha.consumir_paso_antorcha():
		_fallar("La primera antorcha no se consumió correctamente.")
		return
	hud.actualizar_desde_ficha()
	if (
		ficha.obtener_cantidad_antorchas() != 1
		or ficha.pasos_antorcha_actual != 80
		or "×1" not in hud.items_rapidos[0].text
		or hud.antorcha_luces[1].color != Color("#28231b")
	):
		_fallar("El consumo no actualizó la pila y los engarces del HUD.")
		return
	ficha.pasos_antorcha_actual = 1
	if ficha.consumir_paso_antorcha() or ficha.obtener_cantidad_antorchas() != 0:
		_fallar("La última antorcha no desapareció del inventario.")
		return
	var escenario := load("res://scenes/escenario_base/escenario_base.tscn").instantiate() as Node2D
	add_child(escenario)
	for fotograma in 20:
		await get_tree().process_frame
	var tablero := escenario.get("tablero") as TableroGrid
	if (
		tablero.obtener_item_suelo(&"zona1_llave_prueba") != null
		or tablero.obtener_item_suelo(&"zona1_bomba_humo") != null
	):
		_fallar("La llave y la bomba de humo de prueba no deben aparecer al iniciar.")
		return
	var ficha_inicio := escenario.get("ficha_jugador") as Ficha
	var vision := escenario.get_node("GestorVision") as FOVManager
	if (
		ficha_inicio == null
		or ficha_inicio.capa_referencia == null
		or vision.ultimo_radio_jugador != 5
		or vision.ultimo_centro_jugador != ficha_inicio.coordenada_mapa
	):
		_fallar("La iluminación inicial no se aplicó en la posición de la ficha.")
		return
	var coordenada := ficha_inicio.coordenada_mapa
	if (
		(vision.datos_tablero[coordenada] as Celda).visibilidad != Celda.EstadoVisibilidad.VISIBLE
		or vision.capa_oscuridad.get_cell_source_id(coordenada) != -1
	):
		_fallar("La celda inicial continúa cubierta por la oscuridad.")
		return
	var definicion := ficha_inicio.obtener_antorcha_activa()
	var luz := ficha_inicio.get_node("Antorcha") as PointLight2D
	definicion.radio_vision = 7
	definicion.pasos_atenuacion = 4
	definicion.energia_luz = 2.0
	definicion.escala_luz = 1.5
	definicion.color_luz = Color.CYAN
	escenario.call("_actualizar_luz_jugador", coordenada)
	await get_tree().process_frame
	if (
		vision.ultimo_radio_jugador != 7
		or not luz.enabled
		or luz.color != Color.CYAN
		or not is_equal_approx(luz.texture_scale, 1.5)
		or absf(luz.energy - 2.0) > 0.16
	):
		_fallar("La luz debe leer alcance, color, tamaño e intensidad del ítem activo.")
		return
	ficha_inicio.pasos_antorcha_actual = 2
	escenario.call("_actualizar_luz_jugador", coordenada)
	await get_tree().process_frame
	if vision.ultimo_radio_jugador != 3 or absf(luz.energy - 1.0) > 0.16:
		_fallar("La atenuación final debe reducir visión y brillo según el ítem activo.")
		return
	ficha_inicio.inventario.retirar(&"jugador_antorchas_iniciales")
	ficha_inicio.activar_antorcha_si_necesario()
	escenario.call("_actualizar_luz_jugador", coordenada)
	await get_tree().process_frame
	if vision.ultimo_radio_jugador != 1 or luz.enabled:
		_fallar("Sin antorchas no debe quedar activa la luz del jugador.")
		return
	print("Antorchas e indicadores del HUD: correcto.")
	get_tree().quit()


func _fallar(mensaje: String) -> void:
	push_error(mensaje)
	get_tree().quit(1)
