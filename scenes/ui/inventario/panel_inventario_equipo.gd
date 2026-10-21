class_name PanelInventarioEquipo
extends Control

signal menu_cerrado

const ESCENA_CASILLA := preload("res://scenes/ui/inventario/casilla_inventario.tscn")
const SONIDO_CLICK: AudioStream = preload("res://assets/sonidos/boton madera/boton click.wav")

enum RanuraEquipo {
	CABEZA,
	AMULETO,
	PECHO,
	MANO_PRINCIPAL,
	MANO_SECUNDARIA,
	GUANTES,
	BOTAS,
	ANILLO,
	ANTORCHA,
}

@onready var marco_principal: TextureRect = $FondoAtenuado/MarcoPrincipal
@onready var contenedor_mochila: GridContainer = $FondoAtenuado/MarcoPrincipal/LadoMochila/GridMochila
@onready var boton_cerrar: Button = $FondoAtenuado/MarcoPrincipal/BotonCerrar

# Detalle del ítem seleccionado
@onready var panel_detalle: Control = $FondoAtenuado/MarcoPrincipal/LadoMochila/PanelDetalle
@onready var detalle_icono: TextureRect = $FondoAtenuado/MarcoPrincipal/LadoMochila/PanelDetalle/Margen/Contenido/FilaCabecera/Icono
@onready var detalle_nombre: Label = $FondoAtenuado/MarcoPrincipal/LadoMochila/PanelDetalle/Margen/Contenido/FilaCabecera/Textos/Nombre
@onready var detalle_cantidad: Label = $FondoAtenuado/MarcoPrincipal/LadoMochila/PanelDetalle/Margen/Contenido/FilaCabecera/Textos/Cantidad
@onready var detalle_descripcion: Label = $FondoAtenuado/MarcoPrincipal/LadoMochila/PanelDetalle/Margen/Contenido/Descripcion
@onready var boton_accion: Button = $FondoAtenuado/MarcoPrincipal/LadoMochila/PanelDetalle/Margen/Contenido/BotonAccion

# Estadísticas / Atributos (Lado izquierdo)
@onready var label_nombre_heroe: Label = $FondoAtenuado/MarcoPrincipal/LadoEquipo/InfoHeroe/NombreHeroe
@onready var label_stats: Label = $FondoAtenuado/MarcoPrincipal/LadoEquipo/InfoHeroe/StatsLabel

# Diccionario de nodos de ranuras de equipo por enum
@onready var ranuras_equipo_nodos: Dictionary = {
	RanuraEquipo.CABEZA: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila1/RanuraCabeza,
	RanuraEquipo.AMULETO: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila2/RanuraAmuleto,
	RanuraEquipo.PECHO: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila2/RanuraPecho,
	RanuraEquipo.ANTORCHA: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila2/RanuraAntorcha,
	RanuraEquipo.MANO_PRINCIPAL: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila3/RanuraManoPpal,
	RanuraEquipo.ANILLO: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila3/RanuraAnillo,
	RanuraEquipo.MANO_SECUNDARIA: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila3/RanuraManoSec,
	RanuraEquipo.GUANTES: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila4/RanuraGuantes,
	RanuraEquipo.BOTAS: $FondoAtenuado/MarcoPrincipal/LadoEquipo/AreaRanuras/Fila4/RanuraBotas,
}

var ficha_actual: Ficha
var inventario_actual: Inventario
var item_seleccionado: ItemInstancia
var equipo_actual: Dictionary = {} # RanuraEquipo -> ItemInstancia
var capacidad_mochila: int = 24


func _ready() -> void:
	boton_cerrar.pressed.connect(cerrar)
	boton_accion.pressed.connect(_al_presionar_accion)
	_limpiar_detalle()
	_inicializar_ranuras_equipo()
	if inventario_actual == null:
		# Inicialización de prueba si se abre la escena en solitario
		_generar_vista_mochila_vacia()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I):
		get_viewport().set_input_as_handled()
		cerrar()


