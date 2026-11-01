extends Node2D
class_name Ficha


var texturas_por_direccion: Dictionary = {}
var sprite_render: Sprite2D = null
var particulasDanio: CPUParticles2D = CPUParticles2D.new()
var particulasVeneno: CPUParticles2D = CPUParticles2D.new()

@onready var timer: Timer

const TEXTURA_FICHAS_CLASE = preload(
	"res://assets/characters/player/class_tokens/sprites/player_class_tokens_isometric.png"
)
const FRAME_POR_CLASE := {"Guerrero": 3, "Ladrón": 0, "Mago": 6}

const texturaVeneno = preload("res://scenes/efectos_superficie/particulaverde.png")
const particulasLavaEscena = preload("res://scenes/efectos_superficie/particulas_quemado.tscn")
var shaderMat = ShaderMaterial.new()
var shaderMatQ = ShaderMaterial.new()
var particulaFuegoInstancia: Node2D = null
const SONIDO_DANIO_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonidos mmo/MMO_Game_Magic_Source_Armor_02_Metal_Hit_Shuffle.wav")
const SONIDO_QUEMADURA_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/fuego quemadura.wav")
const SONIDO_VENENO_DEBUFF_DEFECTO: AudioStream = preload("res://assets/sonidos/sonidos finales/sonido ambiente/561216__terrytom__poison-debuff.wav")
const SONIDO_TOS_1: AudioStream = preload("res://assets/sonidos/toser/editado/varias toses.wav")
const SONIDO_TOS_2: AudioStream = preload("res://assets/sonidos/toser/editado/varias toses 2.wav")
const SONIDO_CURACION_MAGICA: AudioStream = preload("res://assets/sonidos/posiones/Magic Heal 03.wav")
const SONIDO_COMER: AudioStream = preload("res://assets/sonidos/comer/573577__vibritherabjit123__short-crisps-eating-noise-editado.wav")
const ScriptEstadoPartida = preload("res://scripts/estado_partida.gd")

var _tos_variante_dos: bool = false
var reproductor_audio_ficha: AudioStreamPlayer2D


var shaderVeneno = load("res://assets/ui/shaders/envenenado.gdshader");
var shaderQuemado = load("res://assets/ui/shaders/quemado.gdshader");

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
# shortcut: este corte resuelve solo nivel 2; ampliar con el catálogo de niveles siguientes.
const NIVEL_MAXIMO_IMPLEMENTADO := 2
var nivel_recompensa_pendiente: int = 0
var pasivas_aprendidas: Array[String] = []
var activas_aprendidas: Array[String] = []
var usos_activas: Dictionary = {}
var pasivas_usadas_turno: Array[String] = []
# Compatibilidad con guardados anteriores: estos modos ya no controlan el empuje.
var empuje_habilitado := false
var empuje_ultimo_doble := false
var contagio_elegido := ""
var pasos_inercia := 0
var agarre_objetivo := ""
var agarre_pasos := 0
var senuelos: Dictionary = {}
var energia_maxima: int = 200
var energia_actual: int = 200
var movimiento_por_turno: int:
	get:
		if esta_sobrecargado():
			return 0
		return RecursosTurnoActor.calcular_movimiento(obtener_destreza())

var peso_maximo: float:
	get:
		return 15.0 + float(obtener_fuerza()) * 4.0


func obtener_peso_actual() -> float:
	var total := 0.0
	if inventario != null:
		for item in inventario.obtener_contenido():
			if item != null and item.es_valida():
				total += item.obtener_peso_total()
	return total + equipo.obtener_peso()


func esta_sobrecargado() -> bool:
	return obtener_peso_actual() > peso_maximo
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
var pasos_antorcha_actual: int:
	get:
		var antorcha := obtener_pila_antorcha_activa()
		return antorcha.pasos_antorchas[0] if antorcha != null else 0
	set(valor):
		var antorcha := obtener_pila_antorcha_activa()
		if antorcha != null:
			antorcha.pasos_antorchas[0] = valor
var raciones: int = 3
var usos_ataque_doble: int = 1
var usos_ocultarse: int = 1
var usos_bola_fuego: int = 1
var turnos_oculto: int = 0:
	set(valor):
		turnos_oculto = valor
		_actualizar_visual_sigilo()
