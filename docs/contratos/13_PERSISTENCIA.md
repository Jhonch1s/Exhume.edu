## Persistencia de interactuables colocados — incremento 12.1

### Consolidación de carga — 15-10-2026

Los términos de dados de estados se validan y convierten a `int` en la frontera
de persistencia, porque JSON devuelve números como `float`. Fracciones, valores
no finitos o tipos incorrectos se rechazan antes de cualquier mutación. El motor
de dados conserva su validación estricta y el próximo FIN_TURNO ejecuta los términos
restaurados. Esto se aplica tanto a ficha como a NPC, también a archivos anteriores.

Cargar sin rondas descarta el gestor previo sin ejecutar su política de olvido
sobre la memoria restaurada. No depende del bando anterior del NPC. Validar y
restaurar siguen precediendo a la limpieza transitoria: un rechazo conserva el
encuentro vigente. Formato, campos opcionales y versión no cambian.
Casos y resultados: [Consolidación NPC](../pruebas/CONSOLIDACION_NPC.md).

### XP por derrota de NPC — 15-10-2026

`Ficha.experiencia_acumulada` es el total concedido y ya pertenece al snapshot
de la ficha. La recompensa se suma al morir por daño un NPC participante del
bando oponente durante un encuentro activo, sea daño directo, estados, explosión
o fuente sin autor. No exige contribución previa del jugador ni de sus aliados.
Cargar estados, examinar y recoger botín no emiten otra muerte por daño.
Por ello no se añade un indicador de XP entregada al cadáver ni
se cambia la versión. La ficha sin el campo antiguo migra a cero; los cuerpos
ya muertos en archivos previos no conceden XP al cargar. Guardar antes de una
baja y cargarla restaura a la vez NPC vivo y XP anterior. Los niveles siguen sin
avance automático aunque la XP alcance el umbral.
La prueba de XP indirecta también carga encuentros anteriores sin bandos y fichas
sin XP: conserva los cadáveres con cero XP retroactiva y admite nuevas recompensas
por muertes posteriores. No cambia el formato ni se persiste autoría de estados.

### Bandos y objetivos de NPC — 14-10-2026

Los encuentros nuevos escriben `rondas.bandos`, diccionario por ID con valores
enteros `JUGADOR = 1` y `OPONENTE = 2`, y `rondas.defendidos`, lista de IDs únicos.
Debe haber exactamente un bando por participante; el jugador conserva su lado
y los NPC deben tener capacidad de combate. IDs desconocidos, tipos/rangos
inválidos o listas repetidas se rechazan antes de cualquier cambio. Neutrales
ajenos al encuentro no se serializan como participantes.

Sin `bandos`, la preparación migra al jugador en su lado y todos los NPC
participantes como oponentes, sin consultar su actitud actual. `defendidos`
ausente comienza vacío y no reproduce agresiones anteriores. Sin `rondas`,
cargar exploración limpia bandos previos. El nodo NPC deriva su oposición
compatible del bando restaurado; no se guarda otro booleano.

La coordenada existente `ultima_posicion_conocida` puede referirse a otro NPC;
en ese caso se añade `estado.objetivo_recordado_id`, ID no vacío de un NPC
registrado, con recuerdo válido. Sin ese campo se interpreta como recuerdo del
jugador, conservando los archivos anteriores. Una referencia inválida cancela
la restauración completa. No se consultan posiciones ocultas al compartir memoria.

La facción fija pertenece a `DefinicionPersonaje.faccion_id`, no al estado mutable
ni a una reputación global. No cambia la versión v2. Guardar/cargar conserva
bandos, memoria, puntos, orden, iniciativas y recursos sin ejecutar ataques,
deltas, ticks o tiradas nuevas. PV, botín y patrulla mantienen su formato anterior.

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

El campo opcional `variante_visual` conserva el frame elegido para cada objeto
del suelo. La representación lo elige al crearse por primera vez; al cargar se
aplica el valor guardado antes de entrar en el árbol, sin volver a sortearlo.
La validación rechaza índices fuera de la hoja de sprites y valores no enteros.
Los guardados anteriores sin este campo siguen admitidos: eligen una variante
que queda incluida en el siguiente guardado. No cambia la versión del snapshot.

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
pruebas. Guardar admite movimiento; cargar exige reposo. Ambas operaciones se
rechazan durante una interacción modal.

El bloque `rondas` es opcional mientras exploración no use `GestorRondas`. Cuando
existe conserva ronda, orden por IDs y actor activo. Restaurarlo no llama
`iniciar_turno`, no repone recursos y no ejecuta `FIN_TURNO`. Después de restaurar
la ficha, `TableroGrid` corrige su ocupación y el escenario recalcula pathfinding y
visión.

