extends SceneTree

var fallos: Array[String] = []
var texturas: Array[Texture2D] = []


func _init() -> void:
	call_deferred(&"_probar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)
		push_error(mensaje)


func _probar() -> void:
	for id in ["amuleto_klink", "ganzua_mecanica"]:
		for formato in [["icono", Vector2i(24, 24)], ["suelo", Vector2i(64, 32)], ["ilustracion", Vector2i(100, 100)]]:
			var ruta := "res://assets/items/%s/%s.png" % [id, formato[0]]
			var imagen := Image.load_from_file(ruta)
			comprobar(imagen != null and imagen.get_size() == formato[1] and not imagen.is_invisible(), "Visual válido: " + ruta)
			var textura := ImageTexture.create_from_image(imagen)
			textura.take_over_path(ruta)
			texturas.append(textura)
	var amuleto := load("res://assets/items/amuleto_klink/amuleto_klink.tres") as DefinicionItem
	var ganzua := load("res://assets/items/ganzua_mecanica/ganzua_mecanica.tres") as DefinicionLlave
	comprobar(amuleto.es_valida() and ganzua.es_valida(), "Ambas definiciones deben ser válidas.")
	var ficha := Ficha.new()
	var item := ItemInstancia.new(&"amuleto_test", amuleto)
	ficha.inventario.agregar(item)
	comprobar(EfectosEquipo.fuentes(ficha, "destreza", "", "ventaja").is_empty(), "Llevar el amuleto en mochila no debe conceder ventaja.")
	var destreza := ficha.obtener_destreza()
	comprobar(ficha.equipo.equipar(ficha.inventario, item.id_instancia, 1) == &"", "Debe equiparse en el cuello.")
	comprobar(EfectosEquipo.fuentes(ficha, "destreza", "esquiva", "ventaja").size() == 1 and ficha.obtener_destreza() == destreza, "El amuleto da ventaja en DES sin aumentar el atributo.")
	comprobar(EfectosEquipo.fuentes(ficha, "fuerza", "", "ventaja").is_empty(), "No debe beneficiar a FUE.")
	var equipo_guardado := ficha.equipo.obtener_estado_persistente()
	comprobar(ficha.equipo.restaurar_estado_persistente(equipo_guardado) == &"" and not EfectosEquipo.fuentes(ficha, "destreza", "", "ventaja").is_empty(), "El efecto persiste al cargar el equipo.")
	comprobar(ficha.equipo.desequipar(ficha.inventario, 1) == &"" and EfectosEquipo.fuentes(ficha, "destreza", "", "ventaja").is_empty(), "Desequipar retira la ventaja.")
	var prision := (load("res://scenes/Prision/prision.tscn") as PackedScene).instantiate()
	var puerta := prision.get_node("Interactuables/Puertas/PuertaInteractuable") as PuertaInteractuable
	comprobar(puerta.id_instancia == &"interactuable_001", "La prueba debe usar la puerta de Roffa.")
	puerta.get_parent().remove_child(puerta)
	puerta.definicion = puerta.definicion.duplicate()
	prision.free()
	root.add_child(puerta)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.datos[Vector2i.RIGHT] = Celda.new()
	tablero.registrar_interactuable(Vector2i.RIGHT, puerta)
	var herramienta := ItemInstancia.new(&"ganzua_test", ganzua)
	ficha.inventario.agregar(herramienta)
	var opcion: OpcionAccion
	for candidata in puerta.obtener_opciones_accion(ficha):
		if candidata.id == &"usar_item":
			opcion = candidata
	var contexto := ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, Vector2i.ZERO, Vector2i.RIGHT, herramienta) as ContextoAccion
	var gestor := GestorAcciones.new()
	(puerta.definicion as DefinicionPuerta).patron_cerradura = &"otra_cerradura"
	var fallo := gestor.procesar_accion(contexto)
	comprobar(not fallo.exitosa and puerta.bloqueada and ficha.inventario.obtener_por_id(herramienta.id_instancia) == herramienta, "Una cerradura incompatible conserva la ganzúa y la puerta bloqueada.")
	(puerta.definicion as DefinicionPuerta).patron_cerradura = &"reja_metal"
	var exito := gestor.procesar_accion(contexto)
	comprobar(exito.exitosa and not puerta.bloqueada and not puerta.abierta and ficha.inventario.obtener_por_id(herramienta.id_instancia) == null, "La ganzúa desbloquea la reja y se consume una sola vez.")
	comprobar(not gestor.procesar_accion(contexto).exitosa, "No puede reutilizarse la ganzúa consumida.")
	for candidata in puerta.obtener_opciones_accion(ficha):
		if candidata.id == &"abrir":
			opcion = candidata
	contexto = ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, Vector2i.ZERO, Vector2i.RIGHT) as ContextoAccion
	comprobar(gestor.procesar_accion(contexto).exitosa and puerta.abierta and puerta.permite_caminar_interactuable(), "La puerta de Roffa desbloqueada se abre y permite el paso.")
	var zona := (load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn") as PackedScene).instantiate()
	var cofre := zona.get_node("Interactuables/Cofres/CofreInteractuable5") as CofreInteractuable
	comprobar(cofre._cargar_contenido_inicial() == &"" and cofre.inventario.obtener_contenido().size() == 2, "El cofre 006 contiene los dos objetos nuevos.")
	zona.free()
	gestor.free()
	ficha.free()
	puerta.free()
	tablero.free()
	print("ItemsTemplo: %d fallos." % fallos.size())
	quit(0 if fallos.is_empty() else 1)
