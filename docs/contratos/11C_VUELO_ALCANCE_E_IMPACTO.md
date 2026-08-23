### Representación temporal del vuelo — incremento 9.4

Al confirmar el objetivo, la escena conserva el `ContextoAccion` sin procesarlo e
instancia temporalmente `DefinicionItem.escena_mundo`. Un `Tween` desplaza esa
representación por las celdas del `recorrido` calculado por 9.3; la duración por
celda es una propiedad exportada de la escena. No existe una segunda trayectoria
visual ni se recalculan obstáculos desde la animación.

Mientras el vuelo está activo, el escenario mantiene el estado modal y la instancia
permanece sin cambios en el inventario. Al finalizar se oculta y libera la
representación temporal y recién entonces `GestorAcciones` procesa el contexto. Por
lo tanto, cualquier bloqueo o fallo tardío conserva la pila, y un éxito aplica una
sola vez `IMPACTAR` y el destino final de la unidad. La representación persistente
de un eventual `ItemSuelo` continúa naciendo exclusivamente del registro lógico del
tablero.

Si el item no declara `escena_mundo`, el contexto se procesa inmediatamente: la
ausencia de un asset visual no cambia la mecánica. Este incremento no incorpora
parábolas, rebotes, rotación, desviación ni efectos particulares por definición.

El alcance de lanzamiento usa `MetricaAlcance.CUADRICULA`: la distancia es
`max(abs(dx), abs(dy))`, de modo que avanzar una celda diagonal o cardinal consume
un paso. `ContextoAccion` declara la métrica y `GestorAcciones` la aplica sin conocer
el tipo concreto de acción. Las interacciones existentes conservan Manhattan por
defecto, por lo que una palanca manual continúa exigiendo adyacencia cardinal.

### Alcance según fuerza — incremento 9.5

Un actor capaz de lanzar expone `obtener_fuerza()` como entero no negativo. El
alcance máximo se calcula una sola vez mediante `max(2, 1 + fuerza)` y usa la métrica
de cuadrícula de 9.4. `TransferidorItems.construir_contexto_lanzar()` obtiene el dato
del actor; los llamadores ya no proporcionan un alcance arbitrario.

El escenario consulta al mismo transferidor para validar la celda y dibujar la
previsualización. Antes de resolver, el transferidor recalcula la fuerza y exige que
coincida con el valor inmutable del contexto. Un actor sin el contrato, con un valor
no entero o negativo produce `actor_sin_fuerza`; una discrepancia produce
`alcance_lanzamiento_incoherente`, siempre antes de retirar la unidad.

El peso del item continúa transportándose como magnitud del impacto, pero no altera
el alcance en este incremento. Su interacción con fuerza se definirá únicamente si
el diseño necesita diferenciar objetos arrojables por masa.

### Consecuencia propia del item — incremento 9.6

`DefinicionItem.reaccion_impacto` es opcional. Si existe, debe ofrecer
`validar_impacto()` y `resolver_impacto()`; `TransferidorItems` las invoca sobre la
celda real de caída después de resolver `IMPACTAR`. La ausencia de reacción mantiene
el comportamiento anterior. `GestorAcciones` permanece ajeno a definiciones concretas.

`ReaccionImpactoSuperficie` valida primero tablero, contenedor, celda caminable e ID
de efecto. Al resolver reutiliza `TableroGrid.desplegar_efecto_superficie()` y declara
`CONSUMIR`. Como se agrega después de las reacciones de la celda, conserva la regla
general de 9.1: un destino explícito anterior prevalece.

La definición `bomba_humo` configura esta reacción con radio cero y la escena neutral
`Humo`. Por tanto, una unidad se rompe y despliega una nube en su celda de caída; no
queda `ItemSuelo`. La nube pertenece a la familia `&"humo"`, bloquea visión, declara
diez turnos de duración y no bloquea trayectoria de proyectiles. Su atlas visual tiene
cuatro cuadros de `64×64`; la definición todavía no requiere icono de inventario.

