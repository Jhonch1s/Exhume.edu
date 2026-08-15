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
			return &"linea_fisica_no_implementada"
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
		if celda.bloquea_vision:
			return &"linea_de_efecto_bloqueada"

	return &""
