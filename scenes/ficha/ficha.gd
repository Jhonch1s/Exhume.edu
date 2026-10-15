extends Node2D
class_name Ficha


var texturas_por_direccion: Dictionary = {}
var sprite_render: Sprite2D = null
var particulasDanio: CPUParticles2D = CPUParticles2D.new()



const TEXTURA_FICHAS_CLASE = preload(
	"res://assets/characters/player/class_tokens/sprites/player_class_tokens_isometric.png"
)
const FRAME_POR_CLASE := {"Guerrero": 3, "Ladrón": 0, "Mago": 6}



@export var nombre: String = "Heroe Jr."
@export var titulo: String = "El come cebolla"
@export var id_observador: StringName = &"jugador_principal"
@export var id_actor: StringName = &"jugador_principal"
@export var iniciativa_base: int = 0



var fue: int = 5
var des: int = 4
var vol: int = 2
@export_range(1, 99, 1) var nivel: int = 1
@export_range(0, 999999, 1) var experiencia_acumulada: int = 0
var energia_maxima: int = 200
var energia_actual: int = 200
var movimiento_por_turno: int:
	get:
		return RecursosTurnoActor.calcular_movimiento(des)
@export_range(0, 9, 1) var acciones_principales_por_turno: int = 1
@export_range(0, 9, 1) var acciones_adicionales_por_turno: int = 1
@export_range(0, 9, 1) var reacciones_por_turno: int = 1
var recursos_turno: RecursosTurnoActor

var pv_max: int
var pv_actual: int
var estados_temporales := EstadosTemporalesActor.new()
var clase: String = "Guerrero"
var origen: String = ""

const ID_ANTORCHA := &"antorcha"
const PASOS_MAX_ANTORCHA: int = 80
var pasos_antorcha_actual: int = 0
var raciones: int = 3
var inventario: Inventario = Inventario.new()

var coordenada_mapa: Vector2i = Vector2i.ZERO
var capa_referencia: TileMapLayer = null
var movimiento := MovimientoPorCasillas.new()
var esta_moviendose: bool:
	get:
		return movimiento.esta_moviendose
var interrupcion_solicitada: bool:
	get:
		return movimiento.interrupcion_solicitada
	set(valor):
		movimiento.interrupcion_solicitada = valor

var jugador_esta_cerca: bool = false

@export var velocidad_paso: float = 0.2

signal paso_dado(nueva_coordenada: Vector2i)
signal movimiento_terminado(interrumpido: bool)
signal puntos_vida_cambiados(actual: int, maximo: int)
signal estado_cambiado(clave: StringName, estado: EstadoActor)
signal recursos_turno_cambiados(recursos: RecursosTurnoActor)




func _init() -> void:
	estados_temporales.estado_cambiado.connect(_on_estado_temporal_cambiado)


func _on_estado_temporal_cambiado(clave: StringName, estado: EstadoActor) -> void:
	estado_cambiado.emit(clave, estado)


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

func obtener_cantidad_antorchas() -> int:
	var cantidad := 0
	for item in inventario.obtener_por_definicion(ID_ANTORCHA):
		cantidad += item.cantidad
	return cantidad

func obtener_antorcha_activa() -> DefinicionAntorcha:
	var antorchas := inventario.obtener_por_definicion(ID_ANTORCHA)
	if antorchas.is_empty() or pasos_antorcha_actual <= 0:
		return null
	return antorchas[0].definicion as DefinicionAntorcha

func activar_antorcha_si_necesario() -> bool:
	var antorchas := inventario.obtener_por_definicion(ID_ANTORCHA)
	if antorchas.is_empty():
		pasos_antorcha_actual = 0
		return false
	if pasos_antorcha_actual > 0:
		return true
	pasos_antorcha_actual = int(antorchas[0].definicion.magnitudes.get(
		&"duracion", float(PASOS_MAX_ANTORCHA)
	))
	return pasos_antorcha_actual > 0

