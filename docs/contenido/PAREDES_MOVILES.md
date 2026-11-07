# Paredes móviles

La placa `trampa_superficie_001` del Templo controla cuatro bloques de piedra:

| ID | Casilla cerrada | Posición visual al abrir |
|---|---|---|
| `templo_pared_movil_001` | `(0,-28)` | `(2,-28)` |
| `templo_pared_movil_002` | `(1,-28)` | `(3,-28)` |
| `templo_pared_movil_003` | `(0,-29)` | `(2,-29)` |
| `templo_pared_movil_004` | `(1,-29)` | `(3,-29)` |

Los cuatro tiles originales se sustituyeron por instancias de
`scenes/interactuables/mecanismos/pared_movil.tscn`, bajo
`Interactuables/Mecanismos`. Sus definiciones `recursos/templo/pared_movil_0.tres`
y `pared_movil_1.tres` conservan las regiones originales del atlas de pared alta.
Hay suelo normal bajo el pasaje; no volver a pintar paredes estáticas encima.

## Comportamiento

Al pisar la placa, los bloques se deslizan juntos durante 1,2 segundos, con un
sonido de piedra. El desplazamiento visual de `(64,-32)` píxeles equivale a sumar
dos a X del tablero. Se recogen dentro de las paredes sólidas de las columnas 2
y 3; esas casillas siguen bloqueadas. Los bloques conservan su ancla lógica en
el paso para reutilizar la presencia dinámica y la persistencia de puertas.

Hasta terminar el movimiento bloquean paso, visión y proyectiles. Al concluir,
la señal de presencia actualiza las rutas, la visión y la iluminación. La
apertura es permanente; repetir la señal no reinicia ni salta la animación.

Guardar y cargar conserva la apertura y coloca la imagen en su posición final,
sin repetir el movimiento. Un guardado hecho durante el deslizamiento restaura
el estado abierto final. La placa conserva su estado de activación normal.

## Crear otro paso

Colocar una instancia por tile, sobre suelo libre de paredes estáticas, y asignar
un ID estable y una `DefinicionPuerta` en modo MECANISMO. Configurar textura,
regiones y desplazamientos. El destino del desplazamiento debe estar dentro de
piedra sólida del tablero: este mecanismo es una pared retráctil, sin empuje ni
daño a actores. Añadir los IDs a la placa emisora. Cada bloque lleva su propia
representación y máscaras de niebla.

## Probar

Abrir el Templo y ejecutar F6 en una partida nueva; llegar a la placa 001 y
pisarla. Tras abrirse el paso, caminar por las casillas originales hasta el
umbral `tunel_dialogo`. Verificar que el retrato y el comentario del túnel aparecen.

Prueba automática: `tests/zonas/prueba_paredes_moviles.gd`, usando
`tests/ejecutar_con_autoloads.gd`. Comprueba la activación real de los cuatro
receptores, movimiento intermedio/final, idempotencia, bloqueos, pathfinding y
guardado/carga de estados abiertos y cerrados. La revisión visual en juego
permanece necesaria para ajustar el sonido, el solapamiento y el ritmo.

Las partidas que guardaron el templo antes de añadir estos cuatro interactuables
no contienen sus IDs; para esta edición del mapa se debe probar con partida nueva.
