extends SceneTree


func _initialize() -> void:
	# Cargar la prueba después de registrar los autoloads del proyecto.
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	set_script(load(OS.get_cmdline_user_args()[0]))
	# Al cambiar de script, SceneTree no vuelve a invocar su callback de arranque.
	if has_method(&"_initialize"):
		call(&"_initialize")
