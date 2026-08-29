### Solicitudes de efecto y deduplicación

`SolicitudEfecto` describe una consecuencia pedida pero todavía no confirmada. Es
inmutable durante la agregación y contiene una `clave` semántica, `tipo`, `fuente`,
`objetivo`, `magnitud`, `duracion`, `politica_apilado` e `id_evento`. Clave, tipo e
ID de evento son `StringName`; magnitud y duración no pueden ser negativas.

La política inicial `NO_APILAR_Y_RENOVAR` identifica duplicados por evento, clave
y objetivo. Conserva la primera posición del grupo, la mayor magnitud y la mayor
duración; nunca suma estas cantidades. Claves, objetivos o eventos distintos
coexisten. Solicitudes de un mismo grupo con tipos incompatibles invalidan el lote.

`AgregadorSolicitudesEfecto` es puro: valida el lote completo antes de devolver un
`ResultadoAgregacionEfectos`, no modifica las solicitudes y no aplica consecuencias.
Un error devuelve motivo estable y ninguna salida parcial. `ResultadoAccion`
transporta estas propuestas mediante `solicitudes_efecto`; `efectos_aplicados`
continúa significando exclusivamente efectos ya confirmados.

`ResolverReaccionesCelda` asigna un mismo `id_evento` a todos los contextos del
lote. `GestorAcciones` rechaza solicitudes sin evento o atribuidas a otro evento.
Las señales `accion_resuelta` y `accion_finalizada` conservan el resultado de cada
receptor; la deduplicación entre receptores ocurre después en `ResultadoReacciones`,
que expone `solicitudes_validas`, `motivo_solicitudes` y el lote deduplicado.

### Daño instantáneo y explosión

`AplicadorEfectos` admite inicialmente solicitudes de tipo `&"dano"`. Exige
magnitud entera positiva, duración cero y un objetivo que implemente:

```gdscript
func recibir_danio(cantidad: int, fuente: Object = null) -> int
```

El retorno es el daño realmente aplicado después de limitar la vida. Una aplicación
confirmada produce `ResultadoEfectoAplicado` con clave, tipo, objetivo y magnitud
real. `Ficha` implementa este protocolo, limita sus puntos de vida a cero y emite
`puntos_vida_cambiados`; el aplicador no conoce UI, muerte, armadura ni combate.

`ResultadoReacciones` valida primero todas las solicitudes de daño admitidas y solo
después las aplica en el orden deduplicado. Las solicitudes de tipos todavía no
implementados permanecen pendientes. Expone `efectos_validos` y `motivo_efectos` y
agrega únicamente aplicaciones confirmadas a `efectos_aplicados`.

`Explosion.crear_solicitudes()` es una consecuencia instantánea: recorre un radio
Manhattan, crea una solicitud `&"explosion"`/`&"dano"` por ocupante capaz de recibir
daño y no crea nodos ni superficies. Dos explosiones con el mismo evento y objetivo
se reducen mediante la política inicial antes de modificar vida.

`TerrenoDanino` conecta terrenos persistentes al mismo canal. Al `ENTRAR` solicita
daño instantáneo con una clave estable y deja su aplicación a `AplicadorEfectos`.
La lava usa magnitud dos y mantiene separada su penalización de pathfinding; `Celda`
ya no conserva un diccionario provisional de daño.

### Estados y veneno

`EstadoActor` conserva una única instancia por clave con magnitud, duración total y
ticks pendientes. `Ficha.aplicar_o_renovar_estado()` crea o renueva mediante máximos
y emite `estado_cambiado`; no avanza turnos ni expira estados.

Veneno y quemado pueden conservar una expresión de daño en vez de una magnitud
fija. Crearlos o renovarlos no causa daño inmediato: conservan todos sus ticks para
futuros `FIN_TURNO`. El debuff adicional todavía no forma parte del contrato.

Una aplicación confirmada de estado agrega su mensaje y cambio descriptivo a
`ResultadoReacciones`; como las solicitudes se deduplican antes, superficies
superpuestas no duplican el estado ni el mensaje. `&"quemado"` usa el mismo
contrato: tres ticks pendientes de `1d2`; renovar restaura los tres sin daño
inmediato.

### Fin de turno y expiración de quemado

`ServicioTurnos.avanzar_turno()` es la fuente explícita inicial de avance lógico.
Construye un `ContextoAccion` automático `FIN_TURNO` y lo procesa mediante
`GestorAcciones`; el gestor permanece ajeno a estados concretos. En 11.1 procesa
únicamente `quemado` sobre el actor recibido.

`EstadoActor.ticks_pendientes` es el único contador operativo. `duracion_total`
permanece como dato descriptivo y no se decrementa. Cada fin de turno prevalida el
daño, lo aplica mediante `AplicadorEfectos`, consume un tick y elimina el estado de
`Ficha` al llegar a cero. Llegar a cero puntos de vida no detiene ese consumo.

El `ResultadoAccion` incluye el `ResultadoEfectoAplicado` confirmado y un cambio
`estado_tick` con clave, ticks restantes y marca de expiración. Finalizar un turno
sin `quemado` es un éxito vacío. La UI, las superficies y el tiempo real no forman
parte de este flujo.

Desde 11.2 el actor expone copias de sus claves de estado ordenadas léxicamente y
el servicio procesa `quemado` y `veneno` en ese orden estable. Prevalida todas las
claves, estados y solicitudes de daño antes de aplicar el primer efecto; una clave
desconocida bloquea el lote sin daño ni consumo de ticks. Cada estado conserva su
propio contador y expira independientemente dentro del mismo `ResultadoAccion`.
