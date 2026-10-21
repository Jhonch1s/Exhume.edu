# Visión, iluminación y niebla de guerra

Diseño acordado el 09-10-2026. La primera separación de cálculo de luz y
conocimiento del jugador está implementada el 20-10-2026. Ese día se acordó e
implementó también el alcance descrito abajo. Las reglas definitivas de penumbra
y capacidades especiales siguen pendientes. La superposición de visión NPC
descrita abajo también está implementada.

## Primera etapa — 20-10-2026

`FOVManager.iluminacion_actual` calcula luz y penumbra del mundo sin modificar
`Celda.visibilidad`. Después, sólo las casillas con línea visual desde la ficha
pueden pasar a visibles o exploradas. Se usa el validador espacial existente:
paredes, puertas cerradas, humo y esquinas cerradas bloquean; el obstáculo de
destino puede verse. Incluso una fuente configurada para atravesar muros no
otorga esa capacidad al jugador.

La penumbra conserva provisionalmente su presentación anterior: con alcance y
línea visual produce `EXPLORADO`; luz plena produce `VISIBLE`. Terreno previamente
conocido continúa recordado al perder línea visual o quedar fuera del alcance;
una luz detrás de un bloqueo no descubre terreno nuevo.

## Alcance del jugador y cámara libre — 20-10-2026

Acuerdo posterior del usuario: en oscuridad la ficha ve hasta donde llega su
antorcha actual, incluida la atenuación. Una zona iluminada por otras fuentes se
puede percibir hasta siete casillas desde la ficha, siempre con línea visual.
Se mantiene la geometría circular. La luz ajena no permite ver las casillas
oscuras intermedias fuera del alcance de la antorcha. La excepción de fuentes
percibidas directamente se describe a continuación.

El FOV sigue calculando todas las luces del mundo y limita la incorporación de
conocimiento por distancia a la ficha. La antorcha actual tiene radio base cinco;
si una definición de antorcha ofrece un alcance mayor que siete, conserva su
propio alcance. El valor siete pertenece a la percepción del jugador y no cambia
la detección de NPC ni la incorporación a combate.

Al iniciar una zona, lo iluminado fuera de percepción normal o ampliada permanece
`OCULTO`. Al acercar la ficha puede descubrirse; al alejarla queda `EXPLORADO`.
Desplazar la cámara por los bordes no calcula visión desde la cámara ni añade
conocimiento.

### Ampliación por fuente percibida directamente

Acuerdo confirmado por el usuario el 20-10-2026: una fuente encendida situada
dentro del alcance normal y con línea visual desde la ficha permite percibir
su área iluminada más allá de siete casillas. Cada casilla de esa área necesita
también línea visual desde la ficha; una fuente que atraviese muros no permite
mirar detrás de paredes, puertas ni humo.

No se encadenan fuentes. Si A se percibe directamente y su luz permite ver B
fuera del alcance normal, B no amplía la visión. B sólo puede hacerlo cuando la
ficha se acerque y B quede dentro del alcance normal con línea visual. Recordar
una fuente tampoco activa su ampliación.

`iluminacion_actual` conserva toda la luz del mundo.
`iluminacion_fuentes_percibidas` acumula únicamente las aportaciones de las fuentes
directas, incluidas superficies de fuego. Fuera del alcance normal se usa este
segundo cálculo: una fuente no elegible no convierte en luz plena la penumbra
ampliada de otra ni revela su propia área por solapamiento. Dentro del alcance
normal se conserva la iluminación total. La penumbra mantiene su presentación
provisional como `EXPLORADO`.

Apagar o retirar una fuente, perder su línea visual o alejarse de ella retira
la ampliación. El terreno descubierto queda recordado y los NPC que dejen de
percibirse se ocultan. Estas aportaciones se reconstruyen al cargar, sin añadir
datos al archivo de partida ni cambiar percepción NPC, turnos o cámara.

Selección (incluido clic sobre sprite e items), examen, trampas, HUD de combate,
lanzamiento y campos V siguen consumiendo `Celda.visibilidad`. Los NPC, vivos o
muertos, se ocultan cuando su celda deja de ser `VISIBLE`; su percepción propia
no cambia. Los interactuables estáticos conservan sus máscaras/atenuación de
terreno recordado; todavía no hay una copia histórica de su estado visual.

Durante la carga se suspenden los recálculos provocados por restaurar luces,
puertas y superficies. Al terminar se recalcula desde la posición restaurada,
antes de devolver el control y presentar el encuentro. Se conserva el formato
v1/v2 y sus recursos/turnos. La niebla no se serializaba y esta etapa no añade
esa persistencia ni borra conocimiento previo de la sesión al cargar.

El recorrido automatizado está en
`tests/fov/prueba_luz_percepcion.gd`: cuarto iluminado tras puerta, halo nunca
visto, luz que atraviesa paredes, objetivos, items, examen, trampas, movimiento
real, humo, recuerdo sin NPC, percepción NPC independiente y carga repetida/v1.
`tests/fov/prueba_inicio_percepcion.gd` verifica el arranque real de Zona1 y del
Templo de las Trampas, luces lejanas ocultas, pan a los extremos sin descubrimiento
y guardado/carga desde cámara libre.
`tests/fov/prueba_ampliacion_fuentes.gd` verifica tres fuentes sin cadena,
solapamiento de luz y penumbra, independencia del orden de recorrido, apagado,
distancia, humo, fuente bloqueada y superficies de fuego. El recorrido integrado
comprueba además carga con ampliación activa y con la fuente apagada.

## Superposición de campos NPC — 15-10-2026

