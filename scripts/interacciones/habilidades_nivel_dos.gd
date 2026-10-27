extends RefCounted

var e: Node
var desplazando := false
var empuje_pendiente: PersonajeNPC
signal empuje_resuelto


func _init(escenario: Node) -> void:
	e = escenario


func objetivo(coord: Vector2i) -> PersonajeNPC:
	var celda: Celda = e.tablero.obtener_celda(coord)
	if celda != null:
		for actor in celda.interactuables:
			if actor is PersonajeNPC and actor.puede_actuar():
				return actor
	return null


func libre(coord: Vector2i, ignorados: Array = []) -> bool:
	var celda: Celda = e.tablero.obtener_celda(coord)
	if celda == null or not celda.caminable:
		return false
	for otro in celda.ocupantes + celda.reservas:
		if otro not in ignorados:
			return false
	for otro in celda.interactuables:
		if otro not in ignorados and not otro.permite_caminar_interactuable():
			return false
	return true


func linea_fisica(desde: Vector2i, hasta: Vector2i, sin_ocupantes := false) -> bool:
	var linea := GeometriaGrid.trazar_linea(desde, hasta)
	for i in range(1, linea.size()):
		var celda: Celda = e.tablero.obtener_celda(linea[i])
		if celda == null or not celda.caminable:
			return false
		for otro in celda.interactuables:
			if (not otro is PersonajeNPC or (sin_ocupantes and i < linea.size() - 1)) and not otro.permite_caminar_interactuable():
				return false
		if sin_ocupantes and i < linea.size() - 1 and (not celda.ocupantes.is_empty() or not celda.reservas.is_empty()):
			return false
		var flancos := GeometriaGrid.flancos_paso_diagonal(linea[i - 1], linea[i])
		if flancos.size() == 2 and not libre(flancos[0]) and not libre(flancos[1]):
			return false
	return true


func superficie(coord: Vector2i) -> Node2D:
	var celda: Celda = e.tablero.obtener_celda(coord)
	if celda == null:
		return null
	for efecto in celda.efectos_superficie:
		if efecto is Node2D and e.tablero.efectos_superficie_por_id.get(efecto.obtener_id_reaccion()) == efecto and efecto.has_method("obtener_familia_superficie") and efecto.obtener_familia_superficie() in [&"fuego", &"humo", &"humo_veneno"] and efecto.has_method("obtener_turnos_restantes_superficie"):
			return efecto
	return null


func validar(id: String, destino: Vector2i, fuente: Variant = null) -> StringName:
	var f: Ficha = e.ficha_jugador
	if f == null or not f.puede_actuar() or not f.conoce_habilidad(id):
		return &"habilidad_no_aprendida"
	if e.es_escenario_de_descanso or e._restaurando_partida or e.interaccion_modal_activa or e._acciones_en_resolucion > 0 or e._turno_exploracion_en_curso or e._hay_actor_moviendose() or (e.en_combate and not e._es_turno_jugador()):
		return &"habilidad_accion_en_curso"
	var opcion := CatalogoHabilidades.obtener(id)
	if opcion.get("tipo") != "Activa" or f.usos_activas.get(id, 0) < 1:
		return &"habilidad_sin_usos"
	if f.validar_coste_turno(opcion["recurso"], 1) != &"":
		return &"recursos_turno_insuficientes"
	var alcance := 5 if id in ["transposicion", "trasvase"] else (4 if id == "senuelo" else 3)
	if id in ["ariete", "agarre"]:
		alcance = 1
	var celda: Celda = e.tablero.obtener_celda(destino)
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return &"objetivo_no_visible"
	if e._distancia_cuadricula(f.coordenada_mapa, destino) > alcance or not linea_fisica(f.coordenada_mapa, destino, id == "paso_sombra"):
		return &"fuera_de_alcance_o_linea"
	var actor := objetivo(destino)
	match id:
		"ariete", "agarre":
			if actor == null or _distancia(f.coordenada_mapa, destino) != 1 or (e.en_combate and not e.gestor_rondas.son_oponentes(f, actor)):
				return &"objetivo_no_oponente"
			if id == "ariete" and not libre(destino + destino - f.coordenada_mapa):
				return &"destino_bloqueado"
		"paso_sombra":
			if f.turnos_oculto < 1 or not f.puede_moverse() or f.esta_sobrecargado() or not libre(destino) or destino == f.coordenada_mapa:
				return &"paso_sombra_destino_invalido"
		"transposicion":
			if actor == null or not libre(f.coordenada_mapa, [f, actor]) or not libre(destino, [f, actor]):
				return &"transposicion_destino_invalido"
		"senuelo":
			if not libre(destino):
				return &"destino_bloqueado"
		"trasvase":
			if fuente == null:
				return &"" if superficie(destino) != null else &"superficie_no_trasladable"
			var celda_fuente: Celda = e.tablero.obtener_celda(fuente)
			if not fuente is Vector2i or celda_fuente == null or celda_fuente.visibilidad != Celda.EstadoVisibilidad.VISIBLE or superficie(fuente) == null or e._distancia_cuadricula(f.coordenada_mapa, fuente) > 5 or not linea_fisica(f.coordenada_mapa, fuente):
				return &"superficie_no_trasladable"
			if not libre(destino, [actor] if actor != null else []) or not celda.efectos_superficie.is_empty():
				return &"destino_bloqueado"
	return &""


