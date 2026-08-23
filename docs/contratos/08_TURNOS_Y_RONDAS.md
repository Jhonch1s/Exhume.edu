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
turnos. El modo combate permanece como estado explícito del escenario; su activación
jugable, destrabarse, descansos y usos especiales todavía no se implementan.

### Iniciativa y rondas

Cada `Ficha` declara un `id_actor` estable separado de `id_observador` y una
`iniciativa_base` entera. `GestorRondas` prevalida la lista completa, rechaza IDs
vacíos o duplicados y ordena por iniciativa descendente, desempatando por el texto
del ID estable. La lista no cambia durante la ronda inicial.

Al comenzar, el primer actor vivo repone sus recursos. Finalizar el turno procesa
sus estados mediante `ServicioTurnos`, selecciona el siguiente actor vivo y repone
únicamente los recursos de éste. Pasar desde el final del orden al principio aumenta
la ronda; los actores sin vida se omiten sin reordenar a los restantes. Si ninguno
puede actuar, no queda actor activo.

Cada transición devuelve `ResultadoAvanceTurno` con ronda, actor finalizado, actor
activo siguiente, marca de nueva ronda y el `ResultadoAccion` de `FIN_TURNO`.
Un fallo al procesar estados conserva el actor activo y no avanza el orden. IA, UI
de iniciativa, sorpresa, retrasar turno e incorporación o salida dinámica quedan
fuera de 11.4.

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

