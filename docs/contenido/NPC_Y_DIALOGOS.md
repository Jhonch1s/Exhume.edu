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

## Próximos incrementos sugeridos

1. **Estado persistente del NPC y memoria narrativa.** Definir qué variables
   pertenecen a cada NPC y cuáles a la partida; guardar/restaurar PV, estados y
   `trompo_conocido` con validación y una versión de snapshot compatible.
2. **Ciclo vital común.** Añadir aplicación de daño, curación, estados, derrota
   y reglas para NPC con capacidades opcionales. Evitar que `vida_actual == 0`
   se interprete como «sin inicializar» cuando represente una derrota real.
3. **Relaciones.** Resolver actitud efectiva hacia el jugador a partir de la
   definición y cambios de partida; impedir cambios en NPC de actitud fija.
   Mantener a Trompo como caso neutral inmutable.
4. **Combate inicial.** Integrar jugador contra NPC hostiles en las rondas,
   selección de acciones e IA mínima. Dejar alianzas y terceros neutrales para
   una ampliación posterior.
5. **Progresión.** Conceder XP al derrotar NPC, definir umbrales de nivel y
   conectar la barra del HUD con la XP que falta para el siguiente nivel.
6. **Diálogos con tiradas.** Definir una solicitud de prueba desde el diálogo,
   mostrar el dado y ramificar por resultado sin acoplar Dialogue Manager al
   motor de reglas.

Al continuar esta línea de trabajo, actualizar aquí el estado real de cada
incremento y registrar decisiones de arquitectura en
`docs/decisiones/DECISIONES.md` cuando queden acordadas.
