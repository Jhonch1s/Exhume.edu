class_name PanelInventarioEquipo
extends Control

signal menu_cerrado
signal item_soltado_al_suelo(item: ItemInstancia, origen_indice: int, es_equipo: bool, punto_pantalla: Vector2)

const ESCENA_CASILLA := preload("res://scenes/ui/inventario/casilla_inventario.tscn")
const SONIDO_CLICK: AudioStream = preload("res://assets/sonidos/boton madera/boton click.wav")

const RUTAS_RANURAS := {
	RanuraEquipo.CABEZA: "res://assets/ui/icons/ranuras/slot_cabeza.png",
	RanuraEquipo.AMULETO: "res://assets/ui/icons/ranuras/slot_collar.png",
	RanuraEquipo.PECHO: "res://assets/ui/icons/ranuras/slot_pecho.png",
	RanuraEquipo.ANTORCHA: "res://assets/ui/icons/ranuras/slot_antorcha.png",
	RanuraEquipo.MANO_PRINCIPAL: "res://assets/ui/icons/ranuras/slot_arma.png",
	RanuraEquipo.ANILLO: "res://assets/ui/icons/ranuras/slot_anillo.png",
	RanuraEquipo.MANO_SECUNDARIA: "res://assets/ui/icons/ranuras/slot_escudo.png",
	RanuraEquipo.GUANTES: "res://assets/ui/icons/ranuras/slot_guantes.png",
	RanuraEquipo.BOTAS: "res://assets/ui/icons/ranuras/slot_botas.png",
}

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

# EstadÃ­sticas / Atributos (Lado izquierdo)
@onready var label_nombre_heroe: Label = $FondoAtenuado/MarcoPrincipal/LadoEquipo/InfoHeroe/NombreHeroe
@onready var label_stats: Label = $FondoAtenuado/MarcoPrincipal/LadoEquipo/InfoHeroe/StatsLabel
@onready var label_peso: Label = $FondoAtenuado/MarcoPrincipal/LadoEquipo/InfoHeroe/PesoLabel

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
var _equipo_previsualizacion: Dictionary = {}
var equipo_actual: Dictionary:
	get:
		return ficha_actual.equipo.ranuras if ficha_actual != null else _equipo_previsualizacion
var capacidad_mochila: int = 30
var tooltip_flotante: PanelContainer = null
var hud_inferior: Control


func _ready() -> void:
	boton_cerrar.pressed.connect(cerrar)
	_inicializar_ranuras_equipo()
	if inventario_actual == null:
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
		label_nombre_heroe.text = "HÃ©roe (Vista Previa)"
		label_stats.text = "FUE: 5  |  DES: 4  |  VOL: 2"
	
	refrescar_mochila()
	refrescar_equipo()
	refrescar_peso()


func cerrar() -> void:
	visible = false
	item_seleccionado = null
	_ocultar_tooltip()
	menu_cerrado.emit()


