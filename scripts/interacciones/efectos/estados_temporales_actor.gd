class_name EstadosTemporalesActor
extends RefCounted

## Estado por actor; ServicioTurnos conserva las reglas de daño y expiración.
signal estado_cambiado(clave: StringName, estado: EstadoActor)

var _estados: Dictionary[StringName, EstadoActor] = {}


func obtener_estado(clave: StringName) -> EstadoActor:
	return _estados.get(clave) as EstadoActor


func obtener_claves_estado() -> Array[StringName]:
	var claves: Array[StringName] = []
	claves.assign(_estados.keys())
	claves.sort_custom(func(a, b): return String(a) < String(b))
	return claves


func retirar_estado(clave: StringName) -> bool:
	var estado := obtener_estado(clave)
	if estado == null:
		return false
	_estados.erase(clave)
	estado_cambiado.emit(clave, estado)
	return true


func aplicar_o_renovar_estado(
	clave: StringName, magnitud: float, duracion_total: int, ticks_pendientes: int,
	_fuente: Object = null, terminos_dano_tick: Array[Dictionary] = []
) -> Dictionary:
	if (
		clave == &"" or not is_finite(magnitud) or magnitud < 0.0
		or duracion_total <= 0 or ticks_pendientes < 0
		or (magnitud == 0.0 and terminos_dano_tick.is_empty())
		or _validar_terminos_dano(terminos_dano_tick) != &""
	):
		return {}
	# Enredado termina al liberarse, no al consumir ticks de duración.
	if clave == &"enredado":
		ticks_pendientes = 0
	var estado := obtener_estado(clave)
	var creado := estado == null
	if creado:
		estado = EstadoActor.new(clave, magnitud, duracion_total, ticks_pendientes, terminos_dano_tick)
		_estados[clave] = estado
	else:
		estado.renovar(magnitud, duracion_total, ticks_pendientes, terminos_dano_tick)
	estado_cambiado.emit(clave, estado)
	return {
		&"clave": clave, &"creado": creado,
		&"duracion_total": estado.duracion_total,
		&"ticks_pendientes": estado.ticks_pendientes,
	}


func consumir_tick_estado(clave: StringName) -> Dictionary:
	var estado := obtener_estado(clave)
	if estado == null or clave == &"enredado" or estado.ticks_pendientes <= 0:
		return {}
	var restantes := estado.consumir_tick()
	var expirado := restantes == 0
	if expirado:
		_estados.erase(clave)
	estado_cambiado.emit(clave, estado)
	return {
		&"tipo": &"estado_tick", &"clave": clave,
		&"ticks_restantes": restantes, &"expirado": expirado,
	}


func obtener_estado_persistente() -> Array[Dictionary]:
	var datos: Array[Dictionary] = []
	for clave in obtener_claves_estado():
		var estado := obtener_estado(clave)
		datos.append({
			"clave": String(clave), "magnitud": estado.magnitud,
			"duracion_total": estado.duracion_total,
			"ticks_pendientes": estado.ticks_pendientes,
			"terminos_dano_tick": estado.terminos_dano_tick,
		})
	return datos


func validar_estado_persistente(datos_estados: Variant) -> StringName:
	if not datos_estados is Array:
		return &"estados_actor_guardados_invalidos"
	var claves: Dictionary[String, bool] = {}
	for datos: Variant in datos_estados:
		if not datos is Dictionary:
			return &"estados_actor_guardados_invalidos"
		var clave: Variant = datos.get("clave")
		var magnitud: Variant = datos.get("magnitud")
		if (
			not clave is String or (clave not in ["enredado", "caido", "quemado", "veneno"] and StringName(clave) not in EfectosEquipo.PENALIZACIONES)
			or claves.has(clave) or not (magnitud is int or magnitud is float)
			or not is_finite(float(magnitud)) or magnitud < 0.0
			or not _es_entero(datos.get("duracion_total")) or datos["duracion_total"] <= 0
			or not _es_entero(datos.get("ticks_pendientes")) or datos["ticks_pendientes"] < 0
			or datos["ticks_pendientes"] > datos["duracion_total"]
		):
			return &"estados_actor_guardados_invalidos"
		var terminos: Variant = _leer_terminos_guardados(datos.get("terminos_dano_tick", []))
		if terminos == null:
			return &"estados_actor_guardados_invalidos"
		if (
			(magnitud == 0.0 and terminos.is_empty())
			or (StringName(clave) in EfectosEquipo.PENALIZACIONES and (magnitud < 1 or magnitud > 5 or magnitud != floorf(magnitud) or datos["ticks_pendientes"] < 1 or not terminos.is_empty()))
			or _validar_terminos_dano(terminos) != &""
			or (clave in ["enredado", "caido"] and (magnitud != 1.0 or not terminos.is_empty()))
			or (clave == "caido" and datos["ticks_pendientes"] != 1)
			or (clave in ["quemado", "veneno"] and (magnitud != floorf(magnitud) or datos["ticks_pendientes"] == 0))
		):
			return &"estados_actor_guardados_invalidos"
		claves[clave] = true
	return &""


func restaurar_estado_persistente(datos_estados: Variant) -> StringName:
	var motivo := validar_estado_persistente(datos_estados)
	if motivo != &"":
		return motivo
	var nuevos: Dictionary[StringName, EstadoActor] = {}
	for datos: Dictionary in datos_estados:
		var clave := StringName(datos["clave"])
		var terminos: Array[Dictionary] = _leer_terminos_guardados(datos.get("terminos_dano_tick", []))
		nuevos[clave] = EstadoActor.new(
			clave, float(datos["magnitud"]), int(datos["duracion_total"]),
			0 if clave == &"enredado" else int(datos["ticks_pendientes"]), terminos
		)
	var anteriores := _estados
	_estados = nuevos
	for clave in anteriores:
		if not nuevos.has(clave):
			estado_cambiado.emit(clave, anteriores[clave])
	for clave in obtener_claves_estado():
		estado_cambiado.emit(clave, _estados[clave])
	return &""


func _leer_terminos_guardados(datos: Variant) -> Variant:
	if not datos is Array:
		return null
	var terminos: Array[Dictionary] = []
	for termino: Variant in datos:
		if not termino is Dictionary:
			return null
		for clave in [&"cantidad", &"caras", &"signo"]:
			if not _es_entero(termino.get(clave)):
				return null
		# JSON representa los enteros como float; el motor conserva su contrato int.
		terminos.append({
			&"cantidad": int(termino["cantidad"]),
			&"caras": int(termino["caras"]),
			&"signo": int(termino["signo"]),
		})
	return terminos


func _validar_terminos_dano(terminos: Array[Dictionary]) -> StringName:
	if terminos.is_empty():
		return &""
	var motivo := MotorDados.new().validar_cantidad(
		terminos, 0, TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
	)
	if motivo != &"":
		return motivo
	for termino in terminos:
		if termino[&"signo"] != 1:
			return &"signo_dano_tick_invalido"
	return &""


func _es_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_finite(valor) and valor == roundf(valor))
