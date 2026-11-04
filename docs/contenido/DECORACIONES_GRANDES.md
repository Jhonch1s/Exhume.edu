# Rocas derrumbadas

Se pintan desde la paleta de tiles:

1. Seleccionar `CapaDecoracionNoCaminable` de la zona.
2. En la paleta TileMap, elegir la fuente **Rocas derrumbadas**.
3. Seleccionar la variante 4×8 o 5×8 y pintar una celda para colocar el montículo completo. Borrar esa celda retira la decoración completa.

La fuente está incluida en `assets/tile_sets/decorations/cave_decorations_solid.tres`, compartido por Prisión, ZonaPlantilla y DescansoCuevas. Es una colección de escenas de Godot (`TileSetScenesCollectionSource`, fuente 5; variantes 0 y 1), para dibujar cada objeto grande como una pieza. La capa debe tener `y_sort_enabled = true`. La celda pintada es el ancla frontal de la base.

Los tamaños 4×8 y 5×8 describen las imágenes completas de 256×256 y 320×256 píxeles, a escala 1 y con casillas isométricas de 64×32. La ocupación sigue exactamente los centros de las casillas rojas de `assets/tiles/decorations/custom/*_ocupacion.png`: 29 y 42 casillas, respectivamente. No se interpreta como un rectángulo completo ni se deduce solo del tamaño del PNG. La parte alta no ocupa casillas y permite caminar por detrás; el orden Y hace que la roca cubra al personaje al pasar detrás y que este se dibuje por delante al rodear su base.

Son decoraciones estáticas `Node2D`, sin herencia de `Interactuable`, ID persistente, acciones, examen ni registro de interacción. Las escenas internas `scenes/decoraciones/rocas_derrumbadas_4x8.tscn` y `rocas_derrumbadas_5x8.tscn` conservan los tres sprites y la huella. `scripts/decoraciones/decoracion_no_caminable.gd` permite consultar esa huella y presentar sus máscaras `_hidden` y `_explored`. En el editor se muestra el arte original. No se pintaron montículos en los mapas del juego.

Al generar el tablero, las celdas de la huella quedan no caminables y con altura 2 para bloquear proyectiles; se conserva la opacidad de las demás capas. La parte alta no cambia el paso ni la visión de las celdas traseras. La niebla usa el estado más visible de toda la base, sin requerir que se vea el ancla. Guardar la zona conserva los tiles pintados, sin estados de interactuables.

`Huella Celdas` contiene desplazamientos positivos y negativos respecto al ancla. Las imágenes de ocupación sirven de referencia de autoría y no se cargan durante el juego; si se repintan, debe actualizarse también la huella de la escena.

## Verificación

`tests/interacciones/prueba_rocas_derrumbadas.gd` pinta ambas variantes usando la paleta real, comprueba su carga inicial y recuperación de una zona guardada, ausencia de registro como interactuable, huella exacta según PNG, paso libre por detrás, bloqueo de proyectiles, niebla por toda la base y liberación de casillas al borrar el tile y regenerar el tablero. También valida el tablero antes de entrar al árbol de escenas.

```powershell
& C:\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --log-file C:/godot/exhum_edu/.godot/prueba_rocas_derrumbadas.log --script res://tests/ejecutar_con_autoloads.gd -- res://tests/interacciones/prueba_rocas_derrumbadas.gd
```
