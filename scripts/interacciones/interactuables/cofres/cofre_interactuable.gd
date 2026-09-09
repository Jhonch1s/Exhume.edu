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
