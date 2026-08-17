extends Node
class_name TableroGrid

var datos: Dictionary[Vector2i, Celda] = {}
var interactuables_por_id: Dictionary[StringName, Object] = {}
var servicio_examen: ServicioExamen

# Puntos de extension para trampas, encuentros, puertas y otros triggers.
signal celda_reservada(coord: Vector2i, contenido: Object)
signal reserva_cancelada(coord: Vector2i, contenido: Object)
signal reserva_confirmada(coord: Vector2i, contenido: Object)
signal celda_ocupada(coord: Vector2i, contenido: Object)
signal celda_desocupada(coord: Vector2i, contenido: Object)
signal interactuable_registrado(coord: Vector2i, interactuable: Interactuable)
signal interactuable_retirado(coord: Vector2i, interactuable: Interactuable)
signal iluminacion_cambiada(coord: Vector2i)

func generar_desde_zona(zona: Node2D) -> void:
	datos.clear()
	interactuables_por_id.clear()
	var _capa_suelo: TileMapLayer = zona.get_node_or_null("CapaSuelo")
	var _capa_agua: TileMapLayer = zona.get_node_or_null("CapaAgua")
	var _capa_lava: TileMapLayer = zona.get_node_or_null("CapaLava")
	var _capa_paredes: TileMapLayer = zona.get_node_or_null("CapaParedes")
	var _capa_columnas: TileMapLayer = zona.get_node_or_null("CapaColumnas")
	var _capa_deco_nocaminable: TileMapLayer = zona.get_node_or_null("CapaDecoracionNoCaminable")
	var _capa_decoracion: TileMapLayer = zona.get_node_or_null("CapaDecoracion")
	
	if not _capa_suelo:
		print("Error: No se encontró CapaSuelo")
		return
		
	# 1. Escaneamos Suelo
	var _celdas_suelo = _capa_suelo.get_used_cells()
	for coordenada in _celdas_suelo:
		datos[coordenada] = _crear_celda_desde_tile(_capa_suelo, coordenada, &"piso_vacio")

	# 2. Escaneamos Agua
	if _capa_agua:
		var _celdas_agua = _capa_agua.get_used_cells()
		for coordenada in _celdas_agua:
			var celda_agua := _crear_celda_desde_tile(_capa_agua, coordenada, &"agua")
			# La capa define el comportamiento del líquido, independientemente de su textura.
			celda_agua.caminable = false
			datos[coordenada] = celda_agua

	# 3. Escaneamos Lava
	if _capa_lava:
		var _celdas_lava = _capa_lava.get_used_cells()
		for coordenada in _celdas_lava:
			var celda_lava := _crear_celda_desde_tile(_capa_lava, coordenada, &"lava")
			celda_lava.damage = {
				"tipo": "fuego",
				"turnos": 5,
				"damage": 2
			}
			datos[coordenada] = celda_lava

	# 4. Escaneamos Paredes
	if _capa_paredes:
		var _celdas_paredes = _capa_paredes.get_used_cells()
		for coordenada in _celdas_paredes:
			datos[coordenada] = _crear_celda_desde_tile(_capa_paredes, coordenada, &"pared")
	
	# 5. Escaneamos columnas: son altas y bloquean tanto el paso como la visión.
	if _capa_columnas:
		for coordenada in _capa_columnas.get_used_cells():
			datos[coordenada] = _crear_celda_desde_tile(_capa_columnas, coordenada, &"columna")

	# 6. Escaneamos Decoraciones No Caminables
	if _capa_deco_nocaminable:
		var _celdas_decoracion = _capa_deco_nocaminable.get_used_cells()
		for coord in _celdas_decoracion:
			var celda_decoracion := _crear_celda_desde_tile(
				_capa_deco_nocaminable,
				coord,
				&"decoracion"
			)
			if datos.has(coord):
				datos[coord].caminable = datos[coord].caminable and celda_decoracion.caminable
				datos[coord].bloquea_vision = (
					datos[coord].bloquea_vision or celda_decoracion.bloquea_vision
				)
				# No degradamos una pared o columna si las capas se solapan.
				if celda_decoracion.altura > datos[coord].altura:
					datos[coord].altura = celda_decoracion.altura
					datos[coord].zona = &"decoracion"
					datos[coord].configurar_fog(
						celda_decoracion.familia_fog,
						celda_decoracion.coordenada_fog
					)
			else:
				datos[coord] = celda_decoracion

	# 7. Las decoraciones planas pueden modificar propiedades sin sustituir el terreno.
	if _capa_decoracion:
		for coord in _capa_decoracion.get_used_cells():
			if not datos.has(coord):
				continue
			var celda_decoracion := _crear_celda_desde_tile(
				_capa_decoracion,
				coord,
				&"decoracion"
			)
			datos[coord].caminable = datos[coord].caminable and celda_decoracion.caminable
			datos[coord].bloquea_vision = (
				datos[coord].bloquea_vision or celda_decoracion.bloquea_vision
			)

