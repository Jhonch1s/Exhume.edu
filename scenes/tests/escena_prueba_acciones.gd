extends Node2D

const ObjetoExaminablePrueba = preload("res://scenes/tests/objeto_examinable_prueba.gd")
const RegistroAccionesDesarrolloScript = preload(
	"res://scripts/interacciones/debug/registro_acciones_desarrollo.gd"
)
const COORDENADA_FICHA := Vector2i(0, -1)
const COORDENADA_OBJETO := Vector2i(4, -1)

@export var ejecutar_automaticamente: bool = false

@onready var capa_suelo: TileMapLayer = $CapaSuelo
@onready var tablero: TableroGrid = $TableroGrid
@onready var ficha: Ficha = $Ficha
@onready var objeto_prueba: ObjetoExaminablePrueba = $Interactuables/ObjetoPrueba
@onready var gestor_acciones: GestorAcciones = $GestorAcciones
@onready var registro_acciones: RegistroAccionesDesarrolloScript = (
	$RegistroAccionesDesarrollo
)

var camara_prueba: Camera2D
var etiqueta_estado: Label
var ultimo_resultado: ResultadoAccion


func _ready() -> void:
	tablero.generar_desde_zona(self)
	gestor_acciones.configurar_validador_espacial(
		ValidadorEspacialTablero.new(tablero)
	)
	gestor_acciones.configurar_proveedor_costes(ProveedorCostesFicha.new())
	registro_acciones.observar_gestor(gestor_acciones)
	ficha.inicializar(COORDENADA_FICHA, capa_suelo)
	tablero.ocupar_celda(ficha.coordenada_mapa, ficha)
	objeto_prueba.inicializar(COORDENADA_OBJETO, capa_suelo)
	tablero.ocupar_celda(objeto_prueba.coordenada_mapa, objeto_prueba)
	_crear_camara_prueba()
	_crear_interfaz_prueba()
	print("EscenaPruebaAcciones: %d celdas logicas generadas." % tablero.datos.size())
	print("EscenaPruebaAcciones: coordenadas=%s." % [capa_suelo.get_used_cells()])
	print(
		"EscenaPruebaAcciones: ficha en %s, energia=%d."
		% [ficha.coordenada_mapa, ficha.energia_actual]
	)
	print(
		"EscenaPruebaAcciones: objeto examinable en %s."
		% objeto_prueba.coordenada_mapa
	)
	print("EscenaPruebaAcciones: servicios del gestor configurados.")
	print(
		"EscenaPruebaAcciones: Espacio/Enter=examinar, B=bloqueo, R=reiniciar."
	)
	_actualizar_interfaz()
	if ejecutar_automaticamente:
		_ejecutar_prueba_examinar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and (evento as InputEventKey).echo:
		return

	if evento.is_action_pressed(&"ui_accept"):
		_ejecutar_prueba_examinar()
		get_viewport().set_input_as_handled()
		return

	if evento is InputEventKey:
		var tecla: InputEventKey = evento
		if tecla.pressed and not tecla.echo:
			match tecla.keycode:
				KEY_B:
					_ejecutar_prueba_bloqueo_costes()
					get_viewport().set_input_as_handled()
				KEY_R:
					_reiniciar_prueba()
					get_viewport().set_input_as_handled()


func _ejecutar_prueba_examinar() -> void:
	var energia_anterior: int = ficha.energia_actual
	var examinado_anterior: bool = objeto_prueba.fue_examinado
	ultimo_resultado = gestor_acciones.procesar_accion(
		_crear_contexto_examinar(&"examinar_objeto_prueba", 1.0)
	)

	print(
		"[PRUEBA][EXAMINAR] estado=%s energia=%d->%d examinado=%s->%s"
		% [
			TiposInteraccion.EstadoResolucion.keys()[ultimo_resultado.estado],
			energia_anterior,
			ficha.energia_actual,
			str(examinado_anterior).to_lower(),
			str(objeto_prueba.fue_examinado).to_lower(),
		]
	)
	if (
		not ultimo_resultado.exitosa
		or ficha.energia_actual != energia_anterior - 1
		or not objeto_prueba.fue_examinado
	):
		push_error("EscenaPruebaAcciones: el flujo EXAMINAR no produjo el estado esperado.")
	_actualizar_interfaz()