func abrir(ficha: Ficha = null) -> void:
	ficha_actual = ficha
	visible = true
	if ficha_actual != null:
		inventario_actual = ficha_actual.obtener_inventario()
		label_nombre_heroe.text = ficha_actual.nombre
		label_stats.text = "FUE: %d  |  DES: %d  |  VOL: %d" % [ficha_actual.fue, ficha_actual.des, ficha_actual.vol]
	else:
		label_nombre_heroe.text = "Héroe (Vista Previa)"
		label_stats.text = "FUE: 5  |  DES: 4  |  VOL: 2"
	
	refrescar_mochila()
	refrescar_equipo()


func cerrar() -> void:
	visible = false
	item_seleccionado = null
	_limpiar_detalle()
	menu_cerrado.emit()


func _inicializar_ranuras_equipo() -> void:
	for tipo in ranuras_equipo_nodos:
		var casilla: CasillaInventario = ranuras_equipo_nodos[tipo]
		casilla.configurar(null)
		casilla.pressed.connect(_al_seleccionar_ranura_equipo.bind(tipo))


func _generar_vista_mochila_vacia() -> void:
	for hijo in contenedor_mochila.get_children():
		hijo.queue_free()
	
	for i in range(capacidad_mochila):
		var casilla: CasillaInventario = ESCENA_CASILLA.instantiate()
		contenedor_mochila.add_child(casilla)
		casilla.configurar(null)


func refrescar_mochila() -> void:
	for hijo in contenedor_mochila.get_children():
		hijo.queue_free()
	
	var items: Array[ItemInstancia] = []
	if inventario_actual != null:
		items = inventario_actual.obtener_contenido()
	
	for i in range(capacidad_mochila):
		var casilla: CasillaInventario = ESCENA_CASILLA.instantiate()
		contenedor_mochila.add_child(casilla)
		if i < items.size():
			var item := items[i]
			casilla.configurar(item)
			casilla.pressed.connect(_al_seleccionar_item_mochila.bind(item))
		else:
			casilla.configurar(null)


func refrescar_equipo() -> void:
	for tipo in ranuras_equipo_nodos:
		var casilla: CasillaInventario = ranuras_equipo_nodos[tipo]
		var item: ItemInstancia = equipo_actual.get(tipo, null)
		casilla.configurar(item)


func _al_seleccionar_item_mochila(item: ItemInstancia) -> void:
	item_seleccionado = item
	_mostrar_detalle(item, "Equipar / Usar")


func _al_seleccionar_ranura_equipo(tipo: RanuraEquipo) -> void:
	var item: ItemInstancia = equipo_actual.get(tipo, null)
	if item != null:
		item_seleccionado = item
		_mostrar_detalle(item, "Desequipar")
	else:
		_limpiar_detalle()
		detalle_nombre.text = "Ranura vacía"
		detalle_descripcion.text = "Ranura de equipo: %s" % RanuraEquipo.keys()[tipo]


func _mostrar_detalle(item: ItemInstancia, texto_boton: String) -> void:
	if item == null or not item.es_valida():
		_limpiar_detalle()
		return
	
	detalle_icono.texture = item.definicion.icono
	detalle_nombre.text = item.definicion.nombre
	detalle_cantidad.text = "Cantidad: %d" % item.cantidad if item.cantidad > 1 else ""
	detalle_descripcion.text = item.definicion.descripcion_base
	boton_accion.text = texto_boton
	boton_accion.disabled = false
	panel_detalle.visible = true


func _limpiar_detalle() -> void:
	detalle_icono.texture = null
	detalle_nombre.text = "Selecciona un objeto"
	detalle_cantidad.text = ""
	detalle_descripcion.text = ""
	boton_accion.text = "Acción"
	boton_accion.disabled = true


func _al_presionar_accion() -> void:
	if item_seleccionado == null:
		return
	# ponytail: lógica base de equipar/desequipar conectable con Ficha
	print("Acción ejecutada sobre: ", item_seleccionado.definicion.nombre)
