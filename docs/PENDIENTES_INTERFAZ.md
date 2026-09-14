# Continuidad: pulido de interfaces e interacciones

Punto de partida del 8 de septiembre de 2026. El usuario quiere retomar el pulido
en otro chat; esta actualización solo documenta y no inicia esa implementación.

## Estado del pulido visual

Actualizado el 14 de septiembre de 2026 durante el trabajo asistido en Godot.

- `tema_interacciones.tres` se comparte entre menú contextual, resultados y examen
  ilustrado. Usa `StyleBoxTexture` con el marco de nueve regiones generado para el
  proyecto, Amarante y estados de botón normal, hover, foco, pulsado y deshabilitado.
- `PanelResultadoAccion` y `MenuContextualInteracciones` comienzan ocultos en sus
  escenas. El examen ilustrado y el panel de cofre también se ocultan al iniciar;
  el registro narrativo permanece visible como panel persistente.
- `PanelRegistroNarrativo` conserva un estilo local oscuro para no destacar sobre
  el escenario. Su vista compacta usa una línea por entrada y fuente menor; la vista
  expandida aumenta su altura y muestra los detalles.
- El registro se puede mover arrastrando su cabecera. Las tarjetas usan
  `RichTextLabel` y los fragmentos de daño pueden mostrar la pista de su tirada al
  pasar el cursor mediante BBCode `hint`.
- El cofre queda fuera de este pulido: conserva su ilustración, cuadrícula centrada
  y cuadrada, y los botones `Recoger todo` y `Cerrar`.

Queda por comprobar en ejecución el examen normal e ilustrado, sus cierres y el orden
visual con el registro. La presentación de fallos de transferencia, el menú de items
y la persistencia siguen siendo pendientes funcionales separados.

## Forma de trabajo acordada

Desarrollo asistido: el usuario crea escenas, configura recursos y edita código
en Godot con instrucciones paso a paso. Leer archivos para comprobar el estado
está permitido. Editar directamente solo cuando lo pida explícitamente. No
sustituir ese flujo por una implementación autónoma completa.

## Leer primero

- [Cofres](contenido/COFRES.md): contenido, UI, arte, niebla y límites reales.
- [Personajes](contenido/PERSONAJES.md): modelos de las tres clases y captura actual.
- [Presentación de examen](contratos/16C_PRESENTACION_DE_EXAMEN.md).
- [Registro narrativo](contratos/19_REGISTRO_NARRATIVO_SESION.md).
- [Pruebas y cobertura pendiente](pruebas/PRUEBAS.md).

## Próximo trabajo de presentación

Acordar primero qué interacción o evento se quiere pulir y reproducir su flujo.
Los puntos candidatos son:

- Panel de cofre: posición en pantalla, foco, legibilidad sobre las tablas,
  hover/foco/pulsación de botones, tamaños de ventana y cierre modal.
- Items: menú de click derecho con Recoger, Recoger todo y Examinar; hover con
  la misma información que el examen. Ambos siguen pendientes. Las casillas
  vacías no deben ofrecer texto, hover ni acciones.
- Aclarar en ese menú el alcance de Recoger todo (intención de esta sesión:
  todo el cofre). El botón inferior ya transfiere todas las pilas hasta un fallo.
- Mostrar fallos de transferencia al jugador; hoy son `push_warning` en Salida.
- Revisar qué eventos necesitan panel modal, examen ilustrado o registro narrativo:
  interacción, tiradas, daño, estados, trampas y recogida. No abrir ventanas por
  cada efecto sin revisar el resultado completo y lo que ya comunica el registro.
- Completar iconos de `DefinicionItem`; los objetos sin icono siguen siendo reales.

La estética del cofre pequeño es madera vieja y maltrecha, sin cabecera ni título,
con exactamente dos botones inferiores: Recoger todo y Cerrar. Su cuadrícula debe
permanecer centrada y cuadrada al redimensionar Fondo. Cerrar el panel no cierra
la tapa del cofre en el mundo.

## Pendientes funcionales separados del pulido

- Guardar/restaurar contenido y apertura del cofre, incluida unicidad de IDs entre
  cofres, inventario del jugador y suelo. Las funciones de guardado de partida
  existen, pero no están conectadas a un flujo normal de guardar/cargar.
- El cofre ya bloquea el paso abierto y cerrado; conservar esa regla al pulir su UI.
- Decidir si recoger del cofre debe pasar por acciones, costes y registro narrativo.
- Conectar selección de clase a las capturas del modelo correspondiente; el spawn
  todavía genera siempre el caballero.
- Adaptar pruebas del panel para construir un cofre real y llamar `mostrar()`.

No considerar estos pendientes resueltos por la documentación ni iniciar un nuevo
chat automáticamente. Retomar con el caso concreto que el usuario elija.
