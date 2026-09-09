# Personajes y representación 3D

Estado revisado el 8 de septiembre de 2026.

## Clases y assets disponibles

Las clases admitidas por `EstadoPartida` son `Guerrero`, `Ladrón` y `Mago`.
Las tres tienen un modelo 3D incorporado en `escenario_base.tscn`:

| Clase | Modelo | SubViewport |
|---|---|---|
| Guerrero / caballero | `assets/characters/knight3d/caballero20.glb` | `KnightViewPort/KnightSubViewport` |
| Mago | `assets/characters/knight3d/modelomago2.glb` | `WizardViewPort/WizardSubViewport` |
| Ladrón | `assets/characters/knight3d/modeloladron2.glb` | `ThiefViewPort/ThiefSubViewport` |

Las tres rutas están actualmente bajo `knight3d`, aunque dos modelos correspondan
a otras clases. No se han movido assets al documentarlos.

## Del modelo a la ficha del tablero

El juego mantiene el tablero y `Ficha` en 2D. El escenario usa cámaras
ortográficas y SubViewports con fondo transparente para renderizar modelos 3D.
`capturar_textura(angulo, jugador)` elige caballero (1), mago (2) o ladrón (3),
rota el modelo, espera dos frames y convierte la imagen del viewport en
`ImageTexture`.

`Ficha.texturas_por_direccion` contiene las vistas para cuatro direcciones.
El movimiento cambia la textura de `sprite_render` según su dirección;
`_aplicar_visual_clase()` muestra la textura de dirección cero. El sprite original
de la ficha se oculta al generar esta representación. La ruta actual usa escala
`(0.12, 0.12)` y desplazamiento `(0, -24)` para el sprite capturado.

La selección del aventurero se transmite mediante `EstadoPartida`:
nombre, título, clase, origen y atributos. `Ficha.configurar_creacion()` aplica
esos datos. Modelo, sprite y cámara son presentación; posición, inventario,
recursos y estados pertenecen a la ficha lógica.

## Integración pendiente

Tener los tres modelos no implica que la selección visual por clase esté cerrada.
`spawnear_ficha_inicial()` todavía llama cuatro veces a `capturar_textura(..., 1)`:
siempre genera las vistas del caballero, antes de consumir los datos del aventurero.
`_aplicar_visual_clase()` no selecciona un modelo por nombre de clase.

Queda conectar la clase elegida con el modelo, revisar encuadre y escala de los
tres personajes y verificar la restauración visual al cargar. El spawn configura
explícitamente 512 × 512 y `UPDATE_ALWAYS` para caballero y mago; el ladrón conserva
la configuración de su escena. No documentar esto como una canalización uniforme
ni como un sistema de animación 3D terminado.
