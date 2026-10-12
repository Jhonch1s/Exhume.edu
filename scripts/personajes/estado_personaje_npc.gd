class_name EstadoPersonajeNPC
extends RefCounted

## Datos cambiantes de una instancia. La definición conserva los valores base.

const ATRIBUTOS := [&"fuerza", &"destreza", &"voluntad"]
const PUNTOS_MINIMOS := -10
const PUNTOS_MAXIMOS := 10
const UMBRAL_HOSTIL := -3
const UMBRAL_AMISTOSO := 3
const PENALIZACION_AGRESION := -2

var definicion: DefinicionPersonaje
var _vida_actual: int = -1
var vida_actual: int:
	get:
		return _vida_actual
	set(valor):
		if _vida_actual != 0:
			_vida_actual = clampi(valor, 0, definicion.vida_maxima)
var atributos_actuales: Dictionary[StringName, int] = {}
var nivel_actual: int
var recursos_turno: RecursosTurnoActor
var estados_temporales := EstadosTemporalesActor.new()
var ultima_posicion_conocida: Variant = null
var coordenada_origen: Variant = null
var _puntos_actitud: int


func _init(
	perfil: DefinicionPersonaje,
	vida_inicial: int = -1,
	atributos_iniciales: Dictionary[StringName, int] = {},
	nivel_inicial: int = 0,
	movimiento_habilitado: bool = false
) -> void:
	definicion = perfil
	vida_actual = perfil.vida_maxima if vida_inicial < 0 else vida_inicial
	atributos_actuales = {
		&"fuerza": perfil.fuerza,
		&"destreza": perfil.destreza,
		&"voluntad": perfil.voluntad,
	}
	for clave in ATRIBUTOS:
		if atributos_iniciales.has(clave):
			atributos_actuales[clave] = atributos_iniciales[clave]
	nivel_actual = perfil.nivel if nivel_inicial <= 0 else nivel_inicial
	_puntos_actitud = _puntos_para_actitud(perfil.actitud_inicial_jugador)
	if perfil.puede_combatir or movimiento_habilitado:
		habilitar_movimiento()


func habilitar_movimiento() -> void:
	if recursos_turno == null:
		recursos_turno = _crear_recursos_turno(atributos_actuales[&"destreza"])


func _crear_recursos_turno(destreza: int) -> RecursosTurnoActor:
	return RecursosTurnoActor.new(
		definicion.calcular_movimiento(destreza),
		definicion.acciones_principales_por_turno,
		definicion.acciones_adicionales_por_turno,
		definicion.reacciones_por_turno
	)


func esta_derrotado() -> bool:
	return esta_muerto()


func esta_muerto() -> bool:
	return vida_actual == 0


func recibir_danio(cantidad: int) -> int:
	if cantidad <= 0:
		return 0
	var anterior := vida_actual
	vida_actual = maxi(0, vida_actual - cantidad)
	return anterior - vida_actual


func curar(cantidad: int) -> int:
	if cantidad <= 0 or esta_muerto():
		return 0
	var aplicado := mini(cantidad, maxi(0, definicion.vida_maxima - vida_actual))
	vida_actual += aplicado
	return aplicado


func obtener_actitud_hacia_jugador() -> int:
	if definicion.actitud_hacia_jugador_fija:
		return definicion.actitud_inicial_jugador
	return _actitud_para_puntos(_puntos_actitud)


func obtener_puntos_actitud() -> int:
	if definicion.actitud_hacia_jugador_fija:
		return _puntos_para_actitud(definicion.actitud_inicial_jugador)
	return _puntos_actitud


func modificar_actitud_hacia_jugador(delta: int) -> int:
	if definicion.actitud_hacia_jugador_fija:
		return 0
	var aplicado := clampi(delta, PUNTOS_MINIMOS - _puntos_actitud, PUNTOS_MAXIMOS - _puntos_actitud)
	_puntos_actitud += aplicado
	return aplicado


func establecer_actitud_hacia_jugador(nueva_actitud: int) -> bool:
	if definicion.actitud_hacia_jugador_fija or not _actitud_valida(nueva_actitud):
		return false
	_puntos_actitud = _puntos_para_actitud(nueva_actitud)
	return true


