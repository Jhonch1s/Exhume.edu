# NPC y diálogos

Estado del código revisado el 26 de septiembre de 2026. Este documento distingue
los datos ya configurables de los comportamientos realmente conectados al juego.
Trompo es el primer personaje no jugador colocado en una zona.

## Modelo actual

| Capa | Implementación | Responsabilidad actual |
|---|---|---|
| Definición | `scripts/personajes/definicion_personaje.gd` | Atributos base, vida máxima, nivel, XP de recompensa, actitud inicial, capacidades, sprite, ilustración y temas de diálogo. |
| Instancia | `scripts/personajes/personaje_npc.gd` | Nombre único, vida/atributos/nivel actuales, interacción, bloqueo del paso y selección visual del sprite. |
| Tema de diálogo | `scripts/personajes/dialogo_npc.gd` | ID, título, recurso `.dialogue` y punto de inicio. |
| Representación | `scenes/personajes/npc.tscn` | Sprite de 2 × 2 orientaciones de 64 × 96 px, con offset `(0, -32)` y marcador de diálogo. |

La definición de Trompo está en `recursos/personajes/goblin_unico.tres`. Tiene
15 PV máximos, nivel 3, atributos 5/5/5, recompensa declarada de 120 XP,
actitud inicial neutral y fija, diálogo habilitado y combate deshabilitado.
`puede_tener_inventario` está marcado, pero todavía no crea un inventario real.
La instancia `goblin_001`, llamada Trompo, está en
`scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn`, bajo
`Interactuables/Personajes`. Los atributos y la vida de la definición se usan
como valores iniciales cuando la instancia no trae otros valores configurados.

## Funciona actualmente

- El tablero registra al NPC como interactuable con ID estable. Su celda impide
  caminar sobre él (`permite_caminar_interactuable() == false`).
- El hover sigue los píxeles opacos del sprite y la visibilidad de la celda. El
  outline y el menú contextual proceden del sistema de interactuables.
- `PanelInfoNPC` muestra nombre, nivel y PV actuales/máximos mientras está bajo
  el cursor. El menú ofrece `Hablar` por cada tema válido y usa alcance 1.
- Al elegir `Hablar`, `EscenarioBase` abre Dialogue Manager con NPC y ficha como
  estados, muestra las ilustraciones de ambos y mantiene la interacción modal
  hasta terminar. El panel y las respuestas están dentro del filtro CRT.
- `dialogues/personajes/trompo.dialogue` contiene la presentación inicial y
  ramas de conversación. `EstadoPartida.trompo_conocido` recuerda durante esta
  ejecución si ya se presentó; se reinicia al crear una partida nueva.
- `tools/dialogue_editor.html` permite importar, editar, duplicar puntos o
  bloques y exportar `.dialogue`. Su vista previa muestra la sintaxis generada
  y advierte sobre errores frecuentes de condiciones, saltos y autoloads.
- `Ficha` ya declara nivel y XP acumulada y los incluye en su estado guardado.

## Límites comprobados en el código

- La actitud inicial y `actitud_hacia_jugador_fija` son datos de definición;
  todavía no hay relación dinámica, facciones, reputación ni transición a
  hostilidad. La neutralidad fija de Trompo es intención de contenido, no una
  regla de combate aplicada por un sistema de actitud.
- `PersonajeNPC` no implementa estados temporales, daño/curación, muerte,
  inventario operativo, movimiento autónomo ni interfaz de actor para rondas.
  `puede_combatir` y `experiencia_recompensa_derrota` aún no producen efectos.
- El escenario conserva `en_combate`, pero no inicia una secuencia de turnos con
  NPC. `GestorRondas` es genérico; todavía falta integrar NPC como actores.
- La ficha almacena XP, pero no hay curva, ganancia por derrota, subida de nivel
  ni barra de experiencia conectada: el HUD muestra un valor de muestra.
- El guardado de interactuables usa el estado persistente heredado, vacío para
  `PersonajeNPC`; por ello no conserva PV, nivel, atributos u otros futuros
  cambios del NPC. `EstadoPartida.trompo_conocido` tampoco entra en el snapshot:
  se pierde al cerrar el juego y no se restaura al cargar una partida.
