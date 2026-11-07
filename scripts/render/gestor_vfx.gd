extends Node

signal efecto_emitido(tipo: StringName, posicion: Vector2)

@export_range(0.0, 1.0, 0.05) var intensidad_sacudida: float = 1.0

# Amplitud en píxeles de pantalla, frecuencia y duración en segundos.
const PERFILES := {
	&"piedra_moviendo": Vector3(5.0, 9.0, 1.2),
	&"piedra_encajada": Vector3(5.0, 15.0, 0.22),
	&"trampa": Vector3(2.5, 22.0, 0.16),
	&"impacto": Vector3(4.0, 14.0, 0.22),
	&"explosion": Vector3(8.0, 18.0, 0.5),
	&"chillido": Vector3(2.5, 36.0, 0.45),
	&"derrumbe": Vector3(6.0, 11.0, 1.4),
}

var _camara: Camera2D
var _tablero: TableroGrid
var _gestor: GestorAcciones
var _paredes: Array[Node] = []
var _efectos: Dictionary = {}
var _frames: Dictionary = {}
var _aporte := Vector2.ZERO


func configurar(camara: Camera2D, tablero: TableroGrid, gestor: GestorAcciones) -> void:
	_desconectar()
	_camara = camara
	_tablero = tablero
	_gestor = gestor
	_gestor.accion_finalizada.connect(_on_accion)
	_tablero.interactuable_registrado.connect(_on_interactuable)
	for entidad in _tablero.interactuables_por_id.values():
		_on_interactuable(entidad.coordenada_mapa, entidad)


func _on_interactuable(_coordenada: Vector2i, entidad: Interactuable) -> void:
	if not entidad.has_signal(&"deslizamiento_iniciado") or not entidad.has_signal(&"deslizamiento_terminado") or entidad in _paredes:
		return
	_paredes.append(entidad)
	entidad.connect(&"deslizamiento_iniciado", _on_pared_iniciada.bind(entidad))
	entidad.connect(&"deslizamiento_terminado", _on_pared_terminada.bind(entidad))


func _on_pared_iniciada(duracion: float, id_emisor: StringName, pared: Node2D) -> void:
	solicitar(&"piedra_moviendo", _posicion_vfx_pared(id_emisor, pared), duracion)


func _on_pared_terminada(id_emisor: StringName, pared: Node2D) -> void:
	solicitar(&"piedra_encajada", _posicion_vfx_pared(id_emisor, pared))


func _posicion_vfx_pared(id_emisor: StringName, pared: Node2D) -> Vector2:
	var emisor := _tablero.obtener_interactuable(id_emisor)
	if emisor != null and _es_visible(emisor.global_position):
		return emisor.global_position
	return pared.global_position


func solicitar(tipo: StringName, posicion: Vector2, duracion: float = -1.0, direccion: Vector2 = Vector2.ZERO) -> bool:
	if not PERFILES.has(tipo) or intensidad_sacudida <= 0.0 or not _es_visible(posicion):
		return false
	var frame := Engine.get_process_frames()
	if _frames.get(tipo, -1) == frame:
		return false
	_frames[tipo] = frame
	var perfil: Vector3 = PERFILES[tipo]
	_efectos[tipo] = {"tiempo": 0.0, "duracion": duracion if duracion > 0.0 else perfil.z, "direccion": direccion.normalized()}
	efecto_emitido.emit(tipo, posicion)
	return true


func _es_visible(posicion: Vector2) -> bool:
	if not is_instance_valid(_camara) or not is_instance_valid(_tablero) or _tablero.capa_referencia == null:
		return false
	var capa := _tablero.capa_referencia
	var celda := _tablero.obtener_celda(capa.local_to_map(capa.to_local(posicion)))
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return false
	return _camara.get_viewport_rect().has_point(_camara.get_canvas_transform() * posicion)


func _on_accion(contexto: ContextoAccion, resultado: ResultadoAccion) -> void:
	if not resultado.exitosa or contexto.tipo == TiposInteraccion.TipoAccion.FIN_TURNO:
		return
	var posicion := Vector2.ZERO
	if contexto.tiene_celda_objetivo():
		posicion = _tablero.capa_referencia.to_global(_tablero.capa_referencia.map_to_local(contexto.celda_objetivo))
	elif contexto.objetivo is Node2D:
		posicion = contexto.objetivo.global_position
	else:
		return
	for efecto in resultado.efectos_aplicados + resultado.solicitudes_efecto:
		if (efecto is ResultadoEfectoAplicado or efecto is SolicitudEfecto) and efecto.clave == &"explosion":
			solicitar(&"explosion", posicion)
			return
	if &"terror.chillido_resistido" in resultado.mensajes or &"terror.chillido_aturde" in resultado.mensajes:
		solicitar(&"chillido", posicion)
		return
	if &"trampa.superficie_activada" in resultado.mensajes or &"estatua.escupe_fuego" in resultado.mensajes:
		solicitar(&"trampa", posicion)
		return
	for efecto in resultado.efectos_aplicados:
		if efecto is ResultadoEfectoAplicado and efecto.tipo == &"dano" and efecto.magnitud > 0 and efecto.clave not in [&"veneno", &"quemado"]:
			var direccion := Vector2.ZERO
			if contexto.actor is Node2D:
				direccion = posicion - contexto.actor.global_position
			solicitar(&"impacto", posicion, -1.0, direccion)
			return


func _process(delta: float) -> void:
	if not is_instance_valid(_camara):
		return
	_camara.offset -= _aporte
	_aporte = Vector2.ZERO
	if intensidad_sacudida <= 0.0:
		_efectos.clear()
	for tipo in _efectos.keys():
		var efecto: Dictionary = _efectos[tipo]
		efecto.tiempo += delta
		if efecto.tiempo >= efecto.duracion:
			_efectos.erase(tipo)
			continue
		var perfil: Vector3 = PERFILES[tipo]
		var fase: float = efecto.tiempo * perfil.y * TAU
		var envolvente := pow(1.0 - efecto.tiempo / efecto.duracion, 2.0)
		var onda := Vector2(sin(fase), sin(fase * 1.37) * 0.65)
		if efecto.direccion != Vector2.ZERO:
			onda = efecto.direccion * sin(fase)
		_aporte += onda * perfil.x * envolvente
	_aporte = _aporte.limit_length(8.0) * clampf(intensidad_sacudida, 0.0, 1.0) / _camara.zoom
	_camara.offset += _aporte


func limpiar() -> void:
	if is_instance_valid(_camara):
		_camara.offset -= _aporte
	_aporte = Vector2.ZERO
	_efectos.clear()
	_frames.clear()


func _desconectar() -> void:
	limpiar()
	if is_instance_valid(_gestor) and _gestor.accion_finalizada.is_connected(_on_accion):
		_gestor.accion_finalizada.disconnect(_on_accion)
	if is_instance_valid(_tablero) and _tablero.interactuable_registrado.is_connected(_on_interactuable):
		_tablero.interactuable_registrado.disconnect(_on_interactuable)
	for pared in _paredes:
		if is_instance_valid(pared):
			pared.disconnect(&"deslizamiento_iniciado", _on_pared_iniciada.bind(pared))
			pared.disconnect(&"deslizamiento_terminado", _on_pared_terminada.bind(pared))
	_paredes.clear()


func _exit_tree() -> void:
	_desconectar()
