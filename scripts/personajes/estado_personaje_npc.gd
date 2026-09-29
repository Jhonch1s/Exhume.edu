class_name EstadoPersonajeNPC
extends RefCounted

## Datos cambiantes de una instancia. La definición conserva los valores base.

const ATRIBUTOS := [&"fuerza", &"destreza", &"voluntad"]

var definicion: DefinicionPersonaje
var vida_actual: int
var atributos_actuales: Dictionary[StringName, int] = {}
var nivel_actual: int
var recursos_turno: RecursosTurnoActor
var _actitud_hacia_jugador: int


func _init(
	perfil: DefinicionPersonaje,
	vida_inicial: int = -1,
	atributos_iniciales: Dictionary[StringName, int] = {},
	nivel_inicial: int = 0
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
	_actitud_hacia_jugador = perfil.actitud_inicial_jugador
	if perfil.puede_combatir:
		recursos_turno = _crear_recursos_turno()


func _crear_recursos_turno() -> RecursosTurnoActor:
	return RecursosTurnoActor.new(
		definicion.movimiento_por_turno,
		definicion.acciones_principales_por_turno,
		definicion.acciones_adicionales_por_turno,
		definicion.reacciones_por_turno
	)


func esta_derrotado() -> bool:
	return vida_actual == 0


func recibir_danio(cantidad: int) -> int:
	if cantidad <= 0:
		return 0
	var anterior := vida_actual
	vida_actual = maxi(0, vida_actual - cantidad)
	return anterior - vida_actual


func curar(cantidad: int) -> int:
	if cantidad <= 0:
		return 0
	var aplicado := mini(cantidad, maxi(0, definicion.vida_maxima - vida_actual))
	vida_actual += aplicado
	return aplicado


func obtener_actitud_hacia_jugador() -> int:
	if definicion.actitud_hacia_jugador_fija:
		return definicion.actitud_inicial_jugador
	return _actitud_hacia_jugador


func establecer_actitud_hacia_jugador(nueva_actitud: int) -> bool:
	if definicion.actitud_hacia_jugador_fija or not _actitud_valida(nueva_actitud):
		return false
	_actitud_hacia_jugador = nueva_actitud
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
	}
	if not definicion.actitud_hacia_jugador_fija:
		estado["actitud_hacia_jugador"] = _actitud_hacia_jugador
	if recursos_turno != null:
		var restantes: Dictionary = {}
		for clave in RecursosTurnoActor.CLAVES:
			restantes[String(clave)] = recursos_turno.obtener(clave)
		estado["recursos_turno"] = restantes
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
	if definicion.actitud_hacia_jugador_fija:
		if estado.has("actitud_hacia_jugador"):
			return &"actitud_npc_guardada_invalida"
	elif (
		not _es_entero(estado.get("actitud_hacia_jugador"))
		or not _actitud_valida(int(estado["actitud_hacia_jugador"]))
	):
		return &"actitud_npc_guardada_invalida"
	if estado.size() != campos_base + int(tiene_recursos):
		return &"estado_npc_guardado_invalido"
	if tiene_recursos:
		if recursos_turno == null or not estado["recursos_turno"] is Dictionary:
			return &"recursos_turno_npc_guardados_invalidos"
		var motivo_recursos := recursos_turno.validar_restauracion(estado["recursos_turno"])
		if motivo_recursos != &"":
			return motivo_recursos
	return &""


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	vida_actual = int(estado["vida_actual"])
	nivel_actual = int(estado["nivel_actual"])
	for clave in ATRIBUTOS:
		atributos_actuales[clave] = int(estado["atributos"][String(clave)])
	if not definicion.actitud_hacia_jugador_fija:
		_actitud_hacia_jugador = int(estado["actitud_hacia_jugador"])
	if recursos_turno != null:
		# Los snapshots v2 previos al combate no contenían reservas del NPC.
		recursos_turno = _crear_recursos_turno()
		if estado.has("recursos_turno"):
			return recursos_turno.restaurar(estado["recursos_turno"])
	return &""


func _actitud_valida(valor: int) -> bool:
	return valor in [
		DefinicionPersonaje.ActitudInicialJugador.NEUTRAL,
		DefinicionPersonaje.ActitudInicialJugador.AMISTOSA,
		DefinicionPersonaje.ActitudInicialJugador.HOSTIL,
	]


func _es_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_finite(valor) and is_equal_approx(valor, roundf(valor)))