Desde el 09-10-2026 `rondas.iniciativas` conserva por actor `id`, `dado`,
`destreza` usada al tirar y `total`. Se validan IDs conocidos y únicos, enteros,
dado entre uno y seis, DES entre cero y 99 y suma correcta antes de modificar la
partida. La DES capturada puede diferir de la actual: representa la tirada de esa
ronda. Los incorporados todavía sin tirada no tienen entrada. Se conserva el
orden exacto guardado y no se tira al preparar ni restaurar. El campo es opcional
en snapshot v2: los anteriores conservan orden y empiezan a tirar la próxima ronda.

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

Desde el 11-10-2026 los NPC dinámicos añaden el campo opcional `puntos_actitud`,
entero de -10 a +10. `actitud_hacia_jugador` se escribe como etiqueta derivada:
hostil <= -3, amistosa >= +3 y neutral entre ambos. Validar exige rango, entero
y coherencia entre campos antes de cualquier mutación. Sin puntos, el snapshot
antiguo migra su etiqueta guardada a -3/+3/0. V1 conserva inicialización desde
definición. No cambia la versión v2. Un NPC fijo no guarda ninguno de esos campos.
`en_oposicion_encuentro` no se serializa: el escenario lo reconstruye exclusivamente
desde participantes de `rondas` al cargar, limpiando oposición de encuentros previos.
Cargar no aplica deltas de actitud, no repite ataques ni vuelve a tirar iniciativa.

Desde el 09-10-2026 el bloque opcional `estado.patrulla` pertenece a `PatrullaNPC`:
guarda puntos del circuito, `turnos_espera`, `indice_siguiente` y `espera_restante`.
`PersonajeNPC` valida tanto el estado común como este bloque antes de restaurar.
La ruta y espera configurada deben coincidir con la escena; índices y contadores
deben ser enteros dentro del rango. Sin bloque (guardados anteriores) reinicia el
primer punto y espera cero. No se guardan curvas visuales, rutas calculadas ni
timers; cargar no mueve, consume espera ni repone recursos. Los NPC neutrales
que tienen patrulla también guardan reservas de turno. La [guía de patrullas](../contenido/PATRULLAS_NPC.md)
detalla las restricciones de K/C.

Cada `PersonajeNPC` tiene un `EstadoPersonajeNPC` propio, inicializado una vez
desde `DefinicionPersonaje` y los valores iniciales opcionales de la escena. Su
entrada en `interactuables` guarda `vida_actual`, `atributos` (fuerza, destreza y
voluntad) y `nivel_actual`. Solo un NPC de actitud dinámica guarda
`actitud_hacia_jugador`. La actitud fija se obtiene siempre de la definición.
Un NPC combatiente también guarda las cuatro reservas restantes de
`RecursosTurnoActor`; un NPC sin capacidad de combate no tiene ese bloque.
PV cero significa muerto y no se usa como señal de falta de inicialización.
La caminabilidad, la disponibilidad de diálogo y la capacidad de actuar se
derivan de los PV restaurados; no se guardan indicadores de derrota duplicados.

Desde el 11-10-2026, la asignación de PV y la curación no reviven un NPC con cero
PV. Restaurar un snapshot validado aplica directamente los PV guardados: cargar
un momento anterior donde seguía vivo recupera ese estado. Guardados anteriores
con cero PV se interpretan como cadáveres. No cambia la versión ni se añade un
indicador duplicado de muerte; el inventario restante se restaura por separado.

El snapshot v2 incluye `memoria_narrativa: {"trompo_conocido": bool}` como
estado de partida, separado del estado del NPC. La validación de estos datos se
completa antes de restaurar. Ejecutar la escena con F6 no carga el archivo de
usuario; `cargar_partida()` sigue siendo una operación explícita.

### Movimiento según DES — 08-10-2026

Ficha y NPC combatiente guardan `movimiento_maximo` junto a `recursos_turno`.
El máximo se valida contra **DES guardada + 3**, no contra la destreza de la
ejecución actual. Primero se validan los datos completos; al restaurar se
reconstruye la reserva con la destreza guardada y se aplican los restantes.
Un guardado nuevo conserva exactamente sus reservas, sin iniciar otro turno.

