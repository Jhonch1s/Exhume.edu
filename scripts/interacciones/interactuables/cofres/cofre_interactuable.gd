@tool
class_name CofreInteractuable
extends Interactuable

@export_category("Aspecto")
@export_range(1, 3, 1) var variante: int = 1:
	set(valor):
		variante = clampi(valor, 1, 3)
		_actualizar_representacion()

@export var abierto: bool = false:
	set(valor):
		abierto = valor
		_actualizar_representacion()

@export_category("Contenido inicial")
@export var contenido_inicial: Array[EntradaInventarioInicial] = []

var inventario: Inventario = Inventario.new()


func permite_caminar_interactuable() -> bool:
	return false

func _ready() -> void:
	_actualizar_representacion()
	if Engine.is_editor_hint():
		return

	var motivo := _cargar_contenido_inicial()
	if motivo != &"":
		push_error("Contenido del cofre %s: %s" % [id_instancia, motivo])

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and ajustar_a_celda_en_editor:
		_ajustar_al_centro_celda()

func _cargar_contenido_inicial() -> StringName:
	var datos := definicion as DefinicionCofre
	if (
		datos == null
		or not datos.es_valida()
		or datos.columnas < 1
		or datos.filas < 1
		or id_instancia == &""
	):
		return &"cofre_no_configurado"

	var preparado := Inventario.new()
	preparado.capacidad = datos.columnas * datos.filas

	for indice in range(contenido_inicial.size()):
		var entrada := contenido_inicial[indice]
		if entrada == null:
			return &"entrada_inicial_vacia"

		var id_item := StringName(
			"%s:contenido:%d" % [id_instancia, indice]
		)
		var resultado := preparado.agregar(ItemInstancia.new(
			id_item,
			entrada.definicion,
			entrada.cantidad
		))
		if not resultado.exitosa:
			return resultado.motivo

	inventario = preparado
	return &""

func _actualizar_representacion() -> void:
	var region := Rect2(
		64 if abierto else 0,
		(variante - 1) * 64,
		64,
		64
	)

	for ruta in [ruta_visual_resaltable, ruta_fog_oculto, ruta_fog_explorado]:
		if ruta.is_empty():
			continue
		var sprite := get_node_or_null(ruta) as Sprite2D
		if sprite != null:
			sprite.region_enabled = true
			sprite.region_rect = region

func obtener_inventario() -> Inventario:
	var datos := definicion as DefinicionCofre
	inventario.capacidad = datos.columnas * datos.filas if datos != null else 0
	return inventario


func obtener_estado_persistente() -> Dictionary:
	var items: Array[Dictionary] = []
	for item in inventario.obtener_contenido():
		items.append({
			"id": String(item.id_instancia),
			"definicion_id": String(item.definicion.id_definicion),
			"definicion_path": item.definicion.resource_path,
			"cantidad": item.cantidad,
		})
	return {"abierto": abierto, "inventario": items}


func validar_estado_persistente(estado: Dictionary) -> StringName:
	if (
		estado.size() != 2
		or not estado.get("abierto") is bool
		or not estado.get("inventario") is Array
	):
		return &"estado_cofre_invalido"
	var datos_cofre := definicion as DefinicionCofre
	if datos_cofre == null or not datos_cofre.es_valida():
		return &"cofre_no_configurado"
	if estado["inventario"].size() > datos_cofre.columnas * datos_cofre.filas:
		return &"inventario_cofre_excede_capacidad"
	var ids: Dictionary[String, bool] = {}
	for datos: Variant in estado["inventario"]:
		if not datos is Dictionary:
			return &"inventario_cofre_guardado_invalido"
		var id_item: Variant = datos.get("id")
		var id_definicion: Variant = datos.get("definicion_id")
		var ruta: Variant = datos.get("definicion_path")
		if (
			not id_item is String or id_item.is_empty() or ids.has(id_item)
			or not id_definicion is String or id_definicion.is_empty()
			or not ruta is String or ruta.is_empty() or not ResourceLoader.exists(ruta)
			or not _es_numero_entero(datos.get("cantidad"))
		):
			return &"inventario_cofre_guardado_invalido"
		var definicion_item := ResourceLoader.load(ruta) as DefinicionItem
		var item := ItemInstancia.new(
			StringName(id_item), definicion_item, int(datos["cantidad"])
		)
		if (
			definicion_item == null
			or String(definicion_item.id_definicion) != id_definicion
			or not item.es_valida()
		):
			return &"definicion_item_guardada_invalida"
		ids[id_item] = true
	return &""


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	var inventario_nuevo := Inventario.new()
	var datos_cofre := definicion as DefinicionCofre
	inventario_nuevo.capacidad = datos_cofre.columnas * datos_cofre.filas
	for datos: Dictionary in estado["inventario"]:
		var definicion_item := ResourceLoader.load(datos["definicion_path"]) as DefinicionItem
		inventario_nuevo.agregar(ItemInstancia.new(
			StringName(datos["id"]), definicion_item, int(datos["cantidad"])
		))
	inventario = inventario_nuevo
	abierto = estado["abierto"]
	return &""


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))

func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones := super.obtener_opciones_accion(actor)
	opciones.append(OpcionAccion.crear_habilitada(
		&"abrir_cofre",
		TiposInteraccion.TipoAccion.INTERACTUAR,
		&"interaccion.abrir_cofre",
		self
	))
	return opciones


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion != null and opcion.id == &"abrir_cofre":
		return 1.0
	return super.obtener_alcance_maximo_opcion(opcion)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.validar_accion(contexto)

	if contexto.objetivo != self or contexto.id_accion != &"abrir_cofre":
		return &"accion_no_admitida"
	if not ocupa_coordenada(contexto.celda_objetivo):
		return &"celda_objetivo_invalida"

	var datos := definicion as DefinicionCofre
	if (
		datos == null
		or not datos.es_valida()
		or datos.columnas < 1
		or datos.filas < 1
	):
		return &"cofre_no_configurado"
	if _obtener_inventario_actor(contexto.actor) == null:
		return &"actor_sin_inventario"

	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto == null or contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return super.resolver_accion(contexto)

	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)

	abierto = true
	return ResultadoAccion.crear_exito()
