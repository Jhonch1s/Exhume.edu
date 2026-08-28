class_name EntradaRegistroNarrativo
extends RefCounted

enum Categoria { TIRADA, DANO, ESTADO, MOVIMIENTO, OBJETO, SISTEMA }
enum Visibilidad { VISIBLE, OCULTA }

var secuencia: int
var categoria: Categoria
var titulo: String
var mensaje: String
var detalles: Array[String]
var visibilidad: Visibilidad


func _init(
	secuencia_inicial: int,
	categoria_inicial: Categoria,
	titulo_inicial: String,
	mensaje_inicial: String,
	detalles_iniciales: Array[String] = [],
	visibilidad_inicial: Visibilidad = Visibilidad.VISIBLE
) -> void:
	secuencia = secuencia_inicial
	categoria = categoria_inicial
	titulo = titulo_inicial
	mensaje = mensaje_inicial
	detalles = detalles_iniciales.duplicate()
	visibilidad = visibilidad_inicial
