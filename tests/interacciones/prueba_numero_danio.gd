extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var padre := Node2D.new()
	root.add_child(padre)
	var ficha := Ficha.new()
	padre.add_child(ficha)
	ficha.pv_actual = 20
	ficha.pv_max = 20
	var aplicador := AplicadorEfectos.new()
	var fuente := RefCounted.new()
	for tipo in [&"bola_fuego", &"quemado", &"veneno", &"ataque"]:
		var resultado: Variant = aplicador.aplicar(SolicitudEfecto.new(tipo, &"dano", ficha, &"prueba", 1.0, 0, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, fuente))
		assert(resultado is ResultadoEfectoAplicado and resultado.magnitud == 1.0)
		var numero := padre.get_child(-1) as NumeroDanioFlotante
		assert(numero != null and numero.tipo_danio == tipo)
		assert(numero.etiqueta.get_theme_color("font_color") == NumeroDanioFlotante.COLORES.get(tipo, NumeroDanioFlotante.COLOR_GOLPE))
		assert(numero.scale == Vector2(0.5, 0.5))
	await create_timer(0.5).timeout
	var numero := padre.get_child(-1) as NumeroDanioFlotante
	assert(numero != null and numero.scale.x < 0.5 and numero.position.y < -32.0)
	await create_timer(0.7).timeout
	assert(padre.get_child_count() == 1)
	padre.free()
	print("Números de daño: colores, tamaño y animación correctos")
	quit()
