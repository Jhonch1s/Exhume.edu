class_name PanelRegistroNarrativo
extends PanelContainer

const MAXIMO_COMPACTO := 3

@onready var boton_expandir: Button = $Margen/Contenido/Cabecera/Expandir
@onready var desplazamiento: ScrollContainer = $Margen/Contenido/Desplazamiento
@onready var tarjetas: VBoxContainer = $Margen/Contenido/Desplazamiento/Tarjetas

var registro: RegistroNarrativoSesion
var expandido := false


func _ready() -> void:
	boton_expandir.pressed.connect(alternar)


func observar(nuevo_registro: RegistroNarrativoSesion) -> void:
	if registro != null and registro.entrada_agregada.is_connected(_al_agregar_entrada):
		registro.entrada_agregada.disconnect(_al_agregar_entrada)
	registro = nuevo_registro
	if registro != null:
		registro.entrada_agregada.connect(_al_agregar_entrada)
	_actualizar()


func alternar() -> void:
	expandido = not expandido
	boton_expandir.text = "Contraer" if expandido else "Expandir"
	custom_minimum_size.y = 320.0 if expandido else 0.0
	_actualizar()


func _al_agregar_entrada(_entrada: EntradaRegistroNarrativo) -> void:
	var barra := desplazamiento.get_v_scroll_bar()
	var seguir_final := not expandido or barra.value >= barra.max_value - barra.page - 2.0
	_actualizar()
	if seguir_final:
		await get_tree().process_frame
		desplazamiento.scroll_vertical = int(desplazamiento.get_v_scroll_bar().max_value)


func _actualizar() -> void:
	for tarjeta in tarjetas.get_children():
		tarjeta.queue_free()
	if registro == null:
		return
	var entradas := registro.obtener_entradas_visibles()
	if not expandido and entradas.size() > MAXIMO_COMPACTO:
		entradas = entradas.slice(entradas.size() - MAXIMO_COMPACTO)
	for entrada in entradas:
		var etiqueta := Label.new()
		etiqueta.text = "[%s]\n%s%s" % [
			entrada.titulo,
			("\n".join(entrada.detalles) + "\n") if not entrada.detalles.is_empty() else "",
			entrada.mensaje,
		]
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tarjetas.add_child(etiqueta)
