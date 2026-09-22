# HUD del jugador

Estado del prototipo funcional, septiembre de 2026. Escena:
[`scenes/ui/hud/hud.tscn`](../../scenes/ui/hud/hud.tscn); lógica:
[`hud.gd`](../../scenes/ui/hud/hud.gd). `EscenarioBase` lo instancia dentro de
`CanvasLayer` y le entrega la `Ficha` al terminar el spawn. El filtro CRT de la
escena se aplica también a la interfaz.

## Composición y ajustes visuales

`HUDRoot` contiene una imagen de roca (`assets/ui/panels/hud/hud_base_roca_v01.png`)
y `SeccionesHUD` superpuesta. Ambos están centrados abajo y escalados a 0,8;
sus secciones son controles con offsets propios que se pueden reposicionar en el
editor sin cambiar la imagen. Retrato/recursos, habilidades, ítems rápidos,
engarces de acciones, botón de pasar turno y barra de movimiento son piezas
separadas. La barra verde de experiencia está en `HUDRoot`. No hay minimapa.
Las barras de vida, energía, movimiento y experiencia usan un shader sutil de
sombras animadas en la escena HUD.

`LogAcontecimientos` es una instancia del `PanelRegistroNarrativo` existente,
dentro del HUD pero independiente de la barra inferior: permanece visible y
se puede arrastrar por su cabecera o expandir. La fuente de los acontecimientos
sigue siendo `RegistroNarrativoSesion`, no el HUD. Los paneles de examen, menú
contextual y cofre son hermanos del HUD en el `CanvasLayer`. El panel de resultado
y tiradas está en una capa superior al filtro CRT para conservar la legibilidad
de los dados y textos. Véase
[registro narrativo](../contratos/19_REGISTRO_NARRATIVO_SESION.md).

## Datos y comportamiento actuales

- El retrato cambia según `Ficha.clase` (Guerrero, Ladrón, Mago), usando
  `assets/ui/panels/hud/retratos/`. Nombre, vida y energía provienen de la ficha;
  las barras interpolan su valor al actualizarse.
- Los tres engarces de antorcha leen la cantidad del inventario. El último
  engarce encendido representa el desgaste de la antorcha en uso; no es un
  contador separado en la ficha. La ficha conserva los pasos restantes de esa
  antorcha. El HUD aún usa `Ficha.PASOS_MAX_ANTORCHA` (80) como denominador del
  color y del tooltip: si se crean antorchas con otra duración, habrá que leer
  ese máximo desde su definición también aquí.
- Los engarces de acciones se crean según el máximo de acciones principales de
  `RecursosTurnoActor` y se apagan según las restantes. La barra blanca lee el
  movimiento restante. `Pasar turno` solicita al escenario avanzar el turno;
  el escenario lo ignora durante movimiento o una interacción modal.
- Los estados visibles muestran una inicial y un tooltip de aspecto pétreo.
  Quemado y veneno explican los dados de daño por tick y los turnos pendientes;
  también hay textos para enredado y caído. Actualmente sólo hay tres espacios
  visuales: si se acumulan más estados, los restantes no se muestran.
- Las cuatro ranuras de ítems muestran el icono y la cantidad (si supera uno) de
  las primeras cuatro pilas del inventario, ordenadas por ID de instancia; el
  nombre queda en el tooltip. Si falta el icono, muestran `?`. **Todavía no son
  accesos rápidos configurables ni activan el ítem al pulsar**: sus botones
  están deshabilitados. Las cuatro ranuras de habilidades
  están deshabilitadas. La barra de experiencia tiene un valor de muestra y no
  está conectada a un sistema de experiencia. El overlay superior de combate
  existe como maqueta oculta, sin secuencia de turnos funcional.

## Antorcha en mano: una sola fuente de datos

La antorcha inicial es una `ItemInstancia` con cantidad 3 en el inventario, creada
en `EscenarioBase.spawnear_ficha_inicial`. `Ficha.consumir_paso_antorcha()`
descuenta un paso por movimiento; al agotarse una unidad, `Inventario` la consume
y la ficha carga la duración de la siguiente. Guardado y carga conservan tanto
el inventario como los pasos pendientes.

Al recoger del suelo un ítem con `apilable = true`, `EscenarioBase` lo combina
con una pila de la misma definición si cabe completo. Esto incluye antorchas
(máximo 10 por pila) y piedras (máximo 99). Si no cabe, permanece en otra pila;
no modifica la regla general de `Inventario.agregar()` ni las transferencias
entre inventarios, que conservan las pilas separadas.

Para ajustar la iluminación, editar
[`assets/items/antorcha/antorcha.tres`](../../assets/items/antorcha/antorcha.tres),
que usa [`DefinicionAntorcha`](../../scripts/interacciones/items/definicion_antorcha.gd):

| Propiedad | Efecto actual |
|---|---|
| `magnitudes.duracion` (80) | Pasos de cada antorcha. |
| `radio_vision` (5) | Radio de celdas visibles, limitado por obstáculos mediante `FOVManager`. |
| `pasos_atenuacion` (10) | Últimos pasos durante los que disminuyen el radio de visión y la intensidad visual; 0 desactiva esa atenuación. |
| `energia_luz` (1,3) | Brillo base de `PointLight2D`, con un parpadeo pequeño adicional. |
| `escala_luz` (1) y `color_luz` | Tamaño y tono de la luz visual; no alteran el radio de visión lógico. |

`Ficha.obtener_antorcha_activa()` consulta la primera pila de antorchas del
inventario, la misma que se consume. El escenario lee de esa definición el
radio y la atenuación lógica; `Ficha/Antorcha` lee color, escala y energía cada
fotograma. Sin antorchas, la luz visual se apaga y el radio lógico queda en una
celda. No ajustar `energy` en `ficha.tscn` para cambiar el brillo: el script
lo sobrescribe. Las fuentes de luz fijas del mapa son otro sistema.

Prueba de regresión: `tests/interacciones/prueba_antorchas_hud.tscn` comprueba
consumo, indicadores del HUD, iluminación inicial, propiedades de la definición,
atenuación y ausencia de luz al agotar el inventario.
