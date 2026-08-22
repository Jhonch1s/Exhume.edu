extends Node2D
class_name Ficha

@export var nombre: String = "Heroe Jr."
@export var titulo: String = "El come cebolla"
@export var id_observador: StringName = &"jugador_principal"
@export var id_actor: StringName = &"jugador_principal"
@export var iniciativa_base: int = 0

var fue: int = 3
var des: int = 4
var vol: int = 2
var energia_maxima: int = 200
var energia_actual: int = 200
@export_range(0, 99, 1) var movimiento_por_turno: int = 7
@export_range(0, 9, 1) var acciones_principales_por_turno: int = 1
@export_range(0, 9, 1) var acciones_adicionales_por_turno: int = 1
@export_range(0, 9, 1) var reacciones_por_turno: int = 1
var recursos_turno: RecursosTurnoActor

var pv_max: int
var pv_actual: int
var _estados: Dictionary[StringName, EstadoActor] = {}
var clase: String = "Ladron"

var antorchas: int = 3
var PASOS_MAX_ANTORCHA: int = 80
var pasos_antorcha_actual: int = 80
var raciones: int = 3
var inventario: Inventario = Inventario.new()

var coordenada_mapa: Vector2i = Vector2i.ZERO
var capa_referencia: TileMapLayer = null
var esta_moviendose: bool = false
var interrupcion_solicitada: bool = false

@export var velocidad_paso: float = 0.2

signal paso_dado(nueva_coordenada: Vector2i)
signal movimiento_terminado(interrumpido: bool)
signal puntos_vida_cambiados(actual: int, maximo: int)
signal estado_cambiado(clave: StringName, estado: EstadoActor)
signal recursos_turno_cambiados(recursos: RecursosTurnoActor)


func obtener_id_observador() -> StringName:
	return id_observador

func obtener_id_actor() -> StringName:
	return id_actor

func obtener_iniciativa() -> int:
	return iniciativa_base

func puede_actuar() -> bool:
	return pv_actual > 0

func obtener_inventario() -> Inventario:
	return inventario

func obtener_fuerza() -> int:
	return fue

func recibir_danio(cantidad: int, _fuente: Object = null) -> int:
	if cantidad <= 0:
		return 0
	var anterior := pv_actual
	pv_actual = maxi(0, pv_actual - cantidad)
	var aplicado := anterior - pv_actual
	if aplicado > 0:
		print("Vida de %s: %d/%d" % [nombre, pv_actual, pv_max])
		puntos_vida_cambiados.emit(pv_actual, pv_max)
	return aplicado

func obtener_estado(clave: StringName) -> EstadoActor:
	return _estados.get(clave) as EstadoActor

func obtener_claves_estado() -> Array[StringName]:
	var claves: Array[StringName] = []
	claves.assign(_estados.keys())
	claves.sort_custom(func(a, b): return String(a) < String(b))
	return claves

func aplicar_o_renovar_estado(
	clave: StringName,
	magnitud: float,
	duracion_total: int,
	ticks_pendientes: int,
	_fuente: Object = null
) -> Dictionary:
	if clave == &"" or magnitud < 0.0 or duracion_total <= 0 or ticks_pendientes < 0:
		return {}
	var estado := obtener_estado(clave)
	var creado := estado == null
	if creado:
		estado = EstadoActor.new(clave, magnitud, duracion_total, ticks_pendientes)
		_estados[clave] = estado
	else:
		estado.renovar(magnitud, duracion_total, ticks_pendientes)
	estado_cambiado.emit(clave, estado)
	return {
		&"clave": clave,
		&"creado": creado,
		&"duracion_total": estado.duracion_total,
		&"ticks_pendientes": estado.ticks_pendientes,
	}

func consumir_tick_estado(clave: StringName) -> Dictionary:
	var estado := obtener_estado(clave)
	if estado == null or estado.ticks_pendientes <= 0:
		return {}
	var restantes := estado.consumir_tick()
	var expirado := restantes == 0
	if expirado:
		_estados.erase(clave)
	estado_cambiado.emit(clave, estado)
	return {
		&"tipo": &"estado_tick",
		&"clave": clave,
		&"ticks_restantes": restantes,
		&"expirado": expirado,
	}

func iniciar_turno() -> void:
	if recursos_turno == null:
		recursos_turno = RecursosTurnoActor.new(
			movimiento_por_turno,
			acciones_principales_por_turno,
			acciones_adicionales_por_turno,
			reacciones_por_turno
		)
	else:
		recursos_turno.reponer()
	recursos_turno_cambiados.emit(recursos_turno)

