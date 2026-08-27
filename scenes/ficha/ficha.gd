extends Node2D
class_name Ficha

const TEXTURA_FICHAS_CLASE = preload(
	"res://assets/characters/player/class_tokens/sprites/player_class_tokens_isometric.png"
)
const FRAME_POR_CLASE := {"Guerrero": 3, "Ladrón": 0, "Mago": 6}

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
var clase: String = "Guerrero"
var origen: String = ""

var antorchas: int = 3
var PASOS_MAX_ANTORCHA: int = 80
var pasos_antorcha_actual: int = 80
var raciones: int = 3
var inventario: Inventario = Inventario.new()

var coordenada_mapa: Vector2i = Vector2i.ZERO
var capa_referencia: TileMapLayer = null
var esta_moviendose: bool = false
var interrupcion_solicitada: bool = false

var jugador_esta_cerca: bool = false

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

func obtener_destreza() -> int:
	return des

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


func obtener_estado_persistente() -> Dictionary:
	var estados: Array[Dictionary] = []
	for clave in obtener_claves_estado():
		var estado := obtener_estado(clave)
		estados.append({
			"clave": String(clave),
			"magnitud": estado.magnitud,
			"duracion_total": estado.duracion_total,
			"ticks_pendientes": estado.ticks_pendientes,
		})
	var items: Array[Dictionary] = []
	for item in inventario.obtener_contenido():
		items.append({
			"id": String(item.id_instancia),
			"definicion_id": String(item.definicion.id_definicion),
			"definicion_path": item.definicion.resource_path,
			"cantidad": item.cantidad,
		})
	return {
		"nombre": nombre,
		"titulo": titulo,
		"fuerza": fue,
		"destreza": des,
		"voluntad": vol,
		"clase": clase,
		"origen": origen,
		"id_actor": String(id_actor),
		"id_observador": String(id_observador),
		"coordenada": [coordenada_mapa.x, coordenada_mapa.y],
		"pv_actual": pv_actual,
		"energia_actual": energia_actual,
		"recursos_turno": recursos_turno.obtener_restantes(),
		"estados": estados,
		"inventario": items,
	}


func validar_estado_persistente(estado: Variant) -> StringName:
	if not estado is Dictionary:
		return &"estado_ficha_invalido"
	if (
		not estado.get("nombre") is String or estado["nombre"].strip_edges().is_empty()
		or not estado.get("titulo") is String
		or not estado.get("clase") is String or not FRAME_POR_CLASE.has(estado["clase"])
		or not estado.get("origen") is String
	):
		return &"identidad_ficha_guardada_invalida"
	for atributo in ["fuerza", "destreza", "voluntad"]:
		if not _es_numero_entero(estado.get(atributo)) or estado[atributo] < 2 or estado[atributo] > 5:
			return &"atributos_ficha_guardados_invalidos"
	if estado.get("id_actor") != String(id_actor):
		return &"id_actor_guardado_no_coincide"
	if estado.get("id_observador") != String(id_observador):
		return &"id_observador_guardado_no_coincide"
	var coordenada: Variant = estado.get("coordenada")
	if (
		not coordenada is Array or coordenada.size() != 2
		or not _es_numero_entero(coordenada[0])
		or not _es_numero_entero(coordenada[1])
	):
		return &"coordenada_ficha_guardada_invalida"
	var pv_maximo_guardado: int = estado["fuerza"] + estado["destreza"] + estado["voluntad"]
	if (
		not _es_numero_entero(estado.get("pv_actual"))
		or estado["pv_actual"] < 0 or estado["pv_actual"] > pv_maximo_guardado
		or not _es_numero_entero(estado.get("energia_actual"))
		or estado["energia_actual"] < 0 or estado["energia_actual"] > energia_maxima
	):
		return &"recursos_ficha_guardados_invalidos"
	if not estado.get("recursos_turno") is Dictionary:
		return &"recursos_turno_guardados_invalidos"
	var motivo := recursos_turno.validar_restauracion(estado["recursos_turno"])
	if motivo != &"":
		return motivo
	motivo = _validar_estados_guardados(estado.get("estados"))
	if motivo != &"":
		return motivo
	return _validar_inventario_guardado(estado.get("inventario"))


