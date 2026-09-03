@tool

class_name EstatuaMecanismo
extends Interactuable

const ESCENA_FUEGO := preload("res://scenes/efectos_superficie/Fuego.tscn")

enum Orientacion {
	ABAJO_IZQUIERDA,
	ABAJO_DERECHA,
	ARRIBA_DERECHA,
	ARRIBA_IZQUIERDA,
}

@export var orientacion: Orientacion = Orientacion.ABAJO_IZQUIERDA:
	set(valor):
		orientacion = valor
		_actualizar_visual()

@export_category("Trampa direccional")
@export_range(1, 20, 1) var alcance_disparo: int = 3

func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_actualizar_visual()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and ajustar_a_celda_en_editor:
		_ajustar_al_centro_celda()


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	return super.obtener_opciones_accion(actor)

func permite_caminar_interactuable() -> bool:
	return false

func bloquea_vision_interactuable() -> bool:
	return true

func bloquea_proyectiles_interactuable() -> bool:
	return true


func validar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> StringName:
	if id_emisor == &"":
		return &"emisor_mecanismo_invalido"
	if not activa:
		return &"estatua_solo_admite_activacion"
	if tablero == null:
		return &"tablero_mecanismo_no_configurado"
	if (
		alcance_disparo <= 0
		or tablero.zona_referencia == null
		or tablero.capa_referencia == null
		or tablero.zona_referencia.get_node_or_null(^"EfectosSuperficie") == null
	):
		return &"estatua_trampa_no_configurada"
	return &""


func aplicar_cambio_mecanismo(
	id_emisor: StringName,
	activa: bool
) -> ResultadoAccion:
	var motivo := validar_cambio_mecanismo(id_emisor, activa)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var coordenadas := _obtener_celdas_fuego()
	var efectos_aplicados: Array = []
	var cambios: Array[Dictionary] = []
	var mensajes: Array[StringName] = [
		&"estatua.escupe_fuego" if not coordenadas.is_empty()
		else &"estatua.fuego_bloqueado"
	]
	for indice in coordenadas.size():
		var coordenada: Vector2i = coordenadas[indice]
		var prefijo := StringName("%s_%s_fuego_%d" % [
			id_emisor, id_instancia, indice,
		])
		var desplegadas := tablero.desplegar_efecto_superficie(
			ESCENA_FUEGO, coordenada, 0, prefijo
		)
		if desplegadas.is_empty():
			continue
		var id_fuego := StringName("%s_%d_%d" % [
			prefijo, coordenada.x, coordenada.y,
		])
		var fuego := tablero.efectos_superficie_por_id.get(id_fuego) as Fuego
		cambios.append({
			&"tipo": &"superficie_desplegada",
			&"coordenada": coordenada,
			&"id_superficie": id_fuego,
		})
		if fuego != null:
			_aplicar_fuego_a_ocupantes(
				fuego, coordenada, id_emisor, efectos_aplicados, mensajes
			)
	return ResultadoAccion.crear_exito(
		mensajes,
		efectos_aplicados,
		cambios
	)


func _obtener_celdas_fuego() -> Array[Vector2i]:
	var coordenadas: Array[Vector2i] = []
	var direccion := _obtener_direccion_disparo()
	for distancia in range(1, alcance_disparo + 1):
		var celda := tablero.obtener_celda(coordenada_mapa + direccion * distancia)
		if (
			celda == null
			or not celda.caminable
			or celda.bloquea_proyectiles_efectiva()
		):
			break
		coordenadas.append(coordenada_mapa + direccion * distancia)
	return coordenadas


func _aplicar_fuego_a_ocupantes(
	fuego: Fuego,
	coordenada: Vector2i,
	id_emisor: StringName,
	efectos_aplicados: Array,
	mensajes: Array[StringName]
) -> void:
	var aplicador := AplicadorEfectos.new()
	for ocupante in tablero.obtener_celda(coordenada).ocupantes.duplicate():
		var solicitud := fuego.crear_solicitud_quemado(
			ocupante,
			StringName("%s_%s" % [id_emisor, id_instancia])
		)
		var efecto: Variant = aplicador.aplicar(solicitud)
		if efecto is ResultadoEfectoAplicado:
			efectos_aplicados.append(efecto)
			mensajes.append_array(efecto.mensajes)


func _obtener_direccion_disparo() -> Vector2i:
	match orientacion:
		Orientacion.ABAJO_IZQUIERDA:
			return Vector2i.LEFT
		Orientacion.ABAJO_DERECHA:
			return Vector2i.DOWN
		Orientacion.ARRIBA_IZQUIERDA:
			return Vector2i.UP
		Orientacion.ARRIBA_DERECHA:
			return Vector2i.RIGHT
	return Vector2i.ZERO

func _actualizar_visual() -> void:
	for ruta in [^"Sprite2D", ^"FogOculto", ^"FogExplorado"]:
		var sprite := get_node_or_null(ruta) as Sprite2D
		if sprite != null:
			sprite.region_rect = Rect2(float(orientacion * 64), 0.0, 64, 96)
