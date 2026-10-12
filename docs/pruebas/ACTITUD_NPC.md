# Comprobación de actitud de NPC

Abrir `tests/interacciones/escena_actitud_npc.tscn` y ejecutar F6. Empieza de cero,
sin cargar el slot normal. K/C usan exclusivamente `user://prueba_actitud_npc.json`.
C exige actores en reposo; cerrar paneles antes de guardar/cargar. Clic izquierdo
abre acciones; clic derecho mueve. El cartel muestra puntos, relación, PV y oposición.

Hay tres NPC sin patrulla: **Neutral dinámico** (15 PV, FUE/DES 1, combate,
visión 4); **Neutral fijo combatiente** con las mismas capacidades; y
**Trompo (excepción)**, con su definición neutral fija y combate deshabilitado.
Los diálogos son contenido de comprobación, no cambian el diálogo de Trompo del juego.

1. En el dinámico, elegir Hablar → Ofrecer ayuda tres veces: 0 → 1 → 2 → 3;
   en +3 pasa a amistoso. Insultar una vez lo devuelve a neutral en +2.
2. Reiniciar F6. Atacar al dinámico: al resolverse el intento queda en -2, neutral,
   pero se defiende en su turno. Si el NPC gana iniciativa, el primer clic sólo
   abre encuentro: atacar cuando llegue el turno del jugador para resolver el golpe.
   No hay respuesta gratuita fuera de iniciativa. Fallo y esquiva también restan 2.
3. Huir fuera de su visión: termina la defensa y vuelve a su origen. Acercarse
   después no debe reabrir combate mientras siga neutral.
4. Agredir otra vez: -2 → -4, hostil. Huir y regresar sí permite detección hostil.
   También se llega a hostil con tres insultos desde cero. Ofrecer ayuda puede
   recuperar puntos; cambiar relación durante un encuentro no cancela su defensa.
5. Atacar al fijo combatiente: se defiende, conserva neutral/0. Huir termina su
   oposición. Sus diálogos de +1/-1 no cambian relación. Trompo no ofrece Atacar
   y esos diálogos tampoco cambian su relación.
6. Guardar en -2 durante el encuentro, después de consumir una acción. Modificar
   puntos o continuar el combate, cargar y volver a cargar: debe conservar -2,
   encuentro, iniciativa y recursos; no resta otra penalización ni repite una
   acción gastada. Guardar exploración y cargar sobre otro encuentro elimina la
   oposición anterior y conserva la relación del momento guardado.

Una orden cancelada, sin recursos, con atributos inválidos o que no logra llegar
al alcance no debe modificar relación. El daño de superficies no se atribuye al
jugador. Los valores de esta escena facilitan comprobar supervivencia y huida;
no fijan estadísticas del contenido final.

`tests/interacciones/prueba_actitud_npc.tscn` comprueba límites y transiciones,
independencia por instancia, migración de etiquetas anteriores, JSON y rechazo
atómico de puntos inválidos, ataques acertados/fallidos/esquivados con RNG fijo,
defensa del neutral y del fijo, mutaciones reales de Dialogue Manager y K/C
repetida de encuentro/exploración. Sustituye captura 3D; durante K/C desactiva
timers de decisión para comprobar exactamente las reservas, y al final habilita
el árbol y turno reales para verificar la respuesta autónoma del neutral.
Presentación y balance se revisan con los pasos anteriores.

El 11-10-2026 pasaron en Godot 4.7 sin ventana esta prueba, persistencia NPC
(21 grupos), esquiva (20 casos) y exploración autónoma. Una advertencia previa de
UID de palanca sigue cargando por ruta.

El mismo 11-10-2026 el usuario confirmó la revisión manual con «ya quedó todo
testeado, veo que funciona». Esta confirmación complementa las pruebas
automáticas y cierra el bloque de actitud de NPC.
