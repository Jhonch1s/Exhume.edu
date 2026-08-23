extends Node

signal entrada_registrada(texto: String)

@export var imprimir_en_consola: bool = true

var entradas: Array[String] = []
var _gestor_observado: GestorAcciones
var _filtro_actor: StringName = &""
var _filtro_celda: Variant
var _filtro_tipo: int = -1


func observar_gestor(nuevo_gestor: GestorAcciones) -> void:
	_desconectar_gestor()
	_gestor_observado = nuevo_gestor
	if _gestor_observado == null or not is_instance_valid(_gestor_observado):
		return

	_gestor_observado.accion_iniciada.connect(_al_iniciar_accion)
	_gestor_observado.accion_resuelta.connect(_al_resolver_accion)
	_gestor_observado.accion_finalizada.connect(_al_finalizar_accion)


func limpiar() -> void:
	entradas.clear()


func configurar_filtros(
	id_actor: StringName = &"",
	celda: Variant = null,
	tipo: int = -1
) -> void:
	_filtro_actor = id_actor
	_filtro_celda = celda
	_filtro_tipo = tipo


func limpiar_filtros() -> void:
	configurar_filtros()


func _exit_tree() -> void:
	_desconectar_gestor()


func _al_iniciar_accion(contexto: ContextoAccion) -> void:
	if not _acepta(contexto):
		return
	_registrar(
		"[ACCION][INICIO] tipo=%s actor=%s objetivo=%s origen=%s destino=%s"
		% [
			_nombre_tipo_accion(contexto.tipo),
			_id_objeto(contexto.actor),
			_id_objeto(contexto.objetivo),
			_formatear_coordenada(contexto.origen),
			_formatear_coordenada(contexto.celda_objetivo),
		]
	)


func _al_resolver_accion(
	contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> void:
	if not _acepta(contexto):
		return
	_registrar(
		"[ACCION][RESUELTA] estado=%s motivo=%s solicitudes=%d efectos=%d cambios=%d"
		% [
			_nombre_estado(resultado.estado),
			_formatear_motivo(resultado.motivo),
			resultado.solicitudes_efecto.size(),
			resultado.efectos_aplicados.size(),
			resultado.cambios_estado.size(),
		]
	)


func _al_finalizar_accion(
	contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> void:
	if not _acepta(contexto):
		return
	_registrar(
		"[ACCION][FIN] estado=%s costes=%s interrupcion=%s"
		% [
			_nombre_estado(resultado.estado),
			_formatear_costes(resultado.costes_consumidos),
			str(resultado.interrumpe_movimiento).to_lower(),
		]
	)


func _acepta(contexto: ContextoAccion) -> bool:
	return (
		(_filtro_actor == &"" or _id_objeto(contexto.actor) == String(_filtro_actor))
		and (_filtro_celda == null or contexto.celda_objetivo == _filtro_celda)
		and (_filtro_tipo < 0 or contexto.tipo == _filtro_tipo)
	)


func _registrar(texto: String) -> void:
	entradas.append(texto)
	entrada_registrada.emit(texto)
	if imprimir_en_consola:
		print(texto)


func _desconectar_gestor() -> void:
	if _gestor_observado == null or not is_instance_valid(_gestor_observado):
		_gestor_observado = null
		return

	if _gestor_observado.accion_iniciada.is_connected(_al_iniciar_accion):
		_gestor_observado.accion_iniciada.disconnect(_al_iniciar_accion)
	if _gestor_observado.accion_resuelta.is_connected(_al_resolver_accion):
		_gestor_observado.accion_resuelta.disconnect(_al_resolver_accion)
	if _gestor_observado.accion_finalizada.is_connected(_al_finalizar_accion):
		_gestor_observado.accion_finalizada.disconnect(_al_finalizar_accion)
	_gestor_observado = null


func _nombre_tipo_accion(tipo: TiposInteraccion.TipoAccion) -> String:
	var nombres: Array = TiposInteraccion.TipoAccion.keys()
	if tipo < 0 or tipo >= nombres.size():
		return "DESCONOCIDA"
	return String(nombres[tipo])


func _nombre_estado(estado: TiposInteraccion.EstadoResolucion) -> String:
	var nombres: Array = TiposInteraccion.EstadoResolucion.keys()
	if estado < 0 or estado >= nombres.size():
		return "DESCONOCIDO"
	return String(nombres[estado])


func _formatear_coordenada(valor: Variant) -> String:
	if not valor is Vector2i:
		return "-"
	var coordenada: Vector2i = valor
	return "(%d,%d)" % [coordenada.x, coordenada.y]


func _formatear_motivo(motivo: StringName) -> String:
	if motivo == &"":
		return "-"
	return String(motivo)


func _id_objeto(objeto: Object) -> String:
	if objeto == null or not is_instance_valid(objeto):
		return "-"
	for metodo in [
		&"obtener_id_actor",
		&"obtener_id_objetivo_interaccion",
		&"obtener_id_reaccion",
	]:
		if objeto.has_method(metodo):
			var valor: Variant = objeto.call(metodo)
			if valor is StringName and valor != &"":
				return String(valor)
	return objeto.get_class()


func _formatear_costes(costes: Dictionary[StringName, float]) -> String:
	if costes.is_empty():
		return "{}"

	var claves: Array[String] = []
	for clave: StringName in costes:
		claves.append(String(clave))
	claves.sort()

	var partes: Array[String] = []
	for clave: String in claves:
		var valor: float = costes.get(StringName(clave), 0.0)
		var texto_valor := str(valor)
		if is_equal_approx(valor, floorf(valor)):
			texto_valor = str(roundi(valor))
		partes.append("%s:%s" % [clave, texto_valor])
	return "{" + ", ".join(partes) + "}"