func obtener_estado_persistente() -> Dictionary:
	var estado := {
		"vida_actual": vida_actual,
		"atributos": {
			"fuerza": atributos_actuales.get(&"fuerza"),
			"destreza": atributos_actuales.get(&"destreza"),
			"voluntad": atributos_actuales.get(&"voluntad"),
		},
		"nivel_actual": nivel_actual,
		"estados": estados_temporales.obtener_estado_persistente(),
	}
	if not definicion.actitud_hacia_jugador_fija:
		estado["actitud_hacia_jugador"] = obtener_actitud_hacia_jugador()
		estado["puntos_actitud"] = _puntos_actitud
	if recursos_turno != null:
		var restantes: Dictionary = {}
		for clave in RecursosTurnoActor.CLAVES:
			restantes[String(clave)] = recursos_turno.obtener(clave)
		estado["recursos_turno"] = restantes
		estado["movimiento_maximo"] = recursos_turno.obtener_maximo(RecursosTurnoActor.MOVIMIENTO)
		estado["ultima_posicion_conocida"] = (
			[ultima_posicion_conocida.x, ultima_posicion_conocida.y]
			if ultima_posicion_conocida is Vector2i else null
		)
		if coordenada_origen is Vector2i:
			estado["coordenada_origen"] = [coordenada_origen.x, coordenada_origen.y]
	return estado


