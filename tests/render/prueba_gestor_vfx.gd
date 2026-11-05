extends SceneTree

var fallos: Array[String] = []

class Receptor extends Node2D:
	var resultado: ResultadoAccion
	func validar_accion(_contexto: ContextoAccion) -> StringName:
		return &""
	func resolver_accion(_contexto: ContextoAccion) -> ResultadoAccion:
		return resultado


func _init() -> void:
	call_deferred(&"_probar")


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)
		push_error(mensaje)


func _probar() -> void:
	var camara := CamaraEscenario.new()
	root.add_child(camara)
	camara.zoom = Vector2(2, 2)
	camara.offset = Vector2(7, -3)
	camara.libre = true
	camara.force_update_scroll()
	var offset_base := camara.offset
	var tablero := TableroGrid.new()
	var capa := TileMapLayer.new()
	capa.tile_set = load("res://assets/tile_sets/terrain/cave_terrain.tres")
	root.add_child(capa)
	tablero.capa_referencia = capa
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.datos[Vector2i.ZERO].visibilidad = Celda.EstadoVisibilidad.VISIBLE
	var posicion := capa.map_to_local(Vector2i.ZERO)
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var vfx := load("res://scripts/render/gestor_vfx.gd").new() as Node
	root.add_child(vfx)
	vfx.set_process(false)
	vfx.configurar(camara, tablero, gestor)
	var emitidos: Array[StringName] = []
	vfx.efecto_emitido.connect(func(tipo, _pos): emitidos.append(tipo))
	comprobar(vfx.solicitar(&"piedra_moviendo", posicion) and not vfx.solicitar(&"piedra_moviendo", posicion), "Solicitudes simultáneas de un mismo tipo se agrupan.")
	vfx._process(0.03)
	comprobar(camara.offset != offset_base and camara.position == Vector2.ZERO and camara.zoom == Vector2(2, 2) and camara.libre, "La sacudida no modifica posición, zoom ni modo libre.")
	comprobar(((camara.offset - offset_base) * camara.zoom).length() <= 8.001, "La amplitud está limitada en píxeles de pantalla.")
	vfx._process(2.0)
	comprobar(camara.offset.is_equal_approx(offset_base), "La cámara recupera su offset original.")
	tablero.datos[Vector2i.ZERO].visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	comprobar(not vfx.solicitar(&"impacto", posicion), "No produce sacudidas por sucesos fuera de visión actual.")
	tablero.datos[Vector2i.ZERO].visibilidad = Celda.EstadoVisibilidad.VISIBLE
	camara.position = Vector2(10000, 10000)
	camara.force_update_scroll()
	comprobar(not vfx.solicitar(&"impacto", posicion), "La cámara libre no recibe efectos de sucesos fuera de pantalla.")
	camara.position = Vector2.ZERO
	camara.force_update_scroll()
	vfx.intensidad_sacudida = 0.0
	comprobar(not vfx.solicitar(&"trampa", posicion), "Puede desactivarse la sacudida.")
	vfx.intensidad_sacudida = 1.0
	var receptor := Receptor.new()
	root.add_child(receptor)
	var actor := Ficha.new()
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, actor, Vector2i.LEFT, Vector2i.ZERO, receptor)
	receptor.resultado = ResultadoAccion.crear_bloqueo(&"prueba")
	var cuenta := emitidos.size()
	gestor.procesar_accion(contexto)
	comprobar(emitidos.size() == cuenta, "Las acciones bloqueadas no generan VFX.")
	for par in [[&"trampa.superficie_activada", &"trampa"], [&"terror.chillido_resistido", &"chillido"]]:
		vfx.limpiar()
		receptor.resultado = ResultadoAccion.crear_exito([par[0]])
		var resultado := gestor.procesar_accion(contexto)
		comprobar(resultado == receptor.resultado and emitidos.back() == par[1], "Observa resultados sin modificarlos: %s" % par[1])
	var danio := ResultadoEfectoAplicado.new(&"ataque_basico", &"dano", actor, 3.0)
	vfx.limpiar()
	receptor.resultado = ResultadoAccion.crear_exito([], [danio])
	gestor.procesar_accion(contexto)
	comprobar(emitidos.back() == &"impacto", "Un daño de ataque confirmado produce impacto.")
	vfx.limpiar()
	cuenta = emitidos.size()
	receptor.resultado = ResultadoAccion.crear_exito([], [ResultadoEfectoAplicado.new(&"veneno", &"dano", actor, 1.0)])
	gestor.procesar_accion(ContextoAccion.new(TiposInteraccion.TipoAccion.FIN_TURNO, actor, Vector2i.ZERO, Vector2i.ZERO, receptor))
	comprobar(emitidos.size() == cuenta, "El daño periódico no sacude la cámara.")
	receptor.resultado = ResultadoAccion.crear_exito([], [ResultadoEfectoAplicado.new(&"explosion", &"dano", actor, 3.0)])
	gestor.procesar_accion(contexto)
	comprobar(emitidos.back() == &"explosion", "Se reconoce el resultado de una explosión.")
	seed(123)
	var esperado := randi()
	seed(123)
	vfx._process(0.03)
	comprobar(randi() == esperado, "El VFX no consume el azar global de las tiradas.")
	vfx.limpiar()
	comprobar(camara.offset.is_equal_approx(offset_base), "Limpiar restaura el offset y retira efectos pendientes.")
	vfx.free()
	actor.free()
	receptor.free()
	gestor.free()
	tablero.free()
	capa.free()
	camara.free()
	print("GestorVFX: %d fallos." % fallos.size())
	quit(0 if fallos.is_empty() else 1)
