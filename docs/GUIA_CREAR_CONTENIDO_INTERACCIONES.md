# Crear y diagnosticar contenido de interacciones

Esta guía usa las escenas y `Resource` existentes como plantillas. Agregar contenido
común no requiere modificar `GestorAcciones`.

## Crear una zona

Duplica `scenes/ZonaPlantilla/zona_plantilla.tscn`. La plantilla contiene vacíos
todos los `TileMapLayer` reconocidos por `TableroGrid`, con sus `TileSet`, orden y
configuración visual, además de los contenedores de interactuables y superficies.

`CapaSuelo` y `CapaOscuridad` son necesarias para una zona jugable. Las demás capas
pueden permanecer vacías. Conserva sus nombres: son el contrato de autoría que usa
el tablero para descubrir terreno y superficies.

Al colocar la zona dentro de `EscenarioBase`, el nodo instanciado debe llamarse
`Zona`. El recurso puede conservar un nombre de archivo descriptivo como
`zona_2.tscn`; el escenario ya no depende del nombre `Zona1`.

## Definir la aparición del jugador

Instancia `scenes/zonas/PuntoSpawnZona.tscn` bajo `PuntosSpawn`, déjalo con
`id_spawn = entrada` y arrástralo sobre la celda de acceso: se centra solo. Una
zona cerrada necesita únicamente ese marcador. Si una zona futura tiene varias
conexiones, añade marcadores con IDs distintos; la transición solicitará el ID que
corresponda a la procedencia.

`EscenarioBase` usa `entrada` al iniciar y rechaza marcadores duplicados, vacíos o
fuera de una celda caminable. Las zonas antiguas sin marcadores conservan por ahora
el primer piso caminable como compatibilidad.

Las zonas heredan `ZonaExplorable`. Al ejecutar una directamente con F6, ésta se
monta automáticamente como `Zona` dentro de `EscenarioBase`; así genera tablero,
visión, iluminación y ficha en `entrada`. Cuando el juego carga la misma zona como
contenido normal, el adaptador no interviene. No dupliques en las zonas lógica de
movimiento, diccionarios, UI ni servicios del escenario.

## Crear y colocar un interactuable

1. Duplica la escena y el recurso del caso más cercano:
   - Puerta: `scenes/interactuables/puertas/puerta_interactuable.tscn` y
     `assets/interactuables/puertas/puerta/puerta.tres`.
   - Palanca: `scenes/interactuables/mecanismos/palanca_interactuable.tscn` y
     `assets/interactuables/mecanismos/palanca/palanca.tres`.
   - Trampa: `scenes/interactuables/trampas/TrampaSuperficie.tscn`.
   - Superficie: una escena bajo `scenes/efectos_superficie/`.
2. Asigna un `id_definicion` único al recurso y completa sus campos exportados.
3. Instancia la escena bajo `Interactuables` o `EfectosSuperficie` en la zona.
4. Asigna un `id_instancia` único y coloca el nodo sobre una celda existente.
5. Ejecuta la zona. La prevalidación informa todos los IDs, definiciones,
   coordenadas, contratos o relaciones inválidos antes de registrar contenido.

Las trampas nuevas parten `OCULTAS`. El jugador las descubre con una prueba secreta
de VOL; el destello no permanece. Una vez descubiertas ofrecen desarme adyacente
con FUE, DES o VOL. Configura `escena_superficie`, `radio` y
`interrumpe_al_activar`; no agregues lógica de tiradas al escenario.
Selecciona `fila_atlas`: `Veneno` usa la primera fila, `Fuego` la segunda y
`Neutra` la tercera. En todas, la columna izquierda está armada y la derecha
representa la placa pisada.
Al mover una `TrampaSuperficie` dentro de una zona, ésta se ajusta automáticamente
al centro de la celda más cercana de `CapaSuelo`. Desactiva
`ajustar_a_celda_en_editor` sólo para diagnosticar una colocación excepcional.

`FuenteLuzInteractuable.tscn` también se ajusta al centro y trae una antorcha de
pie como definición inicial visible. Sustituye `definicion` por la variante de
pared izquierda, pared derecha o fogata que corresponda. Las placas ocultas se
muestran en el editor para poder colocarlas, pero durante F6 permanecen invisibles
hasta que una prueba de VOL las descubra; para comprobar su sprite durante una
ejecución puede cambiarse temporalmente su estado a `ACTIVADA`.

Las escenas base ya pertenecen al grupo correcto. Si se crea una escena desde cero,
los interactuables deben heredar `Interactuable`; las superficies deben pertenecer
al grupo `efectos_superficie` e implementar `obtener_id_reaccion()` y
`configurar_registro()`.

## Conectar una palanca

En `ids_receptores_mecanismo`, agrega los `id_instancia` de los receptores. No uses
`NodePath` ni nombres de nodos. Cada receptor debe implementar:

```gdscript
func validar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> StringName
func aplicar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> ResultadoAccion
```

La prevalidación detecta IDs vacíos, repetidos, inexistentes o incompatibles antes
de registrar la zona.

## Diagnosticar una celda

En la escena principal, coloca el cursor sobre una celda y pulsa `F3`. La consola
muestra terreno, presencia efectiva, coste, ocupantes, reservas, interactuables,
items, superficies, iluminación y reacción de terreno.

Para seguir una acción, añade
`scripts/interacciones/debug/registro_acciones_desarrollo.gd` como nodo y llama:

```gdscript
registro.observar_gestor(gestor_acciones)
registro.configurar_filtros(id_actor, celda_objetivo, tipo_accion)
```

Cada ciclo informa inicio, resultado base y resultado final. `limpiar_filtros()`
restaura el registro completo y `limpiar()` vacía el historial.

## Comprobación mínima

El contenido nuevo debe dejar una prueba headless pequeña que instancie la zona o
el receptor real, ejecute una acción válida y compruebe al menos un rechazo sin
mutación. Reutiliza la estructura de `tests/interacciones/` y ejecuta:

```text
Godot.exe --headless --path C:\godot\exhum_edu --script res://tests/interacciones/prueba_elegida.gd
```

No existe generación desde marcadores. Se añadirá solo si la autoría manual con la
plantilla demuestra repetición suficiente para justificarla.