func obtener_fuerza() -> int:
	return fue

func obtener_destreza() -> int:
	return des

func obtener_voluntad() -> int:
	return vol

func recibir_danio(cantidad: int, _fuente: Object = null) -> int:
	if cantidad <= 0:
		return 0
	var anterior := pv_actual
	pv_actual = maxi(0, pv_actual - cantidad)
	var aplicado := anterior - pv_actual
	if aplicado > 0:
		reproducir_efecto_danio()
		print("Vida de %s: %d/%d" % [nombre, pv_actual, pv_max])
		puntos_vida_cambiados.emit(pv_actual, pv_max)
	return aplicado
	
func reproducir_efecto_danio() -> void:
	if is_instance_valid(particulasDanio):
		particulasDanio.restart()

func obtener_estado(clave: StringName) -> EstadoActor:
	return estados_temporales.obtener_estado(clave)

func obtener_claves_estado() -> Array[StringName]:
	return estados_temporales.obtener_claves_estado()


func retirar_estado(clave: StringName) -> bool:
	return estados_temporales.retirar_estado(clave)


func puede_moverse() -> bool:
	return obtener_estado(&"enredado") == null

func aplicar_o_renovar_estado(
	clave: StringName,
	magnitud: float,
	duracion_total: int,
	ticks_pendientes: int,
	_fuente: Object = null,
	terminos_dano_tick: Array[Dictionary] = []
) -> Dictionary:
	return estados_temporales.aplicar_o_renovar_estado(
		clave, magnitud, duracion_total, ticks_pendientes, _fuente, terminos_dano_tick
	)

func consumir_tick_estado(clave: StringName) -> Dictionary:
	return estados_temporales.consumir_tick_estado(clave)

func iniciar_turno() -> void:
	if recursos_turno == null:
		recursos_turno = _crear_recursos_turno(des)
	else:
		recursos_turno.reponer(movimiento_por_turno)
	recursos_turno_cambiados.emit(recursos_turno)


func _crear_recursos_turno(destreza: int) -> RecursosTurnoActor:
	return RecursosTurnoActor.new(
		RecursosTurnoActor.calcular_movimiento(destreza),
		acciones_principales_por_turno, acciones_adicionales_por_turno, reacciones_por_turno
	)


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


func agotar_recursos_turno() -> void:
	for clave in RecursosTurnoActor.CLAVES:
		var restante := obtener_recurso_turno(clave)
		if restante > 0:
			consumir_recurso_turno(clave, restante)


func obtener_estado_persistente() -> Dictionary:
	return {
		"nombre": nombre,
		"titulo": titulo,
		"fuerza": fue,
		"destreza": des,
		"voluntad": vol,
		"nivel": nivel,
		"experiencia_acumulada": experiencia_acumulada,
		"clase": clase,
		"origen": origen,
		"id_actor": String(id_actor),
		"id_observador": String(id_observador),
		"coordenada": [coordenada_mapa.x, coordenada_mapa.y],
		"pv_actual": pv_actual,
		"energia_actual": energia_actual,
		"pasos_antorcha_actual": pasos_antorcha_actual,
		"recursos_turno": recursos_turno.obtener_restantes(),
		"movimiento_maximo": recursos_turno.obtener_maximo(RecursosTurnoActor.MOVIMIENTO),
		"estados": estados_temporales.obtener_estado_persistente(),
		"inventario": inventario.obtener_estado_persistente(),
	}


