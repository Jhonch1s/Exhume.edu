extends "res://scenes/escenario_base/escenario_base.gd"

var ruta_guardado_prueba := "user://prueba_nivel_dos.json"


func guardar_partida(ruta: String = "") -> StringName:
	return super.guardar_partida(ruta if ruta != "" else ruta_guardado_prueba)


func cargar_partida(ruta: String = "") -> StringName:
	return super.cargar_partida(ruta if ruta != "" else ruta_guardado_prueba)
