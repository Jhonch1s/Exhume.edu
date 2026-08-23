## Flujos de referencia

### Palanca

El jugador elige `Accionar`; se crea `INTERACTUAR` con `id_accion = &"accionar"`, actor y palanca. Se valida objetivo y alcance. La palanca reacciona cambiando su estado, devuelve `EXITO` y registra el cambio. El gestor cobra el coste declarado y emite el resultado. La UI solo lo presenta.

### Trampa al entrar

Tras confirmar ocupación se crea `ENTRAR` con origen, destino y ficha. La trampa registrada como interactuable reacciona una vez, produce sus efectos y marca `interrumpe_movimiento`. Se aplican las consecuencias y la ruta se detiene en la celda de destino.

### Item arrojado

Seleccionar un item `arrojable` en el inventario publica `LANZAR_ITEM`; el receptor
potencial no origina esa opción. La acción valida actor, item, coste y trayectoria.
Al terminar la representación del vuelo se crea `IMPACTAR` con el item, celda real,
etiquetas (`impacto`, por ejemplo) y magnitudes como `fuerza_impacto`. Los receptores
reaccionan por propiedades; ninguno necesita conocer la definición concreta del item.
