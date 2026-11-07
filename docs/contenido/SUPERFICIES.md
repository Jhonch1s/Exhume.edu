# Duraciones de superficies

Balance vigente desde el 05-11-2026:

| Superficie | Duración predeterminada | Al expirar |
|---|---:|---|
| Fuego, incluidas estatuas y trampas | 4 rondas | Se transforma en humo nuevo. |
| Humo, incluidas bombas y frascos de bruma | 5 rondas | Desaparece. |
| Nube venenosa | 5 rondas | Desaparece. |
| Telaraña, lodo, hielo, pinchos, agua y lava | Sin caducidad temporal | Permanecen como terreno/superficie. |

El procesador descuenta una unidad al finalizar la ronda de combate. Fuera de
combate, descuenta una por cada avance de turno de exploración. No son segundos
ni turnos individuales de cada combatiente. El humo creado al expirar el fuego
empieza con sus cinco rondas completas.

Estos contadores son independientes de los estados del actor: quemado conserva
3 turnos propios y veneno 2, ambos con 1d2 por pulso. Enredado por telaraña de
suelo requiere liberación; caído dura 1 turno propio.

Los valores anteriores eran fuego 7 y humo/veneno 10. Al cargar una superficie
de una partida anterior, su tiempo restante se limita a su duración configurada
actual. Cero, negativos y valores superiores al máximo anterior/configurado
siguen siendo inválidos. No se reinicia el contador de una superficie que ya
tenía menos tiempo restante.

Los recursos pueden configurar duraciones particulares en el Inspector. Se
actualizó también el frasco de bruma y los valores iniciales de la Forja para
que el contenido actual y las nuevas creaciones usen este balance.

Prueba del ciclo y carga anterior: `tests/interacciones/prueba_duracion_superficies.gd`.
