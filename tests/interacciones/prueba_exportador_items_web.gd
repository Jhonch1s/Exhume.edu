extends SceneTree

const BASE := "res://.godot/forja_export_test/"
var casos := 0
var fallos: Array[String] = []
var texturas: Array[Texture2D] = []


func _initialize() -> void:
	call_deferred(&"_probar")


func _comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
		push_error(mensaje)


func _probar() -> void:
	var ruta := BASE + "manifest.json"
	if not FileAccess.file_exists(ruta):
		push_error("Ejecuta primero node tools/forja_items/tests/core.test.cjs")
		quit(1)
		return
	var fichas: Array = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	for ficha: Dictionary in fichas:
		var carpeta := BASE + "assets/items/forja/%s/" % ficha.id
		# La exportación aislada no pasa por el editor/importador de PNG.
		# Precargar las texturas permite comprobar el mismo .tres nativo en headless.
		for nombre in ["icono.png", "suelo.png", "ilustracion.png"]:
			var archivo: String = carpeta + nombre
			if FileAccess.file_exists(archivo):
				var imagen := Image.load_from_file(archivo)
				_comprobar(imagen != null and not imagen.is_empty(), "PNG: " + archivo)
				var textura := ImageTexture.create_from_image(imagen)
				textura.take_over_path(archivo)
				texturas.append(textura)
		var definicion := load(carpeta + ficha.id + ".tres") as DefinicionItem
		_comprobar(definicion != null, "Carga nativa: " + ficha.id)
		if definicion == null:
			continue
		_comprobar(definicion.es_valida(), "Definición válida: " + ficha.id)
		_comprobar(definicion.efectos_equipo.size() == ficha.equipmentEffects.size(), "Efectos de equipo nativos: " + ficha.id)
		_comprobar(definicion.nombre == ficha.name and definicion.descripcion_base == ficha.description, "Texto y escapes: " + ficha.id)
		var instancia := ItemInstancia.new(StringName(ficha.id), definicion, int(ficha.maxStack))
		_comprobar(instancia.es_valida(), "Instancia válida: " + ficha.id)
		_comprobar(is_equal_approx(instancia.obtener_peso_total(), ficha.weight * ficha.maxStack), "Peso de pila: " + ficha.id)
		var suelo := definicion.escena_mundo.instantiate()
		_comprobar(suelo is RepresentacionItemSuelo, "Representación de suelo: " + ficha.id)
		_comprobar(suelo.get_node("Sprite2D").hframes == int(ficha.hframes), "Variantes de sprite: " + ficha.id)
		suelo.free()
		if ficha.kind == "llave":
			_comprobar(definicion is DefinicionLlave and definicion.patron_cerradura == StringName(ficha.pattern), "Patrón de llave")
		if ficha.kind == "antorcha":
			_comprobar(definicion is DefinicionAntorcha and definicion.radio_vision == int(ficha.torch.vision), "Antorcha nativa")
			_comprobar(definicion.magnitudes[&"duracion"] == ficha.torch.duration, "Duración de luz")
		if ficha.heal.max > 0:
			_comprobar(definicion.magnitudes[&"recuperacion_pv"] == ficha.heal.bonus, "Curación nativa")
			_comprobar(definicion.obtener_formula_curacion() == ficha.heal.formula, "Fórmula de curación: " + ficha.id)
			var generador := RandomNumberGenerator.new()
			generador.seed = 1234
			var referencia := RandomNumberGenerator.new()
			referencia.seed = 1234
			var motor := MotorDados.new(generador)
			for intento in 24:
				var esperado := int(ficha.heal.bonus)
				for dado in int(ficha.heal.dice):
					esperado += referencia.randi_range(1, int(ficha.heal.sides))
				_comprobar(definicion.resolver_curacion(motor) == esperado, "Tirada por uso: " + ficha.id)
		if ficha.impact.type != "none":
			var reaccion := definicion.reaccion_impacto as ReaccionImpactoSuperficie
			_comprobar(reaccion != null and reaccion.radio == int(ficha.impact.radius), "Reacción de impacto: " + ficha.id)
			if reaccion != null:
				var efecto := reaccion.escena_superficie.instantiate()
				_comprobar(efecto.get("duracion_superficie") == int(ficha.impact.duration), "Duración de suelo: " + ficha.id)
				if ficha.impact.type != "humo":
					var propiedad := "ticks_quemado" if ficha.impact.type == "fuego" else "ticks_veneno"
					_comprobar(efecto.get(propiedad) == int(ficha.impact.ticks), "Pulsos de estado: " + ficha.id)
					_comprobar(efecto.get("cantidad_dados_tick") == 2 and efecto.get("caras_dado_tick") == 6, "Dados de estado: " + ficha.id)
				efecto.free()
	print("FORJA_GODOT: %d comprobaciones, %d fallos" % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)
