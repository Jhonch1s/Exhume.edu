extends SceneTree

const NUMERO_DANIO_FLOTANTE = preload("res://scenes/vfx/numero_danio_flotante.gd")

func _init() -> void:
	print("--- INICIANDO PRUEBA DE NUEVAS CARACTERISTICAS AUDIO Y VFX ---")

	# 1. Verificar recursos de audio de cadenas y narrador
	var sonido_cadenas: AudioStream = load("res://assets/sonidos/varios/editados/cadenas menu.wav")
	assert(sonido_cadenas != null, "Sonido cadenas menu debe existir y cargar")

	var narrador_oscuridad: AudioStream = load("res://assets/sonidos/narrador/vuelve a la oscuridad.mp3")
	assert(narrador_oscuridad != null, "Sonido narrador 'vuelve a la oscuridad' debe existir")

	var narrador_sobrevivir: AudioStream = load("res://assets/sonidos/narrador/lograras sobrevivir.mp3")
	assert(narrador_sobrevivir != null, "Sonido narrador 'lograras sobrevivir' debe existir")

	var narrador_prision: AudioStream = load("res://assets/sonidos/narrador/prision.mp3")
	assert(narrador_prision != null, "Sonido narrador 'prision' debe existir")

	print("[OK] Recursos de audio (cadenas y narradores) cargados correctamente")

	# 2. Verificar NumeroDanioFlotante
	var escena_numero_danio := load("res://scenes/vfx/numero_danio_flotante.tscn") as PackedScene
	assert(escena_numero_danio != null, "Escena NumeroDanioFlotante debe existir")
	var nodo_padre := Node2D.new()
	root.add_child(nodo_padre)
	var efecto_numero = NUMERO_DANIO_FLOTANTE.instanciar_en(nodo_padre, Vector2(100, 100), 5)
	assert(efecto_numero != null, "NumeroDanioFlotante debe instanciarse")
	assert(efecto_numero.cantidad_danio == 5, "La cantidad de daño debe asignarse correctamente")
	print("[OK] NumeroDanioFlotante instanciado correctamente")

	# 3. Verificar CamaraEscenario.sacudir()
	var camara := CamaraEscenario.new()
	root.add_child(camara)
	assert(camara.has_method(&"sacudir"), "CamaraEscenario debe tener método sacudir()")
	camara.sacudir(5.0, 0.2)
	assert(camara._shake_tween != null, "Shake tween debe inicializarse al sacudir")
	print("[OK] CamaraEscenario sacudir() funcionando")

	# 4. Verificar oscurecimiento y transparencia de enemigo muerto
	var npc_escena := load("res://scenes/personajes/sirviente_eek.tscn") as PackedScene
	assert(npc_escena != null, "sirviente_eek.tscn debe existir")
	var npc = npc_escena.instantiate()
	nodo_padre.add_child(npc)
	npc._ready()
	npc._inicializar_audio_npc()
	assert(npc.sprite_personaje.modulate == Color.WHITE, "Sprite debe ser blanco normal mientras vive")
	
	# Aplicar daño mortal
	var vida: int = int(npc.vida_actual)
	npc.recibir_danio(vida)
	assert(npc.esta_muerto(), "El NPC debe estar muerto tras recibir daño igual a su vida")
	assert(npc.sprite_personaje.modulate != Color.WHITE, "El modulate debe oscurecer/transparentar el asset")
	print("[OK] NPC muerte y modulate oscuro/transparente validado")

	# 5. Limpieza
	camara.queue_free()
	nodo_padre.queue_free()

	print("--- TODAS LAS NUEVAS CARACTERISTICAS VERIFICADAS CON EXITO ---")
	quit(0)
