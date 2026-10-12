# Primer árbol del NPC con LimboAI

## Abrir el ejemplo

1. Abrir `res://scenes/pruebas LimboAI/prueba_ia.tscn` y ejecutar con F6.
2. Cambiar las condiciones del panel y pulsar **Evaluar decisión**.
3. Leer la decisión y el recorrido debajo del botón.
4. Para editar la estructura, detener la escena, seleccionar `BTPlayer` y pulsar
   su propiedad **Behavior Tree**, que apunta a `res://prueba_ia.tres`.
5. Durante la ejecución, **Depurador → LimboAI** permite observar el árbol.

Es un ejemplo didáctico: elige una acción, pero no mueve personajes ni resuelve
ataques reales. No carga ni escribe partidas guardadas.

## Estructura

```text
Selector: elegir por prioridad
├─ Secuencia: atacar si puedo
│  ├─ ¿Tengo acción y jugador adyacente?
│  └─ Atacar
├─ Secuencia: acercarme si puedo
│  ├─ ¿Estoy lejos y tengo movimiento y camino?
│  └─ Acercarse
└─ Terminar turno
```

- **Selector:** intenta sus hijos en orden. Cuando uno tiene éxito, lo elige.
- **Secuencia:** ejecuta sus hijos en orden; una condición que falla impide
  ejecutar su acción y permite que el selector pruebe la siguiente rama.
- **Blackboard:** memoria compartida. La escena escribe las condiciones;
  las tareas las consultan y escriben la decisión y su recorrido.
- **Manual:** la escena llama a `BTPlayer.update()` al pulsar el botón.
  Primero usa `restart()` para comenzar una evaluación nueva.

## Situaciones para explorar

| Distancia | Acción principal | Movimiento | Camino | Decisión prevista |
|---|---|---|---|---|
| 1 | Sí | Cualquiera | Cualquiera | Atacar |
| 3 | Sí | 2 | Sí | Acercarse |
| 3 | Sí | 0 | Sí | Terminar turno |
| 3 | Sí | 2 | No | Terminar turno |
| 1 | No | 2 | Sí | Terminar turno |
| 3 | No | 2 | Sí | Acercarse |

El último caso muestra que movimiento y acción principal son recursos separados:
se puede decidir acercarse después de gastar la acción. La ejecución real deberá
respetar costes, ocupación del tablero y cambios durante cada paso.

## Archivos y siguiente incremento

- `prueba_ia.tres`: estructura editable y prioridades.
- `scenes/pruebas LimboAI/prueba_ia.gd`: panel y evaluación manual.
- `ai/tasks/compartidas/comprobar_condicion.gd`: condición sobre la memoria.
- `ai/tasks/compartidas/elegir_accion.gd`: comunica la decisión.

El incremento del 06-10-2026 conecta las intenciones con acciones reales del NPC. Un
ataque resuelto puede considerarse una tarea completada aunque la tirada de FUE
falle o el defensor esquive: el resultado de ejecución del árbol y el resultado
de los dados expresan cosas distintas.

Estado: el usuario confirmó el 06-10-2026 que el ejemplo funciona correctamente
en Godot. La integración real usa otro árbol, `recursos/ia/combate_npc.tres`, y
`DecisorCombateNPC`, con las mismas dos tareas compartidas. El escenario ejecuta
la intención y vuelve a evaluar después de moverse. El ejemplo conserva sus
controles para aprender sin ejecutar combate. El usuario confirmó que funciona
el movimiento del NPC en `tests/interacciones/escena_npc_hostil.tscn`.

## Primera prioridad del árbol real — 08-10-2026

`recursos/ia/combate_npc.tres` ahora consulta estas ramas en orden:

```text
Selector
├─ Estoy enredado → Liberarme
├─ Puedo atacar → Atacar
├─ Puedo acercarme → Acercarme
└─ Terminar turno
```

La liberación se elige incluso junto al jugador. El ejecutor comprueba la acción
principal: si no queda, pasa el turno. Cada intento usa DES y paga una acción;
fallar conserva enredado. Al acertar, se reevalúa con los recursos restantes.
Caer obliga a cerrar el turno antes de evaluar otras acciones. El ejemplo
didáctico conserva sus tres ramas originales; estos cambios están en el árbol real.
El usuario confirmó telaraña y caída; otras comprobaciones de estados quedan
registradas por separado en `PRUEBAS.md`.

## Buscar al perder el objetivo — 09-10-2026

El árbol real incluye búsqueda y regreso antes de pasar turno:

```text
Liberarme → Atacar → Acercarme → Buscar → Terminar búsqueda
→ Esperar patrulla → Avanzar punto → Patrullar → Regresar → Pasar
```

Atacar requiere detección propia. Acercarse usa visión propia o, desde el primer
corte grupal, una posición observada por otro participante vivo del encuentro.
Buscar usa la última casilla recordada,
guardada en el estado del NPC; no conoce dónde está ahora el jugador oculto.
Perder detección de todos los oponentes vivos termina el modo combate inmediatamente;
perder sólo la visión propia no obliga a buscar o regresar. Buscar y regresar se
ejecutan en ciclos automáticos de exploración desde el 11-10-2026, también con
el jugador quieto. Al llegar al recuerdo sin detectarlo,
elige terminar búsqueda y borra el recuerdo. Después retoma el punto pendiente
de patrulla o, sin circuito, regresa a la casilla donde apareció originalmente.
Si no hay camino, conserva el destino y espera; al cambiar
el tablero recalcula con el movimiento restante. Varios NPC ejecutan estos
recorridos a la vez; reservar la próxima casilla evita superposiciones.
No tener movimiento obliga a pasar y continuar en el siguiente turno, sin
confundir una reserva agotada con una búsqueda terminada. La ejecución vuelve
a comprobar detección después de cada paso; recuperarla inicia otro combate por
iniciativa. El árbol elige la intención; el escenario controla la modalidad y
ejecuta movimiento, liberación y efectos de fin de turno.

El corte de patrullas usa las condiciones `esperando_patrulla`,
`punto_patrulla_alcanzado` y `puede_patrullar`. Una rama consume un avance de
espera, otra cambia el índice al llegar y la tercera solicita movimiento real.
Todas quedan después de buscar y liberarse. Los puntos se editan como `Path2D`;
ver [Patrullas de NPC](../contenido/PATRULLAS_NPC.md). El 11-10-2026 se ejecutó
`prueba_exploracion_npc_autonoma.tscn` con autorización del usuario: varios ciclos
con el jugador quieto y pausa/reanudación por modalidad de combate, con salida cero.