var inventario: Inventario = Inventario.new()
var equipo := EquipoActor.new()

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
signal descanso_realizado
signal usos_habilidades_cambiados
signal progresion_cambiada
signal golpe_conectado(objetivo: Object)




func _init() -> void:
	estados_temporales.estado_cambiado.connect(_on_estado_temporal_cambiado)
	equipo.propietario = self
	equipo.cambiado.connect(_on_equipo_cambiado)
	


func obtener_equipo() -> EquipoActor:
	return equipo


func _on_equipo_cambiado() -> void:
	if recursos_turno != null:
		recursos_turno.ajustar_movimiento(RecursosTurnoActor.calcular_movimiento(obtener_destreza()))
	progresion_cambiada.emit()


func _on_estado_temporal_cambiado(clave: StringName, estado: EstadoActor) -> void:
	if clave in EfectosEquipo.PENALIZACIONES:
		_on_equipo_cambiado()
	if clave == &"veneno" or clave == &"quemado":
		_actualizar_efectos_estado()
	estado_cambiado.emit(clave, estado)


func _actualizar_visual_sigilo() -> void:
	if is_instance_valid(sprite_render):
		sprite_render.self_modulate.a = 0.4 if turnos_oculto > 0 else 1.0


func _actualizar_efectos_estado() -> void:
	if not is_instance_valid(sprite_render):
		return
	
	var envenenado := obtener_estado(&"veneno") != null
	var quemado := obtener_estado(&"quemado") != null
	particulasVeneno.emitting = envenenado
	sprite_render.material = shaderMatQ if quemado else shaderMat if envenenado else null
	if quemado and not is_instance_valid(particulaFuegoInstancia):
		particulaFuegoInstancia = particulasLavaEscena.instantiate() as Node2D
		# El sprite renderizado está a escala 0,12; conservar el ancho de 64 px en el mapa.
		particulaFuegoInstancia.scale = Vector2.ONE / sprite_render.scale
		sprite_render.add_child(particulaFuegoInstancia)
	elif not quemado and is_instance_valid(particulaFuegoInstancia):
		particulaFuegoInstancia.queue_free()
		particulaFuegoInstancia = null
	
func on_timer_timeout() -> void:
	var envenenado := obtener_estado(&"veneno") != null
	var quemado := obtener_estado(&"quemado") != null
	if (envenenado && quemado):
		print("Cambio de shader")
		if (sprite_render.material == shaderMatQ):
			sprite_render.material = shaderMat
		else:
			sprite_render.material = shaderMatQ
	


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


func ganar_experiencia(cantidad: int) -> void:
	if cantidad <= 0:
		return
	experiencia_acumulada += cantidad
	actualizar_progresion()
	progresion_cambiada.emit()


func actualizar_progresion() -> void:
	if nivel < NIVEL_MAXIMO_IMPLEMENTADO and experiencia_acumulada >= 100:
		nivel = 2
		nivel_recompensa_pendiente = 2


func conoce_habilidad(id: String) -> bool:
	return id in pasivas_aprendidas or id in activas_aprendidas


func aprender_recompensa(id: String) -> bool:
	var opcion := CatalogoHabilidades.obtener(id)
	if nivel_recompensa_pendiente != 2 or opcion.is_empty() or opcion["clase"] != clase:
		return false
	if not pasivas_aprendidas.is_empty() or not activas_aprendidas.is_empty():
		return false
	if opcion["tipo"] == "Activa":
		activas_aprendidas.append(id)
		usos_activas[id] = 1
	else:
		pasivas_aprendidas.append(id)
	nivel_recompensa_pendiente = 0
	progresion_cambiada.emit()
	usos_habilidades_cambiados.emit()
	return true


func romper_agarre() -> void:
	agarre_objetivo = ""
	agarre_pasos = 0


