class_name ServicioExamen
extends RefCounted

var tablero: TableroGrid
var registro_conocimiento: RegistroConocimiento
var evaluador: EvaluadorInformacion
var validador_espacial: ValidadorEspacialTablero


func _init(
	tablero_inicial: TableroGrid,
	registro_inicial: RegistroConocimiento = null
) -> void:
	tablero = tablero_inicial
	registro_conocimiento = registro_inicial
	if registro_conocimiento == null:
		registro_conocimiento = RegistroConocimiento.new()
	evaluador = EvaluadorInformacion.new()
	validador_espacial = ValidadorEspacialTablero.new(tablero)


func validar_examen(
	contexto: ContextoAccion,
	objetivo: Interactuable
) -> StringName:
	var motivo := _validar_contrato(contexto, objetivo)
	if motivo != &"":
		return motivo
	var evaluacion := _evaluar(contexto, objetivo)
	return evaluacion.motivo if evaluacion.bloqueada else &""


func resolver_examen(
	contexto: ContextoAccion,
	objetivo: Interactuable,
	pistas_adicionales: Array[StringName] = []
) -> ResultadoAccion:
	var motivo := _validar_contrato(contexto, objetivo)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)

	var evaluacion := _evaluar(contexto, objetivo, pistas_adicionales)
	if evaluacion.bloqueada:
		return ResultadoAccion.crear_bloqueo(evaluacion.motivo)

	var solicitud := contexto.solicitud_examen
	var registro := registro_conocimiento.registrar_descubrimientos(
		solicitud.id_observador,
		objetivo.id_instancia,
		evaluacion.fragmentos_disponibles
	)
	if not registro.exitosa:
		return ResultadoAccion.crear_fallo(registro.motivo)

	var mensajes: Array[StringName] = []
	for fragmento in evaluacion.fragmentos_disponibles:
		mensajes.append(fragmento.id_mensaje)

	var cambios: Array[Dictionary] = []
	for id_fragmento in registro.ids_fragmentos_nuevos:
		cambios.append({
			&"tipo": &"conocimiento_descubierto",
			&"observador_id": solicitud.id_observador,
			&"objetivo_id": objetivo.id_instancia,
			&"fragmento_id": id_fragmento,
		})
	return ResultadoAccion.crear_exito(mensajes, [], cambios)


func _validar_contrato(
	contexto: ContextoAccion,
	objetivo: Interactuable
) -> StringName:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.EXAMINAR:
		return &"tipo_accion_no_admitido"
	if objetivo == null or contexto.objetivo != objetivo:
		return &"objetivo_invalido"
	if tablero == null or not is_instance_valid(tablero):
		return &"tablero_examen_invalido"
	if objetivo.id_instancia == &"":
		return &"id_objetivo_vacio"
	if objetivo.definicion == null or not objetivo.definicion.es_valida():
		return &"definicion_examinable_invalida"
	if objetivo.definicion.perfil_observacion == null:
		return &"perfil_observacion_ausente"
	if objetivo.definicion.fragmentos_informacion.is_empty():
		return &"informacion_examinable_ausente"
	if contexto.solicitud_examen == null:
		return &"solicitud_examen_ausente"
	if not contexto.solicitud_examen.es_valida(contexto.actor):
		return &"solicitud_examen_invalida"
	if not contexto.tiene_origen() or not contexto.tiene_celda_objetivo():
		return &"coordenadas_incompletas"
	if contexto.celda_objetivo != objetivo.coordenada_mapa:
		return &"coordenada_objetivo_inconsistente"
	return &""


func _evaluar(
	contexto: ContextoAccion,
	objetivo: Interactuable,
	pistas_adicionales: Array[StringName] = []
) -> ResultadoEvaluacionInformacion:
	var distancia := float(
		abs(contexto.celda_objetivo.x - contexto.origen.x)
		+ abs(contexto.celda_objetivo.y - contexto.origen.y)
	)
	var celda := tablero.obtener_celda(contexto.celda_objetivo)
	var objetivo_visible := (
		celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE
	)
	var linea_visual_valida := validador_espacial.validar_linea_efecto(contexto) == &""
	var pistas := contexto.solicitud_examen.pistas
	for pista in pistas_adicionales:
		if pista != &"" and pista not in pistas:
			pistas.append(pista)
	var condiciones := CondicionesObservacion.new(
		contexto.actor,
		distancia,
		objetivo_visible,
		linea_visual_valida,
		pistas
	)
	return evaluador.evaluar(
		objetivo.obtener_fragmentos_informacion(),
		condiciones,
		objetivo.definicion.perfil_observacion
	)
