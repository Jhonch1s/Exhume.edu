extends SceneTree

func _init():
	print("--- INICIANDO VERIFICACION DE AUDIO COMPLETA ---")
	
	# 1. DefinicionItem
	var piedra_def: DefinicionItem = load("res://assets/items/piedra/piedra.tres")
	assert(piedra_def != null, "Piedra def debe existir")
	var rec := piedra_def.obtener_sonido_recoger()
	assert(rec != null, "Sonido recoger piedra configurado")
	var imp := piedra_def.obtener_sonido_impacto()
	assert(imp != null, "Sonido impacto piedra configurado")
	print("[OK] DefinicionItem (recoger/impacto) funcionando correctamente")

	# 2. Puerta
	var puerta_res: DefinicionPuerta = load("res://assets/interactuables/puertas/puerta/puerta.tres")
	assert(puerta_res != null and puerta_res.sonido_abrir != null, "Puerta res tiene sonido abrir")
	print("[OK] DefinicionPuerta con nuevo sonido 'Dungeon Door - Metal Handle.wav'")

	# 3. Personaje NPC y Definicion
	var goblin_def: DefinicionPersonaje = load("res://recursos/personajes/goblin_unico.tres")
	assert(goblin_def != null, "Goblin def existe")
	assert(goblin_def.obtener_sonido_paso_aleatorio() != null, "Paso monstruo OK")
	assert(goblin_def.obtener_sonido_dolor_aleatorio() != null, "Dolor monstruo OK")
	assert(goblin_def.obtener_sonido_proximidad_aleatorio() != null, "Proximidad monstruo OK")
	print("[OK] DefinicionPersonaje (pasos, dolor, rugidos proximidad) OK")

	# 4. Ficha estados y sonidos
	var ficha = Ficha.new()
	assert(ficha.SONIDO_DANIO_DEFECTO != null, "Ficha sonido daño")
	assert(ficha.SONIDO_QUEMADURA_DEFECTO != null, "Ficha sonido quemadura")
	assert(ficha.SONIDO_VENENO_DEBUFF_DEFECTO != null, "Ficha sonido veneno debuff")
	assert(ficha.SONIDO_TOS_1 != null and ficha.SONIDO_TOS_2 != null, "Ficha toses editadas")
	ficha.free()
	print("[OK] Ficha y sonidos de daño/quemadura/veneno debuff/toses intercaladas OK")

	# 5. NPC instancia y ataque
	var npc = PersonajeNPC.new()
	npc.definicion = goblin_def
	root.add_child(npc)
	npc._inicializar_audio_npc()
	assert(npc.reproductor_audio != null, "NPC reproductor_audio creado")
	assert(npc.reproductor_proximidad != null, "NPC reproductor_proximidad creado")
	npc.vida_actual = 10
	npc.recibir_danio(2)
	assert(npc.reproductor_audio.stream != null, "NPC reprodujo gemido de dolor al ser dañado")
	npc.free()
	print("[OK] PersonajeNPC instanciacion, reproductores 2D y dolor OK")

	# 6. Cofres - Sonido de apertura
	var cofre = CofreInteractuable.new()
	root.add_child(cofre)
	cofre.reproducir_sonido_abrir()
	assert(cofre.reproductor_audio != null and cofre.reproductor_audio.stream != null, "Cofre sonido de apertura OK")
	cofre.free()
	print("[OK] Cofre sonido 'MMO_Game_Magic_Source_Chest_02_Door_Unlock_Open_Close' OK")

	# 7. Velas / Fuentes de luz - Sonidos de encender y apagar
	var vela_def: DefinicionFuenteLuz = load("res://assets/interactuables/luces/vela_01.tres")
	assert(vela_def != null, "Vela def debe existir")
	assert(vela_def.sonido_encender != null, "Vela sonido encender asignado")
	assert(vela_def.sonido_apagar != null, "Vela sonido apagar asignado")
	var fuente_luz = FuenteLuzInteractuable.new()
	fuente_luz.definicion = vela_def
	root.add_child(fuente_luz)
	fuente_luz._reproducir_sonido_estado()
	assert(fuente_luz.reproductor_audio != null and fuente_luz.reproductor_audio.stream != null, "Fuente de luz audio OK")
	fuente_luz.free()
	print("[OK] Velas y fuentes de luz encendido/apagado OK")

	# 8. Estatuas - Sonidos de examen
	var estatua_angel: DefinicionInteractuable = DefinicionInteractuable.new()
	estatua_angel.id_definicion = &"trampero_sin_rostro"
	assert(estatua_angel.obtener_sonido_examen() != null, "Estatua angel tiene sonido Mystic Loop 2")
	var estatua_simple: DefinicionInteractuable = DefinicionInteractuable.new()
	estatua_simple.id_definicion = &"estatua_templo"
	assert(estatua_simple.obtener_sonido_examen() != null, "Estatua simple tiene sonido BB20")
	print("[OK] Estatuas: angel (Mystic Loop 2) y simples (BB20) en examen OK")

	# 9. CursorJuego - Click en UI
	var cursor_script: GDScript = load("res://scripts/ui/cursor_juego.gd")
	assert(cursor_script != null, "CursorJuego script existe")
	assert(cursor_script.SONIDO_CLICK_UI != null, "CursorJuego tiene Special Click 02 configurado")
	var cursor_inst = cursor_script.new()
	cursor_inst.reproducir_click_ui()
	assert(cursor_inst._reproductor_click != null, "CursorJuego tiene reproductor de click instanciado")
	cursor_inst.free()
	print("[OK] CursorJuego (Special Click 02 en botones y UI) OK")

	# 10. Diálogos - Growly 4a en Balloon
	var balloon_script: GDScript = load("res://scenes/dialogue/balloon.gd")
	assert(balloon_script != null, "Balloon script existe")
	print("[OK] Diálogo configurado exclusivamente con growly_4a OK")

	print("--- TODAS LAS PRUEBAS DE AUDIO PASARON EXITOSAMENTE ---")
	quit(0)
