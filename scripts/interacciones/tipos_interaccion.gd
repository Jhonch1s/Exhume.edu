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

enum DestinoItem {
	CONSERVAR_EN_INVENTARIO,
	CONSUMIR,
	DEJAR_EN_CELDA,
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

enum MetricaAlcance {
	MANHATTAN,
	CUADRICULA,
}

enum PoliticaCobro {
	SOLO_EXITO,
	AL_INTENTAR,
}

enum PoliticaApilado {
	NO_APILAR_Y_RENOVAR,
}

enum CategoriaReaccion {
	TERRENO,
	EFECTO_SUPERFICIE,
	INTERACTUABLE,
	ITEM_SUELO,
	OCUPANTE,
}
