extends Node
class_name FOVManager

const ALCANCE_PERCEPCION_ILUMINADA := 7

var capa_oscuridad: TileMapLayer
var datos_tablero: Dictionary
var celdas_visibles_actuales: Array[Vector2i] = []
var tablero: TableroGrid
var ultimo_centro_jugador: Vector2i
var ultimo_radio_jugador: int = 0
var tiene_vision_calculada: bool = false
var revision_vision: int = 0
var _opacidad_por_celda: Dictionary[Vector2i, bool] = {}
enum NivelLuz { OSCURIDAD, PENUMBRA, LUZ }
var iluminacion_actual: Dictionary[Vector2i, int] = {}
var iluminacion_fuentes_percibidas: Dictionary[Vector2i, int] = {}
var _validador_espacial: ValidadorEspacialTablero

const FUENTES_FOG_EXPLORADO := {
	&"terreno": 0,
	&"pared": 2,
	&"pared_alta": 10,
	&"pared_alta_esquina": 12,
	&"columna": 4,
	&"estalagmita": 6,
	&"roca": 14,
	&"ruina": 16,
	&"luz": 8,
}

const FUENTES_FOG_OCULTO := {
	&"terreno": 1,
	&"pared": 3,
	&"pared_alta": 11,
	&"pared_alta_esquina": 13,
	&"columna": 5,
	&"estalagmita": 7,
	&"roca": 15,
	&"ruina": 17,
	&"luz": 9,
}

func inicializar(_capa: TileMapLayer, origen_datos: Variant) -> void:
	capa_oscuridad = _capa
	celdas_visibles_actuales.clear()
	iluminacion_actual.clear()
	iluminacion_fuentes_percibidas.clear()
	tiene_vision_calculada = false
	ultimo_radio_jugador = 0
	_opacidad_por_celda.clear()
	if origen_datos is TableroGrid:
		tablero = origen_datos
		_validador_espacial = ValidadorEspacialTablero.new(tablero)
		datos_tablero = tablero.datos
		if not tablero.iluminacion_cambiada.is_connected(_on_iluminacion_cambiada):
			tablero.iluminacion_cambiada.connect(_on_iluminacion_cambiada)
		if not tablero.efecto_superficie_registrado.is_connected(_on_superficie_cambiada):
			tablero.efecto_superficie_registrado.connect(_on_superficie_cambiada)
		if not tablero.efecto_superficie_retirado.is_connected(_on_superficie_cambiada):
			tablero.efecto_superficie_retirado.connect(_on_superficie_cambiada)
		if not tablero.interactuable_registrado.is_connected(_on_superficie_cambiada):
			tablero.interactuable_registrado.connect(_on_superficie_cambiada)
		if not tablero.interactuable_retirado.is_connected(_on_superficie_cambiada):
			tablero.interactuable_retirado.connect(_on_superficie_cambiada)
		if not tablero.presencia_interactuable_cambiada.is_connected(
			_on_presencia_interactuable_cambiada
		):
			tablero.presencia_interactuable_cambiada.connect(
				_on_presencia_interactuable_cambiada
			)
	else:
		tablero = null
		_validador_espacial = null
		datos_tablero = origen_datos
	
	# Al iniciar, cubrimos todo el mapa conocido de negro total
	for coord in datos_tablero.keys():
		_opacidad_por_celda[coord] = datos_tablero[coord].bloquea_vision_efectiva()
		_oscurecer_celda(coord, Celda.EstadoVisibilidad.OCULTO)
	_actualizar_presentacion_interactuables()

func reconstruir_niebla_restaurada() -> void:
	# El snapshot conserva conocimiento; la visibilidad actual se recalcula después.
	celdas_visibles_actuales.clear()
	for coord: Vector2i in datos_tablero:
		_oscurecer_celda(coord, datos_tablero[coord].visibilidad)


func actualizar_vision(centro_jugador: Vector2i, radio_jugador: int) -> void:
	ultimo_centro_jugador = centro_jugador
	ultimo_radio_jugador = radio_jugador
	tiene_vision_calculada = true
	# 1. Sombreamos (al 60%) todo lo que estuvo visible en el paso anterior
	for coord in celdas_visibles_actuales:
		_oscurecer_celda(coord, Celda.EstadoVisibilidad.EXPLORADO)
			
	celdas_visibles_actuales.clear()
	iluminacion_actual.clear()
	iluminacion_fuentes_percibidas.clear()

	# 2. Proyectamos primero todas las fuentes de luz encendidas del mapa
	_procesar_luces_mapa()

	# 3. Proyectamos la luz del jugador (+1 casilla de penumbra)
	proyectar_luz_fuente(centro_jugador, radio_jugador, 1, false)
	_actualizar_conocimiento_jugador()
	_actualizar_presentacion_interactuables()
	revision_vision += 1

