# Recursos de interfaz

Esta carpeta contiene los insumos visuales y sonoros compartidos por los menús y el HUD.
Las escenas y sus scripts permanecen en `res://scenes/menu/`; aquí solo se guardan recursos.

## Estructura

- `themes/`: temas globales de Godot (`.tres`) y variaciones de estilo.
- `fonts/`: tipografías y, cuando sea necesario, recursos `FontFile` o `FontVariation`.
- `backgrounds/`: fondos completos para pantallas y menús.
- `panels/`: marcos, placas, separadores y texturas de paneles.
- `buttons/`: texturas exclusivas de botones y sus estados visuales.
- `icons/`: iconos reutilizables de navegación, ajustes, atributos y objetos.
- `portraits/`: retratos empleados por selección y creación de personajes.
- `cursors/`: cursores y punteros propios del juego.
- `effects/`: máscaras, gradientes, ruido y texturas para transiciones o shaders de UI.
- `audio/`: sonidos de interacción de la interfaz. La música continúa en `assets/music/`.

## Convenciones sugeridas

- Usar nombres en minúsculas con `snake_case`.
- Indicar el estado al final: `boton_normal`, `boton_hover`, `boton_pressed`.
- Evitar duplicar imágenes por pantalla; los recursos comunes deben vivir aquí.
- Crear subcarpetas específicas solo cuando una pantalla acumule varios recursos exclusivos.
- Conservar los archivos fuente editables en `assets/art_source/ui/` y exportar aquí únicamente
  los archivos que Godot utilizará en el juego.

El primer tema global debería crearse como `themes/exhume_theme.tres`. Las excepciones de una
pantalla pueden implementarse como variaciones del tema en vez de copiar estilos completos.
