# Cámara libre

Implementada el 20-10-2026 con los controles acordados por el usuario.

- Acercar el cursor a un borde desplaza la vista. Las esquinas permiten diagonal
  sin aumentar la velocidad. Al retirar el cursor, se conserva el encuadre libre.
- Espacio recentra en la ficha y vuelve al seguimiento. Al empezar el turno propio
  sucede automáticamente; los cambios a turnos NPC conservan el encuadre.
- La rueda del ratón acerca o aleja sobre el escenario, también en cámara libre y
  durante turnos NPC. Va de 1,5 a 4,5 (inicio: 3) en pasos del 20 %. Conserva el
  centro de la vista libre o de la ficha seguida; Espacio no reinicia la escala.
  Los paneles modales y los controles con desplazamiento conservan la rueda.
- El indicador superior derecho muestra el modo y el turno. Un actor oculto sigue
  siendo anónimo. La tira de iniciativa permanece fija.
- Los paneles modales, diálogos (también por área) y lanzamientos en vuelo suspenden
  la cámara. Espacio conserva su función en la interfaz modal. Tras cerrar o
  recentrar hay que retirar el cursor del borde antes de volver a desplazar.
- Las cuatro franjas funcionan también sobre el HUD y otros controles no modales.
  Fuera de ventana, sin foco o con un botón de ratón mantenido no se desplaza por
  bordes. La cámara libre tampoco interrumpe un recorrido.
- Durante el desplazamiento de cámara se suspenden las previsualizaciones y
  confirmaciones de mundo. Retirar el cursor recalcula el objetivo bajo él;
  recentrar no cancela un lanzamiento pendiente.
- El encuadre respeta los límites del contenido de la zona y un margen de 64
  unidades. Se consideran tamaño de vista y zoom; un mapa menor que la vista se
  centra por eje. Cerca del límite la ficha puede quedar desplazada del centro
  para conservar el límite del mapa. Al variar el zoom se recalculan esos límites.
- La cámara no consume recursos ni avanza turnos, modifica visión o guarda su
  posición. Cargar una partida vuelve al seguimiento sin renovar recursos.
  Las patrullas mantienen su reloj y las órdenes conservan los bloqueos del turno.
- La vista libre y el zoom pueden mostrar terreno todavía no explorado, pero
  apuntar o hacer clic derecho en una celda `OCULTO` no traza ni confirma un
  recorrido. Los caminos hacia celdas `EXPLORADO` o `VISIBLE` solo atraviesan
  celdas de esos estados. El acercamiento automático a un interactuable sigue
  la misma regla; la navegación de NPC conserva su grafo habitual.

Las zonas no son nodos ni colisiones independientes: se calculan en
`EscenarioBase/Camera2D`, cuyo script es
`scenes/escenario_base/camara_escenario.gd`. `ANCHO_BORDE` define el grosor
(24 píxeles lógicos); `direccion_borde()` compara la posición del cursor con
los cuatro extremos del viewport. `VELOCIDAD` controla el desplazamiento.

## Validación realizada

`tests/interacciones/prueba_camara_libre.gd`: 64 comprobaciones correctas de
bordes, diagonales, límites, ventanas, seguimiento, recentrado, modales, diálogos,
zoom, foco residual del botón de turno, selección de lanzamiento, turnos NPC/propio,
actor oculto, snapshot/FOV y carga. Incluye recentrado pendiente mientras hay modal.

`tests/movimiento/prueba_camino_conocido.gd` cubre destinos desconocidos, rutas
que rodean terreno nunca visto, revelación posterior, navegación NPC y el clic
derecho sin consulta de ruta sobre una celda oculta. La integración del menú
contextual recorre un corredor explorado para comprobar el autoacercamiento.

Ejecutar con los autoloads:

```powershell
C:/godot/Godot.exe --headless --path C:/godot/exhum_edu --script res://tests/ejecutar_con_autoloads.gd -- res://tests/interacciones/prueba_camara_libre.gd
```

Pasaron también `prueba_ui_combate.gd`, `prueba_gestor_rondas.gd`,
`prueba_persistencia_partida_archivo.gd`, `prueba_selector_objetivos_interaccion.gd`,
`tests/tiradas/prueba_presentacion_tirada.gd`, `prueba_dialogo_tirada_npc.tscn`
y `prueba_exploracion_npc_autonoma.tscn`. Sin errores de script.

Se inspeccionaron capturas con render real a 1280×720 y ventana 900×700,
conservando el escalado/aspecto del proyecto. Espacio se comprobó mediante evento
de entrada y la vista libre mediante el controlador. Las capturas y el script
auxiliar están en `tmp/camara_*` y `tmp/validar_camara_visual.gd`, ignorados por Git.
Falta la valoración jugable del usuario sobre sensibilidad, velocidad y zoom con
ratón real.

La carga de la zona sigue emitiendo el aviso previo de UID de palanca. Las
asignaciones antiguas de color inválido de Zona1 se limpiaron después de la
primera implementación de cámara. La separación completa de luz, percepción y
niebla se trata en [su documento](../contenido/VISION_ILUMINACION_Y_NIEBLA.md).
