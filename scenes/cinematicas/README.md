# Cinemática de imágenes

Abrir `cinematica_imagenes.tscn` y pulsar **F6** para reproducir la escena.

Seleccionar el nodo raíz `CinematicaImagenes` para editar en el Inspector:

- **Imagenes**: las texturas en el orden de reproducción. Se pueden arrastrar imágenes desde el panel de archivos.
- **Tiempo por imagen**: segundos con cada imagen completamente visible (4 por defecto).
- **Tiempo fundido**: segundos de entrada y salida a negro (0,6 por defecto).

Las nueve ilustraciones de `res://assets/ilustraciones/intro/` se muestran en orden
numérico. Las imágenes conservan sus proporciones y se centran sobre fondo negro. La secuencia
comienza automáticamente, se reproduce una vez y termina en negro. La señal
`terminada` permite conectar después el paso a otra escena.

La secuencia dura 46,8 segundos (nueve imágenes de 4 segundos y dos fundidos de
0,6 segundos cada una). Para repetirla,
detener y volver a ejecutar con F6.
