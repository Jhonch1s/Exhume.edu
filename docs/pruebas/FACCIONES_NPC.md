# Comprobación de facciones y bandos

Abrir `tests/interacciones/escena_facciones_npc.tscn` y ejecutar F6. Clic izquierdo:
acciones; clic derecho: movimiento. El cartel muestra facción, puntos, PV, bando
y casilla; el HUD distingue aliados y oponentes. No hay patrullas en esta escena.
V muestra los campos de visión de los NPC visibles; [recorrido específico](VISION_NPC.md).

| NPC | Relación y capacidad | Facción |
|---|---|---|
| Guardia | Neutral dinámico, combatiente, 15 PV | guardia_prueba |
| Compañero fijo | Neutral fijo, combatiente, 15 PV | guardia_prueba |
| Amistoso | Amistoso dinámico, combatiente, 15 PV | Sin facción |
| Compañero lejano | Neutral dinámico, fuera de visión inicial | guardia_prueba |
| Trompo (excepción) | Neutral fijo, no combatiente | Sin facción |

Los combatientes usan FUE/DES 1, movimiento DES + 3 y visión 7. Sus nombres,
texturas y estadísticas sólo facilitan la revisión; no fijan contenido final.

1. Con `inicio_hostil = false` (predeterminado), acercarse y atacar al Guardia.
   Si gana iniciativa, el primer clic abre defensa y el golpe espera al turno
   del jugador. Al resolver, Guardia pasa a -2/neutral y su compañero fijo se
   une al final de ronda como oponente, conservando 0/neutral. Amistoso no ayuda
   en esta agresión a un neutral; el lejano y Trompo tampoco se incorporan.
2. Huir de ambos oponentes. El encuentro termina cuando ninguno detecta;
   defensores neutrales olvidan persecución y regresan. Al volver no atacan
   por pertenencia a facción. Una segunda agresión puede llevar sólo al Guardia
   a -4/hostil; el compañero sigue en 0, salvo una acción propia sobre él.
3. Reiniciar con `inicio_hostil = true` en el nodo raíz del Inspector. El Guardia
   detecta al jugador e inicia encuentro; Amistoso entra como aliado y puede
   moverse/atacar al Guardia en su turno. Si Compañero fijo ve a Amistoso atacar
   al Guardia, puede defender a su compañero y entra como oponente sin cambiar
   puntos. No hay ataque gratuito al incorporarse.
4. Guardar con K durante un encuentro mixto, gastar recursos o continuar y
   cargar con C en reposo. Repetir C: mismos puntos, bandos, iniciativa y recursos
   del guardado; no se repite la penalización ni se repone una acción consumida.
   Cada modo usa su slot: `user://prueba_facciones_npc_neutral.json` o
   `user://prueba_facciones_npc_hostil.json`; no toca `partida.json`.
5. Derrotar a un oponente: el encuentro continúa si queda otro, aunque sobrevivan
   aliados. Al morir el último oponente termina. Examinar y recoger botín junto
   al cadáver; guardar/cargar conserva el cuerpo y las pilas restantes o vacío.
6. Trompo no ofrece Atacar ni se incorpora. Un miembro lejano sólo puede entrar
   cuando perciba un participante pertinente dentro de su propio alcance; no
   recibe puntos de relación por ser de la misma facción. Paredes y humo opaco
   deben impedir percepción. La iluminación no sustituye la línea visual.

`tests/interacciones/prueba_facciones_npc.tscn` reutiliza la escena y crea suelo
propio para casos deterministas. Comprueba fallos/esquivas/daño, bloqueos,
testigo que ve sólo una parte, pared, cadáver y Trompo, prioridades, incorporación
sin cadenas ni renovación, iniciativa de la siguiente ronda, memoria por bando
sin acceso a posición oculta, defensa de un aliado agredido, árbol/turno real
aliado contra NPC, K/C repetida, migración anterior, rechazo atómico y botín vacío.
Sustituye la captura 3D; controla timers para comprobar reservas exactas, excepto
en el caso del turno real. La presentación se verifica con los pasos anteriores.

El 14-10-2026 pasó en Godot 4.7 sin ventana (160 comprobaciones), junto con
actitud, persistencia NPC, esquiva, rondas, exploración autónoma y continuidad
de patrullas (8 circuitos por NPC en 40 segundos). La advertencia previa de UID
de palanca carga por ruta; algunas escenas headless informan recursos del
renderizador pendientes al cerrar, con comprobaciones y salida cero.
El 15-10-2026 el usuario informó que probó la escena y que las pruebas parecen
funcionar; no detalló qué pasos completó. La presentación de visión con V se
implementó el 15-10-2026 en un corte posterior. Niveles, habilidades y encuentros
autónomos sin jugador siguen fuera de este corte.
