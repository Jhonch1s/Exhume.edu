# Verificación de triggers del mapa — 2026-11-03

Autoría y uso: [Triggers del mapa](../contenido/TRIGGERS_MAPA.md).

## Resultado

- `tests/zonas/prueba_triggers_mapa.gd`: 56 comprobaciones correctas en Godot 4.7.
- `tests/zonas/prueba_viaje_entre_zonas.gd`: 26 comprobaciones correctas. Incluye
  spawn alternativo, ida/vuelta, estado del personaje, persistencia de mapas
  visitados y destinos inválidos sin consumir el trigger ni perder el origen.
- Regresiones correctas: `prueba_ciclo_seguro_paso.gd`,
  `prueba_costes_movimiento.gd`, `prueba_persistencia_partida_archivo.gd`,
  `prueba_dialogo_interactuable.gd` y `prueba_ui_combate.gd`.
- Ejecución con OpenGL real de `tests/zonas/zona_triggers.tscn`: la zona se monta
  en `EscenarioBase`, el diálogo aparece al completar el paso a `(2, 0)`, la ruta
  termina allí y el cruce posterior abre la puerta. Se inspeccionaron capturas
  del mapa y del globo de diálogo. Los contornos se habilitaron sólo para la captura.
- Se comprobó con OpenGL real el umbral de viaje de la escena de prueba: carga
  del Templo de las Trampas, llegada al spawn `entrada`, conservación de la vida
  y representación del personaje en el mapa de destino. Sin errores de scripts.
- La plantilla incorpora `Triggers/Dialogos`, `Triggers/Mecanismos` y
  `Triggers/Viajes`. Se comprobó su presencia y, con OpenGL real, el menú de
  Escape y su pantalla de opciones por debajo del CRT; caída, regreso y
  reanudación de la partida funcionan.
- Los dos triggers colocados en Prisión validan y se probaron cruzando sus
  umbrales con OpenGL: el protagonista comenta el derrumbe con su nombre y el
  pasillo final viaja al spawn `entrada` del templo. El destino serializado como
  UID se resuelve correctamente.

La suite nueva cubre el estado por partida, frecuencia, lectura de guardados
anteriores, serialización a archivo, configuración duplicada, fallos de acción,
coincidencias y bloqueo de UI/turnos durante el evento. También usa desplazamiento
real por habilidad y un combate con un NPC registrado.

## Fallos encontrados fuera del corte

Se probaron también habilidades de nivel 2 y campamento. Ambas suites reproducen
los mismos fallos con las versiones de `EscenarioBase` y `EstadoPartida` anteriores
a estos cambios, cargadas desde copias temporales de `HEAD`:

| Suite | Con triggers | Con ambos scripts anteriores |
|---|---|---|
| `prueba_habilidades_nivel_dos.gd` | 221 comprobaciones, 23 fallos | 221 comprobaciones, 23 fallos |
| `prueba_campamento.gd` | 93 comprobaciones, 10 fallos | 93 comprobaciones, 10 fallos |

Incluyen restauración/guardado de habilidades, una decisión de empuje,
referencias a un escenario liberado, aislamiento de los viewports 3D y una llamada
asíncrona de descanso sin `await`. No se modificaron esas suites ni esos sistemas.

La escena `prueba_estado_npc_persistente.tscn` presentó dos fallos en expectativas
de ataque/esquiva; no se atribuyeron a este cambio ni se estableció su línea base.
La regresión de persistencia a archivo sí pasó.

`prueba_plantilla_zona.gd` se detiene en la línea 34, que espera exactamente cuatro
atlas en la decoración sólida. El ajuste de carpetas no cambia los TileSet;
los tres subgrupos y el menú CRT sí se verificaron durante la prueba visual.

El editor bajo el sandbox informa errores previos de configuración de Dialogue
Manager. Las pruebas de juego se ejecutaron con el lanzador existente
`tests/ejecutar_con_autoloads.gd` y directorios de usuario aislados en `tmp/`.
Algunas suites headless notifican recursos/RID pendientes al cerrar, también en
las pruebas de movimiento ajenas al corte. No hubo errores de script durante la
comprobación visual con OpenGL.