func validar_estado_persistente(estado: Variant) -> StringName:
	if not estado is Dictionary:
		return &"estado_ficha_invalido"
	if (
		not estado.get("nombre") is String or estado["nombre"].strip_edges().is_empty()
		or not estado.get("titulo") is String or estado["titulo"].strip_edges().is_empty()
		or not estado.get("clase") is String or not FRAME_POR_CLASE.has(estado["clase"])
		or not estado.get("origen") is String
	):
		return &"identidad_ficha_guardada_invalida"
	for atributo in ["fuerza", "destreza", "voluntad"]:
		if not _es_numero_entero(estado.get(atributo)) or estado[atributo] < 2 or estado[atributo] > 5:
			return &"atributos_ficha_guardados_invalidos"
	if (
		not _es_numero_entero(estado.get("nivel", 1))
		or estado.get("nivel", 1) < 1
		or not _es_numero_entero(estado.get("experiencia_acumulada", 0))
		or estado.get("experiencia_acumulada", 0) < 0
	):
		return &"progresion_ficha_guardada_invalida"
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
	var pasos_antorcha_guardados: Variant = estado.get(
		"pasos_antorcha_actual",
		0
	)
	if (
		not _es_numero_entero(pasos_antorcha_guardados)
		or pasos_antorcha_guardados < 0
		or pasos_antorcha_guardados > PASOS_MAX_ANTORCHA
	):
		return &"recurso_antorcha_guardado_invalido"
	if not estado.get("recursos_turno") is Dictionary:
		return &"recursos_turno_guardados_invalidos"
	var movimiento_guardado: Variant = estado.get("movimiento_maximo", 7)
	var recursos_guardados := _crear_recursos_turno(int(estado["destreza"]))
	if (
		not _es_numero_entero(movimiento_guardado)
		or (estado.has("movimiento_maximo") and movimiento_guardado != recursos_guardados.obtener_maximo(RecursosTurnoActor.MOVIMIENTO))
	):
		return &"recursos_turno_guardados_invalidos"
	var motivo := recursos_guardados.validar_restauracion(estado["recursos_turno"], int(movimiento_guardado))
	if motivo != &"":
		return motivo
	motivo = _validar_estados_guardados(estado.get("estados"))
	if motivo != &"":
		return motivo
	return Inventario.new().validar_estado_persistente(estado.get("inventario"))


func restaurar_estado_persistente(estado: Variant) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	var inventario_nuevo := Inventario.new()
	inventario_nuevo.restaurar_estado_persistente(estado["inventario"])
	nombre = estado["nombre"]
	titulo = estado["titulo"]
	fue = int(estado["fuerza"])
	des = int(estado["destreza"])
	vol = int(estado["voluntad"])
	nivel = int(estado.get("nivel", 1))
	experiencia_acumulada = int(estado.get("experiencia_acumulada", 0))
	clase = estado["clase"]
	origen = estado["origen"]
	pv_max = fue + des + vol
	_aplicar_visual_clase()
	coordenada_mapa = Vector2i(estado["coordenada"][0], estado["coordenada"][1])
	if capa_referencia != null:
		global_position = capa_referencia.to_global(capa_referencia.map_to_local(coordenada_mapa))
	pv_actual = int(estado["pv_actual"])
	energia_actual = int(estado["energia_actual"])
	pasos_antorcha_actual = int(estado.get("pasos_antorcha_actual", 0))
	recursos_turno = _crear_recursos_turno(des)
	recursos_turno.restaurar(estado["recursos_turno"], int(estado.get("movimiento_maximo", 7)))
	inventario = inventario_nuevo
	activar_antorcha_si_necesario()
	estados_temporales.restaurar_estado_persistente(estado["estados"])
	puntos_vida_cambiados.emit(pv_actual, pv_max)
	recursos_turno_cambiados.emit(recursos_turno)
	return &""


func _validar_estados_guardados(datos_estados: Variant) -> StringName:
	return (
		&"" if estados_temporales.validar_estado_persistente(datos_estados) == &""
		else &"estados_ficha_guardados_invalidos"
	)

func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))

func _ready() -> void:
	pv_max = fue + des + vol
	pv_actual = pv_max
	_setear_atributos_particula()
	
	#_aplicar_visual_clase()
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

