## Servicio espacial

La línea de efecto se declara mediante `TipoLineaEfecto`: `NINGUNA` no requiere servicio, `VISUAL` representa observación y luz, y `FISICA` queda preparada para herramientas, trayectorias e impactos. No se deduce únicamente del tipo de acción porque una misma acción puede dirigirse a un objetivo del mundo o a una posesión propia.

`GestorAcciones` recibe un servicio separado mediante `configurar_validador_espacial()`. Cuando el contexto requiere línea, el servicio debe cumplir:

```gdscript
func validar_linea_efecto(contexto: ContextoAccion) -> StringName
```

Devuelve `&""` si la línea está despejada o un motivo de bloqueo. La validación no modifica estado. La ausencia del servicio solo bloquea contextos que lo requieren.

`ValidadorEspacialTablero` implementa actualmente la línea `VISUAL` sobre `TableroGrid`. Usa `GeometriaGrid.trazar_linea()`, utilidad Bresenham compartida con `FOVManager`, y aplica estas reglas: origen y destino deben existir; un hueco intermedio bloquea; las celdas intermedias con bloqueo efectivo de visión bloquean; la celda de destino puede ser opaca porque debe ser posible examinar una pared. `FISICA` devuelve `linea_fisica_no_implementada` hasta definir obstáculos, alturas y colisiones apropiados.

## Servicio de costes

`GestorAcciones` recibe un servicio independiente mediante `configurar_proveedor_costes()`. Solo lo exige cuando `ContextoAccion.costes_solicitados` no está vacío. El proveedor debe cumplir:

```gdscript
func validar_costes(contexto: ContextoAccion) -> StringName
func consumir_costes(contexto: ContextoAccion) -> Variant
```

`validar_costes()` devuelve `&""` o un motivo y nunca modifica recursos. `consumir_costes()` se invoca únicamente después de una validación exitosa y devuelve los importes realmente cobrados como `Dictionary[StringName, float]`; una revalidación defensiva fallida puede devolver un `StringName` con el motivo. Los costes negativos se bloquean antes de consultar el servicio.

`PoliticaCobro.SOLO_EXITO` cobra solo un resultado `EXITO`; `AL_INTENTAR` también cobra un `FALLO` producido por el receptor. Un `BLOQUEO` nunca cobra. Para evitar mutaciones reentrantes entre validación y consumo, el cobro síncrono se confirma antes de emitir las señales finales. `accion_resuelta` transporta el resultado inmutable producido por el receptor, mientras `accion_finalizada` y el retorno de `procesar_accion()` transportan un nuevo resultado con `costes_consumidos` confirmados.

`ProveedorCostesFicha` es el primer adaptador concreto. Resuelve `contexto.actor`, exige que sea `Ficha`, soporta únicamente `&"energia"` en unidades enteras, valida `energia_actual` y descuenta exactamente el coste confirmado. Rechaza claves desconocidas para no omitir futuros costes en silencio. Un proveedor compuesto podrá distribuir más adelante las claves de turno, item e inventario sin introducir esas dependencias en `GestorAcciones`.

