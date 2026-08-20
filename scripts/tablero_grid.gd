extends Node
class_name TableroGrid

var datos: Dictionary[Vector2i, Celda] = {}
var interactuables_por_id: Dictionary[StringName, Object] = {}
var efectos_superficie_por_id: Dictionary[StringName, Object] = {}
var items_suelo_por_id: Dictionary[StringName, ItemSuelo] = {}
var servicio_examen: ServicioExamen
var transferidor_items: TransferidorItems
var zona_referencia: Node2D
var capa_referencia: TileMapLayer

# Puntos de extension para trampas, encuentros, puertas y otros triggers.
signal celda_reservada(coord: Vector2i, contenido: Object)
signal reserva_cancelada(coord: Vector2i, contenido: Object)
signal reserva_confirmada(coord: Vector2i, contenido: Object)
signal celda_ocupada(coord: Vector2i, contenido: Object)
signal celda_desocupada(coord: Vector2i, contenido: Object)
signal interactuable_registrado(coord: Vector2i, interactuable: Interactuable)
signal interactuable_retirado(coord: Vector2i, interactuable: Interactuable)
signal presencia_interactuable_cambiada(coord: Vector2i)
signal efecto_superficie_registrado(coord: Vector2i, efecto: Object)
signal efecto_superficie_retirado(coord: Vector2i, efecto: Object)
signal item_suelo_registrado(coord: Vector2i, item_suelo: ItemSuelo)
signal item_suelo_retirado(coord: Vector2i, item_suelo: ItemSuelo)
signal iluminacion_cambiada(coord: Vector2i)