func descansar_en_campamento() -> StringName:
	if not puede_actuar():
		return &"descanso_jugador_sin_vida"
	if raciones < 1:
		return &"descanso_sin_provisiones"
	raciones -= 1
	pv_actual = pv_max
	energia_actual = energia_maxima
	usos_ataque_doble = 1
	usos_ocultarse = 1
	usos_bola_fuego = 1
	for id in activas_aprendidas:
		usos_activas[id] = 1
	puntos_vida_cambiados.emit(pv_actual, pv_max)
	usos_habilidades_cambiados.emit()
	descanso_realizado.emit()
	return &""


func consumir_ataque_doble() -> bool:
	if clase != "Guerrero" or usos_ataque_doble < 1:
		return false
	usos_ataque_doble -= 1
	usos_habilidades_cambiados.emit()
	return true


func ocultarse() -> bool:
	if clase != "Ladrón" or usos_ocultarse < 1 or not puede_actuar():
		return false
	usos_ocultarse -= 1
	turnos_oculto = 2
	usos_habilidades_cambiados.emit()
	return true


func consumir_bola_fuego() -> bool:
	if clase != "Mago" or usos_bola_fuego < 1:
		return false
	usos_bola_fuego -= 1
	usos_habilidades_cambiados.emit()
	return true


func avanzar_ocultamiento() -> void:
	if turnos_oculto > 0:
		turnos_oculto -= 1
		usos_habilidades_cambiados.emit()


func romper_ocultamiento() -> void:
	if turnos_oculto > 0:
		turnos_oculto = 0
		usos_habilidades_cambiados.emit()

func obtener_cantidad_antorchas() -> int:
	var cantidad := 0
	for item in inventario.obtener_por_definicion(ID_ANTORCHA):
		cantidad += item.cantidad
	return cantidad

func obtener_antorcha_activa() -> DefinicionAntorcha:
	var antorcha := obtener_pila_antorcha_activa()
	if antorcha == null or pasos_antorcha_actual <= 0:
		return null
	return antorcha.definicion as DefinicionAntorcha


func obtener_pila_antorcha_activa() -> ItemInstancia:
	var activa: ItemInstancia = null
	for item in inventario.obtener_por_definicion(ID_ANTORCHA):
		if item.pasos_antorchas.is_empty():
			continue
		# Priorizar las usadas evita cambiar a una nueva al recoger otra pila.
		var usada := item.pasos_antorchas[0] < item.obtener_duracion_antorcha()
		if activa == null or (usada and (
			activa.pasos_antorchas[0] == activa.obtener_duracion_antorcha()
			or item.pasos_antorchas[0] < activa.pasos_antorchas[0]
		)):
			activa = item
	return activa

func activar_antorcha_si_necesario() -> bool:
	return pasos_antorcha_actual > 0

func obtener_fuerza() -> int:
	return maxi(1, fue + EfectosEquipo.bono_atributo(self, "fuerza"))

func obtener_destreza() -> int:
	return maxi(1, des + EfectosEquipo.bono_atributo(self, "destreza"))

func obtener_voluntad() -> int:
	return maxi(1, vol + EfectosEquipo.bono_atributo(self, "voluntad"))


func obtener_atributo_base(atributo: String) -> int:
	return {"fuerza": fue, "destreza": des, "voluntad": vol}.get(atributo, 0)

func recibir_danio(cantidad: int, _fuente: Object = null) -> int:
	if cantidad <= 0:
		return 0
	var anterior := pv_actual
	pv_actual = maxi(0, pv_actual - cantidad)
	var aplicado := anterior - pv_actual
	if aplicado > 0:
		romper_ocultamiento()
		reproducir_efecto_danio()
		reproducir_sonido_danio()
		print("Vida de %s: %d/%d" % [nombre, pv_actual, pv_max])
		puntos_vida_cambiados.emit(pv_actual, pv_max)
	return aplicado

func curar(cantidad: int) -> int:
	if cantidad <= 0 or pv_actual >= pv_max:
		return 0
	var anterior := pv_actual
	pv_actual = mini(pv_max, pv_actual + cantidad)
	var aplicado := pv_actual - anterior
	if aplicado > 0:
		reproducir_sonido_curacion()
		puntos_vida_cambiados.emit(pv_actual, pv_max)
	return aplicado

func reproducir_sonido_curacion() -> void:
	_reproducir_audio_en_ficha(SONIDO_CURACION_MAGICA, -4.0)