func _procesar_luces_mapa() -> void:
	for coord in datos_tablero.keys():
		var lista_luces: Array[Object] = datos_tablero[coord].iluminacion
		for fuente in lista_luces:
			if not is_instance_valid(fuente):
				continue
			if fuente is FuenteLuzInteractuable:
				var definicion: DefinicionFuenteLuz = fuente.obtener_definicion_luz()
				if fuente.encendida and definicion != null:
					proyectar_luz_fuente(
						coord, definicion.radio_luz, definicion.radio_penumbra,
						definicion.atraviesa_muros, _fuente_percibida_directamente(coord)
					)
				continue
			if (
				fuente.has_method(&"esta_encendida")
				and fuente.has_method(&"obtener_radio_luz")
				and fuente.has_method(&"obtener_radio_penumbra")
				and fuente.has_method(&"luz_atraviesa_muros")
				and fuente.call(&"esta_encendida")
			):
				proyectar_luz_fuente(
					coord, fuente.call(&"obtener_radio_luz"),
					fuente.call(&"obtener_radio_penumbra"),
					fuente.call(&"luz_atraviesa_muros"), _fuente_percibida_directamente(coord)
				)

func _on_iluminacion_cambiada(_coord: Vector2i) -> void:
	if tiene_vision_calculada:
		actualizar_vision(ultimo_centro_jugador, ultimo_radio_jugador)

func _on_superficie_cambiada(coord: Vector2i, elemento: Object) -> void:
	var coordenadas: Array[Vector2i] = [coord]
	if elemento is Interactuable:
		coordenadas = elemento.obtener_coordenadas_ocupadas(coord)
	_actualizar_opacidad(coordenadas)

func _on_presencia_interactuable_cambiada(coord: Vector2i) -> void:
	_actualizar_opacidad([coord])

func _actualizar_opacidad(coordenadas: Array[Vector2i]) -> void:
	var cambio := false
	for coord in coordenadas:
		var celda: Celda = datos_tablero.get(coord)
		var opaca := celda != null and celda.bloquea_vision_efectiva()
		cambio = cambio or _opacidad_por_celda.get(coord, false) != opaca
		_opacidad_por_celda[coord] = opaca
	# Ocupación y reservas no alteran los rayos si la opacidad sigue igual.
	if cambio and tiene_vision_calculada:
		actualizar_vision(ultimo_centro_jugador, ultimo_radio_jugador)

# --- MATEMÁTICAS Y RAYCASTING ---

