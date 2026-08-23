### Presentación provisional

`CatalogoMensajesInteraccion` es un `Resource` intercambiable que traduce IDs de
mensajes y motivos a texto visible. Si falta una entrada conserva el ID como respaldo
diagnosticable. Este catálogo provisional podrá sustituirse por el sistema de
localización definitivo sin cambiar fragmentos, resultados ni interactuables.

`PanelResultadoAccion` recibe un título, `ResultadoAccion` y catálogo. Solo compone
y muestra textos; no evalúa condiciones, registra conocimiento ni conoce clases de
contenido. La escena expone señales de presentación y cierre, y permite personalizar
texto del botón, separador, viñeta, tema y estructura visual. Puede cerrarse mediante
su botón o `ui_cancel`.

Toda opción resuelta desde el menú contextual entrega su `ResultadoAccion` al mismo
panel reemplazable. La transición menú → resultado conserva un único estado modal:
el mundo no recupera input entre ambas vistas y el objetivo permanece seleccionado
y resaltado hasta que el resultado se cierra. El panel no conoce la opción elegida,
el constructor de contexto ni la implementación del objetivo.

La vista del menú recibe una posición de pantalla solicitada, pero es responsable de
limitar su posición final al rectángulo visible del viewport. El ajuste considera su
tamaño mínimo una vez construidas las opciones, respeta un margen configurable en los
cuatro bordes y se recalcula cuando cambia el tamaño de la ventana.

La antorcha de pie, la fogata y ambas orientaciones de antorcha de pared publican
`EXAMINAR`. Todas ofrecen un fragmento `BASICO` con variantes narrativas encendida y
apagada; la antorcha de pie conserva además sus fragmentos detallado y secreto.

No existe un atajo directo para `EXAMINAR`. Toda interacción voluntaria comienza con
el clic izquierdo, conserva la selección explícita cuando hay varios objetivos y
obliga a elegir una opción del menú antes de construir y resolver el contexto.

Para la primera fuente de luz, el diseño aprobado prevé información básica hasta
cinco celdas e información detallada solo en adyacencia. Ese alcance de observación
es independiente del radio mecánico de iluminación de la fuente. Una celda
`EXPLORADO` no permitirá descubrimientos nuevos. Los enemigos podrán declarar otro
perfil de alcance en el futuro sin cambiar estos contratos.

