extends Node

var _fallos: Array[String] = []


func _ready() -> void:
	var ficha := Ficha.new()
	add_child(ficha)
	# EscenarioBase proporciona un sprite antes de aplicar la presentación.
	ficha.sprite_render = Sprite2D.new()
	ficha.sprite_render.position = Vector2(0, -24)
	ficha.sprite_render.scale = Vector2(0.12, 0.12)
	ficha.texturas_por_direccion[0] = load("res://icon.svg")
	ficha._aplicar_visual_clase()
	var sprite := ficha.sprite_render
	var particulas := ficha.particulasDanio
	var particulas_veneno := ficha.particulasVeneno
	ficha.pv_actual -= 1
	ficha.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	var guardado: Variant = JSON.parse_string(JSON.stringify(ficha.obtener_estado_persistente()))
	for _carga in range(3):
		ficha.pv_actual = ficha.pv_max
		ficha.iniciar_turno()
		_comprobar(
			ficha.restaurar_estado_persistente(guardado) == &""
			and ficha.sprite_render == sprite
			and ficha.particulasDanio == particulas
			and ficha.particulasVeneno == particulas_veneno
			and sprite.get_parent() == ficha
			and particulas.get_parent() == sprite
			and particulas_veneno.get_parent() == sprite
			and sprite.get_child_count() == 2
			and sprite.position == Vector2(0, -24)
			and sprite.scale == Vector2(0.12, 0.12)
			and ficha.pv_actual == ficha.pv_max - 1
			and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0,
			"Cargar debe reutilizar los nodos visuales y restaurar PV y acciones gastadas."
		)
	ficha.reproducir_efecto_danio()
	ficha.aplicar_o_renovar_estado(&"veneno", 1.0, 2, 2)
	_comprobar(
		ficha.particulasVeneno.emitting and ficha.sprite_render.material == ficha.shaderMat,
		"El veneno debe ser visible mientras el estado está activo."
	)
	ficha.aplicar_o_renovar_estado(&"quemado", 1.0, 2, 2)
	ficha.retirar_estado(&"veneno")
	_comprobar(
		not ficha.particulasVeneno.emitting and ficha.sprite_render.material == ficha.shaderMatQ
		and is_instance_valid(ficha.particulaFuegoInstancia),
		"Retirar veneno debe conservar el efecto visual de quemadura."
	)
	ficha.retirar_estado(&"quemado")
	_comprobar(
		ficha.sprite_render.material == null and ficha.particulaFuegoInstancia == null,
		"Retirar quemadura debe limpiar su efecto visual."
	)
	var ficha_sin_sprite := Ficha.new()
	add_child(ficha_sin_sprite)
	ficha_sin_sprite.texturas_por_direccion[0] = load("res://icon.svg")
	ficha_sin_sprite._aplicar_visual_clase()
	ficha_sin_sprite._aplicar_visual_clase()
	_comprobar(
		ficha_sin_sprite.sprite_render.get_parent() == ficha_sin_sprite
		and ficha_sin_sprite.particulasDanio.get_parent() == ficha_sin_sprite.sprite_render
		and ficha_sin_sprite.particulasVeneno.get_parent() == ficha_sin_sprite.sprite_render,
		"Crear el sprite internamente debe unir cada nodo una sola vez."
	)
	ficha.queue_free()
	ficha_sin_sprite.queue_free()
	await get_tree().process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("CargaVisualFicha: 7 grupos correctos.")
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
