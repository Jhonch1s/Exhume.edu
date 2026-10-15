class_name ConsecuenciaDialogoNPC
extends Resource

enum Tipo { CAMBIAR_ACTITUD, REVELAR_INFORMACION }

@export var tipo: Tipo = Tipo.CAMBIAR_ACTITUD
## Sólo se usa para CAMBIAR_ACTITUD; se respetan la actitud fija y los límites.
@export_range(-20, 20, 1) var puntos_actitud: int = 1
## Sólo se usa para REVELAR_INFORMACION; pertenece al NPC que está hablando.
@export var id_fragmento: StringName = &""


func validar(npc: PersonajeNPC, ficha: Ficha, conocimiento: RegistroConocimiento) -> StringName:
	if not is_instance_valid(npc) or not is_instance_valid(ficha) or conocimiento == null:
		return &"participantes_consecuencia_dialogo_invalidos"
	if npc.esta_muerto() or not ficha.puede_actuar():
		return &"participantes_consecuencia_dialogo_inactivos"
	match tipo:
		Tipo.CAMBIAR_ACTITUD:
			return &"" if puntos_actitud != 0 and absi(puntos_actitud) <= 20 else &"consecuencia_actitud_invalida"
		Tipo.REVELAR_INFORMACION:
			var fragmento := obtener_fragmento(npc)
			if fragmento == null or not fragmento.es_valido() or not fragmento.se_recuerda:
				return &"consecuencia_informacion_invalida"
			return conocimiento.validar_registro(ficha.id_observador, npc.id_instancia, [fragmento])
	return &"tipo_consecuencia_dialogo_invalido"


func obtener_fragmento(npc: PersonajeNPC) -> FragmentoInformacion:
	var encontrado: FragmentoInformacion
	for fragmento in npc.obtener_fragmentos_informacion():
		if fragmento != null and fragmento.id_fragmento == id_fragmento:
			if encontrado != null:
				return null
			encontrado = fragmento
	return encontrado


func aplicar(npc: PersonajeNPC, ficha: Ficha, conocimiento: RegistroConocimiento, catalogo: CatalogoMensajesInteraccion) -> String:
	if validar(npc, ficha, conocimiento) != &"":
		return ""
	if tipo == Tipo.CAMBIAR_ACTITUD:
		var cambio := npc.modificar_actitud_hacia_jugador(puntos_actitud)
		return "Actitud de %s: %+d (total %d)." % [npc.obtener_nombre_interaccion(), cambio, npc.obtener_puntos_actitud()] if cambio != 0 else ""
	var fragmento := obtener_fragmento(npc)
	var resultado := conocimiento.registrar_descubrimientos(ficha.id_observador, npc.id_instancia, [fragmento])
	if resultado.ids_fragmentos_nuevos.is_empty():
		return ""
	return catalogo.resolver(fragmento.id_mensaje) if catalogo != null else String(fragmento.id_mensaje)
