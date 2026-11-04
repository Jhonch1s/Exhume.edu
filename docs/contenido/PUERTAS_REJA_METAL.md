# Puertas de reja metálica

Escenas preparadas para colocar bajo `Interactuables/Puertas`:

- `scenes/interactuables/puertas/puerta_reja_metal_izquierda.tscn`
- `scenes/interactuables/puertas/puerta_reja_metal_derecha.tscn`

Se ajustan al centro de la celda en el editor. ZonaExplorable asigna un ID de instancia al colocarlas. El campo `Abierta` permite revisar los dos estados desde el Inspector; también se actualizan en el editor los ajustes de representación del recurso. Las escenas empiezan cerradas y desbloqueadas, para poder abrirlas manualmente.

## Región visual y alineación

La imagen original `assets/interactuables/puertas/puerta_reja_metal/puerta_reja_metal.png` mide 172×192 px. No necesita recortarse, escalarse ni limitarse a columnas de 64 px: los 64×32 describen la celda del suelo, no el límite del sprite. En el atlas, la hoja abierta derecha está desplazada y llega hasta x=150; extraer solo el tramo x=64…127 la cortaría.

Cada `DefinicionPuerta` usa estos valores:

Los estados se emparejan por filas del atlas: arriba izquierda cerrada / arriba derecha abierta; abajo izquierda cerrada / abajo derecha abierta. La variante `_izquierda` usa la fila superior y `_derecha` la inferior.

| Variante | Región cerrada `(x,y,ancho,alto)` | Región abierta | Desplazamiento sprite | Desplazamiento apertura |
|---|---|---|---|---|
| Izquierda | `(0,0,64,96)` | `(64,0,64,96)` | `(0,-32)` | `(41,0)` |
| Derecha | `(0,96,64,96)` | `(64,96,108,96)` | `(0,-32)` | `(-49,7)` |

`desplazamiento_apertura` se suma al desplazamiento normal solo cuando la puerta está abierta. Compensa tanto el cambio de tamaño de la región como la ubicación de la hoja dentro del atlas, conservando la bisagra en el mismo lugar. El ajuste vuelve a calcularse desde la posición base: no se acumula al abrir y cerrar. Su valor predeterminado es cero, por lo que las puertas anteriores conservan su alineación.

Las bisagras se mantienen en coordenadas locales `(16,8)` y `(-17,8)`, respectivamente, en el extremo inferior del eje fijo. En la fila superior, la hoja abierta se extiende hacia la **derecha** de su bisagra; en la inferior, hacia la **izquierda**. Los estados cerrados y las parejas por fila se conservan. El sobrante visual no añade celdas ocupadas: la puerta sigue asociada a una sola celda y conserva el comportamiento habitual de apertura, cierre y guardado.

## Control

Las dos rejas tienen `bloquea_vision_cerrada = false`: incluso cerradas dejan pasar la luz y permiten ver a través de los barrotes. El motor usa la misma opacidad para luz y visión. Siguen bloqueando el paso y los proyectiles mientras están cerradas. Una pared u otro obstáculo opaco superpuesto conserva su bloqueo. Las puertas anteriores mantienen `bloquea_vision_cerrada = true` por defecto.

Las definiciones están en la misma carpeta del atlas, con sufijos `_izquierda.tres` y `_derecha.tres`. Para añadir una cerradura, activar `Bloqueada` y configurar una llave con el mismo `patron_cerradura` (inicialmente `reja_metal`). Para accionarla con una palanca, hacer único el recurso si el cambio afecta solo a esa instancia, seleccionar el modo `MECANISMO` y enlazar su ID como receptor de la palanca. No se añadieron llaves, palancas ni puertas a los mapas existentes.

## Verificación

`tests/interacciones/prueba_puertas_reja_metal.gd`: 39 comprobaciones, 0 fallos. Cubre el emparejamiento de estados por filas, el sentido de apertura del extremo libre respecto de la bisagra, las dos orientaciones, regiones dentro del atlas, escala original, apertura/cierre, bisagra fija, bloqueo y liberación de la celda, restauración de estado y compatibilidad con las tres definiciones de puertas anteriores. Comprueba proyección real de luz al otro lado de las rejas cerradas, línea visual libre, conservación del bloqueo físico y respeto a una pared superpuesta. Las puertas anteriores conservan su opacidad. También pasaron las regresiones de llave, relación palanca-puerta y persistencia de interactuables. Revisión visual mediante captura de Godot del sentido de apertura; pendiente comprobar la colocación e iluminación manualmente en el mapa.