func _setear_atributos_particula() -> void:
	particulasDanio.scale = Vector2(2.5, 2.5)
	particulasDanio.explosiveness = 1
	particulasDanio.scale_amount_min = 3
	particulasDanio.scale_amount_max = 5
	particulasDanio.amount = 20
	particulasDanio.color = Color(0.58, 0.02, 0.02,1)
	particulasDanio.gravity.y = 100
	particulasDanio.spread = 180
	particulasDanio.initial_velocity_min = 100
	particulasDanio.initial_velocity_max = 100
	particulasDanio.one_shot = true
	particulasDanio.lifetime = 1
	particulasDanio.local_coords = false
	particulasDanio.emitting = false
	var curva_escala := Curve.new()
	curva_escala.add_point(Vector2(0.0, 1.0)) # Inicio: Tamaño máximo
	curva_escala.add_point(Vector2(1.0, 0.0)) # Final: Tamaño cero
	particulasDanio.scale_amount_curve = curva_escala


func _aplicar_visual_clase() -> void:
	if sprite_render == null:
		sprite_render = Sprite2D.new()
		sprite_render.name = "SpriteRender"
	if sprite_render.get_parent() == null:
		add_child(sprite_render)
	if texturas_por_direccion.has(0):
		sprite_render.texture = texturas_por_direccion[0]
		sprite_render.visible = true
		if particulasDanio.get_parent() == null:
			sprite_render.add_child(particulasDanio)
	else:
		push_warning("No hay textura para dirección 0")


func inicializar(coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	capa_referencia = capa
	coordenada_mapa = coordenada_inicial
	if capa_referencia:
		global_position = capa_referencia.to_global(capa_referencia.map_to_local(coordenada_mapa))

func consumir_paso_antorcha() -> bool:
	var antorchas := inventario.obtener_por_definicion(ID_ANTORCHA)
	if antorchas.is_empty():
		pasos_antorcha_actual = 0
		return false
	if not activar_antorcha_si_necesario():
		return false
	pasos_antorcha_actual -= 1
	if pasos_antorcha_actual > 0:
		return true
	if not inventario.consumir_unidad(antorchas[0].id_instancia):
		return false
	var siguientes := inventario.obtener_por_definicion(ID_ANTORCHA)
	if siguientes.is_empty():
		pasos_antorcha_actual = 0
		return false
	pasos_antorcha_actual = int(siguientes[0].definicion.magnitudes.get(
		&"duracion", float(PASOS_MAX_ANTORCHA)
	))
	return true

func solicitar_interrupcion() -> void:
	movimiento.solicitar_interrupcion()





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
) -> bool:
	if not movimiento.paso_dado.is_connected(_on_paso_compartido):
		movimiento.paso_dado.connect(_on_paso_compartido)
		movimiento.movimiento_terminado.connect(_on_movimiento_compartido_terminado)
	return await movimiento.mover_por_camino(
		self, camino, capa_referencia, preparar_paso, confirmar_paso, cancelar_paso,
		procesar_salida, procesar_entrada, calcular_coste_paso, avanzar_turno, en_combate
	)


func validar_paso_movimiento(coste: int) -> bool:
	return coste >= 1 and energia_actual >= coste and coste <= movimiento_por_turno


func consumir_paso_movimiento(coste: int) -> void:
	energia_actual -= coste
	consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, coste)


func orientar_paso_movimiento(origen: Vector2i, destino: Vector2i) -> void:
	var direccion := Vector2(destino - origen)
	var angulo := posmod(int(round(rad_to_deg(direccion.angle()) / 90.0) * 90), 360)
	if sprite_render != null and texturas_por_direccion.has(angulo):
		sprite_render.texture = texturas_por_direccion[angulo]


func _on_paso_compartido(coordenada: Vector2i) -> void:
	paso_dado.emit(coordenada)


func _on_movimiento_compartido_terminado(interrumpido: bool) -> void:
	movimiento_terminado.emit(interrumpido)


func calcular_duracion_paso(coste_paso: int) -> float:
	return velocidad_paso * (2.0 if coste_paso > 1 else 1.0)
