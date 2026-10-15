# Comprobación del primer diálogo con tirada

El usuario confirmó el 15-10-2026 que el diálogo base funcionó muy bien en juego,
sin detallar los pasos revisados. El catálogo de consecuencias descrito al final
todavía requiere su propia revisión jugable.

Abrir `res://tests/interacciones/escena_dialogo_tirada_npc.tscn` y ejecutar con F6.
Se añade un custodio neutral que no combate y usa el arte existente de duende.
Trompo y el contenido permanente conservan sus diálogos. La escena guarda en
`user://prueba_dialogo_tirada_npc.json`, separado del slot habitual.

1. Acercarse al custodio hasta una casilla adyacente y elegir **Hablar** desde el
   menú contextual. Abrir la conversación no debe tirar dados.
2. Elegir **Despedirse sin tirar**. Debe cerrar sin panel ni entrada de tirada.
3. Volver a hablar y elegir **Intentar convencerlo [VOL]**. Debe aparecer el panel
   existente con el objetivo basado en la VOL actual del jugador, sin bonos.
4. Hacer clic en el dado: revela el valor ya resuelto. Con 1d6, igual o menor
   que VOL es éxito; 1 es crítico y 6 es pifia. Clics repetidos no deben cambiarlo
   ni añadir entradas al historial o registro narrativo.
5. Cerrar el panel: el custodio muestra «Has logrado convencerme» o «No me has
   convencido» según el resultado. Continuar hasta terminar la conversación.
6. Pulsar K/C durante la conversación, mientras están los dados y después de
   cerrarlos con la respuesta aún abierta: ambas operaciones deben indicar que
   hay una interacción activa. Al terminar, guardar/cargar vuelve a funcionar.
7. Guardar al terminar y cargar dos veces: no debe reabrir conversación, lanzar
   dados ni repetir registros. Volver a hablar inicia otra conversación y permite
   una nueva prueba. No hay un límite persistente de intentos en este caso.

El diálogo sólo prueba el flujo: no cambia actitud, XP, vida, inventario o recursos
de turno. No se añaden premios ni se guarda una conversación a medio resolver.
La revisión visual/jugable básica fue confirmada por el usuario.

## Catálogo de consecuencias: escena nueva

Abrir `res://tests/interacciones/escena_consecuencias_dialogo_npc.tscn` y ejecutar
con F6. Se conserva la escena anterior como caso sin consecuencias. La nueva
usa `user://prueba_consecuencias_dialogo_npc.json`, con slot propio.

1. Seleccionar el nodo raíz de la escena y desplegar **Tema consecuencias →
   Pruebas**. Ahí están atributo, título, ID, `una_sola_vez` y las listas de
   consecuencias. La [guía de construcción](../contenido/CONSECUENCIAS_DIALOGO_NPC.md)
   explica cómo usar estos recursos en otro NPC.
2. Con los valores predeterminados, acercarse al custodio y guardar con K antes
   de hablar. Elegir ganarse su confianza con VOL y cerrar los dados.
3. En éxito recibe +3 de actitud y revela dónde guarda una llave; el registro
   muestra los dos efectos. En fallo recibe −1 de actitud y no revela el secreto.
   Terminar la conversación antes de intentar guardar o cargar.
4. Volver a hablar y repetir la elección: conserva la rama anterior sin dados,
   cambios de actitud ni entradas duplicadas. En éxito el saludo reconoce que
   ya confió su secreto. El intento único también conserva el fallo.
5. Guardar después del resultado y cargar dos veces: debe conservar puntos,
   información e intento. Cargar el momento anterior al intento restaura todo
   junto y permite otra prueba. F6 permite reiniciar para buscar el otro resultado.
6. Desactivar `una_sola_vez` en el recurso y reiniciar con F6: cada nueva elección
   vuelve a tirar y aplica su lista. La información conocida no se duplica y la
   actitud sigue sus límites. Reactivar la opción restaura el ejemplo de intento único.
7. K/C sigue bloqueado en todas las fases de la conversación, incluidos los dados
   y la respuesta posterior. La escena no consume recursos de turno ni entrega XP.

La confidencia es texto y conocimiento de prueba: no crea una llave como objeto
ni la añade a un inventario. El catálogo inicial sólo tiene actitud e información.
Los datos se pueden editar sin añadir scripts por NPC; las frases deben acompañar
la configuración que el autor elija.

`prueba_consecuencias_dialogo_npc.tscn` pasó 162 comprobaciones automáticas, con
éxito/fallo, crítico/pifia, repetición, memoria por instancia, K/C y migración,
validación de ambas ramas antes de tirar, actitud fija y límites, cadáver,
registro traducido y ausencia de cambios de XP/PV/recursos del jugador.

## Prueba automática

Ejecutar `res://tests/interacciones/prueba_dialogo_tirada_npc.tscn`. Pasa 87
comprobaciones con dados deterministas 2, 5, 1 y 6 contra VOL 3: ramas reales de
Dialogue Manager, registro/historial y presentación únicos, elección repetida,
animación sin consumir azar, despedida, rechazo fuera de diálogo o con atributo
inválido, bloqueo y liberación modal, K/C repetida y estado del mundo sin cambios.

Regresiones aprobadas: `prueba_actitud_npc.tscn`, `prueba_dialogo_interactuable.gd`,
`prueba_motor_dados.gd`, `prueba_prueba_exhume.gd` y `prueba_historial_tiradas.gd`.
Los scripts SceneTree con autoloads se ejecutan mediante
`tests/ejecutar_con_autoloads.gd -- res://ruta.gd`.