# --- UTILIDADES ---

func _crear_celda_desde_tile(
	capa: TileMapLayer,
	coord: Vector2i,
	zona: StringName
) -> Celda:
	var tile_data := capa.get_cell_tile_data(coord)
	if tile_data == null:
		push_warning("No se encontraron datos para el tile %s en %s" % [coord, capa.name])
		return Celda.new(zona)

	var celda := Celda.new(
		zona,
		bool(tile_data.get_custom_data(&"caminable")),
		int(tile_data.get_custom_data(&"altura"))
	)
	celda.bloquea_vision = bool(tile_data.get_custom_data(&"bloquea_vision"))
	var familia := StringName(tile_data.get_custom_data(&"familia_fog"))
	if familia == &"":
		familia = &"terreno"
	celda.configurar_fog(
		familia,
		Vector2i(
			int(tile_data.get_custom_data(&"fog_atlas_x")),
			int(tile_data.get_custom_data(&"fog_atlas_y"))
		)
	)
	return celda

func es_celda_valida(coord: Vector2i) -> bool:
	return datos.has(coord)

func es_caminable(coord: Vector2i) -> bool:
	return datos.has(coord) and datos[coord].caminable

func puede_entrar(coord: Vector2i, contenido: Object = null) -> bool:
	if not es_caminable(coord):
		return false
	var celda: Celda = datos[coord]
	for ocupante in celda.contenido:
		if ocupante != contenido:
			return false
	for reserva in celda.reservas:
		if reserva != contenido:
			return false
	return true

func obtener_celda(coord: Vector2i) -> Celda:
	return datos.get(coord) as Celda

func configurar_servicio_examen(nuevo_servicio: ServicioExamen) -> void:
	servicio_examen = nuevo_servicio
	for interactuable in interactuables_por_id.values():
		if is_instance_valid(interactuable):
			interactuable.configurar_servicio_examen(servicio_examen)

func registrar_interactuables_desde_zona(
	zona: Node2D,
	capa_referencia: TileMapLayer
) -> bool:
	var registro_valido := true
	for nodo in zona.find_children("*", "", true, false):
		if not nodo is Interactuable:
			continue
		var interactuable := nodo as Interactuable
		var posicion_en_capa := capa_referencia.to_local(interactuable.global_position)
		var coord := capa_referencia.local_to_map(posicion_en_capa)
		if not registrar_interactuable(coord, interactuable):
			registro_valido = false
	return registro_valido

func registrar_interactuable(coord: Vector2i, interactuable: Interactuable) -> bool:
	var motivo := validar_registro_interactuable(coord, interactuable)
	if motivo == &"interactuable_invalido":
		push_error("No se puede registrar un interactuable invalido.")
		return false
	if motivo == &"id_instancia_vacio":
		push_error("El interactuable en %s no tiene id_instancia." % coord)
		return false
	if motivo == &"celda_invalida":
		push_error("El interactuable %s esta fuera del tablero: %s." % [
			interactuable.id_instancia, coord
		])
		return false
	if motivo == &"id_instancia_duplicado":
		push_warning("ID de interactuable duplicado: %s." % interactuable.id_instancia)
		return false

	interactuables_por_id[interactuable.id_instancia] = interactuable
	datos[coord].interactuables.append(interactuable)
	interactuable.configurar_registro(self, coord)
	if servicio_examen != null:
		interactuable.configurar_servicio_examen(servicio_examen)
	if interactuable is FuenteLuzInteractuable:
		registrar_luz(coord, interactuable)
	interactuable_registrado.emit(coord, interactuable)
	return true

