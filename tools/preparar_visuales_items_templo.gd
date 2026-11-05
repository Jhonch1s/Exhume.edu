extends SceneTree


func _init() -> void:
	for id in ["amuleto_klink", "ganzua_mecanica"]:
		var carpeta := "res://assets/items/%s/" % id
		var original := Image.load_from_file(carpeta + "original.png")
		if original == null or original.is_empty():
			quit(1)
			return
		for formato in [["icono.png", Vector2i(24, 24), Vector2i(22, 22)], ["ilustracion.png", Vector2i(100, 100), Vector2i(96, 96)], ["suelo.png", Vector2i(64, 32), Vector2i(30, 28)]]:
			var imagen := original.duplicate() as Image
			var limite: Vector2i = formato[2]
			var factor := minf(float(limite.x) / imagen.get_width(), float(limite.y) / imagen.get_height())
			imagen.resize(maxi(1, roundi(imagen.get_width() * factor)), maxi(1, roundi(imagen.get_height() * factor)), Image.INTERPOLATE_NEAREST)
			var lienzo := Image.create_empty(formato[1].x, formato[1].y, false, Image.FORMAT_RGBA8)
			lienzo.blit_rect(imagen, Rect2i(Vector2i.ZERO, imagen.get_size()), (formato[1] - imagen.get_size()) / 2)
			if lienzo.save_png(carpeta + formato[0]) != OK:
				quit(1)
				return
	quit()
