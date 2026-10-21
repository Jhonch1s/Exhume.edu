# Cinemática de introducción (Videos / Imágenes)

Abrir `cinematica_imagenes.tscn` y pulsar **F6** para reproducir la escena en Godot.

Seleccionar el nodo raíz `CinematicaImagenes` para editar en el Inspector:

- **Filtro Crt Activo**: activa o desactiva el post-procesado con curvatura, fósforo y aberración cromática CRT (`filtro_crt_luminancia.gdshader`).
- **Videos**: los streams de video (`.ogv`) en orden narrativo de reproducción (9 clips ubicados en `res://assets/videos/intro/`).
- **Imagenes**: texturas de respaldo en caso de no configurar videos.
- **Tiempo fundido**: segundos de entrada y salida a negro para cada clip (0,6 por defecto).
- **Tiempo por imagen**: segundos con cada imagen completamente visible si se usa el modo estático (4 por defecto).
- **Duracion maxima video**: si es mayor que 0, limita el tiempo de cada video (útil para pruebas y avances rápidos).

Los nueve videos de `res://assets/videos/intro/` se muestran en orden numérico dentro de un `AspectRatioContainer` que mantiene la relación de aspecto 2:1 centrada sobre fondo negro y procesada bajo el filtro CRT del proyecto. La secuencia comienza automáticamente al iniciar la escena, reproduce cada video con fundido a negro y emite la señal `terminada` al finalizar para dar paso a la siguiente escena.
