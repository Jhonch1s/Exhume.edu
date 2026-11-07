extends Interactuable

const DURACION_CAIDA := 1.05

@onready var rocas: Node2D = $Rocas
@onready var posicion_reposo: Vector2 = rocas.position

var _caido := false
var _caida: Tween


func _ready() -> void:
	rocas.hide()


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	return []


func permite_caminar_interactuable() -> bool:
	return not _caido


func bloquea_vision_interactuable() -> bool:
	return _caido


func bloquea_proyectiles_interactuable() -> bool:
	return _caido


func validar_cambio_mecanismo(_id_emisor: StringName, activar: bool) -> StringName:
	if not activar:
		return &"derrumbe_irreversible"
	if _caido:
		return &""
	if tablero == null:
		return &"tablero_mecanismo_no_configurado"
	for coord in obtener_coordenadas_ocupadas():
		var celda := tablero.obtener_celda(coord)
		if not celda.es_caminable_efectiva() or celda.tiene_contenido() or celda.esta_reservada():
			return &"paso_derrumbe_ocupado"
	return &""


func aplicar_cambio_mecanismo(id_emisor: StringName, activar: bool) -> ResultadoAccion:
	var motivo := validar_cambio_mecanismo(id_emisor, activar)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if _caido:
		return ResultadoAccion.crear_exito()
	_caido = true
	_mover_rocas(0.0)
	rocas.show()
	presencia_cambiada.emit()
	_caida = create_tween()
	_caida.tween_method(_mover_rocas, 0.0, 1.0, DURACION_CAIDA)
	return ResultadoAccion.crear_exito([], [], [{
		&"objetivo_id": id_instancia,
		&"propiedad": &"caido",
		&"anterior": false,
		&"nueva": true,
		&"emisor_id": id_emisor,
	}])


func _mover_rocas(avance: float) -> void:
	var vibracion := Vector2(sin(avance * TAU * 7.0) * 9.0, sin(avance * TAU * 11.0) * 5.0)
	var altura := -112.0 * (1.0 - avance * avance)
	rocas.position = posicion_reposo + Vector2(0.0, altura) + vibracion * sin(avance * PI)


func admite_ausencia_en_guardado() -> bool:
	return true


func obtener_estado_persistente() -> Dictionary:
	return {"caido": _caido}


func validar_estado_persistente(estado: Dictionary) -> StringName:
	return &"" if estado.get("caido", false) is bool else &"estado_derrumbe_invalido"


func permite_caminar_estado_guardado(estado: Dictionary) -> bool:
	return not estado.get("caido", false)


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	if _caida != null and _caida.is_valid():
		_caida.kill()
	_caido = estado.get("caido", false)
	rocas.position = posicion_reposo
	rocas.visible = _caido
	presencia_cambiada.emit()
	return &""