func ejecutar(id: String, destino: Vector2i, fuente: Variant = null) -> ResultadoAccion:
	var motivo := validar(id, destino, fuente)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if id == "trasvase" and fuente == null:
		return ResultadoAccion.crear_bloqueo(&"elige_destino_trasvase")
	var f: Ficha = e.ficha_jugador
	var actor := objetivo(destino)
	if actor != null and not e.en_combate and (id in ["ariete", "agarre"] or (id == "transposicion" and actor.obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.HOSTIL)):
		if not e._iniciar_combate(actor):
			return ResultadoAccion.crear_bloqueo(&"npc_no_combatiente")
	var opcion := CatalogoHabilidades.obtener(id)
	if not f.consumir_recurso_turno(opcion["recurso"], 1):
		return ResultadoAccion.crear_bloqueo(&"recursos_turno_insuficientes")
	f.usos_activas[id] = 0
	e._acciones_en_resolucion += 1
	match id:
		"ariete":
			f.romper_ocultamiento()
			await empujar(actor, 2)
		"agarre":
			f.romper_ocultamiento()
			f.agarre_objetivo = String(actor.id_instancia)
			f.agarre_pasos = 2
		"paso_sombra":
			mover_forzado(f, destino)
		"transposicion":
			_intercambiar(actor)
		"senuelo":
			for npc in e.tablero.interactuables_por_id.values():
				if npc is PersonajeNPC and npc.puede_actuar() and not ve_oponente(npc) and oye(npc.coordenada_mapa, destino):
					f.senuelos[String(npc.id_instancia)] = [destino.x, destino.y]
		"trasvase":
			var efecto := superficie(fuente)
			e.tablero.retirar_efecto_superficie(efecto)
			e.tablero.registrar_efecto_superficie(destino, efecto)
			efecto.global_position = e.tablero.capa_referencia.to_global(e.tablero.capa_referencia.map_to_local(destino))
			if actor != null and efecto.has_method("reacciona_automaticamente") and efecto.reacciona_automaticamente(TiposInteraccion.TipoAccion.ENTRAR):
				# Reacciona solo la superficie trasladada; el NPC no vuelve a pisar terreno ni trampas.
				var reacciones: Array[ReaccionCelda] = [ReaccionCelda.new(TiposInteraccion.CategoriaReaccion.EFECTO_SUPERFICIE, efecto.obtener_prioridad_reaccion(TiposInteraccion.TipoAccion.ENTRAR), efecto.obtener_id_reaccion(), efecto)]
				var resultado: ResultadoReacciones = e.resolver_reacciones.resolver(TiposInteraccion.TipoAccion.ENTRAR, actor, destino, destino, reacciones)
				for accion in resultado.resultados:
					if accion.tirada != null:
						e.historial_tiradas.registrar(accion.tirada)
				e._registrar_reaccion_narrativa(TiposInteraccion.TipoAccion.ENTRAR, reacciones, resultado, actor)
	e._acciones_en_resolucion -= 1
	f.usos_habilidades_cambiados.emit()
	e.hud.actualizar_desde_ficha()
	registrar(opcion["nombre"], opcion["descripcion"])
	return ResultadoAccion.crear_exito()


