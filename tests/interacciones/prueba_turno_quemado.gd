extends SceneTree

const ServicioTurnosScript = preload(
	"res://scripts/interacciones/efectos/servicio_turnos.gd"
)

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	await _probar_quemado()
	await _probar_estados_en_orden()
	await _probar_prevalidacion_completa()
	if _fallos.is_empty():
		print("TurnosPersistentes: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_quemado() -> void:
	var ficha := Ficha.new()
	var gestor := GestorAcciones.new()
	root.add_child(ficha)
	root.add_child(gestor)
	var aplicador := AplicadorEfectos.new()
	var servicio := ServicioTurnosScript.new(gestor, aplicador)
	var inicial: Variant = aplicador.aplicar(SolicitudEfecto.new(
		&"quemado", &"estado", ficha, &"entrada_fuego", 0.0, 3,
		TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
		null,
		[{&"cantidad": 1, &"caras": 2, &"signo": 1}]
	))
	_comprobar(inicial is ResultadoEfectoAplicado, "Quemado debe aplicarse antes de avanzar turnos.")
	var vida_tras_entrada := ficha.pv_actual

	var primer_turno := servicio.avanzar_turno(ficha)
	var estado := ficha.obtener_estado(&"quemado")
	_comprobar(primer_turno.exitosa, "FIN_TURNO debe resolverse mediante GestorAcciones.")
	_comprobar(primer_turno.efectos_aplicados.size() == 1, "El turno debe confirmar un daño.")
	_comprobar(
		vida_tras_entrada - ficha.pv_actual in [1, 2]
		and primer_turno.tirada is ResultadoTirada,
		"El primer turno debe resolver un d2."
	)
	_comprobar(estado != null and estado.ticks_pendientes == 2, "Deben quedar dos ticks pendientes.")
	_comprobar(
		primer_turno.cambios_estado == [{
			&"tipo": &"estado_tick",
			&"clave": &"quemado",
			&"ticks_restantes": 2,
			&"expirado": false,
		}],
		"El tick debe quedar representado como cambio estructurado."
	)

	var vida_antes_segundo := ficha.pv_actual
	var segundo_turno := servicio.avanzar_turno(ficha)
	_comprobar(
		vida_antes_segundo - ficha.pv_actual in [1, 2]
		and ficha.obtener_estado(&"quemado").ticks_pendientes == 1,
		"El segundo turno debe resolver otro d2."
	)
	_comprobar(
		segundo_turno.cambios_estado.size() == 1
		and not segundo_turno.cambios_estado[0][&"expirado"],
		"El segundo tick todavía no debe expirar."
	)

	var tercer_turno := servicio.avanzar_turno(ficha)
	_comprobar(
		ficha.obtener_estado(&"quemado") == null
		and tercer_turno.cambios_estado[0][&"expirado"],
		"El resultado debe registrar la expiración."
	)

	var cuarto_turno := servicio.avanzar_turno(ficha)
	_comprobar(
		cuarto_turno.exitosa
		and cuarto_turno.efectos_aplicados.is_empty()
		and cuarto_turno.cambios_estado.is_empty(),
		"FIN_TURNO sin quemado debe tener éxito vacío."
	)

	ficha.queue_free()
	gestor.queue_free()
	await process_frame


func _probar_estados_en_orden() -> void:
	var ficha := Ficha.new()
	var gestor := GestorAcciones.new()
	root.add_child(ficha)
	root.add_child(gestor)
	var aplicador := AplicadorEfectos.new()
	var servicio := ServicioTurnosScript.new(gestor, aplicador)
	aplicador.aplicar(SolicitudEfecto.new(
		&"veneno", &"estado", ficha, &"veneno_inicial", 1.0, 2
	))
	aplicador.aplicar(SolicitudEfecto.new(
		&"quemado", &"estado", ficha, &"fuego_inicial", 1.0, 1
	))
	var vida_antes := ficha.pv_actual
	var resultado := servicio.avanzar_turno(ficha)
	_comprobar(
		resultado.efectos_aplicados.map(func(efecto): return efecto.clave)
		== [&"quemado", &"veneno"],
		"Los estados deben procesarse por clave estable."
	)
	_comprobar(ficha.pv_actual == vida_antes - 2, "Quemado y veneno deben aplicar un tick.")
	_comprobar(
		ficha.obtener_estado(&"quemado") == null
		and ficha.obtener_estado(&"veneno").ticks_pendientes == 1,
		"Quemado debe expirar y veneno debe conservar un tick."
	)
	var segundo := servicio.avanzar_turno(ficha)
	_comprobar(
		segundo.efectos_aplicados.size() == 1
		and segundo.efectos_aplicados[0].clave == &"veneno"
		and ficha.obtener_estado(&"veneno") == null,
		"El segundo fin de turno debe agotar veneno."
	)
	ficha.queue_free()
	gestor.queue_free()
	await process_frame


func _probar_prevalidacion_completa() -> void:
	var ficha := Ficha.new()
	var gestor := GestorAcciones.new()
	root.add_child(ficha)
	root.add_child(gestor)
	ficha.aplicar_o_renovar_estado(&"quemado", 1.0, 2, 1)
	ficha.aplicar_o_renovar_estado(&"desconocido", 1.0, 2, 1)
	var vida_antes := ficha.pv_actual
	var resultado := ServicioTurnosScript.new(gestor).avanzar_turno(ficha)
	_comprobar(
		resultado.motivo == &"estado_persistente_no_admitido",
		"Un estado desconocido debe bloquear el lote completo."
	)
	_comprobar(
		ficha.pv_actual == vida_antes
		and ficha.obtener_estado(&"quemado").ticks_pendientes == 1,
		"La prevalidación debe impedir mutaciones parciales."
	)
	ficha.queue_free()
	gestor.queue_free()
	await process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
