## Persistencia de interactuables colocados — incremento 12.1

`PersistenciaInteractuables` produce un `Dictionary` compatible con JSON con
`version`, `zona_id` y los interactuables ordenados por ID estable. Cada entrada
conserva `id`, `definicion_id`, coordenada y estado particular; nunca contiene
referencias a nodos, escenas completas ni `NodePath` como identidad.

La escena de zona continúa siendo la autoridad sobre existencia, definición,
posición y relaciones. Al cargar, el tablero resuelve cada entidad ya registrada
por `id_instancia`. La versión inicial exige coincidencia exacta del conjunto de
interactuables, zona, definición y coordenada.

Cada `Interactuable` publica por comportamiento:

```gdscript
func obtener_estado_persistente() -> Dictionary
func validar_estado_persistente(estado: Dictionary) -> StringName
func restaurar_estado_persistente(estado: Dictionary) -> StringName
```

La validación recorre el documento completo antes de aplicar el primer cambio. Una
entrada ausente, duplicada o incompatible cancela la restauración sin estado
parcial. Restaurar actualiza consecuencias visuales y mecánicas, pero no ejecuta
acciones, costes ni mensajes. En 12.1 participan puertas, palancas, trampas y
fuentes de luz; items, actores, conocimiento y superficies quedan para incrementos
posteriores.

### Ficha, inventario y conocimiento — incremento 12.2

`PersistenciaPartida` compone el snapshot de interactuables con una ficha y el
registro de conocimiento. La ficha conserva IDs de actor y observador, coordenada,
vida, energía, recursos restantes del turno, estados temporales e inventario.

Cada item guarda identidad de pila, ID y ruta de su definición y cantidad. La carga
usa `ResourceLoader`, comprueba que el Resource siga siendo una `DefinicionItem`
válida con el mismo ID y reconstruye un inventario nuevo antes de sustituir el
actual. Los máximos de vida, energía y recursos continúan perteneciendo a la ficha
y su configuración, no al guardado.

Los estados conservan clave, magnitud, duración total y ticks pendientes. El
conocimiento se representa como entradas ordenadas de observador, objetivo e IDs de
fragmentos recordados. No se serializan `FragmentoInformacion` ni definiciones.

El coordinador valida primero interactuables, ficha, coordenada dentro del tablero,
items y conocimiento. Solo después restaura las tres partes, por lo que un dato
incompatible no deja una partida parcialmente modificada.

### Contenido dinámico — incremento 12.3

El snapshot es la autoridad completa sobre `items_suelo` y `superficies`. Restaurar
reemplaza ambos registros en lugar de mezclarlos con el contenido inicial de la
zona. Las trampas conservan por separado su estado activado y no vuelven a dispararse
durante la carga.

Un item de suelo usa el mismo contrato de identidad y definición que el inventario,
añadiendo coordenada. Los IDs de instancia son únicos entre inventario y suelo. El
registro mediante `TableroGrid` continúa emitiendo las señales que crean o retiran
su representación visual.

Una superficie guarda ID, `scene_path`, coordenada y turnos restantes. La carga
instancia su `PackedScene`, valida el protocolo temporal y establece el contador
directamente, sin simular ticks. Una transformación guarda únicamente su resultado
actual: humo después de fuego se persiste como humo, sin historial.

Antes de retirar contenido existente se validan todas las rutas, escenas, IDs,
cantidades, coordenadas y duraciones y se preparan las nuevas instancias. La propia
creación del snapshot ejecuta esa validación y falla completa si encuentra contenido
que todavía no admite persistencia.

### Archivo y ronda activa — incremento 12.4

`ArchivoPartida` escribe JSON en una ruta temporal, vuelve a leerlo y solo entonces
reemplaza el slot. Si ya existe un guardado lo mueve brevemente a `.bak`; un fallo al
publicar el temporal restaura ese respaldo. Una carga inexistente, ilegible o con
JSON inválido no modifica el mundo.

`PersistenciaPartida.guardar_archivo()` y `cargar_archivo()` componen el archivo con
la validación lógica existente. `EscenarioBase` ofrece ambas operaciones con
`user://partida.json` como único slot predeterminado y permite otra ruta para
pruebas. Guardar o cargar durante movimiento o una interacción modal se rechaza.

El bloque `rondas` es opcional mientras exploración no use `GestorRondas`. Cuando
existe conserva ronda, orden por IDs y actor activo. Restaurarlo no llama
`iniciar_turno`, no repone recursos y no ejecuta `FIN_TURNO`. Después de restaurar
la ficha, `TableroGrid` corrige su ocupación y el escenario recalcula pathfinding y
visión.

La versión 1 se acepta de forma estricta. No hay migraciones hasta que exista una
segunda versión real. Tampoco se guardan animaciones, tweens, hover, menús, rutas
tentativas ni otras presentaciones transitorias.

