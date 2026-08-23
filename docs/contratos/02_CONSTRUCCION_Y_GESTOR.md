## Construcción de contextos desde opciones voluntarias

La interfaz contextual no interpreta propiedades concretas del objetivo ni conoce
las reglas de `EXAMINAR`, antorchas o fogatas. Los proveedores de opciones
voluntarias implementan el protocolo:

```gdscript
func construir_contexto_accion(
    opcion: OpcionAccion,
    actor: Object,
    origen: Vector2i,
    celda_objetivo: Vector2i,
    item_seleccionado: ItemInstancia = null
) -> ContextoAccion
```

`ConstructorContextoAccion` invoca ese protocolo y comprueba que el contexto
devuelto conserve el tipo, actor, objetivo, coordenadas, línea de efecto, costes y
política de la opción elegida. Para `INTERACTUAR`, `id_accion` debe coincidir con el
ID de la opción; para los demás tipos permanece vacío. Un contrato ausente, nulo o
incoherente se rechaza con un motivo estable y nunca llega a resolución.

`Interactuable` implementa la construcción común. `EXAMINAR` obtiene su alcance del
perfil de observación y crea una `SolicitudExamen` con el ID del actor.
`INTERACTUAR` conserva el ID específico publicado. Cada proveedor puede declarar
el alcance mecánico de sus opciones sin exponerlo a la UI; la primera fuente de luz
declara alcance Manhattan `1.0` para `encender` y `apagar`.

Elegir una opción habilitada construye exactamente un contexto y lo entrega a
`GestorAcciones.procesar_accion()`. El gestor repite todas las validaciones
estructurales, espaciales, específicas y económicas inmediatamente antes de
resolver. Por ello, una opción que quedó obsoleta mientras el menú estaba abierto
termina en `BLOQUEO` sin cambios ni costes. `Cancelar` no participa de este
protocolo y nunca construye contexto.

## Ciclo inicial del gestor

`GestorAcciones` procesa la lógica de forma síncrona y emite, en ese orden, `accion_iniciada`, `accion_resuelta` y `accion_finalizada`. Un contexto nulo se bloquea antes de iniciar el ciclo porque no existe un objeto válido que transportar en las señales. Para cualquier contexto existente, tanto el éxito como el fallo o bloqueo producen exactamente una resolución y una finalización.

Las validaciones iniciales comprueban actor, objetivo, coordenadas requeridas, alcance y contrato del receptor. La métrica predeterminada es Manhattan para coincidir con las cuatro direcciones conectadas por el movimiento; cada contexto puede declarar otra métrica cuando su geometría lo requiere. Costes disponibles y agregación de varios receptores se incorporarán mediante contratos específicos antes de cerrar la Fase 1.

