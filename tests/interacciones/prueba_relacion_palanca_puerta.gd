extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	var registro_valido := tablero.registrar_interactuables_desde_zona(
		zona,
		zona.get_node("CapaSuelo")
	)
	var palanca := tablero.obtener_interactuable(
		&"zona1_palanca_03_m03"
	) as PalancaInteractuable
	var puerta := tablero.obtener_interactuable(
		&"zona1_puerta_mecanismo_05_m03"
	) as PuertaInteractuable
	var puerta_derecha := tablero.obtener_interactuable(
		&"zona1_puerta_mecanismo_06_m03"
	) as PuertaInteractuable
	_comprobar(
		registro_valido
		and palanca != null
		and puerta != null
		and puerta_derecha != null,
		"Zona1 debe registrar la relacion real por IDs estables."
	)
	if palanca != null and puerta != null and puerta_derecha != null:
		_probar_relacion_reversible(tablero, palanca, puerta, puerta_derecha)
		_probar_configuracion_invalida(palanca, puerta, puerta_derecha)

	tablero.queue_free()
	zona.queue_free()
	_finalizar()


func _probar_relacion_reversible(
	tablero: TableroGrid,
	palanca: PalancaInteractuable,
	puerta: PuertaInteractuable,
	puerta_derecha: PuertaInteractuable
) -> void:
	var actor := Node.new()
	root.add_child(actor)
	var opciones_puerta := puerta.obtener_opciones_accion(actor)
	_comprobar(
		opciones_puerta.size() == 1
		and opciones_puerta[0].tipo == TiposInteraccion.TipoAccion.EXAMINAR,
		"La puerta de mecanismo no debe ofrecer llave ni apertura manual."
	)
	var apertura := _accionar(palanca, actor)
	_comprobar(
		apertura.exitosa
		and palanca.activada
		and puerta.abierta
		and puerta_derecha.abierta
		and tablero.puede_entrar(puerta.coordenada_mapa)
		and tablero.puede_entrar(puerta_derecha.coordenada_mapa)
		and apertura.cambios_estado.size() == 3
		and puerta_derecha.sprite.region_rect.size == Vector2(72, 96),
		"Activar la palanca debe abrir ambas puertas y agregar los tres cambios."
	)
	var cierre := _accionar(palanca, actor)
	_comprobar(
		cierre.exitosa
		and not palanca.activada
		and not puerta.abierta
		and not puerta_derecha.abierta
		and not tablero.puede_entrar(puerta.coordenada_mapa)
		and not tablero.puede_entrar(puerta_derecha.coordenada_mapa),
		"Desactivar la palanca debe cerrar nuevamente ambas puertas."
	)
	actor.free()


func _probar_configuracion_invalida(
	palanca: PalancaInteractuable,
	puerta: PuertaInteractuable,
	puerta_derecha: PuertaInteractuable
) -> void:
	var actor := Node.new()
	root.add_child(actor)
	var ids_anteriores := palanca.ids_receptores_mecanismo.duplicate()
	palanca.ids_receptores_mecanismo.append(&"zz_receptor_inexistente")
	var resultado := _accionar(palanca, actor)
	_comprobar(
		resultado.motivo == &"receptor_mecanismo_inexistente"
		and not palanca.activada
		and not puerta.abierta
		and not puerta_derecha.abierta,
		"Un receptor inexistente debe bloquear todo el lote sin estado parcial."
	)
	palanca.ids_receptores_mecanismo = [ids_anteriores[0], ids_anteriores[0]]
	resultado = _accionar(palanca, actor)
	_comprobar(
		resultado.motivo == &"id_receptor_mecanismo_duplicado"
		and not palanca.activada
		and not puerta.abierta
		and not puerta_derecha.abierta,
		"Un ID repetido debe detectarse antes de cambiar cualquier receptor."
	)
	palanca.ids_receptores_mecanismo = ids_anteriores
	actor.free()


func _accionar(
	palanca: PalancaInteractuable,
	actor: Object
) -> ResultadoAccion:
	var opcion: OpcionAccion
	for candidata in palanca.obtener_opciones_accion(actor):
		if candidata.id == &"accionar":
			opcion = candidata
			break
	var contexto := palanca.construir_contexto_accion(
		opcion,
		actor,
		palanca.coordenada_mapa,
		palanca.coordenada_mapa
	)
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _finalizar() -> void:
	if _fallos.is_empty():
		print("RelacionPalancaPuerta: 5 grupos correctos.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
