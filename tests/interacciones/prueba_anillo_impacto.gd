extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var texturas: Array[Texture2D] = []
	for nombre in ["icono", "ilustracion", "suelo"]:
		var ruta := "res://assets/items/anillo_impacto/%s.png" % nombre
		var textura := ImageTexture.create_from_image(Image.load_from_file(ruta))
		textura.take_over_path(ruta)
		texturas.append(textura)
	var definicion := load("res://assets/items/anillo_impacto/anillo_impacto.tres") as DefinicionItem
	assert(definicion.es_valida())
	var atacante := Ficha.new()
	var defensor := Ficha.new()
	atacante.fue = 1
	defensor.des = 1
	defensor.pv_max = 20
	defensor.pv_actual = 20
	var proteccion := DefinicionItem.new()
	proteccion.id_definicion = &"armadura_prueba"
	proteccion.nombre = "Armadura"
	proteccion.etiquetas = [&"armadura"]
	proteccion.efectos_equipo = [{"tipo": "armadura", "valor": 5}]
	var armadura := ItemInstancia.new(&"armadura_prueba", proteccion)
	defensor.inventario.agregar(armadura)
	assert(defensor.equipo.equipar(defensor.inventario, armadura.id_instancia, 2) == &"")
	var anillo := ItemInstancia.new(&"anillo_prueba", definicion)
	atacante.inventario.agregar(anillo)
	assert(atacante.equipo.equipar(atacante.inventario, anillo.id_instancia, 7) == &"")
	var rng := RandomNumberGenerator.new()
	for semilla in 10000:
		rng.seed = semilla
		if rng.randi_range(1, 6) == 1 and rng.randi_range(1, 6) == 6:
			rng.seed = semilla
			break
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, atacante, null, null, defensor, null, &"ataque_basico")
	var resultado := ResolverAtaqueBasico.resolver(contexto, defensor, MotorDados.new(rng), AplicadorEfectos.new())
	assert(resultado.tirada_dano != null and defensor.pv_actual == 18)
	assert(EfectosEquipo.bono_dano_final(atacante) == 1)
	var guardado := atacante.equipo.obtener_estado_persistente()
	assert(atacante.equipo.desequipar(atacante.inventario, 7) == &"" and EfectosEquipo.bono_dano_final(atacante) == 0)
	assert(atacante.inventario.retirar(anillo.id_instancia) != null)
	assert(atacante.equipo.restaurar_estado_persistente(guardado) == &"" and EfectosEquipo.bono_dano_final(atacante) == 1)
	atacante.free()
	defensor.free()
	print("AnilloImpacto: daño físico mínimo y equipo correctos.")
	quit()
