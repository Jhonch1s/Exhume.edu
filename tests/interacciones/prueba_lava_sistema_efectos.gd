extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	var coordenada_lava := Vector2i.ZERO
	var encontro_lava := false
	for coordenada in tablero.datos:
		if tablero.datos[coordenada].zona == &"lava":
			coordenada_lava = coordenada
			encontro_lava = true
			break
	_comprobar(encontro_lava, "Zona1 debe contener lava.")

	if encontro_lava:
		var celda := tablero.obtener_celda(coordenada_lava)
		var ficha := Ficha.new()
		root.add_child(ficha)
		var reacciones := ConsultorReaccionesCelda.new().obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
		)
		_comprobar(reacciones.size() == 1, "La lava debe publicar una reacción de terreno.")
		var gestor := GestorAcciones.new()
		root.add_child(gestor)
		var vida_inicial := ficha.pv_actual
		var resultado := ResolverReaccionesCelda.new(gestor).resolver(
			TiposInteraccion.TipoAccion.ENTRAR,
			ficha,
			coordenada_lava + Vector2i.LEFT,
			coordenada_lava,
			reacciones
		)
		_comprobar(ficha.pv_actual == vida_inicial - 2, "La lava debe aplicar dos puntos de daño.")
		_comprobar(
			resultado.efectos_aplicados.size() == 1
				and resultado.efectos_aplicados[0].clave == &"lava",
			"El daño de lava debe quedar confirmado por el aplicador común."
		)
		gestor.queue_free()
		ficha.queue_free()

	_probar_pinchos(tablero)
	_probar_telarana(tablero)
	_probar_lodo(tablero)
	_probar_hielo(tablero)
	_probar_fuego_estatico(tablero)

	tablero.queue_free()
	zona.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("LavaSistemaEfectos: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_pinchos(tablero: TableroGrid) -> void:
	var coordenada := Vector2i(6, 8)
	var celda := tablero.obtener_celda(coordenada)
	_comprobar(
		celda != null and celda.reaccion_terreno is TerrenoDanino,
		"La capa de pinchos debe registrar una reacción de terreno."
	)
	if celda == null or not celda.reaccion_terreno is TerrenoDanino:
		return
	var ficha := Ficha.new()
	root.add_child(ficha)
	var vida_inicial := ficha.pv_actual
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var resultado := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		ficha,
		coordenada + Vector2i.LEFT,
		coordenada,
		ConsultorReaccionesCelda.new().obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
		)
	)
	var accion := resultado.resultados[0] if not resultado.resultados.is_empty() else null
	var dano := vida_inicial - ficha.pv_actual
	_comprobar(dano >= 1 and dano <= 3, "Los pinchos deben causar exactamente 1d3 al entrar.")
	_comprobar(
		accion != null
		and accion.tirada is ResultadoTirada
		and accion.tirada.origen == TiposTirada.Origen.AUTOMATICA
		and accion.tirada.presentacion == TiposTirada.Presentacion.SOLO_LOG
		and resultado.efectos_aplicados.size() == 1
		and resultado.efectos_aplicados[0].clave == &"pinchos",
		"El daño de pinchos debe conservar su tirada y usar el aplicador común."
	)
	_comprobar(ficha.obtener_claves_estado().is_empty(), "Los pinchos no deben dejar estados.")
	gestor.queue_free()
	ficha.queue_free()


func _probar_telarana(tablero: TableroGrid) -> void:
	var coordenada := Vector2i(6, 11)
	var celda := tablero.obtener_celda(coordenada)
	var telarana: Telarana = null
	if celda != null and not celda.efectos_superficie.is_empty():
		telarana = celda.efectos_superficie[0] as Telarana
	_comprobar(telarana != null, "La capa de telaraña debe registrar su superficie.")
	if telarana == null:
		return
	_comprobar(celda.calcular_coste_movimiento() == 2, "La telaraña debe ralentizar como el humo.")
	var ficha := Ficha.new()
	root.add_child(ficha)
	telarana.motor_dados = _motor_para_prueba(ficha.obtener_destreza(), false)
	var gestor := GestorAcciones.new()
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	root.add_child(gestor)
	var entrada := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR, ficha, coordenada + Vector2i.LEFT, coordenada,
		ConsultorReaccionesCelda.new().obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
		)
	)
	_comprobar(
		entrada.interrumpe_movimiento
		and ficha.obtener_estado(&"enredado") != null
		and not ficha.puede_moverse(),
		"Fallar DES debe interrumpir y bloquear el movimiento."
	)
	var accion := AccionDestrabarse.new()
	accion.motor_dados = _motor_para_prueba(ficha.obtener_destreza(), false)
	var fallo := gestor.procesar_accion(accion.construir_contexto(ficha))
	_comprobar(
		fallo.exitosa
		and ficha.obtener_estado(&"enredado") != null
		and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0,
		"Fallar al destrabarse debe conservar el estado y gastar la acción."
	)
	ficha.iniciar_turno()
	accion.motor_dados = _motor_para_prueba(ficha.obtener_destreza(), true)
	var exito := gestor.procesar_accion(accion.construir_contexto(ficha))
	_comprobar(
		exito.exitosa
		and exito.tirada.presentacion == TiposTirada.Presentacion.PRIMER_PLANO
		and ficha.obtener_estado(&"enredado") == null
		and ficha.puede_moverse(),
		"Superar la acción debe retirar enredado y habilitar movimiento."
	)
	gestor.queue_free()
	ficha.queue_free()


