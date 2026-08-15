class_name TiposInteraccion
extends RefCounted

enum TipoAccion {
	EXAMINAR,
	INTERACTUAR,
	ENTRAR,
	SALIR,
	USAR_ITEM,
	LANZAR_ITEM,
	IMPACTAR,
	RECOGER,
	SOLTAR,
	FIN_TURNO,
}

enum EstadoResolucion {
	EXITO,
	FALLO,
	BLOQUEO,
}

enum NivelInformacion {
	VISIBLE,
	BASICO,
	DETALLADO,
	SECRETO,
}

enum TipoLineaEfecto {
	NINGUNA,
	VISUAL,
	FISICA,
}

enum PoliticaCobro {
	SOLO_EXITO,
	AL_INTENTAR,
}
