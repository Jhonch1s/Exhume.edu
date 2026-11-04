extends SceneTree


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var ficha := Ficha.new()
	var gestor := GestorAcciones.new()
	root.add_child(ficha)
	root.add_child(gestor)
	var servicio := ServicioTurnos.new(gestor)
	var creado := ficha.aplicar_o_renovar_estado(&"aturdido", 1, 1, 1)
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, ficha, null, null, gestor)
	var bloqueada := gestor.procesar_accion(contexto)
	var bloqueos_correctos := bloqueada.motivo == &"actor_aturdido" and not ficha.puede_moverse() and ficha.puede_actuar()
	var datos := ficha.estados_temporales.obtener_estado_persistente()
	var copia := EstadosTemporalesActor.new()
	var valido := copia.restaurar_estado_persistente(JSON.parse_string(JSON.stringify(datos))) == &""
	var vida := ficha.pv_actual
	var resultado := servicio.avanzar_turno(ficha)
	var correcto := not creado.is_empty() and valido and bloqueos_correctos and resultado.exitosa and ficha.obtener_estado(&"aturdido") == null and ficha.pv_actual == vida and ficha.puede_moverse()
	print("Aturdimiento base: ", "correcto" if correcto else "fallo")
	ficha.queue_free()
	gestor.queue_free()
	await process_frame
	quit(0 if correcto else 1)
