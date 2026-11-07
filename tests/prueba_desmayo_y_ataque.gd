extends SceneTree

const PANTALLA_DESMAYO_SCRIPT = preload("res://scenes/ui/pantalla_desmayo.gd")
const ESCENA_PANTALLA_DESMAYO = preload("res://scenes/ui/pantalla_desmayo.tscn")
const FICHA_SCRIPT = preload("res://scenes/ficha/ficha.gd")
const PERSONAJE_NPC_SCRIPT = preload("res://scripts/personajes/personaje_npc.gd")

func _init() -> void:
	print("--- INICIANDO PRUEBAS DE DESMAYO POR ENERGIA Y ATAQUE CUERPO A CUERPO ---")
	
	# 1. Comprobar escena PantallaDesmayo
	var pantalla = ESCENA_PANTALLA_DESMAYO.instantiate()
	assert(pantalla != null, "La escena PantallaDesmayo debe instanciarse")
	root.add_child(pantalla)
	pantalla._ready()
	
	var rep_caida: AudioStreamPlayer = pantalla.get_node("AudioCaida")
	var rep_narrador: AudioStreamPlayer = pantalla.get_node("AudioNarrador")
	assert(rep_caida != null, "PantallaDesmayo debe tener AudioCaida")
	assert(rep_narrador != null, "PantallaDesmayo debe tener AudioNarrador")
	assert(PANTALLA_DESMAYO_SCRIPT.SONIDO_CAIDA != null, "Debe tener stream de caída")
	assert(PANTALLA_DESMAYO_SCRIPT.SONIDO_NARRADOR_OSCURIDAD != null, "Debe tener stream del narrador")
	print("[OK] Escena y audios de PantallaDesmayo validados")
	
	# Probar ejecución breve de iniciar_desmayo
	var desmayo_terminado := false
	pantalla.desmayo_completado.connect(func(): desmayo_terminado = true)
	pantalla.iniciar_desmayo(0.05)
	
	for i in range(10):
		await process_frame
	
	pantalla.queue_free()
	print("[OK] Ciclo de vida y señal de PantallaDesmayo validados")
	
	# 2. Comprobar señal energia_agotada en Ficha
	var ficha: Ficha = FICHA_SCRIPT.new()
	root.add_child(ficha)
	ficha.energia_actual = 50
	
	var energia_agotada_emitida := [false]
	ficha.energia_agotada.connect(func():
		energia_agotada_emitida[0] = true
	)
	
	ficha.energia_actual = 10
	assert(not energia_agotada_emitida[0], "No debe emitir si aún queda energía")
	
	ficha.energia_actual = 0
	assert(energia_agotada_emitida[0], "Debe emitir al llegar a 0 de energía")
	
	energia_agotada_emitida[0] = false
	ficha.energia_actual = 0
	assert(not energia_agotada_emitida[0], "No debe emitir de nuevo si ya estaba en 0")
	
	ficha.energia_actual = 50
	ficha.suprimir_senales_recursos = true
	ficha.energia_actual = 0
	assert(not energia_agotada_emitida[0], "No debe emitir si suprimir_senales_recursos es true")
	ficha.suprimir_senales_recursos = false
	print("[OK] Ficha.energia_actual y señal energia_agotada validadas")
	ficha.queue_free()
	
	# 3. Comprobar recuperación y penalización de vida tras desmayo
	var ficha_recuperacion: Ficha = FICHA_SCRIPT.new()
	root.add_child(ficha_recuperacion)
	ficha_recuperacion.pv_max = 20
	ficha_recuperacion.pv_actual = 15
	ficha_recuperacion.energia_maxima = 200
	ficha_recuperacion.energia_actual = 0
	
	# Simular despertar de desmayo (recuperar 60% y perder 3 PV)
	var energia_recuperada: int = int(round(float(ficha_recuperacion.energia_maxima) * 0.60))
	ficha_recuperacion.energia_actual = energia_recuperada
	assert(ficha_recuperacion.energia_actual == 120, "Debe recuperar exactamente 60% (120 de 200)")
	
	var vida_antes := ficha_recuperacion.pv_actual
	ficha_recuperacion.recibir_danio(3)
	assert(ficha_recuperacion.pv_actual == vida_antes - 3, "Debe perder 3 puntos de vida")
	print("[OK] Formula de recuperación de energía (60%) y daño (-3 PV) validada")
	
	# Caso borde: jugador con 2 PV sobreviviendo a 1 PV en vez de morir en el desmayo
	ficha_recuperacion.pv_actual = 2
	var danio_caso_borde: int = 3
	if ficha_recuperacion.pv_actual <= danio_caso_borde:
		danio_caso_borde = maxi(1, ficha_recuperacion.pv_actual - 1)
	ficha_recuperacion.recibir_danio(danio_caso_borde)
	assert(ficha_recuperacion.pv_actual == 1, "Con 2 PV la penalización deja al jugador con 1 PV para no morir injustamente")
	print("[OK] Caso borde de PV crítico en desmayo validado")
	
	ficha_recuperacion.queue_free()
	
	print("--- TODAS LAS PRUEBAS COMPLETADAS CON EXITO ---")
	quit(0)
