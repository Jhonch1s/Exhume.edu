extends SceneTree

const DisparadorDialogoAreaScript = preload("res://scripts/interacciones/dialogos/disparador_dialogo_area.gd")

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	await _probar_palanca_con_disparador()
	await _probar_disparador_dialogo_area()
	await _probar_vincular_por_codigo()
	_finalizar()


func _probar_palanca_con_disparador() -> void:
	var escena := load(
		"res://scenes/interactuables/mecanismos/palanca_interactuable.tscn"
	) as PackedScene
	var palanca := escena.instantiate() as PalancaInteractuable
	root.add_child(palanca)

	var disparador := palanca.get_node_or_null("Area2D") as Area2D
	_comprobar(
		disparador != null and disparador.get_script() == DisparadorDialogoAreaScript,
		"El nodo Area2D de la palanca debe tener el script DisparadorDialogoArea."
	)

	var ficha_jugador := Ficha.new()
	ficha_jugador.id_actor = &"jugador_principal"
	var area_jugador := Area2D.new()
	ficha_jugador.add_child(area_jugador)
	root.add_child(ficha_jugador)

	var ficha_npc := Ficha.new()
	ficha_npc.id_actor = &"npc_comun"
	var area_npc := Area2D.new()
	ficha_npc.add_child(area_npc)
	root.add_child(ficha_npc)

	# 1. Simular entrada de un NPC (no debe activar cercanía)
	disparador.call(&"_on_area_entered", area_npc)
	_comprobar(
		not disparador.get(&"jugador_en_area"),
		"Un NPC no debe marcar que el jugador principal esta cerca del disparador."
	)

	# 2. Simular entrada del jugador principal
	disparador.call(&"_on_area_entered", area_jugador)
	_comprobar(
		disparador.get(&"jugador_en_area"),
		"La entrada del jugador principal debe marcar jugador_en_area = true."
	)
	_comprobar(
		not disparador.get(&"dialogo_activo"),
		"El dialogo no debe activarse automaticamente solo por entrar al area."
	)

	# 3. Simular pulsación de Enter
	var evento_enter := InputEventKey.new()
	evento_enter.pressed = true
	evento_enter.keycode = KEY_ENTER
	disparador.call(&"_unhandled_input", evento_enter)
	_comprobar(
		disparador.get(&"dialogo_activo"),
		"Pulsar Enter con el jugador cerca debe activar el dialogo."
	)

	# 4. Simular salida del jugador
	disparador.call(&"_on_area_exited", area_jugador)
	_comprobar(
		not disparador.get(&"jugador_en_area"),
		"La salida del jugador debe marcar jugador_en_area = false."
	)

	var gestor = Engine.get_singleton("DialogueManager") if Engine.has_singleton("DialogueManager") else null
	if gestor != null and disparador.get(&"recurso_dialogo") != null:
		gestor.dialogue_ended.emit(disparador.get(&"recurso_dialogo"))

	ficha_npc.free()
	ficha_jugador.free()
	palanca.free()
	await create_timer(0.2).timeout


func _probar_disparador_dialogo_area() -> void:
	var disparador = DisparadorDialogoAreaScript.new()
	root.add_child(disparador)

	var ficha := Ficha.new()
	ficha.id_actor = &"jugador_principal"
	var area_ficha := Area2D.new()
	ficha.add_child(area_ficha)
	root.add_child(ficha)

	var flags := [false]
	disparador.dialogo_iniciado.connect(func(_res): flags[0] = true)

	# 1. Entrada de jugador
	disparador.call(&"_on_area_entered", area_ficha)
	_comprobar(
		disparador.get(&"jugador_en_area"),
		"DisparadorDialogoArea debe detectar al jugador principal en el area."
	)
	_comprobar(
		not disparador.get(&"dialogo_activo"),
		"DisparadorDialogoArea por defecto no debe auto-iniciar sin pulsar Enter."
	)

	# 2. Pulsar Enter
	var evento_enter := InputEventKey.new()
	evento_enter.pressed = true
	evento_enter.keycode = KEY_ENTER
	disparador.call(&"_unhandled_input", evento_enter)
	_comprobar(
		disparador.get(&"dialogo_activo") and flags[0],
		"DisparadorDialogoArea debe activar el dialogo al presionar Enter."
	)

	# 3. Salida de jugador
	disparador.call(&"_on_area_exited", area_ficha)
	_comprobar(
		not disparador.get(&"jugador_en_area"),
		"DisparadorDialogoArea debe actualizar jugador_en_area al salir."
	)

	var gestor = Engine.get_singleton("DialogueManager") if Engine.has_singleton("DialogueManager") else null
	if gestor != null and disparador.get(&"recurso_dialogo") != null:
		gestor.dialogue_ended.emit(disparador.get(&"recurso_dialogo"))

	ficha.free()
	disparador.free()
	await create_timer(0.2).timeout


func _probar_vincular_por_codigo() -> void:
	var area_generica := Area2D.new()
	root.add_child(area_generica)
	var recurso := load("res://dialogues/my_dialogue.dialogue") as Resource

	var disp = DisparadorDialogoAreaScript.vincular(area_generica, recurso, "start")
	_comprobar(
		disp != null and disp.recurso_dialogo == recurso,
		"vincular() debe asociar correctamente el recurso de dialogo a un Area2D."
	)

	area_generica.free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PruebaDialogoInteractuable: todas las comprobaciones pasaron con exito.")
		quit(0)
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)
