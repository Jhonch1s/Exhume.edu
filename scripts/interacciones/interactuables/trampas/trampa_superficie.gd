@tool
class_name TrampaSuperficie
extends Interactuable

enum Estado {
	OCULTA,
	DESCUBIERTA,
	ACTIVADA,
	DESACTIVADA,
}

@export_category("Disparo automatico")
@export var escena_superficie: PackedScene = preload(
	"res://scenes/efectos_superficie/HumoVeneno.tscn"
)
@export_range(0, 8, 1) var radio: int = 1
@export var interrumpe_al_activar: bool = true

@export_category("Percepcion")
@export var estado: Estado = Estado.OCULTA
@export_range(1, 6, 1) var pulsos_descubrimiento: int = 3
@export_range(0.05, 1.0, 0.05) var duracion_pulso: float = 0.15

@export_category("Presentacion")
@export_enum("Veneno:0", "Fuego:1", "Neutra:2") var fila_atlas: int = 0

var motor_dados: MotorDados = MotorDados.new()
var _tween_descubrimiento: Tween


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_actualizar_presentacion()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and ajustar_a_celda_en_editor:
		_ajustar_al_centro_celda()


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	var opciones: Array[OpcionAccion] = []
	if estado != Estado.DESCUBIERTA:
		return opciones
	for atributo in [&"fue", &"des", &"vol"]:
		opciones.append(OpcionAccion.crear_habilitada(
			StringName("desarmar_%s" % atributo),
			TiposInteraccion.TipoAccion.INTERACTUAR,
			StringName("interaccion.desarmar_%s" % atributo),
			self,
			{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
			10,
			false,
			{},
			TiposInteraccion.TipoLineaEfecto.FISICA,
			TiposInteraccion.PoliticaCobro.AL_INTENTAR
		))
	return opciones


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion != null and opcion.id in [&"desarmar_fue", &"desarmar_des", &"desarmar_vol"]:
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func es_objetivo_impacto_perceptible() -> bool:
	return estado == Estado.ACTIVADA


func obtener_estado_persistente() -> Dictionary:
	return {"estado": estado}


func validar_estado_persistente(estado: Dictionary) -> StringName:
	if estado.size() == 2 and estado.has("activada") and estado.has("presentacion"):
		var presentacion_anterior: Variant = estado["presentacion"]
		return &"" if (
			estado["activada"] is bool
			and (presentacion_anterior is int or presentacion_anterior is float)
			and int(presentacion_anterior) >= 0
			and int(presentacion_anterior) <= 2
		) else &"estado_trampa_invalido"
	if estado.size() != 1 or not estado.has("estado"):
		return &"estado_trampa_invalido"
	if not (estado["estado"] is int or estado["estado"] is float):
		return &"estado_trampa_invalido"
	var valor := int(estado["estado"])
	if valor < Estado.OCULTA or valor > Estado.DESACTIVADA:
		return &"estado_trampa_invalido"
	return &""


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	if estado.has("estado"):
		self.estado = int(estado["estado"])
	else:
		self.estado = (
			Estado.ACTIVADA if estado["activada"]
			else Estado.DESCUBIERTA if int(estado["presentacion"]) == 2
			else Estado.OCULTA
		)
	_actualizar_presentacion()
	return &""


func descubrir() -> bool:
	if estado != Estado.OCULTA:
		return false
	estado = Estado.DESCUBIERTA
	_parpadear_descubrimiento()
	return true


func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
	return tipo in [
		TiposInteraccion.TipoAccion.ENTRAR,
		TiposInteraccion.TipoAccion.IMPACTAR,
	] and estado in [Estado.OCULTA, Estado.DESCUBIERTA]


func obtener_reacciones_encadenadas(
	tipo: TiposInteraccion.TipoAccion
) -> Array[Object]:
	var trampas: Array[Object] = []
	if tipo not in [
		TiposInteraccion.TipoAccion.ENTRAR,
		TiposInteraccion.TipoAccion.IMPACTAR,
	] or tablero == null:
		return trampas
	for direccion in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var celda := tablero.obtener_celda(coordenada_mapa + direccion)
		if celda == null:
			continue
		for interactuable in celda.interactuables.duplicate():
			if interactuable is TrampaSuperficie and interactuable != self:
				trampas.append(interactuable)
	trampas.sort_custom(func(a, b): return String(a.id_instancia) < String(b.id_instancia))
	return trampas


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo == TiposInteraccion.TipoAccion.INTERACTUAR:
		if contexto.id_accion not in [&"desarmar_fue", &"desarmar_des", &"desarmar_vol"]:
			return &"accion_no_admitida"
		if estado != Estado.DESCUBIERTA:
			return &"trampa_no_descubierta"
		if not contexto.actor is Ficha:
			return &"actor_no_es_ficha"
		if contexto.celda_objetivo != coordenada_mapa:
			return &"celda_objetivo_invalida"
		if tablero == null or escena_superficie == null:
			return &"trampa_no_configurada"
		return &""
	if contexto.tipo not in [
		TiposInteraccion.TipoAccion.ENTRAR,
		TiposInteraccion.TipoAccion.IMPACTAR,
	]:
		return &"accion_no_admitida"
	if contexto.tipo == TiposInteraccion.TipoAccion.IMPACTAR:
		if contexto.item == null or &"impacto" not in contexto.etiquetas:
			return &"impacto_incoherente"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	if tablero == null or escena_superficie == null:
		return &"trampa_no_configurada"
	if estado == Estado.ACTIVADA:
		return &"trampa_ya_activada"
	if estado == Estado.DESACTIVADA:
		return &"trampa_desactivada"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	if contexto.tipo == TiposInteraccion.TipoAccion.INTERACTUAR:
		return _resolver_desarme(contexto)
	return _activar()


func _activar() -> ResultadoAccion:
	var afectadas := tablero.desplegar_efecto_superficie(
		escena_superficie,
		coordenada_mapa,
		radio,
		StringName("%s_superficie" % id_instancia)
	)
	if afectadas.is_empty():
		return ResultadoAccion.crear_fallo(&"superficie_no_desplegada")
	estado = Estado.ACTIVADA
	_actualizar_presentacion()
	var cambios: Array[Dictionary] = []
	for coord in afectadas:
		cambios.append({
			"tipo": &"superficie_desplegada",
			"coordenada": coord,
		})
	return ResultadoAccion.crear_exito(
		[&"trampa.superficie_activada"],
		[],
		cambios,
		{},
		interrumpe_al_activar
	)


func _resolver_desarme(contexto: ContextoAccion) -> ResultadoAccion:
	var atributo := _obtener_atributo_desarme(contexto.actor, contexto.id_accion)
	var desventajas: Array[StringName] = []
	if contexto.actor.clase != "Guerrero":
		desventajas.append(&"desarme_sin_especialidad")
	var tirada := motor_dados.resolver_prueba(
		atributo,
		[],
		desventajas,
		TiposTirada.Origen.SOLICITADA,
		TiposTirada.Presentacion.PRIMER_PLANO
	)
	if tirada.exitosa:
		estado = Estado.DESACTIVADA
		_actualizar_presentacion()
		return ResultadoAccion.crear_exito(
			[&"trampa.desactivada"], [], [{
				&"objetivo_id": id_instancia,
				&"propiedad": &"estado",
				&"nueva": Estado.DESACTIVADA,
			}]
		).con_tirada(tirada)
	var resultado := _activar()
	if not resultado.exitosa:
		return resultado.con_tirada(tirada)
	var mensajes: Array[StringName] = [&"trampa.desarme_fallido"]
	mensajes.append_array(resultado.mensajes)
	return ResultadoAccion.crear_exito(
		mensajes,
		resultado.efectos_aplicados,
		resultado.cambios_estado,
		{},
		resultado.interrumpe_movimiento,
		resultado.terminal,
		resultado.solicitudes_efecto,
		resultado.destino_item
	).con_tirada(tirada)


func _obtener_atributo_desarme(actor: Ficha, id_accion: StringName) -> int:
	match id_accion:
		&"desarmar_fue":
			return actor.obtener_fuerza()
		&"desarmar_des":
			return actor.obtener_destreza()
		_:
			return actor.obtener_voluntad()


func _actualizar_presentacion() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null:
		return
	if estado != Estado.DESCUBIERTA and _tween_descubrimiento != null:
		_tween_descubrimiento.kill()
		_tween_descubrimiento = null
	sprite.region_rect.position = Vector2(
		64.0 if estado == Estado.ACTIVADA else 0.0,
		float(fila_atlas * 32)
	)
	sprite.modulate.a = (
		1.0 if Engine.is_editor_hint() or estado == Estado.ACTIVADA else 0.0
	)


func _parpadear_descubrimiento() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null or not is_inside_tree():
		return
	_tween_descubrimiento = create_tween()
	for _pulso in pulsos_descubrimiento:
		_tween_descubrimiento.tween_property(sprite, ^"modulate:a", 1.0, duracion_pulso)
		_tween_descubrimiento.tween_property(sprite, ^"modulate:a", 0.0, duracion_pulso)