func reproducir_sonido_comer() -> void:
	_reproducir_audio_en_ficha(SONIDO_COMER, -4.0)

func reproducir_efecto_danio() -> void:
	if is_instance_valid(particulasDanio):
		particulasDanio.restart()

func reproducir_sonido_danio() -> void:
	_reproducir_audio_en_ficha(SONIDO_DANIO_DEFECTO, -6.0)

func reproducir_sonido_quemadura() -> void:
	_reproducir_audio_en_ficha(SONIDO_QUEMADURA_DEFECTO, -6.0)

func reproducir_sonido_veneno() -> void:
	_reproducir_audio_en_ficha(SONIDO_VENENO_DEBUFF_DEFECTO, -5.0)
	reproducir_sonido_tos()

func reproducir_sonido_tos() -> void:
	var sonido := SONIDO_TOS_2 if _tos_variante_dos else SONIDO_TOS_1
	_tos_variante_dos = not _tos_variante_dos
	_reproducir_audio_en_ficha(sonido, -6.0)

func _reproducir_audio_en_ficha(stream: AudioStream, vol_db: float = 0.0) -> void:
	if not is_inside_tree() or stream == null:
		return
	if not is_instance_valid(reproductor_audio_ficha):
		reproductor_audio_ficha = AudioStreamPlayer2D.new()
		reproductor_audio_ficha.name = "AudioFicha"
		reproductor_audio_ficha.max_distance = 1500.0
		add_child(reproductor_audio_ficha)
	reproductor_audio_ficha.stream = stream
	reproductor_audio_ficha.volume_db = vol_db
	reproductor_audio_ficha.play()

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
	var resultado := estados_temporales.aplicar_o_renovar_estado(
		clave, magnitud, duracion_total, ticks_pendientes, _fuente, terminos_dano_tick
	)
	if not resultado.is_empty():
		if clave == &"quemado":
			reproducir_sonido_quemadura()
		elif clave == &"veneno":
			reproducir_sonido_veneno()
	return resultado

func consumir_tick_estado(clave: StringName) -> Dictionary:
	var resultado := estados_temporales.consumir_tick_estado(clave)
	if not resultado.is_empty():
		if clave == &"veneno":
			reproducir_sonido_tos()
		elif clave == &"quemado":
			reproducir_sonido_quemadura()
	return resultado

func iniciar_turno() -> void:
	pasivas_usadas_turno.clear()
	pasos_inercia = 0
	romper_agarre()
	if recursos_turno == null:
		recursos_turno = _crear_recursos_turno(obtener_destreza())
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
	if clave == RecursosTurnoActor.MOVIMIENTO and pasos_inercia > 0 and cantidad > 0:
		return &""
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
		"nivel_recompensa_pendiente": nivel_recompensa_pendiente,
		"pasivas_aprendidas": pasivas_aprendidas.duplicate(),
		"activas_aprendidas": activas_aprendidas.duplicate(),
		"habilidades_nivel_dos": {
			"usos": usos_activas.duplicate(), "pasivas_usadas": pasivas_usadas_turno.duplicate(),
			"empujar": empuje_habilitado, "empuje_ultimo_doble": empuje_ultimo_doble, "contagio": contagio_elegido,
			"pasos_inercia": pasos_inercia, "agarre_objetivo": agarre_objetivo,
			"agarre_pasos": agarre_pasos, "senuelos": senuelos.duplicate(true),
		},
		"clase": clase,
		"origen": origen,
		"id_actor": String(id_actor),
		"id_observador": String(id_observador),
		"coordenada": [coordenada_mapa.x, coordenada_mapa.y],
		"pv_actual": pv_actual,
		"energia_actual": energia_actual,
		"raciones": raciones,
		"usos_ataque_doble": usos_ataque_doble,
		"usos_ocultarse": usos_ocultarse,
		"usos_bola_fuego": usos_bola_fuego,
		"turnos_oculto": turnos_oculto,
		"pasos_antorcha_actual": pasos_antorcha_actual,
		"recursos_turno": recursos_turno.obtener_restantes(),
		"movimiento_maximo": recursos_turno.obtener_maximo(RecursosTurnoActor.MOVIMIENTO),
		"estados": estados_temporales.obtener_estado_persistente(),
		"inventario": inventario.obtener_estado_persistente(),
		"equipo": equipo.obtener_estado_persistente(),
	}


