extends "res://tests/interacciones/escena_dialogo_tirada_npc.gd"

@export var tema_consecuencias: DialogoNPC = preload("res://recursos/dialogos/custodio_consecuencias.tres")


func _ready() -> void:
	await super._ready()
	_ruta_guardado = "user://prueba_consecuencias_dialogo_npc.json"
	# El catálogo de prueba no modifica el recurso compartido de la zona.
	var catalogo: CatalogoMensajesInteraccion = _escenario.catalogo_mensajes
	_escenario.catalogo_mensajes = catalogo.duplicate() if catalogo != null else CatalogoMensajesInteraccion.new()
	_escenario.catalogo_mensajes.mensajes[&"dialogo.custodio.confidencia"] = "El custodio guarda una llave de repuesto en su bota."
	_mostrar_estado("CONSECUENCIAS | Hablar → Ganarse su confianza [VOL].\nEjemplo por defecto: éxito +3 e información; fallo -1.\nConfigurable en Tema consecuencias del nodo raíz. K/C fuera del diálogo.")


func _crear_enemigo(zona: Node2D, suelo: TileMapLayer, tablero: TableroGrid, coordenada: Vector2i, numero: int) -> bool:
	if not super._crear_enemigo(zona, suelo, tablero, coordenada, numero):
		return false
	var npc: PersonajeNPC = _enemigos.back()
	var perfil := npc.obtener_definicion_personaje()
	perfil.actitud_hacia_jugador_fija = false
	perfil.dialogos = [tema_consecuencias]
	perfil.fragmentos_informacion.append(preload("res://recursos/dialogos/confidencia_custodio.tres"))
	npc.estado_personaje = null
	return true
