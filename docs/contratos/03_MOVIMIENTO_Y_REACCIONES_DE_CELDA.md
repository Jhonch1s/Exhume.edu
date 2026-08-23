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