func validar_estado_persistente(estado: Variant) -> StringName:
	if not estado is Dictionary:
		return &"estado_ficha_invalido"
	if not _es_numero_entero(estado.get("raciones", 3)) or estado.get("raciones", 3) < 0:
		return &"raciones_guardadas_invalidas"
	if (
		not _es_numero_entero(estado.get("usos_ataque_doble", 1))
		or estado.get("usos_ataque_doble", 1) < 0
		or estado.get("usos_ataque_doble", 1) > 1
	):
		return &"usos_habilidades_guardados_invalidos"
	if (
		not _es_numero_entero(estado.get("usos_ocultarse", 1))
		or estado.get("usos_ocultarse", 1) < 0 or estado.get("usos_ocultarse", 1) > 1
		or not _es_numero_entero(estado.get("turnos_oculto", 0))
		or estado.get("turnos_oculto", 0) < 0 or estado.get("turnos_oculto", 0) > 2
		or (estado.get("turnos_oculto", 0) > 0 and estado.get("clase") != "Ladrón")
	):
		return &"ocultamiento_guardado_invalido"
	if (
		not _es_numero_entero(estado.get("usos_bola_fuego", 1))
		or estado.get("usos_bola_fuego", 1) < 0 or estado.get("usos_bola_fuego", 1) > 1
	):
		return &"usos_habilidades_guardados_invalidos"
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
	var motivo_progresion := _validar_progresion_guardada(estado)
	if motivo_progresion != &"":
		return motivo_progresion
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
	):
		return &"recurso_antorcha_guardado_invalido"
	if not estado.get("recursos_turno") is Dictionary:
		return &"recursos_turno_guardados_invalidos"
	var motivo_inventario := Inventario.new().validar_estado_persistente(estado.get("inventario"))
	if motivo_inventario != &"":
		return motivo_inventario
	var limite_antorcha := 0
	for dato: Dictionary in estado["inventario"]:
		if dato["definicion_id"] == String(ID_ANTORCHA):
			var perfil := load(dato["definicion_path"]) as DefinicionItem
			limite_antorcha = maxi(limite_antorcha, int(perfil.magnitudes.get(&"duracion", float(PASOS_MAX_ANTORCHA))))
	if pasos_antorcha_guardados > (limite_antorcha if limite_antorcha > 0 else PASOS_MAX_ANTORCHA):
		return &"recurso_antorcha_guardado_invalido"
	var equipo_guardado := EquipoActor.new()
	var motivo_equipo := equipo_guardado.validar_estado_persistente(estado.get("equipo", []), estado.get("inventario", []) if estado.get("inventario") is Array else [], estado.get("clase", ""))
	if motivo_equipo != &"":
		return motivo_equipo
	equipo_guardado.restaurar_estado_persistente(estado.get("equipo", []), estado.get("clase", ""))
	var des_guardada := int(estado["destreza"])
	var fuerza_guardada := int(estado["fuerza"])
	for item: ItemInstancia in equipo_guardado.ranuras.values():
		for efecto: Dictionary in item.definicion.efectos_equipo:
			if efecto.tipo == "atributo" and efecto.atributo == "destreza":
				des_guardada += int(efecto.valor)
			if efecto.tipo == "atributo" and efecto.atributo == "fuerza":
				fuerza_guardada += int(efecto.valor)
	for efecto: Variant in estado.get("estados", []) if estado.get("estados") is Array else []:
		if efecto is Dictionary and efecto.get("clave") == "debilitado_destreza" and (efecto.get("magnitud") is float or efecto.get("magnitud") is int):
			des_guardada -= int(efecto.magnitud)
		if efecto is Dictionary and efecto.get("clave") == "debilitado_fuerza" and (efecto.get("magnitud") is float or efecto.get("magnitud") is int):
			fuerza_guardada -= int(efecto.magnitud)
	var movimiento_guardado: Variant = estado.get("movimiento_maximo", 7)
	var recursos_guardados := _crear_recursos_turno(maxi(1, des_guardada))
	var inventario_guardado := Inventario.new()
	inventario_guardado.restaurar_estado_persistente(estado["inventario"])
	var peso_guardado := equipo_guardado.obtener_peso()
	for item: ItemInstancia in inventario_guardado.obtener_contenido():
		peso_guardado += item.obtener_peso_total()
	if movimiento_guardado == 0 and peso_guardado > 15.0 + maxi(1, fuerza_guardada) * 4.0:
		recursos_guardados.ajustar_movimiento(0)
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
	nivel_recompensa_pendiente = int(estado.get("nivel_recompensa_pendiente", 2 if nivel >= 2 else 0))
	pasivas_aprendidas.assign(estado.get("pasivas_aprendidas", []))
	activas_aprendidas.assign(estado.get("activas_aprendidas", []))
	var habilidades: Dictionary = estado.get("habilidades_nivel_dos", {})
	usos_activas = habilidades.get("usos", {}).duplicate()
	for id in usos_activas:
		usos_activas[id] = int(usos_activas[id])
	pasivas_usadas_turno.assign(habilidades.get("pasivas_usadas", []))
	empuje_habilitado = habilidades.get("empujar", false)
	empuje_ultimo_doble = habilidades.get("empuje_ultimo_doble", false)
	contagio_elegido = habilidades.get("contagio", "")
	pasos_inercia = int(habilidades.get("pasos_inercia", 0))
	agarre_objetivo = habilidades.get("agarre_objetivo", "")
	agarre_pasos = int(habilidades.get("agarre_pasos", 0))
	senuelos = habilidades.get("senuelos", {}).duplicate(true)
	for id in senuelos:
		senuelos[id] = [int(senuelos[id][0]), int(senuelos[id][1])]
	# Los guardados previos podían acumular XP sin subir de nivel.
	actualizar_progresion()
	clase = estado["clase"]
	origen = estado["origen"]
	pv_max = fue + des + vol
	_aplicar_visual_clase()
	coordenada_mapa = Vector2i(estado["coordenada"][0], estado["coordenada"][1])
	if capa_referencia != null:
		global_position = capa_referencia.to_global(capa_referencia.map_to_local(coordenada_mapa))
	pv_actual = int(estado["pv_actual"])
	energia_actual = int(estado["energia_actual"])
	# Los guardados anteriores nunca persistían el contador inicial de tres.
	raciones = int(estado.get("raciones", 3))
	usos_ataque_doble = int(estado.get("usos_ataque_doble", 1))
	usos_ocultarse = int(estado.get("usos_ocultarse", 1))
	usos_bola_fuego = int(estado.get("usos_bola_fuego", 1))
	turnos_oculto = int(estado.get("turnos_oculto", 0))
	recursos_turno = _crear_recursos_turno(des)
	recursos_turno.restaurar(estado["recursos_turno"], int(estado.get("movimiento_maximo", 7)))
	inventario = inventario_nuevo
	# Migrar el contador de partidas anteriores que aún no guardaban desgaste por unidad.
	var antorchas_guardadas := inventario.obtener_por_definicion(ID_ANTORCHA)
	if not antorchas_guardadas.is_empty() and int(estado.get("pasos_antorcha_actual", 0)) > 0:
		for dato: Dictionary in estado["inventario"]:
			if dato["id"] == String(antorchas_guardadas[0].id_instancia) and not dato.has("pasos_antorchas"):
				antorchas_guardadas[0].pasos_antorchas[0] = mini(int(estado["pasos_antorcha_actual"]), antorchas_guardadas[0].obtener_duracion_antorcha())
				break
	equipo.restaurar_estado_persistente(estado.get("equipo", []), clase)
	activar_antorcha_si_necesario()
	estados_temporales.restaurar_estado_persistente(estado["estados"])
	# Restaurar el presupuesto efectivo sin reponer acciones ni pasos gastados.
	recursos_turno = _crear_recursos_turno(obtener_destreza())
	recursos_turno.ajustar_movimiento(movimiento_por_turno)
	recursos_turno.restaurar(estado["recursos_turno"], int(estado.get("movimiento_maximo", 7)))
	_actualizar_efectos_estado()
	puntos_vida_cambiados.emit(pv_actual, pv_max)
	recursos_turno_cambiados.emit(recursos_turno)
	usos_habilidades_cambiados.emit()
	progresion_cambiada.emit()
	return &""


