# Visión, iluminación y niebla de guerra

Diseño acordado el 09-10-2026. La separación general de iluminación, percepción
del jugador y niebla de guerra sigue pendiente. La superposición de visión NPC
descrita abajo sí está implementada.

## Superposición de campos NPC — 15-10-2026

V alterna campos de los NPC actualmente visibles. Usa el radio y la línea visual
de cada NPC; sólo dibuja casillas `VISIBLE` del tablero. Un oculto, un cadáver o
una casilla sólo recordada no aparecen. Colores: rojo para hostil u oponente,
verde para amistoso o aliado, gris para neutral. Si un neutral defiende al bando
oponente, se pinta rojo mientras dure el encuentro. No se cambia la detección,
la iluminación ni el guardado. [Prueba manual](../pruebas/VISION_NPC.md).

El estado `VISIBLE` todavía procede del proyector de luz actual, como explica el
diagnóstico inferior. Por eso esta capa respeta la visibilidad actual del juego,
pero no resuelve por sí misma la separación futura de luz y percepción del jugador.

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
  Ese valor no fija todavía un alcance independiente de visión del personaje.
- Incorporación a un combate: alcance acordado de siete casillas, sujeto a
  percepción del encuentro. No concede automáticamente siete casillas de visión
  a cada NPC ni sustituye su configuración individual.

## Decisiones aún pendientes

- Si un personaje normal requiere luz para distinguir enemigos y objetos.
- Cómo se comportan oscuridad y penumbra, y qué capacidades permiten ver sin luz.
- El alcance independiente de visión del jugador.
- Ampliar la incorporación actual de hostiles a otros bandos y a percepción
  dependiente de luz. Hoy exige ver a un participante vivo por línea visual y
  distancia máxima `min(7, radio_agro propio)`; no consulta iluminación ni niebla.
- Cómo actualizar la memoria visual de terreno que haya cambiado fuera de vista.

No se asignan aquí valores ni reglas nuevas a la oscuridad o a la memoria visual. La discusión de
visión queda registrada para retomarla; la prioridad de trabajo vuelve a los NPC.

## Diagnóstico del código actual

- `scripts/fov_manager.gd`: `actualizar_vision()` proyecta las luces del mapa y
  la antorcha mediante el mismo mecanismo. `proyectar_luz_fuente()` termina
  modificando `Celda.visibilidad`; por eso una zona iluminada puede aparecer
  visible sin línea visual desde el jugador. La penumbra también marca terreno
  como explorado. La presentación de interactuables usa ese estado de celda.
- `scripts/personajes/personaje_npc.gd`: `puede_detectar_jugador()` usa distancia
  y `ValidadorEspacialTablero.validar_linea_visual()`, sin consultar iluminación
  ni la niebla del jugador.
- Selección de objetivos, examen y percepción de trampas consultan
  `Celda.visibilidad`. Separar las capacidades requerirá revisar esos consumidores
  y la presentación, además del proyector de luz.

## Responsabilidades previstas

La luz calcula iluminación del mundo; cada actor obtiene su percepción; la
niebla presenta y conserva el conocimiento del jugador. Se aprovecharán los
servicios espaciales existentes y las capacidades compartidas entre actores.
Los nombres y APIs concretos se definirán al implementar, sin comprometer una
reestructuración anticipada del proyecto.
