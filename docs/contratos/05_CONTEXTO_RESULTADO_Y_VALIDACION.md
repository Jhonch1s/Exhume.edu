## Tipos iniciales de acción

```gdscript
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
```

`INTERACTUAR` representa una acción específica publicada por el objetivo. Su `id_accion` distingue verbos de contenido como `&"accionar"`, `&"abrir"` o `&"empujar"` sin ampliar el enum central.

## Estado de resolución

```gdscript
enum EstadoResolucion {
	EXITO,
	FALLO,
	BLOQUEO,
}
```

- `EXITO`: la intención se resolvió y puede haber producido cambios o información.
- `FALLO`: se intentó resolver, pero no logró el resultado buscado. Puede consumir costes si la opción lo declara explícitamente.
- `BLOQUEO`: una precondición conocida impidió intentar la acción. No produce efectos, cambios ni costes.
- **Interrupción** no es un cuarto estado: es una consecuencia ortogonal que solicita detener una secuencia en un punto seguro. Un éxito o un fallo pueden interrumpir movimiento.

## `ContextoAccion`

Objeto inmutable desde que comienza la resolución.

| Campo | Tipo previsto | Regla |
|---|---|---|
| `tipo` | `TipoAccion` | Obligatorio. |
| `id_accion` | `StringName` | Identifica una variante de `INTERACTUAR`; vacío para tipos sin variante. |
| `actor` | `Object` | Origen responsable; puede ser `null` solo en acciones del entorno admitidas explícitamente. |
| `origen` | `Vector2i` o `null` | Celda desde la que nace la acción. |
| `celda_objetivo` | `Vector2i` o `null` | Celda a resolver. |
| `objetivo` | `Object` | Receptor concreto, si existe. |
| `item` | `Object` | Instancia utilizada o lanzada, si corresponde. |
| `etiquetas` | `Array[StringName]` | Propiedades semánticas, sin duplicados. |
| `magnitudes` | `Dictionary[StringName, float]` | Valores normalizados por clave. |
| `alcance_maximo` | `float` | Distancia permitida; negativo significa que el tipo no usa alcance. |
| `metadatos` | `Dictionary` | Extensión excepcional; no sustituye campos estables ni se usa para reglas nucleares. |
| `tipo_linea_efecto` | `TipoLineaEfecto` | `NINGUNA`, `VISUAL` o `FISICA`; declara la validación espacial requerida. |
| `costes_solicitados` | `Dictionary[StringName, float]` | Recursos que el proveedor debe validar y, si corresponde, consumir. |
| `politica_cobro` | `PoliticaCobro` | `SOLO_EXITO` o `AL_INTENTAR`; nunca permite cobrar un bloqueo. |
| `solicitud_examen` | `SolicitudExamen` o `null` | Datos tipados y opcionales de `EXAMINAR`; no se sustituyen por metadatos genéricos. |
| `id_evento` | `StringName` | Identifica el lote automático compartido; puede estar vacío cuando la acción no solicita efectos. |
| `cantidad_item` | `int` | Cantidad explícita para transferencias; `-1` significa la pila completa. |
| `id_item_resultante` | `StringName` | ID obligatorio de la nueva pila en una transferencia parcial; vacío para transferencias completas. |
| `objetivo_impacto` | `Object` o `null` | Receptor elegido para un impacto directo; `null` significa impactar contra el piso de la celda. |

El contexto se construye con copias de etiquetas, magnitudes y metadatos. Los receptores no deben modificarlo.

## `ResultadoAccion`

| Campo | Tipo previsto | Regla |
|---|---|---|
| `estado` | `EstadoResolucion` | Fuente única para éxito, fallo o bloqueo. |
| `motivo` | `StringName` | Código legible/localizable; obligatorio para fallo y bloqueo. |
| `mensajes` | `Array[StringName]` | IDs de mensajes de presentación, en orden. |
| `efectos_aplicados` | `Array` | Efectos confirmados, no propuestas. |
| `solicitudes_efecto` | `Array[SolicitudEfecto]` | Consecuencias pedidas por el receptor y todavía no confirmadas. |
| `cambios_estado` | `Array[Dictionary]` | Registro descriptivo de cambios confirmados. |
| `costes_consumidos` | `Dictionary[StringName, float]` | Energía, acciones, turnos, cargas o cantidad realmente cobrados. |
| `interrumpe_movimiento` | `bool` | Solicita detener la ruta tras el paso confirmado. |
| `terminal` | `bool` | Impide resolver reacciones posteriores del mismo evento sin revertir resultados previos. |
| `destino_item` | `DestinoItem` o `null` | Destino explícito solicitado por una reacción; `null` cuando el resultado no decide sobre una unidad. |

Las propiedades derivadas `exitosa`, `consumio_accion` y `consumio_turno` se calculan desde `estado` y `costes_consumidos`; no se almacenan como fuentes de verdad duplicadas.

Un resultado de `BLOQUEO` debe tener vacíos `efectos_aplicados`, `cambios_estado` y `costes_consumidos`. Los fallos no consumen nada por defecto. Cada coste debe declararse en la opción y cobrarse una sola vez después de resolver.

Los bloqueos tampoco interrumpen ni son terminales. Confirmar costes construye un
nuevo resultado sin perder las marcas de interrupción o terminalidad.