func _validar_estados_guardados(datos_estados: Variant) -> StringName:
	return (
		&"" if estados_temporales.validar_estado_persistente(datos_estados) == &""
		else &"estados_ficha_guardados_invalidos"
	)


func _validar_progresion_guardada(estado: Dictionary, limite_recompensas: int = 1) -> StringName:
	var aprendidas: Variant = estado.get("pasivas_aprendidas", [])
	var activas: Variant = estado.get("activas_aprendidas", [])
	var pendiente: Variant = estado.get("nivel_recompensa_pendiente", 2 if estado.get("nivel", 1) >= 2 else 0)
	if not aprendidas is Array or not activas is Array or aprendidas.size() + activas.size() > limite_recompensas or not _es_numero_entero(pendiente):
		return &"progresion_ficha_guardada_invalida"
	for aprendida: Variant in aprendidas + activas:
		if not aprendida is String:
			return &"progresion_ficha_guardada_invalida"
		var opcion := CatalogoHabilidades.obtener(aprendida)
		if opcion.is_empty() or opcion["clase"] != estado.get("clase") or ((opcion["tipo"] == "Pasiva") != (aprendida in aprendidas)):
			return &"progresion_ficha_guardada_invalida"
	var sin_recompensa: bool = aprendidas.is_empty() and activas.is_empty()
	pendiente = int(pendiente)
	if pendiente not in [0, 2]:
		return &"progresion_ficha_guardada_invalida"
	if estado.get("nivel", 1) < 2 and (pendiente != 0 or not sin_recompensa):
		return &"progresion_ficha_guardada_invalida"
	if estado.get("nivel", 1) >= 2 and ((pendiente == 2) != sin_recompensa):
		return &"progresion_ficha_guardada_invalida"
	var datos: Variant = estado.get("habilidades_nivel_dos", {})
	if not datos is Dictionary:
		return &"habilidades_guardadas_invalidas"
	var usos: Variant = datos.get("usos", {})
	var gastadas: Variant = datos.get("pasivas_usadas", [])
	if estado.get("turnos_oculto", 0) > 0 and estado.get("usos_ocultarse", 1) != 0 and "escapista" not in aprendidas:
		return &"ocultamiento_guardado_invalido"
	if not usos is Dictionary or usos.size() != activas.size() or not gastadas is Array:
		return &"habilidades_guardadas_invalidas"
	for id: String in activas:
		if not _es_numero_entero(usos.get(id)) or usos[id] < 0 or usos[id] > 1:
			return &"habilidades_guardadas_invalidas"
	var vistas: Array = []
	for id: Variant in gastadas:
		if not id is String or id not in aprendidas or id in vistas or id not in ["golpe_desplazante", "inercia", "escapista", "contagio_arcano"]:
			return &"habilidades_guardadas_invalidas"
		vistas.append(id)
	if not datos.get("empujar", false) is bool or not datos.get("empuje_ultimo_doble", false) is bool or not datos.get("contagio", "") is String:
		return &"habilidades_guardadas_invalidas"
	if datos.get("empujar", false) and "golpe_desplazante" not in aprendidas:
		return &"habilidades_guardadas_invalidas"
	if datos.get("empuje_ultimo_doble", false) and (not datos.get("empujar", false) or "golpe_desplazante" not in aprendidas):
		return &"habilidades_guardadas_invalidas"
	if datos.get("contagio", "") not in ["", "veneno", "quemado"] or (datos.get("contagio", "") != "" and "contagio_arcano" not in aprendidas):
		return &"habilidades_guardadas_invalidas"
	for campo in ["pasos_inercia", "agarre_pasos"]:
		if not _es_numero_entero(datos.get(campo, 0)) or datos.get(campo, 0) < 0 or datos.get(campo, 0) > 2:
			return &"habilidades_guardadas_invalidas"
	if datos.get("pasos_inercia", 0) > 0 and "inercia" not in gastadas:
		return &"habilidades_guardadas_invalidas"
	if not datos.get("agarre_objetivo", "") is String or ((datos.get("agarre_objetivo", "") == "") != (datos.get("agarre_pasos", 0) == 0)):
		return &"habilidades_guardadas_invalidas"
	if datos.get("agarre_pasos", 0) > 0 and ("agarre" not in activas or usos.get("agarre") != 0):
		return &"habilidades_guardadas_invalidas"
	var senales: Variant = datos.get("senuelos", {})
	if not senales is Dictionary or (not senales.is_empty() and ("senuelo" not in activas or usos.get("senuelo") != 0)):
		return &"habilidades_guardadas_invalidas"
	for id: Variant in senales:
		var coord: Variant = senales[id]
		if not id is String or id.is_empty() or not coord is Array or coord.size() != 2 or not _es_numero_entero(coord[0]) or not _es_numero_entero(coord[1]):
			return &"habilidades_guardadas_invalidas"
	return &""

