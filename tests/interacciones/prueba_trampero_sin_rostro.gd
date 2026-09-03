extends SceneTree

const RUTA_ESCENA := "res://scenes/decoraciones/trampero_sin_rostro.tscn"


func _init() -> void:
	var templo := (load(
		"res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"
	) as PackedScene).instantiate()
	var decoraciones := templo.get_node("Interactuables/Decoraciones") as Node2D
	var orden_isometrico := decoraciones.y_sort_enabled
	templo.free()
	var estatua := (load(RUTA_ESCENA) as PackedScene).instantiate() as Interactuable
	var tablero := TableroGrid.new()
	for x in range(8):
		for y in range(8):
			var celda := Celda.new()
			celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
			tablero.datos[Vector2i(x, y)] = celda

	estatua.id_instancia = &"trampero_central"
	root.add_child(estatua)
	root.add_child(tablero)
	var rechaza_fuera := tablero.validar_registro_interactuable(
		Vector2i(-1, -1), estatua
	) == &"celda_invalida"
	var registrada := tablero.registrar_interactuable(Vector2i(1, 1), estatua)
	var ocupadas := estatua.obtener_coordenadas_ocupadas()
	var correcta := orden_isometrico and rechaza_fuera and registrada and ocupadas.size() == 32
	for coordenada in ocupadas:
		var celda := tablero.obtener_celda(coordenada)
		correcta = correcta and not celda.es_caminable_efectiva()
		correcta = correcta and not celda.bloquea_vision_efectiva()
		correcta = correcta and estatua in celda.interactuables
	for esquina in [Vector2i(1, 1), Vector2i(1, 6), Vector2i(6, 1), Vector2i(6, 6)]:
		var celda := tablero.obtener_celda(esquina)
		correcta = correcta and celda.es_caminable_efectiva()
		correcta = correcta and not celda.bloquea_vision_efectiva()
		correcta = correcta and estatua not in celda.interactuables

	var objetivos := SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(
		tablero, Vector2i(2, 3)
	)
	correcta = correcta and objetivos == [estatua]
	correcta = correcta and estatua.definicion.ilustracion_examen != null
	var estatua_pequena := (load(
		"res://scenes/interactuables/mecanismos/estatua_mecanismo.tscn"
	) as PackedScene).instantiate() as Interactuable
	estatua_pequena.id_instancia = &"estatua_pequena"
	root.add_child(estatua_pequena)
	correcta = correcta and tablero.registrar_interactuable(
		Vector2i(7, 7), estatua_pequena
	)
	var fov := FOVManager.new()
	fov.tablero = tablero
	fov.datos_tablero = tablero.datos
	for coordenada in ocupadas:
		tablero.obtener_celda(coordenada).visibilidad = Celda.EstadoVisibilidad.OCULTO
	tablero.obtener_celda(Vector2i(7, 7)).visibilidad = Celda.EstadoVisibilidad.OCULTO
	fov._actualizar_presentacion_interactuables()
	correcta = correcta and estatua.visible and estatua_pequena.visible
	correcta = correcta and estatua.get_node("FogOculto").visible
	correcta = correcta and estatua_pequena.get_node("FogOculto").visible
	correcta = correcta and not estatua.get_node("FogExplorado").visible
	correcta = correcta and not estatua_pequena.get_node("FogExplorado").visible
	tablero.obtener_celda(ocupadas[0]).visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	tablero.obtener_celda(Vector2i(7, 7)).visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	fov._actualizar_presentacion_interactuables()
	correcta = correcta and not estatua.get_node("FogOculto").visible
	correcta = correcta and not estatua_pequena.get_node("FogOculto").visible
	correcta = correcta and estatua.get_node("FogExplorado").visible
	correcta = correcta and estatua_pequena.get_node("FogExplorado").visible
	tablero.obtener_celda(ocupadas[0]).visibilidad = Celda.EstadoVisibilidad.VISIBLE
	tablero.obtener_celda(Vector2i(7, 7)).visibilidad = Celda.EstadoVisibilidad.VISIBLE
	fov._actualizar_presentacion_interactuables()
	correcta = correcta and not estatua.get_node("FogOculto").visible
	correcta = correcta and not estatua_pequena.get_node("FogOculto").visible
	correcta = correcta and not estatua.get_node("FogExplorado").visible
	correcta = correcta and not estatua_pequena.get_node("FogExplorado").visible

	estatua_pequena.free()
	estatua.free()
	tablero.free()
	if correcta:
		print("TramperoSinRostro: prueba correcta.")
		quit()
		return
	push_error("La estatua debe ocupar 32 celdas, bloquear el paso y ser examinable.")
	quit(1)
