class_name EfectosEquipo
extends RefCounted

const ATRIBUTOS := ["fuerza", "destreza", "voluntad"]
const PENALIZACIONES := [&"debilitado_fuerza", &"debilitado_destreza", &"debilitado_voluntad"]
const PRUEBAS := ["ataque", "esquiva", "fuerza", "destreza", "voluntad"]


static func entero(valor: Variant, minimo: int, maximo: int) -> bool:
	return (valor is int or valor is float) and is_finite(float(valor)) and valor == floor(float(valor)) and valor >= minimo and valor <= maximo


static func validar(efectos: Variant) -> bool:
	if not efectos is Array or efectos.size() > 16:
		return false
	for e: Variant in efectos:
		if not e is Dictionary:
			return false
		match e.get("tipo"):
			"armadura":
				if not entero(e.get("valor"), 1, 5):
					return false
			"atributo":
				if e.get("atributo") not in ATRIBUTOS or not entero(e.get("valor"), -5, 5) or e.valor == 0:
					return false
			"tirada":
				if e.get("prueba") not in PRUEBAS or e.get("modo") not in ["ventaja", "desventaja"]:
					return false
			"dano", "estado", "penalizacion":
				if e.get("alcance") not in ["arma", "directo"] or not entero(e.get("valor"), 1, 99):
					return false
				if e.tipo != "dano":
					if not entero(e.get("duracion"), 1, 99) or e.get("salvacion") not in ["", "fuerza", "destreza", "voluntad"]:
						return false
					if e.tipo == "estado" and e.get("estado") not in ["veneno", "quemado"]:
						return false
					if e.tipo == "penalizacion" and (e.get("atributo") not in ATRIBUTOS or e.valor > 5):
						return false
			_:
				return false
	return true


static func entradas(actor: Object) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if actor == null or not actor.has_method("obtener_equipo"):
		return resultado
	for ranura: int in actor.obtener_equipo().ranuras:
		var item: ItemInstancia = actor.obtener_equipo().ranuras[ranura]
		for efecto: Dictionary in item.definicion.efectos_equipo:
			resultado.append({"efecto": efecto, "ranura": ranura, "fuente": StringName("equipo:%s" % item.id_instancia)})
	return resultado


static func bono_atributo(actor: Object, atributo: String) -> int:
	var bono := 0
	for entrada in entradas(actor):
		var e: Dictionary = entrada.efecto
		if e.tipo == "atributo" and e.atributo == atributo:
			bono += int(e.valor)
	if actor.has_method("obtener_estado"):
		var estado: EstadoActor = actor.obtener_estado(StringName("debilitado_" + atributo))
		if estado != null:
			bono -= int(estado.magnitud)
	return bono


static func base(actor: Object, atributo: String) -> int:
	if actor.has_method("obtener_atributo_base"):
		return actor.obtener_atributo_base(atributo)
	return actor.call(StringName("obtener_" + atributo))


static func fuentes(actor: Object, atributo: String, prueba: String, modo: String) -> Array[StringName]:
	var resultado: Array[StringName] = []
	for entrada in entradas(actor):
		var e: Dictionary = entrada.efecto
		if e.tipo == "tirada" and e.modo == modo and e.prueba in [atributo, prueba] and not resultado.has(entrada.fuente):
			resultado.append(entrada.fuente)
	return resultado


static func resolver_prueba(motor: MotorDados, actor: Object, atributo: String, origen: int = TiposTirada.Origen.AUTOMATICA, presentacion: int = TiposTirada.Presentacion.SOLO_LOG, prueba: String = "", desventajas: Array[StringName] = []) -> ResultadoPrueba:
	var valor := base(actor, atributo)
	var modificadores: Array[Dictionary] = []
	var bono := bono_atributo(actor, atributo)
	if bono != 0:
		modificadores.append({&"fuente": &"equipo_y_estados", &"valor": bono})
	var negativas := fuentes(actor, atributo, prueba, "desventaja")
	negativas.append_array(desventajas)
	return motor.resolver_prueba(valor, fuentes(actor, atributo, prueba, "ventaja"), negativas, origen, presentacion, modificadores)