func validar_registro_interactuable(
	coord: Vector2i,
	interactuable: Interactuable
) -> StringName:
	if interactuable == null or not is_instance_valid(interactuable):
		return &"interactuable_invalido"
	if interactuable.id_instancia == &"":
		return &"id_instancia_vacio"
	if not datos.has(coord):
		return &"celda_invalida"
	if interactuables_por_id.has(interactuable.id_instancia):
		return &"id_instancia_duplicado"
	return &""

func retirar_interactuable(interactuable: Interactuable) -> void:
	if interactuable == null or not is_instance_valid(interactuable):
		return
	var coord := interactuable.coordenada_mapa
	if datos.has(coord):
		datos[coord].interactuables.erase(interactuable)
		if interactuable is FuenteLuzInteractuable:
			eliminar_luz(coord, interactuable)
	interactuables_por_id.erase(interactuable.id_instancia)
	interactuable_retirado.emit(coord, interactuable)

func obtener_interactuable(id_instancia: StringName) -> Interactuable:
	return interactuables_por_id.get(id_instancia) as Interactuable

func ocupar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido not in datos[coord].contenido:
			datos[coord].contenido.append(contenido)
			celda_ocupada.emit(coord, contenido)

func liberar_celda(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord):
		if contenido != null:
			if contenido in datos[coord].contenido:
				datos[coord].contenido.erase(contenido)
				celda_desocupada.emit(coord, contenido)
		else:
			for ocupante in datos[coord].contenido.duplicate():
				celda_desocupada.emit(coord, ocupante)
			datos[coord].contenido.clear()

func reservar_celda(coord: Vector2i, contenido: Object) -> bool:
	if contenido == null or not puede_entrar(coord, contenido):
		return false
	if contenido not in datos[coord].reservas:
		datos[coord].reservas.append(contenido)
		celda_reservada.emit(coord, contenido)
	return true

func cancelar_reserva(coord: Vector2i, contenido: Object) -> void:
	if datos.has(coord) and contenido in datos[coord].reservas:
		datos[coord].reservas.erase(contenido)
		reserva_cancelada.emit(coord, contenido)

func confirmar_movimiento(origen: Vector2i, destino: Vector2i, contenido: Object) -> bool:
	if not datos.has(destino) or contenido not in datos[destino].reservas:
		return false
	datos[destino].reservas.erase(contenido)
	reserva_confirmada.emit(destino, contenido)
	liberar_celda(origen, contenido)
	ocupar_celda(destino, contenido)
	return true

func registrar_luz(coord: Vector2i, fuente: FuenteLuzInteractuable) -> void:
	if not datos.has(coord) or fuente == null:
		return
	if fuente not in datos[coord].iluminacion:
		datos[coord].iluminacion.append(fuente)
	var definicion_luz := fuente.obtener_definicion_luz()
	if definicion_luz != null:
		datos[coord].caminable = datos[coord].caminable and definicion_luz.permite_caminar
		datos[coord].bloquea_vision = (
			datos[coord].bloquea_vision or definicion_luz.bloquea_vision
		)
		if definicion_luz.familia_fog == &"luz" and datos[coord].altura < 2:
			datos[coord].altura = maxi(datos[coord].altura, definicion_luz.altura)
			datos[coord].configurar_fog(&"luz", definicion_luz.coordenada_fog)
	if not fuente.estado_luz_cambiado.is_connected(_on_estado_luz_cambiado.bind(fuente)):
		fuente.estado_luz_cambiado.connect(_on_estado_luz_cambiado.bind(fuente))
	iluminacion_cambiada.emit(coord)

func eliminar_luz(coord: Vector2i, fuente: FuenteLuzInteractuable) -> void:
	if datos.has(coord):
		datos[coord].iluminacion.erase(fuente)
	iluminacion_cambiada.emit(coord)

func obtener_luces_visibles() -> Array:
	var luces: Array = []
	for coord in datos:
		for luz in datos[coord].iluminacion:
			if is_instance_valid(luz) and luz.encendida:
				luces.append({
					"coord": coord,
					"info": luz
				})
	return luces

func _on_estado_luz_cambiado(_encendida: bool, fuente: FuenteLuzInteractuable) -> void:
	if is_instance_valid(fuente):
		iluminacion_cambiada.emit(fuente.coordenada_mapa)