func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_finite(valor) and valor == roundf(valor))

func _ready() -> void:
	pv_max = fue + des + vol
	pv_actual = pv_max
	_setear_atributos_particula()
	_setear_atributos_particula_veneno()
	shaderMat.shader = shaderVeneno;
	shaderMatQ.shader = shaderQuemado;
	
	timer = Timer.new()
	timer.wait_time = 2.0
	
	get_tree().current_scene.add_child(timer)
	
	timer.timeout.connect(on_timer_timeout)
	#await timer.ready
	timer.start()

	#_aplicar_visual_clase()
	iniciar_turno()



func configurar_creacion(datos: Dictionary) -> bool:
	if ScriptEstadoPartida.validar_aventurero(datos) != &"":
		return false
	nombre = datos["nombre"].strip_edges()
	titulo = datos["titulo"].strip_edges()
	fue = datos["fuerza"]
	des = datos["destreza"]
	vol = datos["voluntad"]
	clase = datos["clase"]
	origen = datos["origen"]
	return true

func _setear_atributos_particula_veneno() -> void:
	particulasVeneno.scale = Vector2(2.5,2.5)
	particulasVeneno.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particulasVeneno.emission_sphere_radius = 12
	particulasVeneno.scale_amount_min = 0.5
	particulasVeneno.scale_amount_max = 0.8
	particulasVeneno.amount = 4
	particulasVeneno.texture = texturaVeneno
	particulasVeneno.explosiveness = 0.67
	particulasVeneno.randomness = 1
	particulasVeneno.gravity.y = -100
	var curva_escala := Curve.new()
	curva_escala.add_point(Vector2(0.0, 1.0)) # Inicio: Tamaño máximo
	curva_escala.add_point(Vector2(1.0, 0.0)) # Final: Tamaño cero
	particulasVeneno.scale_amount_curve = curva_escala
	particulasVeneno.emitting = false
	particulasVeneno.initial_velocity_min = 0
	particulasVeneno.initial_velocity_max = 20
	particulasVeneno.position.y = -240


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
		if particulasVeneno.get_parent() == null:
			sprite_render.add_child(particulasVeneno)
		_actualizar_efectos_estado()
		_actualizar_visual_sigilo()
	else:
		push_warning("No hay textura para dirección 0")


func inicializar(coordenada_inicial: Vector2i, capa: TileMapLayer) -> void:
	capa_referencia = capa
	coordenada_mapa = coordenada_inicial
	if capa_referencia:
		global_position = capa_referencia.to_global(capa_referencia.map_to_local(coordenada_mapa))

func consumir_paso_antorcha() -> bool:
	var antorcha := obtener_pila_antorcha_activa()
	if antorcha == null:
		return false
	if not activar_antorcha_si_necesario():
		return false
	if pasos_antorcha_actual > 1:
		pasos_antorcha_actual -= 1
		return true
	if not inventario.consumir_unidad(antorcha.id_instancia):
		return false
	return activar_antorcha_si_necesario()

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
	if pasos_inercia > 0:
		pasos_inercia -= 1
	else:
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
