# Prisión: contenido y guardias

## Contenido colocado

Las definiciones específicas están en `recursos/prision/`; las definiciones genéricas conservan su configuración.

- **Notas garabateadas**: descripción básica a distancia; al acercarse se leen el texto porcino original y la observación sobre sus trazos.
- **Cofre gastado**: aspecto de madera y herrajes; de cerca se distingue el uso repetido del cierre. Conserva su inventario vacío.
- **Peeble y Rengo**: guardias hostiles que patrullan el acceso.
- **Roffa**: banga encarcelado, inicialmente neutral; habla la lengua del protagonista. Su examen y conversación no revelan la broma ni identifican la herramienta del templo.
- **Velas**: las diez se pueden examinar y describen su estado encendido/apagado. `vela_01` añade información sobre capas de cera.
- **Antorchas**: `antorcha_pie_006` añade mantenimiento reciente; `antorcha_015`, hollín acumulado. Sus propiedades de luz y encendido se conservan.

### Hallazgos añadidos al recorrido

Todos usan escenas reutilizables de `Interactuables/Guias`, ilustraciones existentes y dos fragmentos: básico y detalle a una casilla. Las casillas están expresadas como coordenadas del tablero.

| Hallazgo | Casilla | Ubicación y función |
|---|---|---|
| Advertencia arrugada | `(7, 12)` | Antes del sector de los guardias. Un aventurero cuenta un encuentro amenazante sin idioma común. |
| Registro de celdas | `(25, -1)` | Entrada del bloque central, en un espacio abierto. Dibujos y anotaciones incomprensibles muestran el uso cotidiano de las celdas. |
| Diario inconcluso | `(25, -31)` | Sector lateral de celdas. Contrasta la piedra antigua con los rastros de ocupación reciente y deja una historia sin desenlace. |
| Señal de advertencia | `(72, -12)` | En la pared del corredor más alejado. Pictogramas de celdas y peligro, sin traducción literal ni destino asegurado. |
| Estandarte remendado | `(12, 18)` | Lateral del acceso vigilado. Los remiendos sugieren apego a un emblema gastado. |

No revelan la broma del prisionero, el instrumento ni la ubicación del paso al templo. El estandarte ocupa una casilla lateral; se comprueba que no corte los recorridos de los guardias.

## Triggers

- `dialogoentrada`: el protagonista recuerda la caída por el agujero, reconoce
  que sigue vivo de milagro y reafirma que debe llegar a la tribu de los bangas.
  Usa `dialogues/prision/entrada.dialogue`.
- `salaprincipal`: comenta que observa la sala principal desde arriba y que
  conviene mirar antes de continuar. Usa `dialogues/prision/salaprincipal.dialogue`.
- `peligro1`: presentimiento de que algo espera más adelante y consejo de
  prepararse para defenderse o escapar. Usa `dialogues/prision/peligro1.dialogue`.

Estos tres diálogos usan el nombre del protagonista y la frecuencia única por
partida configurada en sus triggers. Conservan la colocación y geometría del mapa.

- `zona3bloqueo`: umbral X desde `(-9, 11)`, longitud 20. Usa
  `dialogues/prision/derrumbe.dialogue`; el protagonista habla con su nombre:
  «Parece que el derrumbe bloquea el paso. No puedo continuar por aquí.»
- `viaje_templo_de_las_trampas`: umbral X entre `(80, -28)` y `(81, -28)`.
  Lleva al Templo de las Trampas, spawn `entrada`. Se ajustó a longitud 1 porque
  los extremos de la línea anterior quedaban fuera del suelo.

Ambos conservan la frecuencia `CADA_ENTRADA` configurada en la escena. La acción
de viaje admite el UID que Godot guarda al seleccionar el archivo desde el
Inspector. Se comprobaron ambos cruces en ejecución con OpenGL, incluida la
presentación del diálogo y la llegada al templo.

## Cofres de provisiones

Los cofres `CofreInteractuable2` (`cofre_pequeno_001`) y `CofreInteractuable3`
(`cofre_pequeno_002`) contienen cada uno una poción curativa, una bomba de humo y
dos antorchas. Se configura `contenido_inicial` por instancia. Los guardados que
ya contienen el inventario de esos cofres conservan su contenido guardado.

## Guardias

Ambos usan nivel 3, 22 PV, FUE 4, DES 4, VOL 4 y 7 puntos de movimiento; tienen la misma facción y son hostiles al PJ. El radio de detección es de 4 casillas y requiere línea visual. Son valores iniciales de esta configuración, pendientes de balance jugable.

Peeble y Rengo inician combate al detectar al jugador, sin diálogo ni agresión previa. Rengo conserva el ID `banga_peeble_001`. Roffa dejó de ser guardia al asignarle el papel del prisionero.

El árbol existente `recursos/ia/combate_npc.tres` se asigna en ejecución al nodo `DecisorCombate` de cada NPC. Decide patrulla, búsqueda, acercamiento y ataque. No hace falta duplicar el árbol para cada guardia.

Roffa no tiene patrulla. Los recorridos de Peeble y Rengo se conservan.

## Roffa: prisionero e intérprete

Está en `(46, -16)`, ID `banga_roffa`. Conserva su recurso
`recursos/prision/guardia_roffa.tres` y su identidad de definición por compatibilidad.
Comienza neutral y tiene facción propia para no sumarse a los guardias por agresión
compartida; conserva las estadísticas y las reglas normales de reacción a ataques.

