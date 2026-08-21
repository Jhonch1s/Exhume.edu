class_name ValidadorEspacialTablero
extends RefCounted

var tablero: TableroGrid


func _init(tablero_inicial: TableroGrid = null) -> void:
	tablero = tablero_inicial


func configurar_tablero(nuevo_tablero: TableroGrid) -> void:
	tablero = nuevo_tablero


func validar_linea_efecto(contexto: ContextoAccion) -> StringName:
	match contexto.tipo_linea_efecto:
		TiposInteraccion.TipoLineaEfecto.NINGUNA:
			return &""
		TiposInteraccion.TipoLineaEfecto.VISUAL:
			return _validar_linea_visual(contexto)
		TiposInteraccion.TipoLineaEfecto.FISICA:
			return _validar_linea_fisica(contexto)
		_:
			return &"tipo_linea_efecto_invalido"


func _validar_linea_visual(contexto: ContextoAccion) -> StringName:
	if tablero == null or not is_instance_valid(tablero):
		return &"tablero_espacial_no_configurado"
	if not contexto.tiene_origen() or not contexto.tiene_celda_objetivo():
		return &"coordenadas_incompletas"

	var origen: Vector2i = contexto.origen
	var destino: Vector2i = contexto.celda_objetivo
	if not tablero.es_celda_valida(origen) or not tablero.es_celda_valida(destino):
		return &"celda_espacial_invalida"

	var linea := GeometriaGrid.trazar_linea(origen, destino)
	for indice in range(1, linea.size() - 1):
		var coordenada := linea[indice]
		if not tablero.es_celda_valida(coordenada):
			return &"linea_fuera_del_tablero"
		var celda := tablero.obtener_celda(coordenada)
		if celda == null:
			return &"linea_fuera_del_tablero"
		if celda.bloquea_vision_efectiva():
			return &"linea_de_efecto_bloqueada"

	return &""


func _validar_linea_fisica(contexto: ContextoAccion) -> StringName:
	var motivo := _validar_extremos(contexto)
	if motivo != &"":
		return motivo
	var linea := GeometriaGrid.trazar_linea(contexto.origen, contexto.celda_objetivo)
	for indice in range(1, linea.size() - 1):
		var celda := tablero.obtener_celda(linea[indice])
		if celda == null:
			return &"linea_fuera_del_tablero"
		if celda.bloquea_proyectiles_efectiva():
			return &"linea_de_efecto_bloqueada"
	return &""


func resolver_trayectoria_lanzamiento(
	origen: Vector2i,
	destino: Vector2i,
	alcance: float
) -> Dictionary:
	if (
		tablero == null
		or not is_instance_valid(tablero)
		or alcance < 0.0
		or not tablero.es_celda_valida(origen)
		or not tablero.es_celda_valida(destino)
	):
		return {}
	var recorrido: Array[Vector2i] = [origen]
	var ultima_libre := origen
	for coordenada in GeometriaGrid.trazar_linea(origen, destino).slice(1):
		if not tablero.es_celda_valida(coordenada):
			return {}
		if _distancia_cuadricula(origen, coordenada) > alcance:
			return {
				&"destino_alcanzado": false,
				&"hubo_colision": false,
				&"celda_impacto": ultima_libre,
				&"celda_caida": ultima_libre,
				&"recorrido": recorrido,
			}
		recorrido.append(coordenada)
		if tablero.obtener_celda(coordenada).bloquea_proyectiles_efectiva():
			return {
				&"destino_alcanzado": coordenada == destino,
				&"hubo_colision": true,
				&"celda_impacto": coordenada,
				&"celda_caida": ultima_libre,
				&"recorrido": recorrido,
			}
		ultima_libre = coordenada
	return {
		&"destino_alcanzado": true,
		&"hubo_colision": false,
		&"celda_impacto": destino,
		&"celda_caida": destino,
		&"recorrido": recorrido,
	}


func _validar_extremos(contexto: ContextoAccion) -> StringName:
	if tablero == null or not is_instance_valid(tablero):
		return &"tablero_espacial_no_configurado"
	if not contexto.tiene_origen() or not contexto.tiene_celda_objetivo():
		return &"coordenadas_incompletas"
	if (
		not tablero.es_celda_valida(contexto.origen)
		or not tablero.es_celda_valida(contexto.celda_objetivo)
	):
		return &"celda_espacial_invalida"
	return &""


func _distancia_cuadricula(origen: Vector2i, destino: Vector2i) -> float:
	return float(maxi(abs(destino.x - origen.x), abs(destino.y - origen.y)))
