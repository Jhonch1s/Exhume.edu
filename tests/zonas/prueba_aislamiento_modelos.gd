extends SceneTree

const VISTAS := ["KnightViewPort", "WizardViewPort", "ThiefViewPort"]


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene
	var mundos: Array[World3D] = []
	var escenarios: Array[Node] = []
	# Dos escenarios coexisten al viajar o entrar al descanso.
	for indice in 2:
		var escenario := escena.instantiate()
		escenario.set_script(null)
		# Conservar las vistas reales sin iniciar la partida.
		for hijo in escenario.get_children():
			if not String(hijo.name) in VISTAS:
				hijo.free()
		root.add_child(escenario)
		escenarios.append(escenario)
		for nombre in VISTAS:
			var vista := escenario.get_node(nombre).get_child(0) as SubViewport
			assert(vista.own_world_3d, "%s debe aislar su captura" % nombre)
			var mundo := vista.find_world_3d()
			assert(not mundos.has(mundo), "Dos capturas comparten modelos 3D")
			mundos.append(mundo)
	print("AislamientoModelos: seis capturas con mundos independientes.")
	mundos.clear()
	for escenario in escenarios:
		escenario.free()
	quit(0)
