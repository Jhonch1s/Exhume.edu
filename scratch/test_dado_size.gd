extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://scenes/ui/interacciones/vista_dado_3d.tscn")
	var dado: VistaDado3D = escena.instantiate()
	dado.custom_minimum_size = Vector2(180, 180)
	dado.size = Vector2(180, 180)
	root.add_child(dado)
	await process_frame
	
	print("SubViewport size:", dado.get_node("SubViewport").size)
	dado.animar_a_valor(4)
	await dado.animacion_finalizada
	print("Animacion finalizada con éxito en cara 4!")
	quit(0)
