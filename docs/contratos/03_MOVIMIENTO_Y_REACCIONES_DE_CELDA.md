## Ciclo seguro de un paso

`Ficha.mover_por_camino()` conserva la animación y la decisión de iniciar el
siguiente tramo. Cada paso confirmado respeta este orden:

```text
reservar destino
→ completar tween
→ procesar SALIR con ocupación todavía en el origen
→ confirmar movimiento en TableroGrid
→ actualizar coordenada de la ficha
→ cobrar el coste normal del paso
→ procesar ENTRAR con ocupación confirmada en el destino
→ emitir paso_dado
→ continuar o interrumpir antes del siguiente tween
```

Los puntos `SALIR` y `ENTRAR` son callbacks síncronos coordinados por el
escenario. No abren menú ni manipulan UI. Las señales de reserva y ocupación de
`TableroGrid` son observacionales y no constituyen una segunda ruta para
ejecutar reacciones. La consulta, orden y agregación de varios receptores se
incorporarán en los siguientes incrementos de la Fase 5.

El coste normal de caminar se cobra exactamente una vez al confirmar el paso y
permanece separado de futuros costes adicionales del terreno y de las
consecuencias producidas por reacciones. Una interrupción solicitada durante
`SALIR` o `ENTRAR` nunca detiene el tween actual ni revierte la ocupación: evita
que comience el siguiente tramo.

### Recálculo y espera en exploración — 09-10-2026

`MovimientoPorCasillas.mover_por_camino()` admite destino final, callback de
recálculo `(origen, destino, actor)` y callback de espera `(actor)`. Los recorridos
fijos conservan su comportamiento. Un NPC de exploración usa el recálculo para
continuar hacia el mismo destino si su ruta inicial queda bloqueada, sin depender
de su actitud. El recálculo usa ocupación y reservas actuales del tablero.

Si falla la reserva antes de empezar un paso, recalcula. Desde el 11-10-2026,
si no hay ruta, el NPC cierra el recorrido y procesa el `FIN_TURNO` normal;
reintenta en el próximo ciclo. No deja `esta_moviendose` activo entre ciclos ni
reserva celdas o consume movimiento por esperar. El jugador puede seguir caminando. La revisión
se actualiza con reservas, ocupación, presencia y registro/retiro de elementos que
afectan las rutas; no se ejecuta A* en cada frame mientras el tablero no cambie.

Cada NPC tiene su propio recorrido y contador `pasos_completados`, usado para
registrar distancia incluso al tomar un desvío. La reserva sigue siendo sólo la
próxima casilla, y el cobro/reacciones conservan el orden del paso confirmado.
Entrar en combate interrumpe recorridos. El siguiente ciclo de exploración repone
recursos una sola vez; una ruta bloqueada no añade ciclos ni renueva recursos.

### Consulta de reacciones de una celda

`ConsultorReaccionesCelda` obtiene fuentes compatibles sin validarlas ni
resolverlas. Consulta, en orden contractual, terreno, efectos de superficie,
interactuables, items en el suelo y ocupantes. Al consultar ocupantes excluye al
actor del evento para impedir que reaccione contra sí mismo.

Una fuente automática implementa, además del contrato receptor:

```gdscript
func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool
func obtener_id_reaccion() -> StringName
func obtener_prioridad_reaccion(tipo: TiposInteraccion.TipoAccion) -> int
```

Las fuentes con retornos inválidos o que no implementan el contrato completo se
omiten. Cada fuente aceptada produce un `ReaccionCelda` con categoría, prioridad,
ID estable y receptor. El resultado se ordena por categoría, prioridad entera
ascendente e ID estable textual. Las colecciones de la celda se consultan mediante
copias para que una mutación posterior no altere el conjunto ya obtenido.

`Celda.reaccion_terreno` representa la fuente singular asociada al terreno.
`efectos_superficie`, `interactuables`, `items_suelo` y `ocupantes` conservan sus
colecciones separadas. `Interactuable` aporta por defecto su `id_instancia` y
prioridad cero, pero no reacciona automáticamente hasta que una especialización
lo declare. La consulta no presenta UI, no cobra costes y no aplica consecuencias.