func mover_forzado(actor: Node2D, destino: Vector2i) -> bool:
	if not actor.puede_actuar() or actor.esta_moviendose or not e.tablero.reservar_celda(destino, actor):
		return false
	var origen: Vector2i = actor.coordenada_mapa
	desplazando = true
	e._procesar_salida_paso_actor(origen, destino, actor)
	if not actor.puede_actuar() or not e.tablero.confirmar_movimiento(origen, destino, actor):
		e.tablero.cancelar_reserva(destino, actor)
		desplazando = false
		return false
	actor.coordenada_mapa = destino
	actor.global_position = e.tablero.capa_referencia.to_global(e.tablero.capa_referencia.map_to_local(destino))
	e._procesar_entrada_paso_actor(origen, destino, actor)
	desplazando = false
	if actor == e.ficha_jugador:
		e._on_ficha_paso_dado(destino)
	limpiar_agarre()
	return true


func empujar(actor: PersonajeNPC, pasos: int) -> void:
	var f: Ficha = e.ficha_jugador
	var direccion: Vector2i = actor.coordenada_mapa - f.coordenada_mapa
	if _distancia(actor.coordenada_mapa, f.coordenada_mapa) != 1:
		return
	for i in pasos:
		if not f.puede_actuar() or not actor.puede_actuar() or not await _paso_empuje(actor, actor.coordenada_mapa + direccion):
			break
		var reaccion: ResultadoReacciones = e.ultimo_resultado_entrar
		if (reaccion != null and (reaccion.interrumpe_movimiento or &"trampa.superficie_activada" in reaccion.mensajes or &"trampa.mecanismo_activado" in reaccion.mensajes)) or actor.obtener_estado(&"enredado") != null or actor.obtener_estado(&"caido") != null:
			break


func _paso_empuje(actor: PersonajeNPC, destino: Vector2i) -> bool:
	if not libre(destino) or actor.esta_moviendose or not e.tablero.reservar_celda(destino, actor):
		return false
	var origen := actor.coordenada_mapa
	desplazando = true
	actor.movimiento.esta_moviendose = true
	e._procesar_salida_paso_actor(origen, destino, actor)
	if actor.puede_actuar():
		var tween := actor.create_tween()
		tween.tween_property(actor, "global_position", e.tablero.capa_referencia.to_global(e.tablero.capa_referencia.map_to_local(destino)), 0.2)
		await tween.finished
	actor.movimiento.esta_moviendose = false
	if not actor.puede_actuar() or not e.tablero.confirmar_movimiento(origen, destino, actor):
		e.tablero.cancelar_reserva(destino, actor)
		actor.actualizar_posicion_visual()
		desplazando = false
		return false
	actor.coordenada_mapa = destino
	e._procesar_entrada_paso_actor(origen, destino, actor)
	desplazando = false
	limpiar_agarre()
	return true


func resolver_empuje(aceptar: bool) -> void:
	var actor := empuje_pendiente
	if not is_instance_valid(actor):
		return
	var f: Ficha = e.ficha_jugador
	if aceptar and actor.puede_actuar() and f.puede_actuar() and "golpe_desplazante" not in f.pasivas_usadas_turno and _distancia(f.coordenada_mapa, actor.coordenada_mapa) == 1 and libre(actor.coordenada_mapa * 2 - f.coordenada_mapa):
		f.pasivas_usadas_turno.append("golpe_desplazante")
		e._acciones_en_resolucion += 1
		await empujar(actor, 1)
		e._acciones_en_resolucion -= 1
		registrar("Golpe desplazante", "Tras acertar, eliges empujar al objetivo una casilla.")
	empuje_pendiente = null
	f.usos_habilidades_cambiados.emit()
	e._actualizar_estado_modal_interaccion()
	empuje_resuelto.emit()


func _intercambiar(actor: PersonajeNPC) -> void:
	var f: Ficha = e.ficha_jugador
	var origen := f.coordenada_mapa
	var destino := actor.coordenada_mapa
	desplazando = true
	e._procesar_salida_paso_actor(origen, destino, f)
	e._procesar_salida_paso_actor(destino, origen, actor)
	if not f.puede_actuar() or not actor.puede_actuar():
		desplazando = false
		return
	e.tablero.liberar_celda(origen, f)
	e.tablero.reubicar_interactuable(actor, origen)
	f.inicializar(destino, e.tablero.capa_referencia)
	e.tablero.ocupar_celda(destino, f)
	actor.global_position = e.tablero.capa_referencia.to_global(e.tablero.capa_referencia.map_to_local(origen))
	e._procesar_entrada_paso_actor(origen, destino, f)
	e._procesar_entrada_paso_actor(destino, origen, actor)
	desplazando = false
	e._on_ficha_paso_dado(destino)
	limpiar_agarre()