static func aplica(entrada: Dictionary, es_arma: bool) -> bool:
	return entrada.efecto.alcance == "directo" or (es_arma and entrada.ranura == 3)


static func bono_dano(actor: Object, es_arma: bool) -> int:
	var bono := 0
	for entrada in entradas(actor):
		if entrada.efecto.tipo == "dano" and aplica(entrada, es_arma):
			bono += int(entrada.efecto.valor)
	return bono


static func bono_armadura(actor: Object) -> int:
	var bono := 0
	for entrada in entradas(actor):
		if entrada.efecto.tipo == "armadura":
			bono += int(entrada.efecto.valor)
	return bono


static func bono_fuerza_dano(actor: Object) -> int:
	var fuerza := base(actor, "fuerza") + bono_atributo(actor, "fuerza")
	return maxi(0, floori(float(fuerza - 1) / 2.0))


static func terminos_dano_armas(actor: Object) -> Array[Dictionary]:
	var terminos: Array[Dictionary] = []
	if actor.has_method("obtener_equipo"):
		var ranuras: Dictionary = actor.obtener_equipo().ranuras
		var principal: ItemInstancia = ranuras.get(3)
		if principal != null:
			_agregar_dado_arma(terminos, principal)
			var secundaria: ItemInstancia = ranuras.get(4)
			if secundaria != null and &"daga" in principal.definicion.etiquetas and &"daga" in secundaria.definicion.etiquetas:
				_agregar_dado_arma(terminos, secundaria)
	if terminos.is_empty():
		terminos.append({&"cantidad": 1, &"caras": 2, &"signo": 1})
	return terminos


static func _agregar_dado_arma(terminos: Array[Dictionary], item: ItemInstancia) -> void:
	var magnitudes := item.definicion.magnitudes
	if magnitudes.has(&"dano_arma_dados") and magnitudes.has(&"dano_arma_caras"):
		terminos.append({
			&"cantidad": int(magnitudes[&"dano_arma_dados"]),
			&"caras": int(magnitudes[&"dano_arma_caras"]),
			&"signo": 1,
		})


static func aplicar_impacto(actor: Object, objetivo: Object, es_arma: bool, motor: MotorDados, aplicador: AplicadorEfectos, evento: StringName) -> Array:
	var resultados: Array = []
	for entrada in entradas(actor):
		var e: Dictionary = entrada.efecto
		if e.tipo not in ["estado", "penalizacion"] or not aplica(entrada, es_arma) or not objetivo.puede_actuar():
			continue
		if e.salvacion != "":
			var salvacion := resolver_prueba(motor, objetivo, e.salvacion)
			if not salvacion.valida or salvacion.exitosa:
				if salvacion.valida:
					resultados.append(ResultadoEfectoAplicado.new(&"equipo_resistido", &"estado", objetivo, 0.0, [&"estado.efecto_equipo_resistido"]))
				continue
		var clave := StringName(e.estado if e.tipo == "estado" else "debilitado_" + e.atributo)
		var resultado: Variant = aplicador.aplicar(SolicitudEfecto.new(clave, &"estado", objetivo, evento, float(e.valor), int(e.duracion), TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, actor))
		if not resultado is StringName:
			resultados.append(resultado)
	return resultados


static func describir(e: Dictionary) -> String:
	match e.tipo:
		"armadura": return "Equipado: reduce %d de daño de ataques físicos (mínimo 1)." % int(e.valor)
		"atributo": return "Equipado: %+d %s." % [int(e.valor), String(e.atributo).to_upper()]
		"tirada": return "Equipado: %s en %s." % [e.modo, e.prueba]
		"dano": return "Al acertar (%s): +%d daño." % [e.alcance, int(e.valor)]
		_: return "Al acertar (%s): %s %d, %d turnos%s." % [e.alcance, e.get("estado", "-" + e.get("atributo", "")), int(e.valor), int(e.duracion), "; salvación " + e.salvacion if e.salvacion != "" else ""]
