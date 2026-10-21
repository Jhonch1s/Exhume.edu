extends CanvasLayer

var escenario: Node
var escenario_descanso: Node2D
var fogata: FuenteLuzInteractuable
var descanso_pendiente := false

const ZONA_DESCANSO := preload("res://scenes/DescansoCuevas/DescansoCuevas.tscn")
const ACCION_DESCANSAR := &"campamento_descansar"
const ACCION_CONFIRMAR := &"campamento_confirmar_descanso"
const ACCION_VOLVER := &"campamento_volver"
const ACCION_GUARDAR := &"campamento_guardar"
const ACCION_CARGAR := &"campamento_cargar"


func _ready() -> void:
	_preparar_escenario()
	actualizar()


func _preparar_escenario() -> void:
	escenario_descanso = (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	escenario_descanso.es_escenario_de_descanso = true
	escenario_descanso.control_descanso = self
	escenario_descanso.nombreClase = escenario.ficha_jugador.clase
	escenario_descanso.get_node("Zona").free()
	var zona := ZONA_DESCANSO.instantiate()
	zona.name = "Zona"
	escenario_descanso.add_child(zona)
	fogata = zona.get_node("Interactuables/FuentesLuz/FogataDescanso") as FuenteLuzInteractuable
	$ContenedorEscenario/VistaEscenario.add_child(escenario_descanso)
	escenario_descanso.menu_contextual.cancelado.connect(cancelar_descanso)
	escenario_descanso.menu_contextual.visibility_changed.connect(_al_cambiar_visibilidad_menu)
	_sincronizar_ficha_al_crearse()


func _sincronizar_ficha_al_crearse() -> void:
	while is_instance_valid(escenario_descanso) and (
		escenario_descanso.ficha_jugador == null
		or escenario_descanso.hud.ficha != escenario_descanso.ficha_jugador
	):
		await get_tree().process_frame
	if not is_instance_valid(escenario_descanso) or not is_instance_valid(escenario):
		return
	var ficha_campamento: Ficha = escenario_descanso.ficha_jugador
	var datos: Dictionary = escenario.ficha_jugador.obtener_estado_persistente()
	datos["coordenada"] = [ficha_campamento.coordenada_mapa.x, ficha_campamento.coordenada_mapa.y]
	var motivo := ficha_campamento.restaurar_estado_persistente(datos)
	if motivo != &"":
		push_error("No se pudo preparar la ficha del descanso: %s" % motivo)
		return
	escenario_descanso.hud.actualizar_desde_ficha()
	escenario_descanso.centrar_camara_en_ficha()


func actualizar() -> void:
	if not is_instance_valid(escenario) or not is_instance_valid(escenario_descanso):
		return
	var ficha: Ficha = escenario.ficha_jugador
	if is_instance_valid(escenario_descanso.ficha_jugador):
		var ficha_campamento: Ficha = escenario_descanso.ficha_jugador
		ficha_campamento.pv_actual = ficha.pv_actual
		ficha_campamento.energia_actual = ficha.energia_actual
		ficha_campamento.raciones = ficha.raciones
		ficha_campamento.usos_ataque_doble = ficha.usos_ataque_doble
		ficha_campamento.usos_ocultarse = ficha.usos_ocultarse
		ficha_campamento.usos_bola_fuego = ficha.usos_bola_fuego
		ficha_campamento.turnos_oculto = ficha.turnos_oculto
		escenario_descanso.hud.actualizar_desde_ficha()


func es_fogata(objetivo: Object) -> bool:
	return objetivo == fogata


func es_opcion_campamento(opcion: OpcionAccion) -> bool:
	return opcion != null and opcion.objetivo == fogata and opcion.id in [
		ACCION_DESCANSAR, ACCION_CONFIRMAR, ACCION_VOLVER, ACCION_GUARDAR, ACCION_CARGAR
	]


func _entrada(id: StringName, texto: String, habilitada: bool = true, motivo: String = "") -> EntradaMenuContextual:
	var opcion := OpcionAccion.new(id, TiposInteraccion.TipoAccion.INTERACTUAR, id, fogata, habilitada)
	return EntradaMenuContextual.new(EntradaMenuContextual.TipoEntrada.ACCION, texto, habilitada, motivo, opcion)


func obtener_entradas_fogata() -> Array[EntradaMenuContextual]:
	var ficha: Ficha = escenario.ficha_jugador
	var puede_descansar := ficha.raciones > 0 and ficha.puede_actuar()
	var motivo := "Necesitas al menos 1 ración." if ficha.raciones < 1 else "Necesitas una ficha con vida."
	var entradas: Array[EntradaMenuContextual] = [
		_entrada(ACCION_DESCANSAR, "Descansar · 1 ración (PV, energía y habilidades)", puede_descansar, "" if puede_descansar else motivo),
		_entrada(ACCION_VOLVER, "Volver a explorar [B]"),
		_entrada(ACCION_GUARDAR, "Guardar [F5]"),
		_entrada(ACCION_CARGAR, "Cargar [F9]"),
	]
	var opciones_fogata: Array[OpcionAccion] = fogata.obtener_opciones_accion(escenario_descanso.ficha_jugador)
	entradas.append_array(escenario_descanso.adaptador_menu_contextual.construir_entradas_acciones(opciones_fogata, escenario_descanso.catalogo_mensajes))
	return entradas


func ejecutar_opcion_campamento(opcion: OpcionAccion) -> void:
	if not es_opcion_campamento(opcion):
		return
	var posicion: Vector2 = escenario_descanso.menu_contextual.position
	if opcion.id == ACCION_CONFIRMAR:
		confirmar_descanso()
		escenario_descanso._cerrar_menu_contextual()
		return
	escenario_descanso._cerrar_menu_contextual()
	match opcion.id:
		ACCION_DESCANSAR: solicitar_descanso(posicion)
		ACCION_VOLVER: escenario.salir_campamento()
		ACCION_GUARDAR: guardar()
		ACCION_CARGAR: cargar()


func solicitar_descanso(posicion: Vector2 = Vector2.ZERO) -> void:
	if descanso_pendiente or escenario.ficha_jugador.raciones < 1 or not escenario.ficha_jugador.puede_actuar():
		return
	descanso_pendiente = true
	var raciones: int = escenario.ficha_jugador.raciones
	var entradas: Array[EntradaMenuContextual] = [
		_entrada(ACCION_CONFIRMAR, "Confirmar · gastar 1 de %d raciones" % raciones),
		EntradaMenuContextual.cancelar("Seguir en el campamento"),
	]
	escenario_descanso.menu_contextual.mostrar("Descansar junto al fuego", entradas, posicion)
	escenario_descanso._actualizar_estado_modal_interaccion()


func cancelar_descanso() -> void:
	descanso_pendiente = false


func _al_cambiar_visibilidad_menu() -> void:
	if not escenario_descanso.menu_contextual.visible:
		cancelar_descanso()


func confirmar_descanso() -> StringName:
	if not descanso_pendiente:
		return &"descanso_sin_confirmacion"
	descanso_pendiente = false
	escenario_descanso.menu_contextual.ocultar()
	var motivo: StringName = escenario.ficha_jugador.descansar_en_campamento()
	actualizar()
	_registrar_estado("Has descansado. Consumiste 1 ración." if motivo == &"" else "No puedes descansar: necesitas provisiones y una ficha con vida.")
	return motivo


func guardar() -> void:
	var motivo: StringName = escenario.guardar_partida()
	_registrar_estado("Partida guardada en el campamento." if motivo == &"" else "No se pudo guardar: %s" % motivo)


func cargar() -> void:
	var motivo: StringName = escenario.cargar_partida()
	if motivo == &"" and is_instance_valid(escenario.campamento):
		actualizar()
		_registrar_estado("Partida recuperada.")
	elif motivo != &"":
		_registrar_estado("No se pudo cargar: %s" % motivo)


func _registrar_estado(texto: String) -> void:
	if is_instance_valid(escenario_descanso):
		escenario_descanso.registro_narrativo.registrar(EntradaRegistroNarrativo.Categoria.SISTEMA, "Campamento", texto)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or descanso_pendiente:
		return
	match event.keycode:
		KEY_B, KEY_ESCAPE: escenario.salir_campamento()
		KEY_F5: guardar()
		KEY_F9: cargar()
		_: return
	get_viewport().set_input_as_handled()
