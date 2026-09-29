# NPC y diálogos

Estado del código revisado el 28 de septiembre de 2026. Este documento distingue
los datos ya configurables de los comportamientos realmente conectados al juego.
Trompo es el primer personaje no jugador colocado en una zona.

## Modelo actual

| Capa | Implementación | Responsabilidad actual |
|---|---|---|
| Definición | `scripts/personajes/definicion_personaje.gd` | Atributos base, vida máxima, nivel, iniciativa, recursos por turno, XP de recompensa, actitud inicial, capacidades, sprite, ilustración y temas de diálogo. |
| Instancia | `scripts/personajes/personaje_npc.gd` | Nombre único, configuración inicial opcional, interacción, bloqueo del paso y selección visual del sprite. |
| Estado de instancia | `scripts/personajes/estado_personaje_npc.gd` | PV, atributos, nivel, actitud efectiva y recursos de turno cuando puede combatir. |
| Estado guardado | `PersistenciaInteractuables` y `PersistenciaPartida` | Datos planos por ID de instancia y memoria narrativa de la partida. |
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

- El tablero registra al NPC como interactuable con ID estable. Un NPC con PV
  bloquea su celda; al quedar derrotado permite atravesarla.
- El hover sigue los píxeles opacos del sprite y la visibilidad de la celda. El
  outline y el menú contextual proceden del sistema de interactuables.
- `PanelInfoNPC` muestra nombre, nivel y PV actuales/máximos mientras está bajo
  el cursor. El menú ofrece `Hablar` por cada tema válido y usa alcance 1.
- Al elegir `Hablar`, `EscenarioBase` abre Dialogue Manager con NPC y ficha como
  estados, muestra las ilustraciones de ambos y mantiene la interacción modal
  hasta terminar. El panel y las respuestas están dentro del filtro CRT.
- `dialogues/personajes/trompo.dialogue` contiene la presentación inicial y
  ramas de conversación. `EstadoPartida.trompo_conocido` recuerda si ya se
  presentó, se reinicia al crear una partida nueva y se guarda con la partida.
- El estado de cada NPC se inicializa una vez desde su definición. El snapshot
  conserva PV actuales, fuerza, destreza, voluntad y nivel. Para NPC de actitud
  dinámica conserva también la actitud hacia el jugador. Trompo tiene actitud
  fija neutral y rechaza cambios de actitud.
- `vida_actual == 0` indica derrota y se conserva al cargar. La versión 2 del
  snapshot incluye `memoria_narrativa.trompo_conocido`. La carga de versión 1
  inicializa los NPC desde su definición y asume que Trompo aún no es conocido.
- `PersonajeNPC.recibir_danio()` y `curar()` limitan los PV entre cero y el
  máximo de la definición. Emiten cambios de vida y de derrota; curar desde cero
  revierte la derrota. `AplicadorEfectos` puede aplicar daño a un NPC mediante
  su contrato existente. Recibir daño no altera la actitud fija de Trompo.
- A 0 PV, el NPC permanece visible y registrado. `puede_actuar()` devuelve
  `false`, `Hablar` y `Atacar` desaparecen del menú y las acciones de diálogo
  antiguas se bloquean al resolverlas. `Examinar` permanece si su definición
  tiene perfil de observación y fragmentos; esta es la condición de contenido
  que exige el sistema de examen. La celda queda caminable y el pathfinding
  consulta ese estado al recalcular rutas. Curarlo por encima de cero restaura
  las opciones y el bloqueo del paso.
- Un NPC hostil con `puede_combatir` ofrece `Atacar` mientras tiene PV. La acción
  usa el menú contextual, alcance 1, una prueba de FUE del jugador y consume una
  acción principal aunque falle. En el prototipo, un acierto causa 1 PV fijo;
  crítico y pifia siguen las reglas de la prueba, sin daño adicional. La prueba
  integrada usa un enemigo creado solo para ese caso: no se añadió uno al
  contenido permanente de la zona.
- `tests/interacciones/escena_npc_hostil.tscn` monta `EscenarioBase` con un
  objetivo hostil de 2 PV, generado cerca del jugador y teñido de rojo para
  distinguirlo del sprite provisional de Trompo. En esta escena de revisión,
  clic izquierdo abre las acciones, clic derecho mueve, F7 guarda en
  `user://prueba_npc_hostil.json` y F8 carga ese archivo. F6 inicia de cero;
  la carga sigue siendo explícita. La escena no modifica el Templo ni el slot
  normal `user://partida.json`.