func obtener_recurso_turno(clave: StringName) -> int:
	if recursos_turno == null:
		iniciar_turno()
	return recursos_turno.obtener(clave)

func validar_coste_turno(clave: StringName, cantidad: int) -> StringName:
	if recursos_turno == null:
		iniciar_turno()
	return recursos_turno.validar_consumo(clave, cantidad)

func consumir_recurso_turno(clave: StringName, cantidad: int) -> bool:
	if recursos_turno == null:
		iniciar_turno()
	if not recursos_turno.consumir(clave, cantidad):
		return false
	recursos_turno_cambiados.emit(recursos_turno)
	return true

func _ready() -> void:
	pv_max = fue + des + vol
	pv_actual = pv_max
	iniciar_turno()

func inicializar(coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	capa_referencia = capa
	coordenada_mapa = coordenada_inicial
	if capa_referencia:
		global_position = capa_referencia.map_to_local(coordenada_mapa)

func consumir_o_recargar_antorcha() -> bool:
	if pasos_antorcha_actual > 0:
		return true
	if antorchas > 1:
		antorchas -= 1
		pasos_antorcha_actual = PASOS_MAX_ANTORCHA
		print("Se cambia antorcha")
		return true
	antorchas = 0
	print("No quedan mas antorchas")
	return false

func solicitar_interrupcion() -> void:
	if esta_moviendose:
		interrupcion_solicitada = true

func mover_por_camino(
	camino: Array[Vector2i],
	preparar_paso: Callable,
	confirmar_paso: Callable,
	cancelar_paso: Callable,
	procesar_salida: Callable = Callable(),
	procesar_entrada: Callable = Callable(),
	calcular_coste_paso: Callable = Callable(),
	avanzar_turno: Callable = Callable(),
	en_combate: bool = false
) -> void:
	if camino.is_empty() or esta_moviendose or not capa_referencia:
		return

	esta_moviendose = true
	interrupcion_solicitada = false
	var fue_interrumpido := false

	for siguiente_coord in camino:
		# AStar incluye el origen: no cuenta como paso ni consume recursos.
		if siguiente_coord == coordenada_mapa:
			continue
		if interrupcion_solicitada:
			fue_interrumpido = true
			break
		var origen := coordenada_mapa
		var coste_paso := 1
		if calcular_coste_paso.is_valid():
			var coste_calculado: Variant = calcular_coste_paso.call(
				origen,
				siguiente_coord,
				self
			)
			if not coste_calculado is int or coste_calculado < 1:
				fue_interrumpido = true
				break
			coste_paso = coste_calculado
		if energia_actual < coste_paso:
			print("sin energia para caminar mas")
			fue_interrumpido = true
			break
		if coste_paso > movimiento_por_turno:
			fue_interrumpido = true
			break
		if validar_coste_turno(RecursosTurnoActor.MOVIMIENTO, coste_paso) != &"":
			if en_combate or not avanzar_turno.is_valid() or not avanzar_turno.call(self):
				fue_interrumpido = true
				break

		# La ruta puede quedar obsoleta; reservamos cada destino antes de usarlo.
		if not preparar_paso.call(origen, siguiente_coord, self):
			fue_interrumpido = true
			break

		var destino_pixeles := capa_referencia.map_to_local(siguiente_coord)
		var tween := create_tween()
		tween.tween_property(
			self,
			"global_position",
			destino_pixeles,
			calcular_duracion_paso(coste_paso)
		)
		await tween.finished

		if procesar_salida.is_valid():
			procesar_salida.call(origen, siguiente_coord, self)

		if not confirmar_paso.call(origen, siguiente_coord, self):
			cancelar_paso.call(siguiente_coord, self)
			global_position = capa_referencia.map_to_local(origen)
			fue_interrumpido = true
			break

		# El paso se vuelve definitivo solamente al llegar.
		coordenada_mapa = siguiente_coord
		energia_actual -= coste_paso
		consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, coste_paso)
		print("energia actual: ", energia_actual)
		if procesar_entrada.is_valid():
			procesar_entrada.call(origen, siguiente_coord, self)
		paso_dado.emit(coordenada_mapa)
		if interrupcion_solicitada:
			fue_interrumpido = true
			break

	esta_moviendose = false
	interrupcion_solicitada = false
	movimiento_terminado.emit(fue_interrumpido)

func calcular_duracion_paso(coste_paso: int) -> float:
	return velocidad_paso * (2.0 if coste_paso > 1 else 1.0)
