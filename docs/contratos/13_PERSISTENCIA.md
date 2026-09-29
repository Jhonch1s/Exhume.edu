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

El escenario ya guarda `rondas` durante combate. Al cargar primero reconstruye
un `GestorRondas` temporal con la ficha y los NPC identificados en el orden
guardado; valida el snapshot completo antes de cambiar el modo del escenario.
Una carga con `rondas = null` vuelve a exploración. Si el actor activo guardado
es un NPC, reanuda su decisión automática; cargar no consume un turno ni
repone los recursos de la ficha. El estado de cada NPC combatiente guarda
`recursos_turno` como cuatro reservas restantes. Así, cargar después de su
ataque no repite esa acción. Los snapshots v2 anteriores a este campo se
aceptan y reponen los recursos iniciales del NPC al restaurar.

La versión 2 es el formato de escritura actual. La versión 1 se acepta al cargar:
los NPC con estado vacío se inicializan desde su definición y la memoria narrativa
se inicia con `trompo_conocido = false`. Tampoco se guardan animaciones, tweens,
hover, menús, rutas tentativas ni otras presentaciones transitorias.

### Estado de NPC y memoria narrativa — septiembre de 2026

Cada `PersonajeNPC` tiene un `EstadoPersonajeNPC` propio, inicializado una vez
desde `DefinicionPersonaje` y los valores iniciales opcionales de la escena. Su
entrada en `interactuables` guarda `vida_actual`, `atributos` (fuerza, destreza y
voluntad) y `nivel_actual`. Solo un NPC de actitud dinámica guarda
`actitud_hacia_jugador`. La actitud fija se obtiene siempre de la definición.
Un NPC combatiente también guarda las cuatro reservas restantes de
`RecursosTurnoActor`; un NPC sin capacidad de combate no tiene ese bloque.
PV cero significa derrotado y no se usa como señal de falta de inicialización.
La caminabilidad, la disponibilidad de diálogo y la capacidad de actuar se
derivan de los PV restaurados; no se guardan indicadores de derrota duplicados.

El snapshot v2 incluye `memoria_narrativa: {"trompo_conocido": bool}` como
estado de partida, separado del estado del NPC. La validación de estos datos se
completa antes de restaurar. Ejecutar la escena con F6 no carga el archivo de
usuario; `cargar_partida()` sigue siendo una operación explícita.

### Cofres — septiembre de 2026

`CofreInteractuable` guarda su apertura y las pilas restantes. Cada pila usa el
mismo contrato de identidad, definición, ruta y cantidad de la ficha. La validación
rechaza inventarios que exceden la capacidad y IDs repetidos entre cualquier cofre,
la ficha y el suelo. Restaurar reemplaza el inventario inicial sin repetir acciones.

Las funciones de guardar/cargar archivo existen, pero no hay llamadas desde el
flujo normal del juego que las ofrezcan al jugador; las llamadas actuales están
en pruebas. Existencia del serializador no equivale a guardado automático.