- `tools/dialogue_editor.html` permite importar, editar, duplicar puntos o
  bloques y exportar `.dialogue`. Su vista previa muestra la sintaxis generada
  y advierte sobre errores frecuentes de condiciones, saltos y autoloads.
- `Ficha` ya declara nivel y XP acumulada y los incluye en su estado guardado.

## Límites comprobados en el código

- El estado admite cambios de actitud en NPC dinámicos, pero todavía no hay
  eventos de relación, facciones, reputación ni transición a hostilidad.
  El ataque básico consulta la actitud efectiva; faltan las demás reglas de
  combate.
- `PersonajeNPC` no implementa estados temporales, muerte definitiva,
  inventario operativo ni movimiento autónomo.
  `experiencia_recompensa_derrota` aún no produce efectos.
- El escenario inicia combate al elegir `Atacar` contra un NPC hostil combatiente.
  `GestorRondas` incluye a la ficha y al objetivo, y el panel superior muestra
  ronda, orden y actor activo. Si está adyacente, el NPC intenta un ataque de
  FUE que gasta una acción principal; si está lejos, pasa. Faltan movimiento,
  otras acciones, defensa, decisiones tácticas y XP.
- La derrota todavía no tiene pose, animación, cadáver separado, botín ni XP.
  El texto de `Examinar` procede de la definición y aún no cambia por derrota.
- La ficha almacena XP, pero no hay curva, ganancia por derrota, subida de nivel
  ni barra de experiencia conectada: el HUD muestra un valor de muestra.
- Los estados temporales, el inventario operativo y otras capacidades futuras
  de NPC todavía no forman parte del snapshot.
- Los diálogos pueden escribir condiciones y mutaciones de Dialogue Manager,
  pero aún no hay una acción de diálogo conectada a tiradas de dados ni una
  presentación específica del resultado de una tirada dentro del diálogo.

## Decisiones acordadas para el modelo de estado (26 y 28-09-2026)

- **Definición:** `DefinicionPersonaje` es la plantilla compartida con valores
  base, actitud inicial, capacidades y presentación. No recibe cambios propios
  de una instancia durante la partida.
- **Instancia:** cada `PersonajeNPC` conserva identidad y ubicación, con estado
  de ejecución independiente inicializado desde su definición.
- **Estado guardado:** se serializa como datos planos asociados al ID estable de
  la instancia, usando los métodos de estado persistente que ya delega
  `PersistenciaInteractuables`. No se serializan nodos ni referencias a recursos.
- **Derrota:** por ahora equivale a `vida_actual == 0`. La inicialización desde
  la definición debe distinguirse explícitamente de la restauración para no
  reponer PV a una instancia derrotada. A 0 PV permanece visible y examinable
  cuando tiene contenido de examen, no habla ni actúa y permite pasar por su
  casilla. Una curación que sube los PV revierte esta situación.
- **Actitud:** la actitud fija de Trompo prevalece sobre cualquier sistema de
  relaciones y permanece neutral. Para NPC dinámicos se guarda la actitud
  efectiva hacia el jugador; el juego es actualmente de un solo jugador.
- **Memoria narrativa:** `trompo_conocido` se guarda en el snapshot de
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

1. **Estado común del NPC y memoria narrativa persistentes: implementado.**
   `EstadoPersonajeNPC` guarda PV, atributos, nivel y actitud dinámica.
   `PersistenciaPartida` guarda `trompo_conocido`, valida antes de restaurar y
   acepta snapshots v1. F6 sigue iniciando sin carga automática.
2. **Ciclo vital común: implementado.** Daño y curación respetan los límites de
   vida, notifican cambios y mantienen la derrota definida por PV cero.
3. **Estados temporales.** Acordar su contrato de duración y expiración antes de
   incorporarlos al estado persistente del NPC.
4. **Relaciones dinámicas.** Resolver la actitud efectiva respetando la actitud
   fija y persistir la relación del jugador cuando corresponda.
5. **Modo de combate: dos cortes implementados.** `Atacar` inicia un encuentro
   con el objetivo; hay orden visible, actor activo, `Pasar turno`, límite de
   movimiento por recursos, salida al derrotarlo y guardado de ronda y actor.
   El usuario informó que este primer flujo funcionó en Godot. El segundo corte
   añade ataque adyacente del NPC y recursos propios persistentes; falta su
   comprobación jugable. Revisar también el daño provisional de 1 PV y F7/F8
   durante un combate activo. Después definir defensa y decisiones tácticas;
   mantener combate e inventario como capacidades opcionales.
6. **Progresión y diálogos con tiradas.** Conceder XP y definir niveles; luego
   conectar solicitudes de tirada al diálogo sin acoplar Dialogue Manager al
   motor de reglas.