func generar_desde_zona(zona: Node2D) -> void:
	zona_referencia = zona
	_limpiar_items_suelo()
	datos.clear()
	interactuables_por_id.clear()
	efectos_superficie_por_id.clear()
	var _capa_suelo: TileMapLayer = zona.get_node_or_null("CapaSuelo")
	capa_referencia = _capa_suelo
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
			celda_lava.penalizacion_peligro_ruta = 4.0
			celda_lava.reaccion_terreno = TerrenoDanino.new(
				&"lava",
				coordenada,
				2
			)
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
	if capa.tile_set.get_custom_data_layer_by_name(&"coste_movimiento_adicional") >= 0:
		celda.coste_movimiento_adicional = maxi(
			0,
			int(tile_data.get_custom_data(&"coste_movimiento_adicional"))
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
	return datos.has(coord) and datos[coord].es_caminable_efectiva()

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

func configurar_transferidor_items(nuevo_transferidor: TransferidorItems) -> void:
	transferidor_items = nuevo_transferidor
	for item_suelo in items_suelo_por_id.values():
		if item_suelo != null:
			item_suelo.configurar_transferidor_items(transferidor_items)

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
	var cambio_presencia := _on_presencia_interactuable_cambiada.bind(interactuable)
	if not interactuable.presencia_cambiada.is_connected(cambio_presencia):
		interactuable.presencia_cambiada.connect(cambio_presencia)
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
	var cambio_presencia := _on_presencia_interactuable_cambiada.bind(interactuable)
	if interactuable.presencia_cambiada.is_connected(cambio_presencia):
		interactuable.presencia_cambiada.disconnect(cambio_presencia)
	interactuables_por_id.erase(interactuable.id_instancia)
	interactuable_retirado.emit(coord, interactuable)

func _on_presencia_interactuable_cambiada(interactuable: Interactuable) -> void:
	if (
		interactuable == null
		or not is_instance_valid(interactuable)
		or interactuables_por_id.get(interactuable.id_instancia) != interactuable
	):
		return
	presencia_interactuable_cambiada.emit(interactuable.coordenada_mapa)

func obtener_interactuable(id_instancia: StringName) -> Interactuable:
	return interactuables_por_id.get(id_instancia) as Interactuable

func validar_registro_item_suelo(
	coord: Vector2i,
	item_suelo: ItemSuelo
) -> StringName:
	if item_suelo == null:
		return &"item_suelo_invalido"
	if not item_suelo.es_valido():
		return &"item_invalido"
	if not datos.has(coord):
		return &"celda_invalida"
	if item_suelo.esta_registrado:
		return &"item_suelo_ya_registrado"
	if items_suelo_por_id.has(item_suelo.item.id_instancia):
		return &"id_item_duplicado"
	# ponytail: búsqueda lineal suficiente; añadir índice inverso si el tablero la hace costosa.
	for celda in datos.values():
		if item_suelo in celda.items_suelo:
			return &"registro_item_incoherente"
	return &""

func registrar_item_suelo(coord: Vector2i, item_suelo: ItemSuelo) -> bool:
	if validar_registro_item_suelo(coord, item_suelo) != &"":
		return false
	items_suelo_por_id[item_suelo.item.id_instancia] = item_suelo
	datos[coord].items_suelo.append(item_suelo)
	datos[coord].items_suelo.sort_custom(func(a: ItemSuelo, b: ItemSuelo):
		return String(a.item.id_instancia) < String(b.item.id_instancia)
	)
	item_suelo._configurar_registro(coord)
	if transferidor_items != null:
		item_suelo.configurar_transferidor_items(transferidor_items)
	item_suelo_registrado.emit(coord, item_suelo)
	return true

func validar_retiro_item_suelo(item_suelo: ItemSuelo) -> StringName:
	if item_suelo == null or not item_suelo.es_valido():
		return &"item_suelo_invalido"
	if not item_suelo.esta_registrado or not item_suelo.coordenada_mapa is Vector2i:
		return &"item_suelo_no_registrado"
	var coord: Vector2i = item_suelo.coordenada_mapa
	if (
		not datos.has(coord)
		or items_suelo_por_id.get(item_suelo.item.id_instancia) != item_suelo
		or item_suelo not in datos[coord].items_suelo
	):
		return &"registro_item_incoherente"
	return &""

func retirar_item_suelo(item_suelo: ItemSuelo) -> bool:
	if validar_retiro_item_suelo(item_suelo) != &"":
		return false
	var coord: Vector2i = item_suelo.coordenada_mapa
	datos[coord].items_suelo.erase(item_suelo)
	items_suelo_por_id.erase(item_suelo.item.id_instancia)
	item_suelo._limpiar_registro()
	item_suelo_retirado.emit(coord, item_suelo)
	return true

func obtener_item_suelo(id_instancia: StringName) -> ItemSuelo:
	return items_suelo_por_id.get(id_instancia)

func validar_colocacion_item_suelo(coord: Vector2i, actor: Object = null) -> StringName:
	if not datos.has(coord):
		return &"celda_invalida"
	var celda: Celda = datos[coord]
	if not celda.es_caminable_efectiva():
		return &"celda_no_caminable"
	for ocupante in celda.ocupantes:
		if ocupante != actor:
			return &"celda_ocupada"
	for reserva in celda.reservas:
		if reserva != actor:
			return &"celda_reservada"
	return &""

func _limpiar_items_suelo() -> void:
	for item_suelo in items_suelo_por_id.values():
		if item_suelo != null:
			item_suelo._limpiar_registro()
	for celda in datos.values():
		celda.items_suelo.clear()
	items_suelo_por_id.clear()

func registrar_efectos_superficie_desde_zona(
	zona: Node2D,
	capa_referencia: TileMapLayer
) -> bool:
	var registro_valido := true
	for nodo in zona.find_children("*", "", true, false):
		if not nodo.is_in_group(&"efectos_superficie"):
			continue
		var posicion_en_capa := capa_referencia.to_local(nodo.global_position)
		var coord := capa_referencia.local_to_map(posicion_en_capa)
		if not registrar_efecto_superficie(coord, nodo):
			registro_valido = false
	return registro_valido

func registrar_efecto_superficie(coord: Vector2i, efecto: Object) -> bool:
	if efecto == null or not is_instance_valid(efecto):
		return false
	if (
		not efecto.has_method(&"obtener_id_reaccion")
		or not efecto.has_method(&"configurar_registro")
	):
		return false
	var id_efecto: Variant = efecto.call(&"obtener_id_reaccion")
	if (
		not id_efecto is StringName
		or id_efecto == &""
		or not datos.has(coord)
		or efectos_superficie_por_id.has(id_efecto)
	):
		return false
	efectos_superficie_por_id[id_efecto] = efecto
	datos[coord].efectos_superficie.append(efecto)
	efecto.call(&"configurar_registro", self, coord)
	efecto_superficie_registrado.emit(coord, efecto)
	return true

func retirar_efecto_superficie(efecto: Object) -> bool:
	if (
		efecto == null
		or not is_instance_valid(efecto)
		or not efecto.has_method(&"obtener_id_reaccion")
		or not efecto.has_method(&"obtener_coordenada_reaccion")
	):
		return false
	var id_efecto: Variant = efecto.call(&"obtener_id_reaccion")
	var coord: Variant = efecto.call(&"obtener_coordenada_reaccion")
	if (
		not id_efecto is StringName
		or not coord is Vector2i
		or efectos_superficie_por_id.get(id_efecto) != efecto
	):
		return false
	if datos.has(coord):
		datos[coord].efectos_superficie.erase(efecto)
	efectos_superficie_por_id.erase(id_efecto)
	efecto_superficie_retirado.emit(coord, efecto)
	return true

func desplegar_efecto_superficie(
	escena: PackedScene,
	centro: Vector2i,
	radio: int,
	prefijo_id: StringName
) -> Array[Vector2i]:
	var coordenadas: Array[Vector2i] = []
	if (
		escena == null
		or radio < 0
		or prefijo_id == &""
		or zona_referencia == null
		or capa_referencia == null
	):
		return coordenadas
	var contenedor := zona_referencia.get_node_or_null("EfectosSuperficie") as Node2D
	if contenedor == null:
		return coordenadas

	for desplazamiento_y in range(-radio, radio + 1):
		for desplazamiento_x in range(-radio, radio + 1):
			var coord := centro + Vector2i(desplazamiento_x, desplazamiento_y)
			if (
				not datos.has(coord)
				or not datos[coord].caminable
				or abs(desplazamiento_x) + abs(desplazamiento_y) > radio
			):
				continue
			var efecto := escena.instantiate() as Node2D
			if efecto == null or not efecto.has_method(&"configurar_id_instancia"):
				if efecto != null:
					efecto.free()
				continue
			var id_efecto := StringName("%s_%d_%d" % [prefijo_id, coord.x, coord.y])
			efecto.call(&"configurar_id_instancia", id_efecto)
			contenedor.add_child(efecto)
			efecto.global_position = capa_referencia.to_global(
				capa_referencia.map_to_local(coord)
			)
			if registrar_efecto_superficie(coord, efecto):
				coordenadas.append(coord)
			else:
				efecto.queue_free()
	return coordenadas

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