func restaurar_estado_persistente(estado: Variant) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	var inventario_nuevo := Inventario.new()
	for datos: Dictionary in estado["inventario"]:
		var definicion := ResourceLoader.load(datos["definicion_path"]) as DefinicionItem
		inventario_nuevo.agregar(ItemInstancia.new(
			StringName(datos["id"]), definicion, int(datos["cantidad"])
		))
	var estados_nuevos: Dictionary[StringName, EstadoActor] = {}
	for datos: Dictionary in estado["estados"]:
		var clave := StringName(datos["clave"])
		estados_nuevos[clave] = EstadoActor.new(
			clave,
			float(datos["magnitud"]),
			int(datos["duracion_total"]),
			int(datos["ticks_pendientes"])
		)
	nombre = estado["nombre"]
	titulo = estado["titulo"]
	fue = int(estado["fuerza"])
	des = int(estado["destreza"])
	vol = int(estado["voluntad"])
	clase = estado["clase"]
	origen = estado["origen"]
	pv_max = fue + des + vol
	_aplicar_visual_clase()
	coordenada_mapa = Vector2i(estado["coordenada"][0], estado["coordenada"][1])
	if capa_referencia != null:
		global_position = capa_referencia.map_to_local(coordenada_mapa)
	pv_actual = int(estado["pv_actual"])
	energia_actual = int(estado["energia_actual"])
	recursos_turno.restaurar(estado["recursos_turno"])
	inventario = inventario_nuevo
	_estados = estados_nuevos
	puntos_vida_cambiados.emit(pv_actual, pv_max)
	recursos_turno_cambiados.emit(recursos_turno)
	for clave in obtener_claves_estado():
		estado_cambiado.emit(clave, _estados[clave])
	return &""


func _validar_estados_guardados(datos_estados: Variant) -> StringName:
	if not datos_estados is Array:
		return &"estados_ficha_guardados_invalidos"
	var claves: Dictionary[String, bool] = {}
	for datos: Variant in datos_estados:
		if not datos is Dictionary:
			return &"estados_ficha_guardados_invalidos"
		var clave: Variant = datos.get("clave")
		var magnitud: Variant = datos.get("magnitud")
		if (
			not clave is String or clave.is_empty() or claves.has(clave)
			or not (magnitud is int or magnitud is float)
			or not is_finite(float(magnitud)) or magnitud < 0.0
			or not _es_numero_entero(datos.get("duracion_total"))
			or datos["duracion_total"] <= 0
			or not _es_numero_entero(datos.get("ticks_pendientes"))
			or datos["ticks_pendientes"] < 0
		):
			return &"estados_ficha_guardados_invalidos"
		claves[clave] = true
	return &""


func _validar_inventario_guardado(datos_items: Variant) -> StringName:
	if not datos_items is Array:
		return &"inventario_guardado_invalido"
	var ids: Dictionary[String, bool] = {}
	for datos: Variant in datos_items:
		if not datos is Dictionary:
			return &"inventario_guardado_invalido"
		var id_item: Variant = datos.get("id")
		var id_definicion: Variant = datos.get("definicion_id")
		var ruta: Variant = datos.get("definicion_path")
		if (
			not id_item is String or id_item.is_empty() or ids.has(id_item)
			or not id_definicion is String or id_definicion.is_empty()
			or not ruta is String or ruta.is_empty() or not ResourceLoader.exists(ruta)
			or not _es_numero_entero(datos.get("cantidad"))
		):
			return &"inventario_guardado_invalido"
		var definicion := ResourceLoader.load(ruta) as DefinicionItem
		var item := ItemInstancia.new(StringName(id_item), definicion, int(datos["cantidad"]))
		if definicion == null or String(definicion.id_definicion) != id_definicion or not item.es_valida():
			return &"definicion_item_guardada_invalida"
		ids[id_item] = true
	return &""


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))

func _ready() -> void:
	pv_max = fue + des + vol
	pv_actual = pv_max
	_aplicar_visual_clase()
	iniciar_turno()


func configurar_creacion(datos: Dictionary) -> bool:
	if EstadoPartida.validar_aventurero(datos) != &"":
		return false
	nombre = datos["nombre"].strip_edges()
	titulo = datos["titulo"].strip_edges()
	fue = datos["fuerza"]
	des = datos["destreza"]
	vol = datos["voluntad"]
	clase = datos["clase"]
	origen = datos["origen"]
	return true


func _aplicar_visual_clase() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.texture = TEXTURA_FICHAS_CLASE
	sprite.hframes = 3
	sprite.vframes = 4
	sprite.frame = FRAME_POR_CLASE.get(clase, 0)
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE
	sprite.offset = Vector2.ZERO

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
