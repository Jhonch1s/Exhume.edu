### Palanca y origen de Lanzar — ajuste tras 8.2

`PalancaInteractuable` publica `INTERACTUAR` con `id_accion = &"accionar"` y
alcance Manhattan uno. Cualquier actor adyacente puede alternar su estado sin item.
Su definición declara la textura y dos regiones de `64×64`; la instancia conserva
únicamente `activada` y actualiza la región visible.

La palanca no publica `Usar item…` ni `Lanzar item…`. Lanzar nace al seleccionar
una instancia `arrojable` desde el inventario. Después se elige
la celda o trayectoria; el objetivo alcanzado recibe `IMPACTAR` y reacciona a las
etiquetas y magnitudes reales del impacto. Así un receptor nunca ofrece acciones
basándose en items que todavía permanecen en posesión del actor.

### Puerta y llave compatible — incremento 8.4

`DefinicionLlave` añade un `patron_cerradura` estable y exige la etiqueta `&"llave"`.
`DefinicionPuerta` declara el patrón aceptado y dos regiones visuales de `64×96`.
El patrón no es una etiqueta: representa compatibilidad de contenido y evita crear
etiquetas específicas por cada pareja de llave y puerta.

Una puerta bloqueada publica `Abrir` deshabilitado y conserva el `Usar item…`
heredado. `PuertaInteractuable` primero reutiliza la validación estructural de
`USAR_ITEM`; al resolver, un item que no sea llave o una llave con otro patrón
devuelven `FALLO` sin modificar estado. Una llave compatible cambia únicamente
`bloqueada` a falso, devuelve `EXITO` y se conserva en el inventario. Abrir o cerrar
son acciones `INTERACTUAR` posteriores, adyacentes e independientes.

En 8.4 una puerta ocupa una celda. Cerrada hace que esa celda no sea caminable
efectivamente y bloquee visión; abierta libera ambos aspectos sin modificar las
propiedades base del terreno. `Celda` consulta los aportes de sus interactuables,
por lo que dos obstáculos superpuestos no pueden habilitarse accidentalmente entre
sí.

`Interactuable.presencia_cambiada` invalida la presencia dinámica en `TableroGrid`.
El pathfinding ya reevalúa las celdas en cada cálculo y `FOVManager` vuelve a
proyectar visión y luz al recibir el cambio. La huella multicelda para portones de
dos hojas queda pendiente hasta implementar el registro de un mismo interactuable
en varias celdas; no se representa mediante dos puertas independientes.

### Destino del item después de una acción — implementado en 9.1

No existe una propiedad global `consumible`: el mismo item puede sobrevivir o
desaparecer según la reacción concreta. El resultado de una acción con item deberá
declarar exactamente uno de estos destinos cuando exista el primer consumidor real:

- `CONSERVAR_EN_INVENTARIO`: mantiene la misma instancia, como una llave o herramienta.
- `CONSUMIR`: retira la cantidad usada sin crear un `ItemSuelo`.
- `DEJAR_EN_CELDA`: la cantidad usada sobrevive como `ItemSuelo` en la celda final.

Un `BLOQUEO` o un fallo anterior a la resolución no modifica el inventario. Cuando
se use una unidad de una pila, la pila origen conserva su identidad y la unidad
separada recibe una nueva si debe sobrevivir fuera del inventario. La transferencia
se confirmará atómicamente mediante `TransferidorItems`; `GestorAcciones` seguirá
sin conocer reglas de consumo, lanzamiento ni combinaciones.

Para una roca lanzada, el destino normal es `DEJAR_EN_CELDA`. Una reacción puede
elegir `CONSUMIR` si el impacto la rompe, absorbe o destruye.

