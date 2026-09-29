### Recursos separados del turno

`RecursosTurnoActor` conserva para una `Ficha` cuatro reservas independientes:
`movimiento`, `accion_principal`, `accion_adicional` y `reaccion`. Sus valores
iniciales configurables son `7`, `1`, `1` y `1`; reponer el turno restaura máximos,
no energía persistente ni usos por descanso. `ProveedorCostesFicha` valida y cobra
estas claves mediante el mismo diccionario de costes ya usado por `GestorAcciones`.

Cada paso confirmado consume de `movimiento` el coste real de la celda y continúa
consumiendo `energia_actual` según la regla histórica. Fuera de combate, una ruta
que agota movimiento ejecuta un `FIN_TURNO`, repone recursos y continúa sólo si el
actor sigue vivo. En combate la ruta se detiene y no inicia otro turno.

La previsualización de combate recorta la ruta por la suma de costes reales, no por
cantidad de celdas. En exploración muestra la ruta completa que podrá encadenar
turnos. Destrabarse, descansos y usos especiales en combate todavía necesitan
reglas propias.

### Primera integración del modo de combate

Elegir `Atacar` contra un NPC hostil y combatiente inicia el modo de combate con
la ficha y ese objetivo. `GestorRondas` ordena por iniciativa descendente y una
franja superior muestra ronda, orden, actor activo y participantes derrotados.
La ficha conserva movimiento y acción principal como recursos independientes:
puede moverse y atacar mientras sea su turno y tenga recursos. `Pasar turno`
procesa sus estados, avanza al NPC y, cuando vuelve a la ficha, repone sus
recursos. El control del mapa se bloquea durante el turno del NPC.

En el segundo corte, un NPC hostil combatiente tiene su propio
`RecursosTurnoActor`. Si está a una celda Manhattan del jugador y conserva
acción principal, intenta un ataque básico automático: tirada de FUE con la
misma regla provisional del jugador, 1 PV de daño si acierta y coste de una
acción principal también si falla. El resultado aparece en el registro
narrativo. Si no está junto al jugador, pasa; todavía no se mueve ni elige
entre varias capacidades. Tras resolverlo, pasa el turno y la ronda continúa.
No hay defensa opuesta, reacción, animación ni IA de persecución en este corte.

El combate termina si el objetivo llega a 0 PV o la ficha deja de poder actuar.
Al salir, la ficha viva repone recursos para continuar en exploración. Esto es
una regla provisional para el encuentro aislado: quedan por decidir detección
e inicio autónomo, varios enemigos, huida, defensa, más acciones del NPC y qué
interacciones se permiten durante el turno de combate. La iniciativa base del
NPC pertenece a `DefinicionPersonaje`; el objetivo de la escena de revisión usa
`-1` para que la ficha actúe primero. Trompo sigue siendo neutral y no entra en
combate.

### Iniciativa y rondas

Cada `Ficha` declara un `id_actor` estable separado de `id_observador` y una
`iniciativa_base` entera. `GestorRondas` prevalida la lista completa, rechaza IDs
vacíos o duplicados y ordena por iniciativa descendente, desempatando por el texto
del ID estable. La lista no cambia durante la ronda inicial.

Al comenzar, el primer actor vivo repone sus recursos si los tiene. Finalizar el
turno procesa sus estados mediante `ServicioTurnos` cuando admite esa capacidad,
selecciona el siguiente actor vivo e invoca `iniciar_turno` en éste. El NPC
combatiente repone sus recursos al comenzar su turno; sus estados temporales
siguen sin contrato propio. Pasar desde el
final del orden al principio aumenta
la ronda; los actores sin vida se omiten sin reordenar a los restantes. Si ninguno
puede actuar, no queda actor activo.

Cada transición devuelve `ResultadoAvanceTurno` con ronda, actor finalizado, actor
activo siguiente, marca de nueva ronda y el `ResultadoAccion` de `FIN_TURNO`.
Un fallo al procesar estados conserva el actor activo y no avanza el orden.
Sorpresa, retrasar turno e incorporación o salida dinámica siguen pendientes.

### Duración y transformación de superficies

`ProcesadorSuperficies` usa el registro existente de `TableroGrid`, prevalida todas
las superficies temporales y las procesa por `id_instancia` léxico. Cada instancia
es la única fuente de sus rondas restantes. `GestorRondas` invoca el procesador una
sola vez al pasar del último actor vivo al primero; cambiar de actor dentro de la
misma ronda no reduce duraciones.

Al llegar a cero la superficie se retira mediante `TableroGrid` y su nodo queda bajo
control del procesador. `Humo` y `HumoVeneno` desaparecen. `Fuego` instancia `Humo`
en la misma celda y posición con ID derivado estable, y el humo comienza con sus diez
rondas completas. Las señales existentes de registro y retiro actualizan visión sin
acoplar el procesador a `FOVManager`.

El resultado de la transición conserva un `ResultadoAccion` adicional con cambios
`superficie_tick`, rondas restantes, expiración e ID resultante cuando corresponde.
Propagación, superficie mojada, explosión con veneno y una matriz general de
combinaciones quedan fuera de 11.5.

En exploración, donde sólo participa la ficha jugadora, cada `FIN_TURNO` automático
equivale también al cierre de una ronda: procesa estados, avanza todas las superficies
y luego repone recursos si el actor continúa vivo. Por ello, humo, humo venenoso y
fuego conservan la misma duración temporal dentro y fuera de combate.