func _obtener_icono_ranura(tipo: RanuraEquipo) -> Texture2D:
	var ruta: String = RUTAS_RANURAS.get(tipo, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		return load(ruta) as Texture2D
	return null


func _inicializar_ranuras_equipo() -> void:
	for tipo in ranuras_equipo_nodos:
		var casilla: CasillaInventario = ranuras_equipo_nodos[tipo]
		casilla.icono_vacio = _obtener_icono_ranura(tipo)
		casilla.es_ranura_equipo = true
		casilla.tipo_ranura_equipo = tipo
		casilla.indice_ranura = tipo
		casilla.configurar(null)
		casilla.pressed.connect(_al_seleccionar_ranura_equipo.bind(tipo))
		if not casilla.item_arrastrado_soltado.is_connected(_al_soltar_item):
			casilla.item_arrastrado_soltado.connect(_al_soltar_item)
		if not casilla.raton_entro.is_connected(_mostrar_tooltip):
			casilla.raton_entro.connect(_mostrar_tooltip)
		if not casilla.raton_salio.is_connected(_ocultar_tooltip):
			casilla.raton_salio.connect(_ocultar_tooltip)


func _generar_vista_mochila_vacia() -> void:
	for hijo in contenedor_mochila.get_children():
		hijo.queue_free()
	
	for i in range(capacidad_mochila):
		var casilla: CasillaInventario = ESCENA_CASILLA.instantiate()
		casilla.indice_ranura = i
		casilla.es_ranura_equipo = false
		contenedor_mochila.add_child(casilla)
		casilla.configurar(null)
		casilla.item_arrastrado_soltado.connect(_al_soltar_item)
		casilla.raton_entro.connect(_mostrar_tooltip)
		casilla.raton_salio.connect(_ocultar_tooltip)


func refrescar_mochila() -> void:
	for hijo in contenedor_mochila.get_children():
		hijo.queue_free()
	
	for i in range(capacidad_mochila):
		var casilla: CasillaInventario = ESCENA_CASILLA.instantiate()
		casilla.indice_ranura = i
		casilla.es_ranura_equipo = false
		contenedor_mochila.add_child(casilla)
		
		var item: ItemInstancia = null
		if inventario_actual != null:
			item = inventario_actual.obtener_en_ranura(i)
		
		casilla.configurar(item)
		if item != null:
			casilla.pressed.connect(_al_seleccionar_item_mochila.bind(item))
		casilla.item_arrastrado_soltado.connect(_al_soltar_item)
		casilla.raton_entro.connect(_mostrar_tooltip)
		casilla.raton_salio.connect(_ocultar_tooltip)
	
	refrescar_peso()


func refrescar_equipo() -> void:
	if ficha_actual != null:
		label_stats.text = "FUE: %d (%+d)  |  DES: %d (%+d)  |  VOL: %d (%+d)" % [ficha_actual.obtener_fuerza(), ficha_actual.obtener_fuerza() - ficha_actual.fue, ficha_actual.obtener_destreza(), ficha_actual.obtener_destreza() - ficha_actual.des, ficha_actual.obtener_voluntad(), ficha_actual.obtener_voluntad() - ficha_actual.vol]
	for tipo in ranuras_equipo_nodos:
		var casilla: CasillaInventario = ranuras_equipo_nodos[tipo]
		casilla.icono_vacio = _obtener_icono_ranura(tipo)
		var item: ItemInstancia = equipo_actual.get(tipo, null)
		if ficha_actual != null and ficha_actual.equipo != null:
			item = ficha_actual.equipo.ranuras.get(tipo, null)
		casilla.configurar(item)


func refrescar_peso() -> void:
	if label_peso == null:
		return
	if ficha_actual != null:
		var actual: float = ficha_actual.obtener_peso_actual()
		var maximo: float = ficha_actual.peso_maximo
		if ficha_actual.esta_sobrecargado():
			label_peso.text = "Carga: %.1f / %.1f kg  [SOBRECARGADO]" % [actual, maximo]
			label_peso.add_theme_color_override(&"font_color", Color("#e04536"))
		else:
			label_peso.text = "Carga: %.1f / %.1f kg" % [actual, maximo]
			label_peso.add_theme_color_override(&"font_color", Color("#d4c7ab"))
	else:
		label_peso.text = "Carga: 0.0 / 35.0 kg"
		label_peso.add_theme_color_override(&"font_color", Color("#d4c7ab"))


func _mostrar_tooltip(casilla: CasillaInventario) -> void:
	_ocultar_tooltip()
	if casilla == null or casilla.item == null or not casilla.item.es_valida():
		return
	
	tooltip_flotante = casilla.crear_cuadro_tooltip()
	if tooltip_flotante == null:
		return
	
	tooltip_flotante.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for hijo in tooltip_flotante.get_children():
		(hijo as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		for nieto in hijo.get_children():
			(nieto as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	tooltip_flotante.z_index = 60
	add_child(tooltip_flotante)
	tooltip_flotante.reset_size()
	
	var ancla := casilla.get_global_rect()
	var pantalla := get_viewport_rect().size
	if is_instance_valid(hud_inferior) and hud_inferior.is_visible_in_tree():
		pantalla.y = minf(pantalla.y, hud_inferior.get_global_rect().position.y)
	var pos_x: float = ancla.position.x - tooltip_flotante.size.x - 8.0
	if pos_x < 8.0:
		pos_x = ancla.end.x + 8.0
	pos_x = clampf(pos_x, 8.0, maxf(8.0, pantalla.x - tooltip_flotante.size.x - 8.0))
	var pos_y: float = clampf(ancla.position.y - 4.0, 8.0, maxf(8.0, pantalla.y - tooltip_flotante.size.y - 8.0))
	
	tooltip_flotante.global_position = Vector2(pos_x, pos_y)


func _ocultar_tooltip() -> void:
	if tooltip_flotante != null and is_instance_valid(tooltip_flotante):
		tooltip_flotante.queue_free()
		tooltip_flotante = null


func _al_seleccionar_item_mochila(item: ItemInstancia) -> void:
	item_seleccionado = item


func _al_seleccionar_ranura_equipo(tipo: RanuraEquipo) -> void:
	var item: ItemInstancia = equipo_actual.get(tipo, null)
	if item == null:
		return
	item_seleccionado = item


func _al_soltar_item(
	origen_indice: int,
	origen_es_equipo: bool,
	destino_indice: int,
	destino_es_equipo: bool
) -> void:
	_ocultar_tooltip()
	if inventario_actual == null:
		return
	
	# Caso 1: Reordenar / Mover dentro de la mochila
	if not origen_es_equipo and not destino_es_equipo:
		inventario_actual.mover_ranura(origen_indice, destino_indice)
		refrescar_mochila()
		return
	
	# Caso 2: Equipar desde la mochila a una ranura de equipo
	if not origen_es_equipo and destino_es_equipo:
		var item := inventario_actual.obtener_en_ranura(origen_indice)
		if item == null:
			return
		if ficha_actual != null:
			ficha_actual.equipo.equipar(inventario_actual, item.id_instancia, destino_indice)
			refrescar_mochila()
			refrescar_equipo()
			return
		if _item_compatible_con_ranura(item, destino_indice):
			var reemplazado: ItemInstancia = equipo_actual.get(destino_indice, null)
			equipo_actual[destino_indice] = item
			inventario_actual.retirar(item.id_instancia)
			if reemplazado != null:
				inventario_actual.agregar(reemplazado)
			refrescar_mochila()
			refrescar_equipo()
		return
	
	# Caso 3: Desequipar desde equipo a la mochila
	if origen_es_equipo and not destino_es_equipo:
		if ficha_actual != null:
			ficha_actual.equipo.desequipar(inventario_actual, origen_indice)
			refrescar_mochila()
			refrescar_equipo()
			return
		var item: ItemInstancia = equipo_actual.get(origen_indice, null)
		if item == null:
			return
		equipo_actual.erase(origen_indice)
		inventario_actual.agregar(item)
		refrescar_mochila()
		refrescar_equipo()
		return


func _item_compatible_con_ranura(item: ItemInstancia, ranura: int) -> bool:
	return EquipoActor.compatible(item, ranura, ficha_actual.clase if ficha_actual != null else "")


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not visible:
		return false
	if not (data is Dictionary and data.get("tipo") == "item_inventario" and data.get("item") != null):
		return false
	var pos_cursor := global_position + at_position
	if marco_principal != null and marco_principal.get_global_rect().has_point(pos_cursor):
		return false
	if pos_cursor.y >= 830.0:
		return false
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	_ocultar_tooltip()
	var item: ItemInstancia = data.get("item")
	var origen_indice: int = int(data.get("origen_indice", -1))
	var es_equipo: bool = bool(data.get("es_equipo", false))
	item_soltado_al_suelo.emit(item, origen_indice, es_equipo, global_position + at_position)