func _obtener_area_circulo(centro: Vector2i, radio: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for x in range(-radio, radio + 1):
		for y in range(-radio, radio + 1):
			if Vector2(x, y).length() <= radio + 0.5: 
				area.append(centro + Vector2i(x, y))
	return area

func _trazar_linea_bresenham(p0: Vector2i, p1: Vector2i) -> Array[Vector2i]:
	return GeometriaGrid.trazar_linea(p0, p1)

# --- PROYECTOR DE LUZ GENERICO ---
func proyectar_luz_fuente(centro: Vector2i, radio_luz: int, radio_penumbra: int, atraviesa_muros: bool = false, fuente_percibida: bool = false) -> void:
	var radio_total = radio_luz + radio_penumbra
	var celdas_area = _obtener_area_circulo(centro, radio_total)

	for destino in celdas_area:
		var linea = _trazar_linea_bresenham(centro, destino)
		
		for indice in linea.size():
			var coord: Vector2i = linea[indice]
			if (
				not atraviesa_muros
				and indice > 0
				and _esquina_bloquea_vision(linea[indice - 1], coord)
			):
				break
			# Si choca con pared y la luz no atraviesa muros, iluminamos la pared y cortamos el rayo
			if (
				not atraviesa_muros
				and datos_tablero.has(coord)
				and datos_tablero[coord].bloquea_vision_efectiva()
			):
				_aplicar_nivel_luz(coord, centro, radio_luz, fuente_percibida)
				break
				
			_aplicar_nivel_luz(coord, centro, radio_luz, fuente_percibida)

func _esquina_bloquea_vision(origen: Vector2i, destino: Vector2i) -> bool:
	var flancos := GeometriaGrid.flancos_paso_diagonal(origen, destino)
	return (
		flancos.size() == 2
		and datos_tablero.has(flancos[0])
		and datos_tablero.has(flancos[1])
		and datos_tablero[flancos[0]].bloquea_vision_efectiva()
		and datos_tablero[flancos[1]].bloquea_vision_efectiva()
	)

func _aplicar_nivel_luz(coord: Vector2i, centro: Vector2i, radio_luz: int, fuente_percibida: bool) -> void:
	if not datos_tablero.has(coord):
		return
	var distancia := int(Vector2(coord - centro).length())
	var nivel := NivelLuz.LUZ if distancia <= radio_luz else NivelLuz.PENUMBRA
	iluminacion_actual[coord] = maxi(iluminacion_actual.get(coord, NivelLuz.OSCURIDAD), nivel)
	if fuente_percibida:
		iluminacion_fuentes_percibidas[coord] = maxi(
			iluminacion_fuentes_percibidas.get(coord, NivelLuz.OSCURIDAD), nivel
		)

func _en_alcance_normal(coord: Vector2i) -> bool:
	var alcance := maxi(ALCANCE_PERCEPCION_ILUMINADA, ultimo_radio_jugador)
	return (coord - ultimo_centro_jugador).length_squared() <= alcance * alcance

func _fuente_percibida_directamente(coord: Vector2i) -> bool:
	# La elegibilidad no usa visibilidad ampliada ni recuerdos: no encadena fuentes.
	return _en_alcance_normal(coord) and _tiene_linea_visual_jugador(coord)

func _actualizar_conocimiento_jugador() -> void:
	for coord: Vector2i in iluminacion_actual:
		var nivel: int = iluminacion_actual[coord]
		if not _en_alcance_normal(coord):
			nivel = iluminacion_fuentes_percibidas.get(coord, NivelLuz.OSCURIDAD)
		if nivel == NivelLuz.OSCURIDAD:
			continue
		if not _tiene_linea_visual_jugador(coord):
			continue
		if nivel == NivelLuz.LUZ:
			_revelar_celda(coord)
		else:
			# shortcut: conservar penumbra explorada hasta acordar su presentación definitiva.
			_oscurecer_celda(coord, Celda.EstadoVisibilidad.EXPLORADO)

func _tiene_linea_visual_jugador(destino: Vector2i) -> bool:
	if _validador_espacial != null:
		return _validador_espacial.validar_linea_visual(ultimo_centro_jugador, destino) == &""
	# Compatibilidad con la inicialización por diccionario sin TableroGrid.
	if not datos_tablero.has(ultimo_centro_jugador):
		return false
	var linea := _trazar_linea_bresenham(ultimo_centro_jugador, destino)
	for indice in range(1, linea.size()):
		if _esquina_bloquea_vision(linea[indice - 1], linea[indice]):
			return false
		if indice < linea.size() - 1 and (
			not datos_tablero.has(linea[indice])
			or datos_tablero[linea[indice]].bloquea_vision_efectiva()
		):
			return false
	return true

func _revelar_celda(coord: Vector2i) -> void:
	capa_oscuridad.erase_cell(coord)
	if not coord in celdas_visibles_actuales:
		celdas_visibles_actuales.append(coord)
	if datos_tablero.has(coord):
		datos_tablero[coord].visibilidad = Celda.EstadoVisibilidad.VISIBLE

func _oscurecer_celda(coord: Vector2i, estado: int) -> void:
	if not datos_tablero.has(coord):
		return
		
	var celda: Celda = datos_tablero[coord]
	celda.visibilidad = estado
	var fuentes: Dictionary = FUENTES_FOG_OCULTO
	if estado == Celda.EstadoVisibilidad.EXPLORADO:
		fuentes = FUENTES_FOG_EXPLORADO

	var familia := celda.familia_fog
	var coordenada_fog := celda.coordenada_fog
	var source_id: int = fuentes.get(familia, fuentes[&"terreno"])
	capa_oscuridad.set_cell(coord, source_id, coordenada_fog)

func _actualizar_presentacion_interactuables() -> void:
	if tablero == null:
		return
	for interactuable in tablero.interactuables_por_id.values():
		if not is_instance_valid(interactuable):
			continue
		var estado := Celda.EstadoVisibilidad.OCULTO
		for coord in interactuable.obtener_coordenadas_ocupadas():
			if datos_tablero.has(coord):
				estado = maxi(estado, datos_tablero[coord].visibilidad)
		interactuable.actualizar_presentacion_visibilidad(estado)