func _ejecutar_prueba_bloqueo_costes() -> void:
	_reiniciar_prueba()
	var energia_anterior: int = ficha.energia_actual
	var examinado_anterior: bool = objeto_prueba.fue_examinado
	var coste_imposible := float(energia_anterior + 1)
	ultimo_resultado = gestor_acciones.procesar_accion(
		_crear_contexto_examinar(&"examinar_sin_energia", coste_imposible)
	)

	print(
		"[PRUEBA][BLOQUEO] estado=%s motivo=%s energia=%d->%d examinado=%s->%s"
		% [
			TiposInteraccion.EstadoResolucion.keys()[ultimo_resultado.estado],
			ultimo_resultado.motivo,
			energia_anterior,
			ficha.energia_actual,
			str(examinado_anterior).to_lower(),
			str(objeto_prueba.fue_examinado).to_lower(),
		]
	)
	if (
		ultimo_resultado.estado != TiposInteraccion.EstadoResolucion.BLOQUEO
		or ultimo_resultado.motivo != &"costes_insuficientes"
		or ficha.energia_actual != energia_anterior
		or objeto_prueba.fue_examinado != examinado_anterior
	):
		push_error("EscenaPruebaAcciones: el bloqueo produjo efectos inesperados.")
	_actualizar_interfaz()


func _crear_contexto_examinar(
	id_accion: StringName,
	coste_energia: float
) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		ficha,
		ficha.coordenada_mapa,
		objeto_prueba.coordenada_mapa,
		objeto_prueba,
		null,
		id_accion,
		[],
		{},
		4.0,
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL,
		{&"energia": coste_energia},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO
	)


func _reiniciar_prueba() -> void:
	ficha.energia_actual = ficha.energia_maxima
	objeto_prueba.reiniciar()
	registro_acciones.limpiar()
	ultimo_resultado = null
	print(
		"[PRUEBA][REINICIO] energia=%d examinado=false historial=0"
		% ficha.energia_actual
	)
	_actualizar_interfaz()


func _crear_camara_prueba() -> void:
	camara_prueba = Camera2D.new()
	camara_prueba.name = "CamaraPrueba"
	camara_prueba.zoom = Vector2(3.0, 3.0)
	add_child(camara_prueba)
	var centro_tablero := _calcular_centro_tablero()
	camara_prueba.global_position = capa_suelo.to_global(centro_tablero) + Vector2(0, -24)
	camara_prueba.make_current()


func _crear_interfaz_prueba() -> void:
	var capa_interfaz := CanvasLayer.new()
	capa_interfaz.name = "InterfazPrueba"
	add_child(capa_interfaz)

	etiqueta_estado = Label.new()
	etiqueta_estado.name = "EstadoPrueba"
	etiqueta_estado.position = Vector2(16, 16)
	etiqueta_estado.add_theme_font_size_override(&"font_size", 18)
	etiqueta_estado.add_theme_color_override(&"font_color", Color.WHITE)
	etiqueta_estado.add_theme_color_override(&"font_outline_color", Color.BLACK)
	etiqueta_estado.add_theme_constant_override(&"outline_size", 6)
	capa_interfaz.add_child(etiqueta_estado)


func _actualizar_interfaz() -> void:
	var estado := "SIN EJECUTAR"
	var motivo := "-"
	if ultimo_resultado != null:
		estado = String(
			TiposInteraccion.EstadoResolucion.keys()[ultimo_resultado.estado]
		)
		if ultimo_resultado.motivo != &"":
			motivo = String(ultimo_resultado.motivo)

	etiqueta_estado.text = (
		"PRUEBA DE ACCIONES\n"
		+ "[Espacio/Enter] Exito   [B] Bloqueo   [R] Reiniciar\n\n"
		+ "Energia: %d\n" % ficha.energia_actual
		+ "Objeto examinado: %s\n" % str(objeto_prueba.fue_examinado).to_lower()
		+ "Ultimo resultado: %s\n" % estado
		+ "Motivo: %s" % motivo
	)


func _calcular_centro_tablero() -> Vector2:
	var celdas: Array[Vector2i] = capa_suelo.get_used_cells()
	if celdas.is_empty():
		return Vector2.ZERO

	var minima: Vector2i = celdas[0]
	var maxima: Vector2i = celdas[0]
	for celda: Vector2i in celdas:
		minima.x = mini(minima.x, celda.x)
		minima.y = mini(minima.y, celda.y)
		maxima.x = maxi(maxima.x, celda.x)
		maxima.y = maxi(maxima.y, celda.y)

	return (capa_suelo.map_to_local(minima) + capa_suelo.map_to_local(maxima)) * 0.5