func al_paso(origen: Vector2i, _destino: Vector2i, actor: Node2D) -> void:
	var f: Ficha = e.ficha_jugador
	if desplazando:
		return
	if actor != f:
		limpiar_agarre()
		return
	if f.agarre_objetivo.is_empty():
		return
	var agarrado = e.tablero.obtener_interactuable(StringName(f.agarre_objetivo))
	if not f.puede_actuar() or not agarrado is PersonajeNPC or not agarrado.puede_actuar() or _distancia(agarrado.coordenada_mapa, origen) != 1 or not mover_forzado(agarrado, origen):
		f.romper_agarre()
		return
	f.agarre_pasos -= 1
	if f.agarre_pasos <= 0 or not agarrado.puede_actuar() or (e.ultimo_resultado_entrar != null and e.ultimo_resultado_entrar.interrumpe_movimiento):
		f.romper_agarre()
		f.solicitar_interrupcion()


func limpiar_agarre() -> void:
	var f: Ficha = e.ficha_jugador
	if f == null or f.agarre_objetivo.is_empty():
		return
	var agarrado = e.tablero.obtener_interactuable(StringName(f.agarre_objetivo))
	if not f.puede_actuar() or not agarrado is PersonajeNPC or not agarrado.puede_actuar() or _distancia(f.coordenada_mapa, agarrado.coordenada_mapa) != 1:
		f.romper_agarre()


func al_golpe(blanco: Object) -> void:
	var f: Ficha = e.ficha_jugador
	if not blanco is PersonajeNPC or not blanco.puede_actuar():
		return
	if empuje_pendiente == null and f.conoce_habilidad("golpe_desplazante") and "golpe_desplazante" not in f.pasivas_usadas_turno and _distancia(f.coordenada_mapa, blanco.coordenada_mapa) == 1 and libre(blanco.coordenada_mapa * 2 - f.coordenada_mapa):
		empuje_pendiente = blanco
		e._actualizar_estado_modal_interaccion()
	if f.conoce_habilidad("contagio_arcano") and f.contagio_elegido != "" and "contagio_arcano" not in f.pasivas_usadas_turno:
		var estado := f.obtener_estado(StringName(f.contagio_elegido))
		if estado != null:
			var anterior = blanco.obtener_estado(estado.clave)
			if anterior == null or anterior.ticks_pendientes < estado.ticks_pendientes:
				blanco.retirar_estado(estado.clave)
				blanco.aplicar_o_renovar_estado(estado.clave, estado.magnitud, estado.duracion_total, estado.ticks_pendientes, f, estado.terminos_dano_tick)
			f.retirar_estado(estado.clave)
			f.pasivas_usadas_turno.append("contagio_arcano")
			registrar("Contagio arcano", "Transfieres %s y conservas sus ticks pendientes." % f.contagio_elegido)
	f.usos_habilidades_cambiados.emit()


func al_derrotar(fuente: Object, _blanco: PersonajeNPC) -> void:
	var f: Ficha = e.ficha_jugador
	limpiar_agarre()
	if fuente != f or not f.puede_actuar() or not f.conoce_habilidad("inercia") or "inercia" in f.pasivas_usadas_turno:
		return
	f.pasivas_usadas_turno.append("inercia")
	f.pasos_inercia = 2
	registrar("Inercia", "Dispones de dos pasos sin gastar movimiento. Conservan energía y peligros.")


func al_terminar_movimiento() -> void:
	var f: Ficha = e.ficha_jugador
	if not e.en_combate or not e._es_turno_jugador() or f.movimiento.pasos_completados < 1 or not f.puede_actuar() or not f.conoce_habilidad("escapista") or "escapista" in f.pasivas_usadas_turno:
		return
	for otro in e._actores_combate():
		if otro is PersonajeNPC and e.gestor_rondas.son_oponentes(f, otro) and otro.puede_ver_coordenada(f.coordenada_mapa, e.validador_espacial):
			return
	f.pasivas_usadas_turno.append("escapista")
	f.turnos_oculto = maxi(f.turnos_oculto, 1)
	f.usos_habilidades_cambiados.emit()
	registrar("Escapista", "Has salido de la visión enemiga y te ocultas.")
	e._resolver_perdida_agro()