El campo es opcional para los snapshots anteriores al cambio, cuyo máximo era
siete. La carga valida sus restantes contra siete y conserva el gasto:
`restante_nuevo = max(0, DES + 3 - (7 - restante_anterior))`. Por ejemplo, un NPC
con DES 2 y cuatro puntos restantes había gastado tres; se restaura con dos de
su nuevo máximo cinco. Si el nuevo máximo es mayor, los restantes pueden crecer
por esa diferencia, conservando los puntos gastados. No cambia la versión v2.
Un NPC sin reservas en un guardado antiguo sigue recibiendo sus reservas iniciales,
ahora calculadas con DES. No se procesa `FIN_TURNO` durante esta migración.

El goblin hostil usa ahora un máximo fijo de cuatro. Su carga admite también el
máximo DES + 3 de los archivos anteriores y migra conservando puntos gastados;
si antes tenía cinco y gastó dos, restaura dos restantes del nuevo máximo cuatro.
Los NPC sin máximo fijo mantienen la validación DES + 3. No cambia la versión v2.

### Memoria de búsqueda y origen del NPC — 09-10-2026

Un NPC combatiente guarda `ultima_posicion_conocida` como `[x, y]` o `null`.
Es memoria de una detección previa, propia o de un compañero vivo del encuentro,
no una referencia a la ficha ni acceso automático a su posición actual.
La validación exige dos enteros y una casilla del tablero; no exige que
siga siendo caminable porque una puerta u otro obstáculo puede cambiar después.

El campo es opcional en snapshots anteriores. Su ausencia restaura memoria vacía,
sin conservar recuerdos de la ejecución actual ni inventar una coordenada del
jugador. Al reanudar un combate antiguo, el escenario vuelve a comprobar detección:
si detecta, registra un recuerdo; si no, termina la modalidad combate inmediatamente.
Salir por pérdida de agro conserva la memoria. Buscar y regresar continúan durante
los turnos de exploración; cargar no ejecuta un turno. No cambia la versión v2 y
no se guardan rutas ni blackboards.

El combate grupal usa el mismo campo individual para la posición compartida.
El snapshot de rondas ya conserva los IDs de todos los participantes, incluidos
derrotados, el orden fijo y el actor activo. No cambia la versión ni se crea un
campo global de agro. Al reanudar se consulta la detección conjunta; cargar no
inicia ni repone turnos. La escena manual usa archivos por cantidad de enemigos
para mantener separado el guardado anterior de un solo NPC.

`coordenada_origen` guarda `[x, y]`, capturada al registrar inicialmente al NPC,
independiente de su posición móvil. Se validan forma, enteros y límites del tablero
antes de modificar la partida. El destino puede estar ocupado o bloqueado: el NPC
espera hasta tener ruta. Los archivos anteriores sin este campo usan el origen de
la instancia en la escena, incluso al cargar sobre un NPC que ya se desplazó.
La fase se deduce de los datos: recuerdo presente = buscar; sin recuerdo y fuera
del origen = regresar; en el origen = reposo. Cargar fuera de combate conserva
el recuerdo restaurado, sin limpiarlo desde el gestor del encuentro anterior.

Desde el 11-10-2026 guardar admite actores moviéndose y avances NPC en curso.
El snapshot se obtiene de forma síncrona y conserva `coordenada_mapa`, la última
casilla confirmada de cada actor, con los recursos y estados de ese momento.
El paso cuyo tween aún no terminó no está cobrado ni ejecutó sus reacciones;
la posición visual intermedia, las reservas y la ruta en curso no se serializan.
Guardar no interrumpe el recorrido. Al cargar, los actores aparecen en sus
casillas guardadas; la ficha no continúa su ruta anterior y los NPC vuelven a
decidir desde el objetivo persistente.

Cargar exige que no haya actores moviéndose ni avances NPC en curso de exploración.
Una ruta bloqueada cierra el avance y espera entre ciclos, permitiendo cargar en
reposo. La cola de ejecución es transitoria y no se serializa. Una carga correcta
invalida ejecuciones anteriores para que no consuman recursos ni procesen estados
del mundo restaurado.

El escenario devuelve un motivo específico si falta la ficha o hay una interacción
modal. Sólo para cargar comprueba además movimientos y ciclos de exploración en
curso. Antes de comprobarlo recalcula el estado modal desde los paneles
y acciones actuales. La escena manual traduce el motivo con el catálogo y lo
registra en la salida; para un NPC en movimiento también registra su ID.

Desde el 15-10-2026 el diálogo con tirada mantiene ese bloqueo durante toda la
conversación: abrir/cerrar el panel de dados no permite guardar ni cargar entre
la elección y la respuesta. El resultado temporal se limpia al terminar y no
forma parte del snapshot. Cargar después no repite la tirada ni reabre el diálogo.