## Progreso

- **Completado:** inspección de `DefinicionPersonaje`, `PersonajeNPC`, `Ficha`,
  `EstadoActor` y los contratos actuales de persistencia. Se acordó el modelo
  definición/instancia/snapshot, la derrota por PV cero, la persistencia de
  actitud dinámica y memoria narrativa, y el reinicio limpio de F6.
- **Implementado:** `EstadoPersonajeNPC` es un `RefCounted` por instancia. El
  snapshot actual es v2 y acepta v1 con estado de NPC vacío; la prueba
  `prueba_estado_npc_persistente.tscn` verificó la restauración y la compatibilidad.
- **Implementado:** operaciones de daño y curación, señales de vida y derrota, y
  recepción de daño mediante `AplicadorEfectos`. `Atacar` usa la misma ruta de
  opciones, contexto y `GestorAcciones`; se comprobó con un enemigo de prueba.
- **Implementado:** comportamiento de derrota acordado para visibilidad,
  interacción y paso; escena aislada con objetivo hostil y guardado propio para
  revisión manual. El usuario confirmó en Godot que puede atacarlo hasta 0 PV,
  atravesar su casilla, examinarlo, ver que `Atacar` desaparece y restaurar el
  estado derrotado con F7/F8. La escena de prueba no tiene diálogo; el bloqueo
  de `Hablar` al estar derrotado está implementado, pero no se verificó allí.
- **Primer corte, comprobado inicialmente por el usuario:** `Atacar` entra en
  combate con ficha y NPC, panel superior de orden y ronda, avance desde
  `Pasar turno`, pase automático inicial del NPC, bloqueo de entrada fuera del
  turno del jugador y salida cuando el
  objetivo llega a 0 PV. F7/F8 de la escena aislada guardan y restauran un
  combate activo sin reponer recursos al cargar. El usuario informó que el
  flujo funcionó en Godot; falta comprobar por separado cada caso de F7/F8
  durante el combate. El diseño visual del HUD superior se revisará más adelante.
- **Implementado para revisión:** un NPC hostil con capacidad de combate
  dispone de reservas de turno; si está adyacente y conserva acción principal,
  intenta un ataque de FUE que causa 1 PV al acertar. Si no está junto al
  jugador, pasa. El resultado va al registro narrativo. Las reservas se guardan
  y se restauran; los snapshots v2 previos siguen admitidos. Falta comprobar
  este segundo corte en Godot.
- **Pendiente de diseño:** daño fijo de 1 PV, inicio por detección, encuentros
  con varios NPC, huida, movimiento y otras acciones del NPC, defensa, IA y
  presentación final del derrotado.
- **Pendiente:** definir semántica y persistencia de estados temporales.

## Punto de continuidad para otra PC (28-09-2026)

- **Implementado y confirmado por el usuario:** el primer modo de combate se
  inicia con `Atacar`, muestra orden y actor activo, permite pasar turno y sale
  al derrotar al objetivo. También se comprobó antes la derrota a 0 PV, el
  examen y paso sobre el NPC derrotado, y F7/F8 para ese estado.
- **Implementado, pendiente de comprobación jugable:** el segundo corte hace
  que el NPC hostil ataque con FUE y gaste una acción principal si está
  adyacente. Si está lejos, pasa sin moverse. El resultado aparece en el
  registro narrativo; sus recursos se guardan y restauran. El daño de 1 PV
  sigue siendo provisional.
- **Para retomar:** abrir `tests/interacciones/escena_npc_hostil.tscn` en Godot,
  ejecutar la escena, elegir `Atacar` y, tras cerrar el resultado, usar
  `Pasar turno` estando junto al objetivo. Revisar el registro y los PV del
  jugador. Repetir desde lejos para confirmar que el NPC pasa. Revisar F7/F8
  durante el combate, especialmente después de un ataque del NPC.
- **Siguiente decisión:** definir defensa y reacciones del jugador antes de
  ampliar la IA o agregar más acciones al NPC. El aspecto del HUD superior
  se trabajará más adelante, como pidió el usuario.
- **Al cambiar de PC:** F6 inicia sin cargar partida. F7/F8 usan
  `user://prueba_npc_hostil.json`, que pertenece a la instalación local de
  Godot y no viaja con el repositorio; en la otra PC se crea un guardado nuevo.

Al continuar esta línea de trabajo, actualizar aquí el estado real de cada
incremento y registrar decisiones de arquitectura en
`docs/decisiones/DECISIONES.md` cuando queden acordadas.
