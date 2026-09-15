class_name PanelInventarioCofre
extends Control

const ESCENA_CASILLA := preload(
	"res://scenes/ui/inventario/casilla_inventario.tscn"
)

@onready var fondo: TextureRect = $Fondo
@onready var proporcion: AspectRatioContainer = $Fondo/AreaItems/Proporcion
@onready var contenido: GridContainer = $Fondo/AreaItems/Proporcion/Contenido
@onready var detalle_item: PanelContainer = $DetalleItem
@onready var detalle_imagen: TextureRect = $DetalleItem/Margen/Contenido/Imagen
@onready var detalle_nombre: Label = $DetalleItem/Margen/Contenido/Nombre
@onready var detalle_cantidad: Label = $DetalleItem/Margen/Contenido/Cantidad
@onready var detalle_descripcion: Label = $DetalleItem/Margen/Contenido/Descripcion

var cofre: CofreInteractuable
var inventario_destino: Inventario
var _arrastrando := false


func mostrar(
	nuevo_cofre: CofreInteractuable,
	destino: Inventario
) -> void:
	if not is_instance_valid(nuevo_cofre):
		return

	var datos := nuevo_cofre.definicion as DefinicionCofre
	if datos == null or datos.columnas < 1 or datos.filas < 1:
		return

	var items := nuevo_cofre.obtener_inventario().obtener_contenido()
	var capacidad := datos.columnas * datos.filas
	if items.size() > capacidad:
		push_error("El cofre tiene más pilas que espacios disponibles.")
		return

	cofre = nuevo_cofre
	inventario_destino = destino
	$Fondo/Botones/RecogerTodos.disabled = (
		destino == null
		or destino == cofre.obtener_inventario()
		or items.is_empty()
	)
	
	fondo.texture = datos.imagen_interfaz
	contenido.columns = datos.columnas
	proporcion.ratio = float(datos.columnas) / datos.filas

	for casilla in contenido.get_children():
		contenido.remove_child(casilla)
		casilla.queue_free()

	for indice in range(capacidad):
		var casilla := ESCENA_CASILLA.instantiate() as CasillaInventario
		casilla.custom_minimum_size = Vector2.ZERO
		casilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		casilla.size_flags_vertical = Control.SIZE_EXPAND_FILL
		contenido.add_child(casilla)
		casilla.configurar(items[indice] if indice < items.size() else null)
		casilla.mouse_entered.connect(_mostrar_detalle.bind(casilla.item))
		casilla.mouse_exited.connect(_ocultar_detalle)

	_ocultar_detalle()
	show()


func _ready() -> void:
	$Fondo/Botones/Cerrar.pressed.connect(ocultar)
	$Fondo/Botones/RecogerTodos.pressed.connect(_recoger_todos)
	hide()


func ocultar() -> void:
	_arrastrando = false
	_ocultar_detalle()
	hide()
	cofre = null
	inventario_destino = null


func _mostrar_detalle(item: ItemInstancia) -> void:
	if item == null or not item.es_valida():
		_ocultar_detalle()
		return
	var definicion := item.definicion
	detalle_imagen.texture = (
		definicion.ilustracion_examen
		if definicion.ilustracion_examen != null
		else definicion.icono
	)
	detalle_imagen.visible = detalle_imagen.texture != null
	detalle_nombre.text = definicion.nombre
	detalle_cantidad.text = "Cantidad: %d" % item.cantidad
	detalle_descripcion.text = definicion.descripcion_base
	detalle_item.show()


func _ocultar_detalle() -> void:
	detalle_item.hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		ocultar()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = event.pressed
		accept_event()


func _input(event: InputEvent) -> void:
	if not visible or not _arrastrando:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = event.pressed
	elif event is InputEventMouseMotion:
		var limite := (get_viewport_rect().size - size).max(Vector2.ZERO)
		position = Vector2(
			clampf(position.x + event.relative.x, 0.0, limite.x),
			clampf(position.y + event.relative.y, 0.0, limite.y)
		)

func _recoger_todos() -> void:
	if not is_instance_valid(cofre) or inventario_destino == null:
		return

	var origen := cofre.obtener_inventario()

	for item in origen.obtener_contenido():
		var resultado := origen.transferir_a(
			inventario_destino,
			item.id_instancia
		)
		if not resultado.exitosa:
			push_warning("No se pudo recoger: %s" % resultado.motivo)
			break

	mostrar(cofre, inventario_destino)