func ve_oponente(npc: PersonajeNPC) -> bool:
	if e.en_combate:
		for otro in e._actores_combate():
			if e.gestor_rondas.son_oponentes(npc, otro) and npc.puede_ver_actor(otro, e.validador_espacial):
				return true
		return false
	return npc.puede_detectar_jugador(e.ficha_jugador, e.validador_espacial)


func oye(origen: Vector2i, destino: Vector2i) -> bool:
	var pendientes: Array[Vector2i] = [origen]
	var distancias := {origen: 0}
	var indice := 0
	while indice < pendientes.size():
		var celda := pendientes[indice]
		indice += 1
		if celda == destino:
			return true
		if distancias[celda] >= 4:
			continue
		for dir: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
			var siguiente := celda + dir
			if not distancias.has(siguiente) and linea_fisica(celda, siguiente):
				distancias[siguiente] = distancias[celda] + 1
				pendientes.append(siguiente)
	return false


func plan_senuelo(npc: PersonajeNPC) -> Dictionary:
	var f: Ficha = e.ficha_jugador
	var id := String(npc.id_instancia)
	if not f.senuelos.has(id):
		return {}
	if npc.obtener_estado(&"enredado") != null or npc.obtener_estado(&"caido") != null:
		return {}
	if ve_oponente(npc):
		f.senuelos.erase(id)
		return {}
	var coord: Array = f.senuelos[id]
	var destino := Vector2i(coord[0], coord[1])
	var ruta: Array[Vector2i] = e.pathfinding.calcular_camino(npc.coordenada_mapa, destino, e.tablero.datos, npc)
	var camino: Array[Vector2i] = e.pathfinding.limitar_camino_por_movimiento(ruta, e.tablero.datos, npc, npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO))
	return {"decision": &"acercarse" if e.en_combate and camino.size() > 1 else (&"buscar" if camino.size() > 1 else &"terminar_turno"), "objetivo": null, "destino": destino, "camino": camino, "objetivo_visible": false}


func lanzar_al_suelo(destino: Vector2i) -> ResultadoAccion:
	var f: Ficha = e.ficha_jugador
	var celda: Celda = e.tablero.obtener_celda(destino)
	if not f.conoce_habilidad("piromancia_libre") or not f.puede_actuar() or f.usos_bola_fuego < 1 or celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE or not libre(destino) or not celda.efectos_superficie.is_empty() or e._distancia_cuadricula(f.coordenada_mapa, destino) > 4 or not linea_fisica(f.coordenada_mapa, destino):
		return ResultadoAccion.crear_bloqueo(&"piromancia_destino_invalido")
	if e.es_escenario_de_descanso or e._restaurando_partida or e.interaccion_modal_activa or e._turno_exploracion_en_curso or e._hay_actor_moviendose() or (e.en_combate and not e._es_turno_jugador()) or f.validar_coste_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1) != &"":
		return ResultadoAccion.crear_bloqueo(&"habilidad_accion_en_curso")
	if not encender_celda(destino):
		return ResultadoAccion.crear_bloqueo(&"superficie_no_configurada")
	f.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	f.consumir_bola_fuego()
	if e != null and e.has_method("reproducir_sonido_magia_fuego"):
		e.reproducir_sonido_magia_fuego()
	f.romper_ocultamiento()
	registrar("Piromancia libre", "Enciendes una casilla durante tres turnos.")
	return ResultadoAccion.crear_exito()


func encender_celda(destino: Vector2i) -> bool:
	var celda: Celda = e.tablero.obtener_celda(destino)
	if celda == null:
		return false
	for efecto in celda.efectos_superficie:
		if efecto.has_method("obtener_familia_superficie") and efecto.obtener_familia_superficie() == &"fuego":
			efecto.restaurar_turnos_restantes_superficie(3)
			return true
	var celdas: Array[Vector2i] = e.tablero.desplegar_efecto_superficie(preload("res://scenes/efectos_superficie/Fuego.tscn"), destino, 0, StringName("bola_fuego_%d" % Time.get_ticks_usec()))
	if celdas.is_empty():
		return false
	for efecto in celda.efectos_superficie:
		if efecto.has_method("obtener_familia_superficie") and efecto.obtener_familia_superficie() == &"fuego":
			efecto.restaurar_turnos_restantes_superficie(3)
	return true


func registrar(titulo: String, texto: String) -> void:
	e.registro_narrativo.registrar(EntradaRegistroNarrativo.Categoria.SISTEMA, titulo, texto)


func _distancia(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