func validar_estado_persistente(estado: Dictionary) -> StringName:
	if (
		not _es_entero(estado.get("vida_actual"))
		or int(estado["vida_actual"]) < 0
		or int(estado["vida_actual"]) > definicion.vida_maxima
		or not _es_entero(estado.get("nivel_actual"))
		or int(estado["nivel_actual"]) < 1
		or int(estado["nivel_actual"]) > 99
	):
		return &"estado_npc_guardado_invalido"
	var atributos: Variant = estado.get("atributos")
	if not atributos is Dictionary or atributos.size() != ATRIBUTOS.size():
		return &"atributos_npc_guardados_invalidos"
	for clave in ATRIBUTOS:
		var valor: Variant = atributos.get(String(clave))
		if not _es_entero(valor) or int(valor) < 0 or int(valor) > 99:
			return &"atributos_npc_guardados_invalidos"
	var campos_base := 3 if definicion.actitud_hacia_jugador_fija else 4
	var tiene_recursos := estado.has("recursos_turno")
	var tiene_estados := estado.has("estados")
	var tiene_movimiento_maximo := estado.has("movimiento_maximo")
	var tiene_memoria := estado.has("ultima_posicion_conocida")
	var tiene_origen := estado.has("coordenada_origen")
	var tiene_puntos := estado.has("puntos_actitud")
	if definicion.actitud_hacia_jugador_fija:
		if estado.has("actitud_hacia_jugador") or tiene_puntos:
			return &"actitud_npc_guardada_invalida"
	elif (
		not _es_entero(estado.get("actitud_hacia_jugador"))
		or not _actitud_valida(int(estado["actitud_hacia_jugador"]))
	):
		return &"actitud_npc_guardada_invalida"
	if tiene_puntos and (
		not _es_entero(estado["puntos_actitud"])
		or estado["puntos_actitud"] < PUNTOS_MINIMOS or estado["puntos_actitud"] > PUNTOS_MAXIMOS
		or _actitud_para_puntos(int(estado["puntos_actitud"])) != int(estado["actitud_hacia_jugador"])
	):
		return &"actitud_npc_guardada_invalida"
	if (
		estado.size() != campos_base + int(tiene_recursos) + int(tiene_estados) + int(tiene_movimiento_maximo) + int(tiene_memoria) + int(tiene_origen) + int(tiene_puntos)
		or ((tiene_movimiento_maximo or tiene_memoria or tiene_origen) and not tiene_recursos)
	):
		return &"estado_npc_guardado_invalido"
	var recuerdo: Variant = estado.get("ultima_posicion_conocida")
	if recuerdo != null and (
		not recuerdo is Array or recuerdo.size() != 2
		or not _es_entero(recuerdo[0]) or not _es_entero(recuerdo[1])
	):
		return &"memoria_npc_guardada_invalida"
	var origen: Variant = estado.get("coordenada_origen")
	if tiene_origen and (
		not origen is Array or origen.size() != 2
		or not _es_entero(origen[0]) or not _es_entero(origen[1])
	):
		return &"origen_npc_guardado_invalido"
	var motivo_estados := estados_temporales.validar_estado_persistente(estado.get("estados", []))
	if motivo_estados != &"":
		return motivo_estados
	if tiene_recursos:
		if recursos_turno == null or not estado["recursos_turno"] is Dictionary:
			return &"recursos_turno_npc_guardados_invalidos"
		var movimiento_guardado: Variant = estado.get("movimiento_maximo", 7)
		var recursos_guardados := _crear_recursos_turno(int(atributos["destreza"]))
		# Antes del movimiento fijo, los snapshots guardaban el máximo DES + 3.
		var maximo_anterior := RecursosTurnoActor.calcular_movimiento(int(atributos["destreza"]))
		var migra_movimiento: bool = definicion.movimiento_fijo >= 0 and movimiento_guardado == maximo_anterior
		if (
			not _es_entero(movimiento_guardado)
			or (tiene_movimiento_maximo and movimiento_guardado != recursos_guardados.obtener_maximo(RecursosTurnoActor.MOVIMIENTO) and not migra_movimiento)
		):
			return &"recursos_turno_npc_guardados_invalidos"
		var motivo_recursos := recursos_guardados.validar_restauracion(estado["recursos_turno"], int(movimiento_guardado))
		if motivo_recursos != &"":
			return motivo_recursos
	return &""


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	# Cargar restaura el momento guardado, incluso si el NPC entonces estaba vivo.
	_vida_actual = int(estado["vida_actual"])
	nivel_actual = int(estado["nivel_actual"])
	for clave in ATRIBUTOS:
		atributos_actuales[clave] = int(estado["atributos"][String(clave)])
	if not definicion.actitud_hacia_jugador_fija:
		_puntos_actitud = int(estado.get("puntos_actitud", _puntos_para_actitud(int(estado["actitud_hacia_jugador"]))))
	var recuerdo: Variant = estado.get("ultima_posicion_conocida")
	ultima_posicion_conocida = Vector2i(int(recuerdo[0]), int(recuerdo[1])) if recuerdo is Array else null
	if estado.has("coordenada_origen"):
		var origen: Array = estado["coordenada_origen"]
		coordenada_origen = Vector2i(int(origen[0]), int(origen[1]))
	# Los snapshots anteriores no tenían estados temporales del NPC.
	estados_temporales.restaurar_estado_persistente(estado.get("estados", []))
	if recursos_turno != null:
		# Los snapshots v2 previos al combate no contenían reservas del NPC.
		recursos_turno = _crear_recursos_turno(atributos_actuales[&"destreza"])
		if estado.has("recursos_turno"):
			return recursos_turno.restaurar(estado["recursos_turno"], int(estado.get("movimiento_maximo", 7)))
	return &""


static func _puntos_para_actitud(actitud: int) -> int:
	if actitud == DefinicionPersonaje.ActitudInicialJugador.HOSTIL:
		return UMBRAL_HOSTIL
	if actitud == DefinicionPersonaje.ActitudInicialJugador.AMISTOSA:
		return UMBRAL_AMISTOSO
	return 0


static func _actitud_para_puntos(puntos: int) -> int:
	if puntos <= UMBRAL_HOSTIL:
		return DefinicionPersonaje.ActitudInicialJugador.HOSTIL
	if puntos >= UMBRAL_AMISTOSO:
		return DefinicionPersonaje.ActitudInicialJugador.AMISTOSA
	return DefinicionPersonaje.ActitudInicialJugador.NEUTRAL


func _actitud_valida(valor: int) -> bool:
	return valor in [
		DefinicionPersonaje.ActitudInicialJugador.NEUTRAL,
		DefinicionPersonaje.ActitudInicialJugador.AMISTOSA,
		DefinicionPersonaje.ActitudInicialJugador.HOSTIL,
	]


func _es_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_finite(valor) and is_equal_approx(valor, roundf(valor)))