El catálogo configurable posterior conserva un campo opcional `pruebas_dialogo`
por NPC: diccionario de IDs estables de prueba a booleanos de éxito/fallo. Sólo
se incluye cuando hay intentos únicos resueltos. Se guarda el resultado después
de aplicar consecuencias y antes de continuar la respuesta, con K/C bloqueado.
El resultado permite reutilizar la rama sin abrir dados ni reaplicar efectos.
IDs vacíos, claves no textuales y valores no booleanos invalidan el estado antes
de restaurar. Ausencia del campo restaura memoria vacía; no conserva intentos del
mundo previo a la carga. Actitud usa su campo existente y la información usa
`RegistroConocimiento`. No cambia la versión ni los diálogos sin estas pruebas.

### Estados temporales de NPC — 08-10-2026

Cada NPC guarda un array `estados`, incluido cuando está vacío, mediante
`EstadosTemporalesActor`. Conserva clave, magnitud, duración total, ticks pendientes
y términos de daño. La validación rechaza claves desconocidas o repetidas,
duraciones inválidas y términos de dados incompatibles antes de restaurar.

El campo es opcional para aceptar snapshots v2 anteriores; su ausencia restaura
estados vacíos, sin conservar efectos de la ejecución actual. Los snapshots v1
siguen reinicializando el estado completo del NPC. No cambia la versión de escritura.
`enredado` se restaura con cero ticks aunque un guardado anterior declare más:
su final depende de liberarse. La ficha usa la misma validación y normalización.
Cargar no ejecuta efectos, no consume ticks y no repone las reservas guardadas.

### Posición de NPC móviles — 06-10-2026

La coordenada existente de cada interactuable ahora puede restaurarse cuando
`admite_restaurar_posicion()` lo permite. `PersonajeNPC` admite esta operación;
puertas y otros elementos estáticos siguen exigiendo su ubicación original.
No cambia la versión 2 ni se serializa la capacidad de movimiento.

Antes de modificar el mundo se validan juntas las posiciones finales y la
caminabilidad de los estados guardados: límites del tablero, terreno caminable,
superposición entre NPC y bloqueadores, y ubicación final del jugador. Un NPC
derrotado permite paso y puede compartir casilla con la ficha. La validación usa
los PV y la apertura de puertas guardados, sin depender de su estado vivo actual.

Restaurar aplica estados y luego reubica los actores mediante
`TableroGrid.reubicar_interactuable()`. Conserva IDs y conexiones, retira su
presencia de las celdas anteriores, la registra en las nuevas y actualiza su
posición visual. No dispara `SALIR`/`ENTRAR`, no anima ni cobra movimiento.
Cargar se rechaza mientras se mueve la ficha o cualquier NPC registrado;
guardar conserva sus últimas casillas confirmadas incluso durante movimiento.
Después de cargar un turno de NPC, el árbol decide desde las posiciones y reservas
restauradas; la ruta anterior y el blackboard no se guardan.

### Cofres — septiembre de 2026

`CofreInteractuable` guarda su apertura y las pilas restantes. Cada pila usa el
mismo contrato de identidad, definición, ruta y cantidad de la ficha. La validación
rechaza inventarios que exceden la capacidad y IDs repetidos entre cualquier cofre,
la ficha y el suelo. Restaurar reemplaza el inventario inicial sin repetir acciones.

### Botín de NPC — 11 de octubre de 2026

Los NPC con `puede_tener_inventario` guardan el campo opcional `inventario` junto
a PV, atributos, recursos y patrulla. Usa el mismo formato de pilas que los
cofres; `Inventario` comparte la serialización y validación de ambos. La lista
vacía es un estado válido y evita reponer el botín tras recogerlo y cargar.
Los IDs se comprueban también entre todos los NPC, cofres, ficha y suelo.
La derrota sólo habilita la interacción: no crea objetos nuevos ni altera IDs.

Los snapshots anteriores sin ese campo recuperan el contenido inicial de la
instancia. La muerte irreversible se representa con cero PV desde el 11-10-2026;
la XP concedida queda en la ficha desde el 15-10-2026. Guardar mantiene el bloqueo modal;
cargar mantiene además los bloqueos de movimiento y ciclos de exploración en curso.

Las funciones de guardar/cargar archivo existen, pero no hay llamadas desde el
flujo normal del juego que las ofrezcan al jugador; las llamadas actuales están
en pruebas. Existencia del serializador no equivale a guardado automático.