- Los diálogos pueden escribir condiciones y mutaciones de Dialogue Manager,
  pero aún no hay una acción de diálogo conectada a tiradas de dados ni una
  presentación específica del resultado de una tirada dentro del diálogo.

## Decisiones acordadas para el modelo de estado (26-09-2026)

- **Definición:** `DefinicionPersonaje` es la plantilla compartida con valores
  base, actitud inicial, capacidades y presentación. No recibe cambios propios
  de una instancia durante la partida.
- **Instancia:** cada `PersonajeNPC` conserva identidad y ubicación, y tendrá
  estado de ejecución independiente inicializado desde su definición.
- **Estado guardado:** se serializa como datos planos asociados al ID estable de
  la instancia, usando los métodos de estado persistente que ya delega
  `PersistenciaInteractuables`. No se serializan nodos ni referencias a recursos.
- **Derrota:** por ahora equivale a `vida_actual == 0`. La inicialización desde
  la definición debe distinguirse explícitamente de la restauración para no
  reponer PV a una instancia derrotada.
- **Actitud:** la actitud fija de Trompo prevalece sobre cualquier sistema de
  relaciones y permanece neutral. Para NPC dinámicos se guarda la actitud
  efectiva hacia el jugador; el juego es actualmente de un solo jugador.
- **Memoria narrativa:** `trompo_conocido` también se guardará en el snapshot de
  partida, separado del estado individual de Trompo.
- **Capacidades opcionales:** combate e inventario no se vuelven requisitos del
  estado común. Sus datos específicos se incorporarán cuando esas capacidades
  tengan implementación.
- **Estados temporales:** quedan fuera del primer incremento de persistencia.
  Antes de guardarlos definiremos duración, ticks, expiración y qué ocurre al
  cambiar de zona o cargar una partida.
- **Prueba de desarrollo:** F6 debe iniciar la escena desde valores iniciales,
  como primera visita, sin cargar automáticamente `user://partida.json`. La
  carga de progreso guardado seguirá siendo explícita. Actualmente el proyecto
  no tiene un cargador automático en `_ready`; `EstadoPartida` empieza con
  `trompo_conocido = false` y solo se carga guardado mediante
  `EscenarioBase.cargar_partida()`.

## Próximos incrementos sugeridos

1. **Estado común del NPC y memoria narrativa persistentes.** Añadir estado de
   ejecución por NPC para PV, atributos y nivel; guardar/restaurar esos valores
   con validación, más la actitud solo cuando sea dinámica. Guardar y restaurar
   `trompo_conocido` en la sección de partida. Comprobar el caso de PV cero y que
   la ejecución de desarrollo con F6 no restaure un guardado anterior.
2. **Ciclo vital común.** Incorporar operaciones de daño y curación; mantener la
   derrota definida por PV cero. No añadir todavía reglas de combate.
3. **Estados temporales.** Acordar su contrato de duración y expiración antes de
   incorporarlos al estado persistente del NPC.
4. **Relaciones dinámicas.** Resolver la actitud efectiva respetando la actitud
   fija y persistir la relación del jugador cuando corresponda.
5. **Combate inicial.** Integrar NPC combatientes en rondas y acciones; mantener
   combate e inventario como capacidades opcionales.
6. **Progresión y diálogos con tiradas.** Conceder XP y definir niveles; luego
   conectar solicitudes de tirada al diálogo sin acoplar Dialogue Manager al
   motor de reglas.

## Progreso de planificación

- **Completado:** inspección de `DefinicionPersonaje`, `PersonajeNPC`, `Ficha`,
  `EstadoActor` y los contratos actuales de persistencia. Se acordó el modelo
  definición/instancia/snapshot, la derrota por PV cero, la persistencia de
  actitud dinámica y memoria narrativa, y el reinicio limpio de F6.
- **Pendiente:** elegir el tipo concreto del objeto de estado de ejecución y
  cerrar el esquema/versionado del snapshot al iniciar la implementación.
- **Pendiente:** definir semántica y persistencia de estados temporales.

Al continuar esta línea de trabajo, actualizar aquí el estado real de cada
incremento y registrar decisiones de arquitectura en
`docs/decisiones/DECISIONES.md` cuando queden acordadas.
