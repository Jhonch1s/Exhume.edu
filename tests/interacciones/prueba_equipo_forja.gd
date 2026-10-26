extends SceneTree

var casos := 0
var fallos: Array[String] = []
var texturas: Array[Texture2D] = []
var escena: Node


func _initialize() -> void:
	call_deferred(&"_probar")


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
		push_error(mensaje)


func definicion(id: String) -> DefinicionItem:
	var carpeta := "res://.godot/forja_export_test/assets/items/forja/%s/" % id
	for nombre in ["icono.png", "suelo.png"]:
		var ruta: String = carpeta + nombre
		var textura := ImageTexture.create_from_image(Image.load_from_file(ruta))
		textura.take_over_path(ruta)
		texturas.append(textura)
	return load(carpeta + id + ".tres") as DefinicionItem


func motor(resultados: Array) -> MotorDados:
	var rng := RandomNumberGenerator.new()
	for semilla in 20000:
		rng.seed = semilla
		var coincide := true
		for valor: int in resultados:
			if rng.randi_range(1, 6) != valor:
				coincide = false
				break
		if coincide:
			rng.seed = semilla
			return MotorDados.new(rng)
	push_error("No se encontró semilla para %s" % str(resultados))
	return MotorDados.new()


func _probar() -> void:
	escena = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	var e: Node = escena.get_node("Escenario")
	e.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(escena)
	for intento in 200:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 5:
			break
	escena.set_process(false)
	e.set_process(false)
	var f: Ficha = e.ficha_jugador
	var npc: PersonajeNPC = escena.get("_enemigos")[0]
	var espada_inicial: ItemInstancia = f.equipo.ranuras.get(3)
	comprobar(espada_inicial != null and espada_inicial.definicion.id_definicion == &"espada_inicial", "El Guerrero comienza con la espada exportada equipada.")
	comprobar(CasillaInventario.texto_tooltip_item(espada_inicial).contains("Solo: Guerrero"), "El inventario explica la restricción de clase.")
	comprobar(EquipoActor.new().validar_estado_persistente(f.equipo.obtener_estado_persistente(), [], "Ladrón") == &"equipo_guardado_incompatible", "Un guardado no puede equipar armas de otra clase.")
	comprobar(EfectosEquipo.terminos_dano_armas(f)[0].caras == 3, "La espada inicial aporta 1d3 al combate.")
	var sprite_espada := espada_inicial.definicion.escena_mundo.instantiate() as RepresentacionItemSuelo
	comprobar(sprite_espada.get_node("Sprite2D").position == Vector2.ZERO, "El sprite 64×32 de la espada queda centrado en la celda.")
	sprite_espada.free()
	var tooltip_espada := CasillaInventario.crear_cuadro_tooltip_item(espada_inicial)
	var ilustraciones := tooltip_espada.find_children("*", "TextureRect", true, false)
	comprobar(not ilustraciones.is_empty() and (ilustraciones[0] as TextureRect).texture == espada_inicial.definicion.ilustracion_examen, "El hover de inventario muestra la ilustración de la espada.")
	tooltip_espada.free()
	f.equipo.desequipar(f.inventario, 3)
	f.clase = "Ladrón"
	comprobar(f.equipo.equipar(f.inventario, espada_inicial.id_instancia, 3) == &"equipo_incompatible", "El Ladrón no puede equipar la espada exclusiva del Guerrero.")
	f.clase = "Guerrero"
	f.inventario.retirar(espada_inicial.id_instancia)
	var espada := ItemInstancia.new(&"espada_web", definicion("espada_forja"))
	var anillo := ItemInstancia.new(&"anillo_web", definicion("anillo_forja"))
	comprobar(espada.es_valida() and anillo.es_valida(), "Recursos exportados válidos con efectos.")
	var fuerza_base := f.fue
	var des_base := f.des
	var vol_base := f.vol
	var peso_antes := f.obtener_peso_actual()
	var snapshot_anterior := JSON.parse_string(JSON.stringify(f.obtener_estado_persistente())) as Dictionary
	snapshot_anterior.erase("equipo")
	f.inventario.agregar(espada)
	f.inventario.agregar(anillo)
	var peso_total := f.obtener_peso_actual()
	comprobar(f.obtener_fuerza() == fuerza_base and EfectosEquipo.bono_dano(f, true) == 0, "La mochila no activa los efectos.")
	comprobar(f.equipo.equipar(f.inventario, espada.id_instancia, 7) == &"equipo_incompatible", "No equipar arma en anillo.")
	comprobar(f.inventario.obtener_por_id(espada.id_instancia) == espada, "Un equipamiento inválido conserva el objeto.")
	f.consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, 2)
	var pasos := f.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO)
	comprobar(f.equipo.equipar(f.inventario, espada.id_instancia, 3) == &"", "Equipar espada exportada.")
	comprobar(f.equipo.equipar(f.inventario, anillo.id_instancia, 7) == &"", "Equipar anillo exportado.")
	comprobar(f.obtener_fuerza() == fuerza_base + 1 and f.obtener_voluntad() == vol_base + 1 and f.obtener_destreza() == des_base - 1, "Bonos y contrapartida efectivos.")
	comprobar(f.fue == fuerza_base and f.des == des_base and f.vol == vol_base, "Los atributos base no se modifican.")
	comprobar(is_equal_approx(f.obtener_peso_actual(), peso_total) and peso_total > peso_antes, "El equipo sigue contando para la carga.")
	comprobar(f.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) <= pasos, "Equipar no repone movimiento.")
	comprobar(EfectosEquipo.bono_dano(f, true) == 3 and EfectosEquipo.bono_dano(f, false) == 1, "Separar arma y daño directo global.")
	var prueba := EfectosEquipo.resolver_prueba(motor([6, 1]), f, "fuerza", TiposTirada.Origen.SOLICITADA, TiposTirada.Presentacion.SOLO_LOG, "ataque")
	comprobar(prueba.valida and prueba.exitosa and prueba.dados.size() == 2 and prueba.modificadores.size() == 1, "Ventaja y modificadores llegan al motor sin invalidar atributos mayores a cinco.")
	var pifia := EfectosEquipo.resolver_prueba(motor([6, 6]), f, "fuerza", TiposTirada.Origen.SOLICITADA, TiposTirada.Presentacion.SOLO_LOG, "ataque")
	comprobar(not pifia.exitosa, "Dos seises siguen siendo pifia con equipo.")
	anillo.definicion.efectos_equipo.append({"tipo": "tirada", "prueba": "ataque", "modo": "desventaja"})
	var neutralizada := EfectosEquipo.resolver_prueba(motor([3]), f, "fuerza", TiposTirada.Origen.SOLICITADA, TiposTirada.Presentacion.SOLO_LOG, "ataque")
	comprobar(neutralizada.dados.size() == 1, "Fuentes opuestas de ventaja y desventaja se compensan.")
	anillo.definicion.efectos_equipo.pop_back()
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, f, null, null, npc, null, &"ataque_basico")
	var aplicador := AplicadorEfectos.new()
	var vida := npc.vida_actual
	var fallo := ResolverAtaqueBasico.resolver(contexto, npc, motor([6, 6]), aplicador)
	comprobar(fallo.exitosa and npc.vida_actual == vida and npc.obtener_estado(&"veneno") == null, "Un fallo no causa daño ni debuffs.")
	var esquiva := ResolverAtaqueBasico.resolver(contexto, npc, motor([1, 1, 1]), aplicador)
	comprobar(esquiva.exitosa and npc.vida_actual == vida and npc.obtener_estado(&"debilitado_fuerza") == null, "Esquivar evita también efectos de equipo.")
	var acierto := ResolverAtaqueBasico.resolver(contexto, npc, motor([1, 1, 6]), aplicador)
	var dado_espada: ResultadoTirada = acierto.tirada_dano
	comprobar(dado_espada != null and dado_espada.terminos.size() == 1 and dado_espada.terminos[0].caras == 3, "La espada exportada tira 1d3 después de acertar.")
	comprobar(acierto.exitosa and vida - npc.vida_actual == dado_espada.total_efectivo + EfectosEquipo.bono_fuerza_dano(f) + 3, "El daño suma dado de espada, FUE efectiva y bonos de equipo.")
	comprobar(npc.obtener_estado(&"veneno") != null and npc.obtener_estado(&"debilitado_fuerza") != null, "Se combinan veneno y penalización al acertar.")
	comprobar(npc.obtener_fuerza() == maxi(1, npc.obtener_atributo_base("fuerza") - 1), "El debuff afecta a los atributos del enemigo.")
	var datos_npc := npc.obtener_estado_persistente()
	comprobar(npc.validar_estado_persistente(datos_npc) == &"", "Los debuffs del enemigo se pueden guardar.")
	var turnos := ServicioTurnos.new(e.gestor_acciones)
	vida = npc.vida_actual
	var fin_turno := turnos.avanzar_turno(npc)
	comprobar(fin_turno.exitosa and npc.vida_actual == vida - 1, "El veneno hace daño, la penalización de atributo no.")
	comprobar(npc.obtener_estado(&"debilitado_fuerza").ticks_pendientes == 1, "La penalización consume un turno.")
	turnos.avanzar_turno(npc)
	comprobar(npc.obtener_estado(&"debilitado_fuerza") == null and npc.obtener_estado(&"veneno") == null, "Ambos estados expiran sin dejar bonos residuales.")
	espada.definicion.efectos_equipo[3].salvacion = "voluntad"
	espada.definicion.efectos_equipo[4].salvacion = "voluntad"
	var resistidos := EfectosEquipo.aplicar_impacto(f, npc, true, motor([1, 1]), aplicador, &"salvacion_prueba")
	comprobar(npc.obtener_estado(&"veneno") == null and npc.obtener_estado(&"debilitado_fuerza") == null and resistidos.size() == 2, "Salvar evita cada efecto y devuelve feedback narrativo.")
	EfectosEquipo.aplicar_impacto(f, npc, true, motor([6, 6]), aplicador, &"salvacion_prueba")
	comprobar(npc.obtener_estado(&"veneno") != null and npc.obtener_estado(&"debilitado_fuerza") != null, "Fallar salvación aplica los dos efectos.")
	espada.definicion.efectos_equipo[3].salvacion = ""
	espada.definicion.efectos_equipo[4].salvacion = ""
	npc.restaurar_estado_persistente(datos_npc)
	comprobar(npc.obtener_estado(&"debilitado_fuerza") != null, "La carga restaura el estado temporal.")
	var snapshot := JSON.parse_string(JSON.stringify(f.obtener_estado_persistente())) as Dictionary
	var cantidad_equipo_snapshot := f.equipo.ranuras.size()
	comprobar(f.validar_estado_persistente(snapshot) == &"", "Snapshot con equipo y valores JSON válido.")
	f.equipo.desequipar(f.inventario, 3)
	comprobar(f.obtener_fuerza() == fuerza_base and EfectosEquipo.bono_dano(f, true) == 1, "Desequipar retira solo sus propios efectos.")
	comprobar(f.restaurar_estado_persistente(snapshot) == &"" and f.equipo.ranuras.size() == cantidad_equipo_snapshot and f.obtener_fuerza() == fuerza_base + 1, "Cargar restaura ranuras y efectos una vez.")
	comprobar(f.inventario.obtener_por_id(espada.id_instancia) == null, "No se duplica el objeto entre mochila y equipo al cargar.")
	var duplicado := snapshot.duplicate(true)
	duplicado.inventario.append(duplicado.equipo[0].item)
	comprobar(f.validar_estado_persistente(duplicado) != &"", "Rechazar ID compartido entre mochila y equipo.")
	var panel: PanelInventarioEquipo = load("res://scenes/ui/inventario/panel_inventario_equipo.tscn").instantiate()
	root.add_child(panel)
	panel.abrir(f)
	comprobar(panel.equipo_actual == f.equipo.ranuras and panel.label_stats.text.contains("+1"), "La interfaz usa el modelo y muestra aportes efectivos.")
	panel._al_soltar_item(7, true, 0, false)
	comprobar(not f.equipo.ranuras.has(7) and f.obtener_voluntad() == vol_base, "Desequipar desde UI retira bonos.")
	panel.queue_free()
	comprobar(f.validar_estado_persistente(snapshot_anterior) == &"", "Los guardados previos sin equipo siguen siendo válidos.")
	# Reemplazar una pieza y rechazar desequipado con mochila llena sin perderla.
	var nueva := ItemInstancia.new(&"espada_reemplazo", espada.definicion)
	f.inventario.agregar(nueva)
	f.equipo.equipar(f.inventario, nueva.id_instancia, 3)
	comprobar(f.obtener_fuerza() == fuerza_base + 1 and f.inventario.obtener_por_id(espada.id_instancia) != null, "Reemplazar devuelve la pieza anterior y no acumula sus bonos.")
	f.inventario.capacidad = f.inventario.obtener_contenido().size()
	comprobar(f.equipo.desequipar(f.inventario, 3) == &"inventario_lleno" and f.equipo.ranuras[3] == nueva, "Mochila llena no hace desaparecer la pieza equipada.")
	f.inventario.capacidad = -1
	# Una penalización de DES del NPC modifica movimiento, se guarda y expira sin daño.
	npc.aplicar_o_renovar_estado(&"debilitado_destreza", 1.0, 2, 2)
	comprobar(npc.validar_estado_persistente(npc.obtener_estado_persistente()) == &"", "Guardar NPC con penalización de DES y presupuesto de movimiento.")
	var antes_penalizacion := npc.vida_actual
	npc.retirar_estado(&"veneno")
	turnos.avanzar_turno(npc)
	turnos.avanzar_turno(npc)
	comprobar(npc.vida_actual == antes_penalizacion and npc.obtener_estado(&"debilitado_destreza") == null, "Expirar penalización no causa daño de estado.")
	var piedras := ItemInstancia.new(&"peso_prueba", definicion("forja_piedra"), 40)
	f.inventario.agregar(piedras)
	f.iniciar_turno()
	comprobar(f.esta_sobrecargado() and f.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) == 0, "La carga incluye el equipo y puede impedir movimiento.")
	comprobar(f.validar_estado_persistente(JSON.parse_string(JSON.stringify(f.obtener_estado_persistente()))) == &"", "Se puede guardar estando sobrecargado con equipo.")
	var daga_principal := ItemInstancia.new(&"daga_principal", definicion("daga_forja"))
	var daga_secundaria := ItemInstancia.new(&"daga_secundaria", definicion("daga_forja"))
	var baston := ItemInstancia.new(&"baston", definicion("baston_forja"))
	comprobar(daga_principal.es_valida() and baston.es_valida(), "Forja exporta daga y bastón con dado 1d2.")
	f.inventario.agregar(daga_principal)
	f.inventario.agregar(daga_secundaria)
	f.inventario.agregar(baston)
	comprobar(f.equipo.equipar(f.inventario, daga_principal.id_instancia, 3) == &"" and f.equipo.equipar(f.inventario, daga_secundaria.id_instancia, 4) == &"", "Una daga puede ocupar cada mano.")
	var dados_dagas := EfectosEquipo.terminos_dano_armas(f)
	comprobar(dados_dagas.size() == 2 and dados_dagas[0].caras == 2 and dados_dagas[1].caras == 2, "Las dos dagas tiran 2d2 y FUE se suma una vez.")
	comprobar(f.equipo.equipar(f.inventario, baston.id_instancia, 3) == &"equipo_incompatible", "El Guerrero no puede equipar el bastón del Mago.")
	f.equipo.desequipar(f.inventario, 4)
	f.clase = "Mago"
	comprobar(f.equipo.equipar(f.inventario, baston.id_instancia, 3) == &"" and EfectosEquipo.terminos_dano_armas(f).size() == 1 and EfectosEquipo.terminos_dano_armas(f)[0].caras == 2, "El bastón tira 1d2.")
	comprobar(f.equipo.equipar(f.inventario, daga_secundaria.id_instancia, 4) == &"equipo_incompatible", "El bastón a dos manos impide equipar la otra mano.")
	for configuracion in [
		{"clase": "Guerrero", "ranuras": [0, 2, 3, 4], "arma": &"espada_inicial"},
		{"clase": "Ladrón", "ranuras": [0, 3, 4, 6], "arma": &"daga_inicial"},
		{"clase": "Mago", "ranuras": [2, 3, 6], "arma": &"baston_inicial"},
	]:
		var ficha_prueba := e._crear_ficha() as Ficha
		ficha_prueba.clase = configuracion.clase
		e._equipar_carga_inicial(ficha_prueba)
		var ranuras_reales: Array = ficha_prueba.equipo.ranuras.keys()
		ranuras_reales.sort()
		comprobar(ranuras_reales == configuracion.ranuras and ficha_prueba.equipo.ranuras[3].definicion.id_definicion == configuracion.arma, "Carga inicial completa de %s." % configuracion.clase)
		ficha_prueba.free()
	for id_consumible in [&"pocion_1", &"frasco_de_bruma"]:
		var definicion_consumible := load("res://assets/items/forja/%s/%s.tres" % [id_consumible, id_consumible]) as DefinicionItem
		comprobar(definicion_consumible != null and definicion_consumible.es_valida() and definicion_consumible.icono != null and definicion_consumible.ilustracion_examen != null and definicion_consumible.escena_mundo != null, "El consumible %s carga sus tres imágenes." % id_consumible)
	var pocion := load("res://assets/items/forja/pocion_1/pocion_1.tres") as DefinicionItem
	comprobar(pocion.obtener_formula_curacion() == "1d6", "La poción exportada muestra curación 1d6.")
	var curacion_pocion := pocion.resolver_curacion()
	comprobar(curacion_pocion >= 1 and curacion_pocion <= 6, "La poción exportada tira de 1 a 6 PV.")
	escena.queue_free()
	await process_frame
	print("EQUIPO_FORJA: %d comprobaciones, %d fallos" % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)
