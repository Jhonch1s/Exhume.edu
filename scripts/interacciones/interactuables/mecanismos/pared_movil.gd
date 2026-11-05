@tool
extends "res://scripts/interacciones/interactuables/puertas/puerta_interactuable.gd"

signal deslizamiento_iniciado(duracion: float, id_emisor: StringName)
signal deslizamiento_terminado(id_emisor: StringName)

@export_range(0.1, 5.0, 0.1) var duracion_deslizamiento: float = 1.2
var _deslizamiento: Tween
var _animando := false
static var _ultimo_frame_sonido: int = -1


func _reproducir_sonido_apertura() -> void:
	var frame := Engine.get_process_frames()
	if frame == _ultimo_frame_sonido:
		return
	_ultimo_frame_sonido = frame
	super._reproducir_sonido_apertura()


func permite_caminar_interactuable() -> bool:
	return abierta and not _animando


func bloquea_vision_interactuable() -> bool:
	return not permite_caminar_interactuable()


func bloquea_proyectiles_interactuable() -> bool:
	return not permite_caminar_interactuable()


func validar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> StringName:
	var motivo := super.validar_cambio_mecanismo(id_emisor, activa)
	if motivo != &"":
		return motivo
	if not activa:
		return &"pared_solo_admite_apertura"
	if tablero == null or tablero.capa_referencia == null:
		return &"tablero_mecanismo_no_configurado"
	var datos := definicion as DefinicionPuerta
	var capa := tablero.capa_referencia
	var destino := capa.local_to_map(capa.map_to_local(coordenada_mapa) + datos.desplazamiento_apertura)
	var celda := tablero.obtener_celda(destino)
	# El bloque se recoge dentro de piedra sólida; no deja un obstáculo sin registrar.
	if destino == coordenada_mapa or celda == null or celda.caminable:
		return &"pared_sin_hueco_de_recepcion"
	return &""


func aplicar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> ResultadoAccion:
	var motivo := validar_cambio_mecanismo(id_emisor, activa)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if abierta:
		return ResultadoAccion.crear_exito()
	var origen := sprite.position
	_animando = true
	var resultado := super.aplicar_cambio_mecanismo(id_emisor, activa)
	var destino := sprite.position
	_mover_visual(origen)
	_deslizamiento = create_tween()
	_deslizamiento.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_deslizamiento.tween_method(_mover_visual, origen, destino, duracion_deslizamiento)
	_deslizamiento.tween_callback(_terminar_deslizamiento.bind(id_emisor))
	deslizamiento_iniciado.emit(duracion_deslizamiento, id_emisor)
	return resultado


func _terminar_deslizamiento(id_emisor: StringName) -> void:
	_animando = false
	presencia_cambiada.emit()
	deslizamiento_terminado.emit(id_emisor)


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	if _deslizamiento != null and _deslizamiento.is_valid():
		_deslizamiento.kill()
	_animando = false
	motivo = super.restaurar_estado_persistente(estado)
	presencia_cambiada.emit()
	return motivo


func _actualizar_representacion() -> void:
	super._actualizar_representacion()
	if not is_instance_valid(sprite):
		return
	for nombre in ["FogOculto", "FogExplorado"]:
		var mascara := get_node_or_null(nombre) as Sprite2D
		if mascara != null:
			mascara.texture = sprite.texture
			mascara.region_enabled = true
			mascara.region_rect = sprite.region_rect
			mascara.position = sprite.position


func _mover_visual(posicion: Vector2) -> void:
	sprite.position = posicion
	for nombre in ["FogOculto", "FogExplorado"]:
		var mascara := get_node_or_null(nombre) as Sprite2D
		if mascara != null:
			mascara.position = posicion
