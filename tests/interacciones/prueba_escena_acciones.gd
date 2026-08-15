extends SceneTree

const EscenaPruebaAcciones = preload(
	"res://scenes/tests/EscenaPruebaAcciones.tscn"
)

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var escena := EscenaPruebaAcciones.instantiate()
	escena.set(&"ejecutar_automaticamente", true)
	root.add_child(escena)

	var ficha := escena.get_node("Ficha") as Ficha
	var objeto := escena.get_node("Interactuables/ObjetoPrueba")
	var registro := escena.get_node("RegistroAccionesDesarrollo")
	var entradas: Array = registro.get(&"entradas")

	_comprobar(ficha.energia_actual == 199, "La escena debe consumir una energía.")
	_comprobar(bool(objeto.get(&"fue_examinado")), "La escena debe examinar el objeto.")
	_comprobar(entradas.size() == 3, "La escena debe registrar las tres etapas.")

	escena.call(&"_ejecutar_prueba_bloqueo_costes")
	var resultado_bloqueo := escena.get(&"ultimo_resultado") as ResultadoAccion
	entradas = registro.get(&"entradas")
	_comprobar(
		resultado_bloqueo.estado == TiposInteraccion.EstadoResolucion.BLOQUEO,
		"La escena debe producir un bloqueo por costes."
	)
	_comprobar(
		resultado_bloqueo.motivo == &"costes_insuficientes",
		"El bloqueo debe conservar el motivo esperado."
	)
	_comprobar(ficha.energia_actual == 200, "El bloqueo no debe consumir energía.")
	_comprobar(
		not bool(objeto.get(&"fue_examinado")),
		"El bloqueo no debe resolver el receptor."
	)
	_comprobar(entradas.size() == 3, "El bloqueo debe registrar las tres etapas.")

	escena.free()
	if _fallos.is_empty():
		print("EscenaPruebaAcciones: 2 pruebas de integración correctas.")
		quit()
		return

	for fallo: String in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