V alterna campos de los NPC actualmente visibles. Usa el radio y la línea visual
de cada NPC; sólo dibuja casillas `VISIBLE` del tablero. Un oculto, un cadáver o
una casilla sólo recordada no aparecen. Colores: rojo para hostil u oponente,
verde para amistoso o aliado, gris para neutral. Si un neutral defiende al bando
oponente, se pinta rojo mientras dure el encuentro. No se cambia la detección,
la iluminación ni el guardado. [Prueba manual](../pruebas/VISION_NPC.md).

El estado `VISIBLE` procede ahora de luz filtrada por línea visual del jugador.
Esta capa respeta ese estado sin definir por sí misma capacidades especiales ni
reglas adicionales de penumbra.

## Tres conceptos distintos

| Concepto | Qué representa | Qué no concede por sí solo |
|---|---|---|
| Iluminación | Luz que llega a cada casilla desde antorchas, fuego o ambiente. | Conocimiento de esa casilla por un personaje. |
| Visión o percepción | Lo que un actor puede percibir desde su ubicación, según alcance y obstáculos. | Conocimiento de zonas fuera de su percepción. |
| Niebla de guerra | Presentación del conocimiento actual y recordado del jugador. | Información actual sobre entidades en terreno recordado. |

Una habitación puede estar iluminada detrás de una pared y seguir oculta para el
jugador. Al entrar la descubre; al salir recuerda su distribución, pero no sabe
si el goblin sigue allí. Encender una luz no descubre automáticamente una zona
desde cualquier posición del mapa.

## Estados de conocimiento del jugador

| Estado | Presentación prevista |
|---|---|
| Nunca visto | Terreno oculto. |
| Visto anteriormente | Terreno recordado y atenuado; sin revelar ocupantes actuales. |
| Visible ahora | Terreno y entidades que el personaje puede percibir en ese momento. |

La iluminación de una zona no debe marcarla como explorada si el jugador nunca
la percibió. Recordar terreno tampoco permite seguir a un enemigo oculto, examinar
sus cambios de estado ni conocer su posición actual.

## Percepción por actor

Jugador y NPC necesitan percepción propia. La niebla presentada al jugador no
decide qué sabe un NPC: éste consulta su alcance y obstáculos desde su posición.
Tampoco puede consultar la posición real del jugador después de perderlo; usa
su última posición conocida o información obtenida por los participantes del
encuentro. La difusión local se describe en [NPC y diálogos](NPC_Y_DIALOGOS.md).

La línea visual debe considerar los bloqueos del tablero: paredes, superficies
opacas como humo y esquinas cerradas. El diseño permite incorporar después
emboscadas y capacidades especiales de visión, sin definirlas en esta etapa.

La detección actual es circular, sin cono de orientación. Separar luz y visión
no acuerda introducir un cono ni nuevas tiradas de percepción.

## Alcances que no deben confundirse

- Goblins de la escena hostil: movimiento fijo cuatro y detección doce por defecto,
  configurable con `radio_vision_enemigos`. Es un ajuste provisional del balance
  solicitado después de la primera revisión del grupo; antes usaban seis.
- Antorcha del jugador: radio base de luz cinco, con atenuación al agotarse.
  En oscuridad determina el alcance actual de visión de la ficha. Otras fuentes
  permiten percibir terreno iluminado hasta siete casillas, con línea visual.
- Incorporación a un combate: alcance acordado de siete casillas, sujeto a
  percepción del encuentro. No concede automáticamente siete casillas de visión
  a cada NPC ni sustituye su configuración individual.

## Decisiones aún pendientes

- La presentación definitiva de penumbra y las capacidades especiales que
  permiten ver sin luz. Para el jugador normal se aplica el alcance de antorcha
  en oscuridad y siete casillas hacia zonas iluminadas, como se acordó arriba.
- Ampliar la incorporación actual de hostiles a otros bandos y a percepción
  dependiente de luz. Hoy exige ver a un participante vivo por línea visual y
  distancia máxima `min(7, radio_agro propio)`; no consulta iluminación ni niebla.
- Cómo actualizar la memoria visual de terreno que haya cambiado fuera de vista.

El alcance normal descrito arriba queda acordado. Las capacidades especiales,
la penumbra definitiva y la memoria visual de cambios requieren acuerdos posteriores.

## Diagnóstico anterior a la primera etapa

- `scripts/fov_manager.gd`: `actualizar_vision()` proyecta las luces del mapa y
  la antorcha mediante el mismo mecanismo. `proyectar_luz_fuente()` termina
  modificando `Celda.visibilidad`; por eso una zona iluminada puede aparecer
  visible sin línea visual desde el jugador. La penumbra también marca terreno
  como explorado. La presentación de interactuables usa ese estado de celda.
- `scripts/personajes/personaje_npc.gd`: `puede_detectar_jugador()` usa distancia
  y `ValidadorEspacialTablero.validar_linea_visual()`, sin consultar iluminación
  ni la niebla del jugador.
- Selección de objetivos, examen y percepción de trampas consultan
  `Celda.visibilidad`. En la primera etapa se revisaron esos consumidores y se
  corrigió el origen común de su estado, además de la presentación NPC y carga.

## Responsabilidades previstas

La luz calcula iluminación del mundo; cada actor obtiene su percepción; la
niebla presenta y conserva el conocimiento del jugador. Se aprovecharán los
servicios espaciales existentes y las capacidades compartidas entre actores.
La primera etapa mantiene los consumidores existentes y separa su cálculo de
origen, sin una reestructuración general del proyecto.