El menú **Hablar** usa `dialogues/prision/roffa.dialogue`. En el primer encuentro
Roffa llama al protagonista y ofrece responder o retirarse. Al responder se
presenta en un intercambio breve; sólo al completarlo se guarda
`EstadoPartida.roffa_conocido`. Si se abandona antes, la introducción sigue
pendiente. Las conversaciones posteriores usan un saludo corto.

Después de presentarse, el menú inicial ofrece preguntar por el encierro,
ofrecer ayuda para salir o despedirse. Los rumores del lugar con trampas se
descubren al preguntar cómo abrir la celda y elegir una alternativa a la llave.
La mediación con los guardias aparece sólo cuando se consume el trigger existente
`Triggers/Dialogos/Guardias`, ID `guardias`, en esta prisión. Se consulta su
memoria persistente; no se duplica el trigger ni se presupone haber combatido.
La pregunta por el derrumbe exige haber iniciado su diálogo, que registra
`EstadoPartida.prision_derrumbe_visto`; el trigger conserva `CADA_ENTRADA`.
Las respuestas no habilitadas se ocultan en el globo, sin mostrar sus textos
desactivados. Presentación, hitos y triggers descubiertos se guardan en la partida,
se conservan al viajar y se reinician para un nuevo aventurero; los guardados
anteriores comienzan con presentación y derrumbe pendientes.

Roffa evita explicar por qué lo encerraron; la broma queda reservada para el
encuentro posterior con los guardias. Sólo conoce rumores y sugiere buscar alguna
herramienta, sin conocer la ganzúa concreta.

La definición permite hablar hasta cuatro casillas (distancia Manhattan). Se
necesitan cuatro para conversar desde el pasillo `(46, -12)`, accesible desde la
entrada con la celda cerrada. El resto de NPC conserva alcance de una casilla.
Hablar exige línea visual: permite conversar entre barrotes pero no atravesar
muros opacos. El alcance de ataques y botín sigue siendo de una casilla.

La puerta colocada en `(45, -13)` tenía una definición vacía, que impedía registrar
todo el contenido de la prisión. Se le asignó la definición existente de reja
metálica derecha; se conserva su posición, ID y estado cerrado con cerradura.
La liberación, seguimiento del preso y mediación posterior quedan pendientes de
su implementación como secuencia de nivel; esta conversación no los ejecuta.

## Ilustraciones

La ilustración aportada por el usuario se incorporó sin alterar a
`assets/characters/npcs/banga/portraits/roffa_dialogo.png` y se asignó a
`ilustracion_dialogo`. `roffa_portrait.png` sigue siendo el retrato pequeño de turno.

**No falta ninguna imagen para jugar con este contenido.**

Mejoras opcionales que se pueden producir:

| Imagen | Uso y orientación |
|---|---|
| `prision_cofre_gastado.png` | Examen ilustrado del cofre. Composición cuadrada o vertical, objeto completo, tablas oscuras y herrajes oxidados sobre piedra de prisión; sin texto. Se asignaría a `cofre_gastado.tres > ilustracion_examen`. |
| `peeble_portrait.png` y `roffa_portrait.png` | Ya incorporados desde `assets/characters/npcs/banga/portraits/` mediante `retrato_turno`. Ambos usan el formato vertical de los retratos del jugador: 58 × 105 px. |

Mantener fantasía oscura, pixel art, paleta terrosa y luz tenue. El pergamino ya tiene ilustración. La ficha de examen de los NPC es actualmente textual; asignar `ilustracion_examen` no añade una imagen a esa ficha.

## Verificación

`tests/interacciones/prueba_contenido_prision.gd` carga la prisión con los sistemas reales, comprueba registro y textos, diferencia examen cercano y lejano, espera dos vueltas de ambas patrullas y verifica detección, inicio de combate y decisión de ataque.

La regresión también valida la colocación del contenido, la ausencia de diálogo con los guardias y el inicio automático desde el procesamiento normal de la escena. `tests/interacciones/prueba_roffa_prisionero.gd` comprueba por separado neutralidad, conversación desde el pasillo con la celda cerrada, límites de alcance y visión, todas las ramas narrativas y apertura/cierre del globo mediante el flujo contextual.

Verificación inicial del 03-11-2026: Roffa, 29 comprobaciones sin fallos; contenido de
prisión, 200 sin fallos. La revisión de introducción amplía la prueba de Roffa con
presentación aplazable, saludo posterior, desbloqueo por cruce real del trigger de
guardias, pregunta del derrumbe, memoria compatible con guardados anteriores e
ilustración visible. Se comprobó también con OpenGL desde el pasillo. La prueba adicional
`prueba_dialogo_tirada_npc.tscn` conserva cuatro fallos en la comparación de VOL
y dados deterministas (1, 2, 5 y 6), reproducidos cargando en memoria el
`PersonajeNPC` de HEAD, sin los cambios de alcance ni línea visual de este trabajo.
No se modificó ese sistema de tiradas.

Revisión de introducción: 43 comprobaciones de Roffa, 56 de triggers, 26 de viajes
y 9 de persistencia en archivo, todas correctas. Capturas de ejecución real:
`tmp/roffa_intro.png` y `tmp/roffa_preguntas_iniciales.png`; muestran la ilustración
y las preguntas iniciales sin las ramas todavía desconocidas.

Para evaluar la nueva configuración de NPC, usar una partida nueva. Los guardados previos conservan estados y rutas anteriores y pueden ser incompatibles con estas definiciones.
