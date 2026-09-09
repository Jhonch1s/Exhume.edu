class_name PanelInventarioCofre
extends Control

const ESCENA_CASILLA := preload(
	"res://scenes/ui/inventario/casilla_inventario.tscn"
)

@onready var fondo: TextureRect = $Fondo
@onready var proporcion: AspectRatioContainer = $Fondo/AreaItems/Proporcion
@onready var contenido: GridContainer = $Fondo/AreaItems/Proporcion/Contenido

var cofre: CofreInteractuable
var inventario_destino:Inventario


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

	show()


func _ready() -> void:
	$Fondo/Botones/Cerrar.pressed.connect(ocultar)
	$Fondo/Botones/RecogerTodos.pressed.connect(_recoger_todos)
	hide()


func ocultar() -> void:
	hide()
	cofre = null
	inventario_destino = null


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		ocultar()
		get_viewport().set_input_as_handled()

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
