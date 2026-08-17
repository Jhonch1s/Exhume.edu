extends SceneTree

var _fallos: Array[String] = []
var _tablero: TableroGrid
var _registro: RegistroConocimiento
var _gestor: GestorAcciones
var _fuente: FuenteLuzInteractuable
var _actor: Node
var _zona: Node2D


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	if not _preparar_vertical_slice():
		_finalizar()
		return

	_probar_opciones_publicadas()
	_probar_primer_examen_profundo()
	_probar_examen_repetido()
	_probar_examen_basico_distante()
	_probar_secreto_con_pista()
	_probar_estado_apagado_y_visibilidad()
	_liberar_vertical_slice()
	_finalizar()


func _preparar_vertical_slice() -> bool:
	var escena := load("res://scenes/Zona1/zona_1.tscn") as PackedScene
	_comprobar(escena != null, "La zona debe cargar para integrar EXAMINAR.")
	if escena == null:
		return false

	_zona = escena.instantiate() as Node2D
	root.add_child(_zona)
	var capa_suelo := _zona.get_node("CapaSuelo") as TileMapLayer
	_tablero = TableroGrid.new()
	root.add_child(_tablero)
	_tablero.generar_desde_zona(_zona)
	_registro = RegistroConocimiento.new()
	_tablero.configurar_servicio_examen(ServicioExamen.new(_tablero, _registro))
	_comprobar(
		_tablero.registrar_interactuables_desde_zona(_zona, capa_suelo),
		"Las fuentes deben registrarse con el servicio compartido."
	)

	_fuente = _tablero.obtener_interactuable(
		&"zona1_antorcha_pie_02_01"
	) as FuenteLuzInteractuable
	_comprobar(_fuente != null, "La antorcha vertical slice debe estar registrada.")
	if _fuente == null:
		return false

	_actor = Ficha.new()
	root.add_child(_actor)
	_gestor = GestorAcciones.new()
	root.add_child(_gestor)
	_gestor.configurar_validador_espacial(ValidadorEspacialTablero.new(_tablero))
	_tablero.obtener_celda(_fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.VISIBLE
	)
	return true


func _probar_opciones_publicadas() -> void:
	var opciones := _fuente.obtener_opciones_accion(_actor)
	_comprobar(opciones.size() == 2, "La antorcha debe publicar Examinar y Apagar.")
	_comprobar(opciones[0].id == &"examinar", "Examinar debe ser la primera opción.")
	_comprobar(
		opciones[0].tipo == TiposInteraccion.TipoAccion.EXAMINAR,
		"La opción debe usar el tipo EXAMINAR."
	)
	_comprobar(
		opciones[0].tipo_linea_efecto == TiposInteraccion.TipoLineaEfecto.VISUAL,
		"Examinar debe declarar línea visual."
	)


func _probar_primer_examen_profundo() -> void:
	_fuente.encendida = true
	var resultado := _gestor.procesar_accion(_crear_contexto_examen())
	_comprobar(resultado.exitosa, "El examen visible y adyacente debe tener éxito.")
	_comprobar(
		resultado.mensajes == [
			&"examen.antorcha_pie.basico_encendida",
			&"examen.antorcha_pie.construccion",
		],
		"El examen profundo debe mostrar información básica unificada y construcción."
	)
	_comprobar(
		resultado.cambios_estado.size() == 2,
		"Solo identidad y construcción deben registrarse como descubrimientos."
	)
	var ids_conocidos := _registro.obtener_ids_conocidos(
		&"jugador_principal",
		_fuente.id_instancia
	)
	_comprobar(
		ids_conocidos == [&"construccion", &"identidad"],
		"El estado actual de la llama no debe recordarse. Actual: %s" % [ids_conocidos]
	)


func _probar_examen_repetido() -> void:
	var resultado := _gestor.procesar_accion(_crear_contexto_examen())
	_comprobar(resultado.exitosa, "Repetir el examen debe seguir teniendo éxito.")
	_comprobar(
		resultado.cambios_estado.is_empty(),
		"Repetir información conocida no debe duplicar descubrimientos."
	)
	_comprobar(
		resultado.mensajes.size() == 2,
		"La información disponible debe poder presentarse aunque ya sea conocida."
	)


func _probar_examen_basico_distante() -> void:
	var encontro_origen := false
	for origen in _tablero.datos:
		var coord_origen: Vector2i = origen
		var distancia: int = abs(coord_origen.x - _fuente.coordenada_mapa.x) + abs(
			coord_origen.y - _fuente.coordenada_mapa.y
		)
		if distancia != 5:
			continue
		var resultado := _gestor.procesar_accion(
			_crear_contexto_examen([], coord_origen)
		)
		if not resultado.exitosa:
			continue
		encontro_origen = true
		_comprobar(
			resultado.mensajes == [&"examen.antorcha_pie.basico_encendida"],
			"A cinco celdas la antorcha real debe producir un solo mensaje básico."
		)
		break
	_comprobar(encontro_origen, "La zona debe ofrecer una línea válida a cinco celdas.")


func _probar_secreto_con_pista() -> void:
	var resultado := _gestor.procesar_accion(
		_crear_contexto_examen([&"marca_oculta_revelable"])
	)
	_comprobar(resultado.exitosa, "La pista explícita debe permitir resolver el examen.")
	_comprobar(
		&"examen.antorcha_pie.marca_oculta" in resultado.mensajes,
		"El mensaje secreto debe aparecer al cumplir su pista."
	)
	_comprobar(
		resultado.cambios_estado.size() == 1
		and resultado.cambios_estado[0][&"fragmento_id"] == &"marca_oculta",
		"El secreto debe registrarse exactamente una vez."
	)


func _probar_estado_apagado_y_visibilidad() -> void:
	_fuente.encendida = false
	var apagada := _gestor.procesar_accion(_crear_contexto_examen())
	_comprobar(
		&"examen.antorcha_pie.basico_apagada" in apagada.mensajes,
		"El estado particular debe seleccionar el mensaje básico apagado."
	)
	_comprobar(
		not (&"examen.antorcha_pie.basico_encendida" in apagada.mensajes),
		"El mensaje no debe exponer un estado anterior."
	)

	_tablero.obtener_celda(_fuente.coordenada_mapa).visibilidad = (
		Celda.EstadoVisibilidad.EXPLORADO
	)
	var no_visible := _gestor.procesar_accion(_crear_contexto_examen())
	_comprobar(
		no_visible.estado == TiposInteraccion.EstadoResolucion.BLOQUEO
		and no_visible.motivo == &"objetivo_no_visible",
		"Una celda solo explorada no debe producir descubrimientos nuevos."
	)


func _crear_contexto_examen(
	pistas: Array[StringName] = [],
	origen: Variant = null
) -> ContextoAccion:
	var origen_examen: Vector2i = _fuente.coordenada_mapa
	if origen is Vector2i:
		origen_examen = origen
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		_actor,
		origen_examen,
		_fuente.coordenada_mapa,
		_fuente,
		null,
		&"",
		[],
		{},
		_fuente.definicion.perfil_observacion.alcance_basico,
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL,
		{},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		SolicitudExamen.new(&"jugador_principal", pistas)
	)


func _liberar_vertical_slice() -> void:
	_gestor.queue_free()
	_actor.queue_free()
	_tablero.queue_free()
	_zona.queue_free()


func _finalizar() -> void:
	if _fallos.is_empty():
		print("IntegracionExaminarFuenteLuz: 6 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