func _motor_para_prueba(atributo: int, exito: bool) -> MotorDados:
	for semilla in 1000:
		var generador := RandomNumberGenerator.new()
		generador.seed = semilla
		var motor := MotorDados.new(generador)
		if motor.resolver_prueba(atributo).exitosa == exito:
			generador.seed = semilla
			return MotorDados.new(generador)
	return MotorDados.new()


func _probar_lodo(tablero: TableroGrid) -> void:
	var coordenada := Vector2i(6, 10)
	var celda := tablero.obtener_celda(coordenada)
	var lodo: Lodo = null
	if celda != null:
		for efecto in celda.efectos_superficie:
			if efecto is Lodo:
				lodo = efecto
				break
	_comprobar(lodo != null, "La capa de lodo debe registrar su superficie.")
	if lodo == null:
		return
	_comprobar(celda.calcular_coste_movimiento() == 1, "El lodo no debe añadir lentitud.")
	var ficha := Ficha.new()
	root.add_child(ficha)
	lodo.motor_dados = _motor_para_prueba(ficha.obtener_destreza(), false)
	var gestor := GestorAcciones.new()
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	root.add_child(gestor)
	var entrada := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR, ficha, coordenada + Vector2i.LEFT, coordenada,
		ConsultorReaccionesCelda.new().obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
		)
	)
	_comprobar(
		entrada.interrumpe_movimiento
		and ficha.obtener_estado(&"caido") != null
		and ficha.obtener_estado(&"caido").ticks_pendientes == 1,
		"Fallar DES en lodo debe interrumpir y aplicar caído por ese turno."
	)
	ficha.agotar_recursos_turno()
	for clave in RecursosTurnoActor.CLAVES:
		_comprobar(ficha.obtener_recurso_turno(clave) == 0, "Caer debe agotar todos los recursos del turno.")
	var fin_turno := ServicioTurnos.new(gestor).avanzar_turno(ficha)
	_comprobar(
		fin_turno.exitosa and ficha.obtener_estado(&"caido") == null,
		"Caído debe retirarse al cerrar el turno."
	)
	ficha.iniciar_turno()
	_comprobar(
		ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1,
		"El nuevo turno debe comenzar con la ficha levantada y sus recursos repuestos."
	)
	gestor.queue_free()
	ficha.queue_free()


func _probar_hielo(tablero: TableroGrid) -> void:
	var celda := tablero.obtener_celda(Vector2i(6, 9))
	var hielo: Lodo = null
	if celda != null:
		for efecto in celda.efectos_superficie:
			if efecto is Lodo and efecto.obtener_familia_superficie() == &"hielo":
				hielo = efecto
				break
	_comprobar(
		hielo != null and celda.calcular_coste_movimiento() == 1,
		"CapaHielo debe reutilizar la superficie resbaladiza sin añadir lentitud."
	)


func _probar_fuego_estatico(tablero: TableroGrid) -> void:
	var coordenada := Vector2i(6, 7)
	var celda := tablero.obtener_celda(coordenada)
	var fuego: Fuego = null
	if celda != null:
		for efecto in celda.efectos_superficie:
			if efecto is Fuego:
				fuego = efecto
				break
	_comprobar(
		fuego != null
		and fuego in celda.iluminacion
		and fuego.obtener_radio_luz() == 2
		and celda.calcular_coste_movimiento() == 2,
		"CapaFuego debe registrar una superficie luminosa con coste adicional."
	)
	if fuego == null:
		return
	var ficha := Ficha.new()
	root.add_child(ficha)
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR, ficha, coordenada + Vector2i.LEFT, coordenada,
		ConsultorReaccionesCelda.new().obtener_reacciones(
			celda, TiposInteraccion.TipoAccion.ENTRAR, ficha
		)
	)
	var quemado := ficha.obtener_estado(&"quemado")
	_comprobar(
		quemado != null
		and quemado.ticks_pendientes == 3
		and quemado.terminos_dano_tick == [{
			&"cantidad": 1, &"caras": 2, &"signo": 1,
		}],
		"Entrar al fuego estático debe aplicar tres ticks de 1d2 sin salvación."
	)
	gestor.queue_free()
	ficha.queue_free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
