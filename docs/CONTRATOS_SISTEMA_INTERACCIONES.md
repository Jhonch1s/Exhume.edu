# Contratos del sistema de interacciones

Este documento cierra la Fase 0 del [roadmap](../ROADMAP_SISTEMA_INTERACCIONES.md). Define el vocabulario que deberán respetar las implementaciones a partir de la Fase 1.

## Convenciones

- El código, los identificadores de contenido y los mensajes de desarrollo se escriben en español.
- Las clases usan `PascalCase`; propiedades, métodos, señales y archivos usan `snake_case`.
- Los valores de catálogos cerrados se expresan mediante `enum`. Las etiquetas extensibles y los IDs de contenido usan `StringName` en minúsculas, sin tildes y con guion bajo.
- Las coordenadas del tablero usan `Vector2i`. Una coordenada ausente se representa con `null`, no con un valor centinela.
- Los contratos transportan referencias durante la ejecución, pero la persistencia futura deberá guardar IDs estables, nunca `NodePath` ni referencias a nodos.
- `GestorAcciones` coordina; no contiene reglas específicas de puertas, palancas, terrenos o items.

## Vocabulario

**Acción solicitada:** intención explícita del jugador. Siempre pasa por selección de opción y validación antes de resolverse. Ejemplos: `EXAMINAR`, `INTERACTUAR` y `USAR_ITEM`.

**Acción automática:** hecho del juego que usa el mismo canal, pero no requiere menú. Ejemplos: `ENTRAR`, `SALIR`, `IMPACTAR` y `FIN_TURNO`.

**Reacción:** respuesta de un receptor a un contexto ya validado. Puede rechazarlo o producir cero o más efectos y cambios de estado. Una reacción no presenta UI ni cobra costes directamente.

**Efecto:** consecuencia mecánica reutilizable producida por una reacción, como daño, cambio de energía o interrupción. La reacción decide qué debe ocurrir; el efecto encapsula cómo aplicarlo.

**Receptor:** objeto capaz de validar o resolver una acción. Puede ser terreno, efecto de superficie, interactuable, item u ocupante.

**Coste:** recurso que se consume al confirmar una resolución: energía, acción, turno, carga o cantidad de item. Validar nunca consume costes.

## Contrato de receptores

GDScript no ofrece interfaces formales y los futuros receptores tendrán clases base diferentes. Por ello, un receptor de acciones se define por comportamiento y debe implementar estos dos métodos públicos:

```gdscript
func validar_accion(contexto: ContextoAccion) -> StringName
func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion
```

`validar_accion()` devuelve `&""` cuando acepta el contexto o un código de motivo cuando lo bloquea. Debe ser idempotente y no puede modificar estado, consumir recursos ni producir efectos. Puede llamarse al publicar una opción y debe repetirse inmediatamente antes de resolverla.

`resolver_accion()` se llama únicamente después de superar todas las validaciones comunes y específicas. Puede modificar estado y devuelve siempre un `ResultadoAccion` estructurado.

El coordinador reconoce provisionalmente el contrato mediante `has_method(&"validar_accion")` y `has_method(&"resolver_accion")`. La publicación de `OpcionAccion` es una responsabilidad separada que se incorporará con los interactuables; no forma parte de este contrato mínimo.

## Construcción de contextos desde opciones voluntarias

La interfaz contextual no interpreta propiedades concretas del objetivo ni conoce
las reglas de `EXAMINAR`, antorchas o fogatas. Los proveedores de opciones
voluntarias implementan el protocolo:

```gdscript
func construir_contexto_accion(
    opcion: OpcionAccion,
    actor: Object,
    origen: Vector2i,
    celda_objetivo: Vector2i,
    item_seleccionado: ItemInstancia = null
) -> ContextoAccion
```

`ConstructorContextoAccion` invoca ese protocolo y comprueba que el contexto
devuelto conserve el tipo, actor, objetivo, coordenadas, línea de efecto, costes y
política de la opción elegida. Para `INTERACTUAR`, `id_accion` debe coincidir con el
ID de la opción; para los demás tipos permanece vacío. Un contrato ausente, nulo o
incoherente se rechaza con un motivo estable y nunca llega a resolución.

`Interactuable` implementa la construcción común. `EXAMINAR` obtiene su alcance del
perfil de observación y crea una `SolicitudExamen` con el ID del actor.
`INTERACTUAR` conserva el ID específico publicado. Cada proveedor puede declarar
el alcance mecánico de sus opciones sin exponerlo a la UI; la primera fuente de luz
declara alcance Manhattan `1.0` para `encender` y `apagar`.

Elegir una opción habilitada construye exactamente un contexto y lo entrega a
`GestorAcciones.procesar_accion()`. El gestor repite todas las validaciones
estructurales, espaciales, específicas y económicas inmediatamente antes de
resolver. Por ello, una opción que quedó obsoleta mientras el menú estaba abierto
termina en `BLOQUEO` sin cambios ni costes. `Cancelar` no participa de este
protocolo y nunca construye contexto.

## Ciclo inicial del gestor

`GestorAcciones` procesa la lógica de forma síncrona y emite, en ese orden, `accion_iniciada`, `accion_resuelta` y `accion_finalizada`. Un contexto nulo se bloquea antes de iniciar el ciclo porque no existe un objeto válido que transportar en las señales. Para cualquier contexto existente, tanto el éxito como el fallo o bloqueo producen exactamente una resolución y una finalización.

Las validaciones iniciales comprueban actor, objetivo, coordenadas requeridas, alcance y contrato del receptor. La métrica predeterminada es Manhattan para coincidir con las cuatro direcciones conectadas por el movimiento; cada contexto puede declarar otra métrica cuando su geometría lo requiere. Costes disponibles y agregación de varios receptores se incorporarán mediante contratos específicos antes de cerrar la Fase 1.

## Ciclo seguro de un paso

`Ficha.mover_por_camino()` conserva la animación y la decisión de iniciar el
siguiente tramo. Cada paso confirmado respeta este orden:

```text
reservar destino
→ completar tween
→ procesar SALIR con ocupación todavía en el origen
→ confirmar movimiento en TableroGrid
→ actualizar coordenada de la ficha
→ cobrar el coste normal del paso
→ procesar ENTRAR con ocupación confirmada en el destino
→ emitir paso_dado
→ continuar o interrumpir antes del siguiente tween
```

Los puntos `SALIR` y `ENTRAR` son callbacks síncronos coordinados por el
escenario. No abren menú ni manipulan UI. Las señales de reserva y ocupación de
`TableroGrid` son observacionales y no constituyen una segunda ruta para
ejecutar reacciones. La consulta, orden y agregación de varios receptores se
incorporarán en los siguientes incrementos de la Fase 5.

El coste normal de caminar se cobra exactamente una vez al confirmar el paso y
permanece separado de futuros costes adicionales del terreno y de las
consecuencias producidas por reacciones. Una interrupción solicitada durante
`SALIR` o `ENTRAR` nunca detiene el tween actual ni revierte la ocupación: evita
que comience el siguiente tramo.

### Consulta de reacciones de una celda

`ConsultorReaccionesCelda` obtiene fuentes compatibles sin validarlas ni
resolverlas. Consulta, en orden contractual, terreno, efectos de superficie,
interactuables, items en el suelo y ocupantes. Al consultar ocupantes excluye al
actor del evento para impedir que reaccione contra sí mismo.

Una fuente automática implementa, además del contrato receptor:

```gdscript
func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool
func obtener_id_reaccion() -> StringName
func obtener_prioridad_reaccion(tipo: TiposInteraccion.TipoAccion) -> int
```

Las fuentes con retornos inválidos o que no implementan el contrato completo se
omiten. Cada fuente aceptada produce un `ReaccionCelda` con categoría, prioridad,
ID estable y receptor. El resultado se ordena por categoría, prioridad entera
ascendente e ID estable textual. Las colecciones de la celda se consultan mediante
copias para que una mutación posterior no altere el conjunto ya obtenido.

`Celda.reaccion_terreno` representa la fuente singular asociada al terreno.
`efectos_superficie`, `interactuables`, `items_suelo` y `ocupantes` conservan sus
colecciones separadas. `Interactuable` aporta por defecto su `id_instancia` y
prioridad cero, pero no reacciona automáticamente hasta que una especialización
lo declare. La consulta no presenta UI, no cobra costes y no aplica consecuencias.

## Servicio espacial

La línea de efecto se declara mediante `TipoLineaEfecto`: `NINGUNA` no requiere servicio, `VISUAL` representa observación y luz, y `FISICA` queda preparada para herramientas, trayectorias e impactos. No se deduce únicamente del tipo de acción porque una misma acción puede dirigirse a un objetivo del mundo o a una posesión propia.

`GestorAcciones` recibe un servicio separado mediante `configurar_validador_espacial()`. Cuando el contexto requiere línea, el servicio debe cumplir:

```gdscript
func validar_linea_efecto(contexto: ContextoAccion) -> StringName
```

Devuelve `&""` si la línea está despejada o un motivo de bloqueo. La validación no modifica estado. La ausencia del servicio solo bloquea contextos que lo requieren.

`ValidadorEspacialTablero` implementa actualmente la línea `VISUAL` sobre `TableroGrid`. Usa `GeometriaGrid.trazar_linea()`, utilidad Bresenham compartida con `FOVManager`, y aplica estas reglas: origen y destino deben existir; un hueco intermedio bloquea; las celdas intermedias con bloqueo efectivo de visión bloquean; la celda de destino puede ser opaca porque debe ser posible examinar una pared. `FISICA` devuelve `linea_fisica_no_implementada` hasta definir obstáculos, alturas y colisiones apropiados.

## Servicio de costes

`GestorAcciones` recibe un servicio independiente mediante `configurar_proveedor_costes()`. Solo lo exige cuando `ContextoAccion.costes_solicitados` no está vacío. El proveedor debe cumplir:

```gdscript
func validar_costes(contexto: ContextoAccion) -> StringName
func consumir_costes(contexto: ContextoAccion) -> Variant
```

`validar_costes()` devuelve `&""` o un motivo y nunca modifica recursos. `consumir_costes()` se invoca únicamente después de una validación exitosa y devuelve los importes realmente cobrados como `Dictionary[StringName, float]`; una revalidación defensiva fallida puede devolver un `StringName` con el motivo. Los costes negativos se bloquean antes de consultar el servicio.

`PoliticaCobro.SOLO_EXITO` cobra solo un resultado `EXITO`; `AL_INTENTAR` también cobra un `FALLO` producido por el receptor. Un `BLOQUEO` nunca cobra. Para evitar mutaciones reentrantes entre validación y consumo, el cobro síncrono se confirma antes de emitir las señales finales. `accion_resuelta` transporta el resultado inmutable producido por el receptor, mientras `accion_finalizada` y el retorno de `procesar_accion()` transportan un nuevo resultado con `costes_consumidos` confirmados.

`ProveedorCostesFicha` es el primer adaptador concreto. Resuelve `contexto.actor`, exige que sea `Ficha`, soporta únicamente `&"energia"` en unidades enteras, valida `energia_actual` y descuenta exactamente el coste confirmado. Rechaza claves desconocidas para no omitir futuros costes en silencio. Un proveedor compuesto podrá distribuir más adelante las claves de turno, item e inventario sin introducir esas dependencias en `GestorAcciones`.

## Tipos iniciales de acción

```gdscript
enum TipoAccion {
	EXAMINAR,
	INTERACTUAR,
	ENTRAR,
	SALIR,
	USAR_ITEM,
	LANZAR_ITEM,
	IMPACTAR,
	RECOGER,
	SOLTAR,
	FIN_TURNO,
}
```

`INTERACTUAR` representa una acción específica publicada por el objetivo. Su `id_accion` distingue verbos de contenido como `&"accionar"`, `&"abrir"` o `&"empujar"` sin ampliar el enum central.

## Estado de resolución

```gdscript
enum EstadoResolucion {
	EXITO,
	FALLO,
	BLOQUEO,
}
```

- `EXITO`: la intención se resolvió y puede haber producido cambios o información.
- `FALLO`: se intentó resolver, pero no logró el resultado buscado. Puede consumir costes si la opción lo declara explícitamente.
- `BLOQUEO`: una precondición conocida impidió intentar la acción. No produce efectos, cambios ni costes.
- **Interrupción** no es un cuarto estado: es una consecuencia ortogonal que solicita detener una secuencia en un punto seguro. Un éxito o un fallo pueden interrumpir movimiento.

## `ContextoAccion`

Objeto inmutable desde que comienza la resolución.

| Campo | Tipo previsto | Regla |
|---|---|---|
| `tipo` | `TipoAccion` | Obligatorio. |
| `id_accion` | `StringName` | Identifica una variante de `INTERACTUAR`; vacío para tipos sin variante. |
| `actor` | `Object` | Origen responsable; puede ser `null` solo en acciones del entorno admitidas explícitamente. |
| `origen` | `Vector2i` o `null` | Celda desde la que nace la acción. |
| `celda_objetivo` | `Vector2i` o `null` | Celda a resolver. |
| `objetivo` | `Object` | Receptor concreto, si existe. |
| `item` | `Object` | Instancia utilizada o lanzada, si corresponde. |
| `etiquetas` | `Array[StringName]` | Propiedades semánticas, sin duplicados. |
| `magnitudes` | `Dictionary[StringName, float]` | Valores normalizados por clave. |
| `alcance_maximo` | `float` | Distancia permitida; negativo significa que el tipo no usa alcance. |
| `metadatos` | `Dictionary` | Extensión excepcional; no sustituye campos estables ni se usa para reglas nucleares. |
| `tipo_linea_efecto` | `TipoLineaEfecto` | `NINGUNA`, `VISUAL` o `FISICA`; declara la validación espacial requerida. |
| `costes_solicitados` | `Dictionary[StringName, float]` | Recursos que el proveedor debe validar y, si corresponde, consumir. |
| `politica_cobro` | `PoliticaCobro` | `SOLO_EXITO` o `AL_INTENTAR`; nunca permite cobrar un bloqueo. |
| `solicitud_examen` | `SolicitudExamen` o `null` | Datos tipados y opcionales de `EXAMINAR`; no se sustituyen por metadatos genéricos. |
| `id_evento` | `StringName` | Identifica el lote automático compartido; puede estar vacío cuando la acción no solicita efectos. |
| `cantidad_item` | `int` | Cantidad explícita para transferencias; `-1` significa la pila completa. |
| `id_item_resultante` | `StringName` | ID obligatorio de la nueva pila en una transferencia parcial; vacío para transferencias completas. |
| `objetivo_impacto` | `Object` o `null` | Receptor elegido para un impacto directo; `null` significa impactar contra el piso de la celda. |

El contexto se construye con copias de etiquetas, magnitudes y metadatos. Los receptores no deben modificarlo.

## `ResultadoAccion`

| Campo | Tipo previsto | Regla |
|---|---|---|
| `estado` | `EstadoResolucion` | Fuente única para éxito, fallo o bloqueo. |
| `motivo` | `StringName` | Código legible/localizable; obligatorio para fallo y bloqueo. |
| `mensajes` | `Array[StringName]` | IDs de mensajes de presentación, en orden. |
| `efectos_aplicados` | `Array` | Efectos confirmados, no propuestas. |
| `solicitudes_efecto` | `Array[SolicitudEfecto]` | Consecuencias pedidas por el receptor y todavía no confirmadas. |
| `cambios_estado` | `Array[Dictionary]` | Registro descriptivo de cambios confirmados. |
| `costes_consumidos` | `Dictionary[StringName, float]` | Energía, acciones, turnos, cargas o cantidad realmente cobrados. |
| `interrumpe_movimiento` | `bool` | Solicita detener la ruta tras el paso confirmado. |
| `terminal` | `bool` | Impide resolver reacciones posteriores del mismo evento sin revertir resultados previos. |
| `destino_item` | `DestinoItem` o `null` | Destino explícito solicitado por una reacción; `null` cuando el resultado no decide sobre una unidad. |

Las propiedades derivadas `exitosa`, `consumio_accion` y `consumio_turno` se calculan desde `estado` y `costes_consumidos`; no se almacenan como fuentes de verdad duplicadas.

Un resultado de `BLOQUEO` debe tener vacíos `efectos_aplicados`, `cambios_estado` y `costes_consumidos`. Los fallos no consumen nada por defecto. Cada coste debe declararse en la opción y cobrarse una sola vez después de resolver.

Los bloqueos tampoco interrumpen ni son terminales. Confirmar costes construye un
nuevo resultado sin perder las marcas de interrupción o terminalidad.

### Solicitudes de efecto y deduplicación

`SolicitudEfecto` describe una consecuencia pedida pero todavía no confirmada. Es
inmutable durante la agregación y contiene una `clave` semántica, `tipo`, `fuente`,
`objetivo`, `magnitud`, `duracion`, `politica_apilado` e `id_evento`. Clave, tipo e
ID de evento son `StringName`; magnitud y duración no pueden ser negativas.

La política inicial `NO_APILAR_Y_RENOVAR` identifica duplicados por evento, clave
y objetivo. Conserva la primera posición del grupo, la mayor magnitud y la mayor
duración; nunca suma estas cantidades. Claves, objetivos o eventos distintos
coexisten. Solicitudes de un mismo grupo con tipos incompatibles invalidan el lote.

`AgregadorSolicitudesEfecto` es puro: valida el lote completo antes de devolver un
`ResultadoAgregacionEfectos`, no modifica las solicitudes y no aplica consecuencias.
Un error devuelve motivo estable y ninguna salida parcial. `ResultadoAccion`
transporta estas propuestas mediante `solicitudes_efecto`; `efectos_aplicados`
continúa significando exclusivamente efectos ya confirmados.

`ResolverReaccionesCelda` asigna un mismo `id_evento` a todos los contextos del
lote. `GestorAcciones` rechaza solicitudes sin evento o atribuidas a otro evento.
Las señales `accion_resuelta` y `accion_finalizada` conservan el resultado de cada
receptor; la deduplicación entre receptores ocurre después en `ResultadoReacciones`,
que expone `solicitudes_validas`, `motivo_solicitudes` y el lote deduplicado.

### Daño instantáneo y explosión

`AplicadorEfectos` admite inicialmente solicitudes de tipo `&"dano"`. Exige
magnitud entera positiva, duración cero y un objetivo que implemente:

```gdscript
func recibir_danio(cantidad: int, fuente: Object = null) -> int
```

El retorno es el daño realmente aplicado después de limitar la vida. Una aplicación
confirmada produce `ResultadoEfectoAplicado` con clave, tipo, objetivo y magnitud
real. `Ficha` implementa este protocolo, limita sus puntos de vida a cero y emite
`puntos_vida_cambiados`; el aplicador no conoce UI, muerte, armadura ni combate.

`ResultadoReacciones` valida primero todas las solicitudes de daño admitidas y solo
después las aplica en el orden deduplicado. Las solicitudes de tipos todavía no
implementados permanecen pendientes. Expone `efectos_validos` y `motivo_efectos` y
agrega únicamente aplicaciones confirmadas a `efectos_aplicados`.

`Explosion.crear_solicitudes()` es una consecuencia instantánea: recorre un radio
Manhattan, crea una solicitud `&"explosion"`/`&"dano"` por ocupante capaz de recibir
daño y no crea nodos ni superficies. Dos explosiones con el mismo evento y objetivo
se reducen mediante la política inicial antes de modificar vida.

`TerrenoDanino` conecta terrenos persistentes al mismo canal. Al `ENTRAR` solicita
daño instantáneo con una clave estable y deja su aplicación a `AplicadorEfectos`.
La lava usa magnitud dos y mantiene separada su penalización de pathfinding; `Celda`
ya no conserva un diccionario provisional de daño.

### Estados y veneno

`EstadoActor` conserva una única instancia por clave con magnitud, duración total y
ticks pendientes. `Ficha.aplicar_o_renovar_estado()` crea o renueva mediante máximos
y emite `estado_cambiado`; no avanza turnos ni expira estados.

La configuración inicial de `&"veneno"` es magnitud `1` y dos ticks. Crearlo o
renovarlo no causa daño inmediato: conserva ambos ticks para futuros `FIN_TURNO`.
`&"quemado"` mantiene su daño inicial al prenderse y registra únicamente los ticks
posteriores. El debuff adicional todavía no forma parte del contrato.

Una aplicación confirmada de estado agrega su mensaje y cambio descriptivo a
`ResultadoReacciones`; como las solicitudes se deduplican antes, superficies
superpuestas no duplican el estado, el daño inicial ni el mensaje. `&"quemado"`
usa el mismo contrato: tres ticks totales de un punto, el primero inmediato y dos
pendientes; renovar no repite el daño inmediato.

### Fin de turno y expiración de quemado

`ServicioTurnos.avanzar_turno()` es la fuente explícita inicial de avance lógico.
Construye un `ContextoAccion` automático `FIN_TURNO` y lo procesa mediante
`GestorAcciones`; el gestor permanece ajeno a estados concretos. En 11.1 procesa
únicamente `quemado` sobre el actor recibido.

`EstadoActor.ticks_pendientes` es el único contador operativo. `duracion_total`
permanece como dato descriptivo y no se decrementa. Cada fin de turno prevalida el
daño, lo aplica mediante `AplicadorEfectos`, consume un tick y elimina el estado de
`Ficha` al llegar a cero. Llegar a cero puntos de vida no detiene ese consumo.

El `ResultadoAccion` incluye el `ResultadoEfectoAplicado` confirmado y un cambio
`estado_tick` con clave, ticks restantes y marca de expiración. Finalizar un turno
sin `quemado` es un éxito vacío. La UI, las superficies y el tiempo real no forman
parte de este flujo.

Desde 11.2 el actor expone copias de sus claves de estado ordenadas léxicamente y
el servicio procesa `quemado` y `veneno` en ese orden estable. Prevalida todas las
claves, estados y solicitudes de daño antes de aplicar el primer efecto; una clave
desconocida bloquea el lote sin daño ni consumo de ticks. Cada estado conserva su
propio contador y expira independientemente dentro del mismo `ResultadoAccion`.

### Resolución y agregación de reacciones

`ResolverReaccionesCelda` recibe la lista ya ordenada, crea un `ContextoAccion`
automático dirigido a cada receptor y lo entrega a `GestorAcciones`. No abre menú
ni presenta resultados. Un mismo objeto receptor se procesa como máximo una vez
por evento, aunque aparezca repetido en la lista.

`ResultadoReacciones` conserva los resultados individuales y agrega, en orden,
mensajes, solicitudes, efectos confirmados y cambios de estado. Al finalizar el
evento deduplica las solicitudes antes de exponerlas. Los costes confirmados con la
misma clave se suman; `interrumpe_movimiento` y `terminal` se combinan mediante OR.
Un resultado terminal detiene receptores posteriores, pero conserva todo lo ya
confirmado.

`EscenarioBase` usa este flujo en los callbacks seguros de cada paso: consulta el
origen para `SALIR`, el destino para `ENTRAR` y solicita a `Ficha` la interrupción
agregada. La decisión se aplica después del paso actual y antes del siguiente
tween. Las reacciones automáticas atraviesan así el mismo gestor lógico que las
acciones voluntarias, sin construir opciones ni usar el menú contextual.

### Efectos de superficie colocados

Las zonas organizan estas entidades bajo un nodo `EfectosSuperficie`, separado de
`Interactuables`. Cada instancia pertenece al grupo Godot
`&"efectos_superficie"`, declara un ID estable y se registra por coordenada en
`Celda.efectos_superficie`. El grupo facilita el descubrimiento al cargar la zona;
la categoría mecánica procede del registro en la celda.

La primera instancia es `HumoVeneno`. Su representación es un `Sprite2D` al nivel
visual de la celda y su reacción automática a `ENTRAR` solicita el estado veneno e
interrumpe. No usa colisiones, `Area2D`, señales físicas ni menú contextual. El
mensaje y cambio se registran únicamente después de aplicar el estado deduplicado.

`Fuego` sigue el mismo contrato de superficie sin depender de una trampa concreta.
Al `ENTRAR` solicita `quemado`, añade uno al coste bajo la familia `&"fuego"` y
declara siete turnos de duración. Fuego y humo pueden coexistir y aplicar sus dos
estados; varias instancias de una misma familia producen una sola solicitud lógica
por objetivo y evento.

### Coste de un paso y peso de ruta

`Celda.calcular_coste_movimiento(actor)` compone el coste entero del paso como
`1 + adicional del terreno + adicionales lógicos de superficies`. El adicional del
terreno se carga desde el dato de tile `coste_movimiento_adicional`. Una
superficie puede aportar un entero no negativo mediante
`obtener_coste_movimiento_adicional(actor)`; no necesita implementar este método
si no modifica el coste. `HumoVeneno` aporta inicialmente `1`, por lo que entrar
en su celda cuesta `2`.

Una superficie puede declarar `obtener_familia_superficie() -> StringName`. La
celda conserva el mayor aporte de cada familia y suma familias distintas. Las
superficies sin familia se consideran contribuciones independientes para mantener
compatibilidad. Dos nubes `&"humo_veneno"` superpuestas cuestan una sola unidad
adicional; humo y fuego sí pueden sumar costes diferentes.

`TableroGrid.retirar_efecto_superficie()` elimina únicamente la instancia indicada
del registro global y de su celda y emite `efecto_superficie_retirado`. No libera el
nodo: la entidad propietaria conserva el control de su representación. Si queda otra
instancia de la misma familia, su contribución mecánica continúa activa.

### Bloqueo visual de superficies

`Celda.bloquea_vision_efectiva()` combina con OR el bloqueo propio del terreno y
el declarado por cada superficie activa mediante `bloquea_vision_superficie()`.
`FOVManager` y `ValidadorEspacialTablero` consultan esta única fuente. El FOV se
recalcula al registrar o retirar una superficie; por ello, dos bloqueos
superpuestos permanecen activos hasta retirar el último.

`Humo` bloquea visión y declara una duración de superficie de diez turnos. El valor
queda disponible desde `obtener_duracion_superficie()`; su decremento y expiración
pertenecen a la fuente de turnos de la Fase 11. `HumoVeneno` aplica veneno y coste
de movimiento, pero no bloquea visión: toxicidad y opacidad son propiedades
independientes.

La ficha calcula y valida ese total antes de reservar el destino o iniciar el
tween. Si no dispone de energía suficiente, permanece en el origen y no reserva
ni consume. El coste se descuenta una sola vez después de confirmar la ocupación
del destino y antes de resolver `ENTRAR`. Un coste mayor que `1` duplica la
duración del tween del paso, equivalente a caminar a la mitad de velocidad; no se
interrumpe nunca una animación entre celdas.

`Celda.calcular_peso_ruta(actor)` suma al coste de movimiento una
`penalizacion_peligro_ruta` no negativa. Esta penalización orienta el pathfinding
sin cobrar energía: la lava conserva un peso total alto mientras su daño se aplica
por separado como reacción de terreno. Veneno, quemado y otros estados tampoco se
modelan como costes de desplazamiento.

### Recursos separados del turno

`RecursosTurnoActor` conserva para una `Ficha` cuatro reservas independientes:
`movimiento`, `accion_principal`, `accion_adicional` y `reaccion`. Sus valores
iniciales configurables son `7`, `1`, `1` y `1`; reponer el turno restaura máximos,
no energía persistente ni usos por descanso. `ProveedorCostesFicha` valida y cobra
estas claves mediante el mismo diccionario de costes ya usado por `GestorAcciones`.

Cada paso confirmado consume de `movimiento` el coste real de la celda y continúa
consumiendo `energia_actual` según la regla histórica. Fuera de combate, una ruta
que agota movimiento ejecuta un `FIN_TURNO`, repone recursos y continúa sólo si el
actor sigue vivo. En combate la ruta se detiene y no inicia otro turno.

La previsualización de combate recorta la ruta por la suma de costes reales, no por
cantidad de celdas. En exploración muestra la ruta completa que podrá encadenar
turnos. El modo combate permanece como estado explícito del escenario; su activación
jugable, destrabarse, descansos y usos especiales todavía no se implementan.

### Iniciativa y rondas

Cada `Ficha` declara un `id_actor` estable separado de `id_observador` y una
`iniciativa_base` entera. `GestorRondas` prevalida la lista completa, rechaza IDs
vacíos o duplicados y ordena por iniciativa descendente, desempatando por el texto
del ID estable. La lista no cambia durante la ronda inicial.

Al comenzar, el primer actor vivo repone sus recursos. Finalizar el turno procesa
sus estados mediante `ServicioTurnos`, selecciona el siguiente actor vivo y repone
únicamente los recursos de éste. Pasar desde el final del orden al principio aumenta
la ronda; los actores sin vida se omiten sin reordenar a los restantes. Si ninguno
puede actuar, no queda actor activo.

Cada transición devuelve `ResultadoAvanceTurno` con ronda, actor finalizado, actor
activo siguiente, marca de nueva ronda y el `ResultadoAccion` de `FIN_TURNO`.
Un fallo al procesar estados conserva el actor activo y no avanza el orden. IA, UI
de iniciativa, sorpresa, retrasar turno e incorporación o salida dinámica quedan
fuera de 11.4.

### Trampas que despliegan superficies

`TrampaSuperficie` es un interactuable únicamente automático: participa en la
categoría `INTERACTUABLE` al resolver `ENTRAR`, pero devuelve cero opciones
voluntarias. Por ello no puede seleccionarse, resaltarse ni examinarse a distancia
desde el menú contextual. La inspección adyacente y el desarme quedan fuera de
este incremento.

Cada instancia configura una `PackedScene` de superficie y un radio entero. Las
trampas son de un solo uso. Al activarse, `TableroGrid` instancia la superficie sobre las
celdas caminables comprendidas por distancia Manhattan, le asigna un ID estable,
la coloca bajo `EfectosSuperficie` y la registra en la celda correspondiente. El
resultado informa esos cambios e interrumpe la ruta después de que la ficha haya
terminado el tween y confirmado su ocupación.

Desde 9.2 una trampa armada también publica reacción automática a `IMPACTAR` cuando
el contexto transporta un item con la etiqueta `&"impacto"`. Esto se aplica aunque
la trampa esté oculta y se haya elegido el piso: el impacto pertenece a toda la
celda. Reutiliza sin duplicación el mismo despliegue de superficie y la misma cadena
cardinal de `ENTRAR`. La trampa no declara `destino_item`; la unidad lanzada conserva
por defecto `DEJAR_EN_CELDA`.

La consulta de reacciones usa una instantánea: el humo creado sobre la celda de
la trampa no se ejecuta retroactivamente en el mismo evento `ENTRAR`. Sí modifica
el coste y reacciona en entradas posteriores. Una explosión instantánea permanece
como consecuencia separada y nunca se registra como superficie.

La presentación visual es independiente de la reacción y admite `OCULTA`,
`INDICIO` y `VISIBLE`. `OCULTA` transparenta el sprite; `INDICIO` usa el sprite creado
con opacidad reducida; `VISIBLE` lo muestra completo. Estos estados no conceden
por sí mismos opciones de interacción ni conocimiento al actor.

El atlas inicial usa celdas de `64×32`: la primera columna representa la placa
armada y la segunda la placa presionada. `INDICIO` usa alpha `0.7`, `OCULTA`
alpha `0.0` y `VISIBLE` alpha `1.0`. Activar la trampa cambia la región del sprite
sin intervención de la UI.

Una trampa consultada incluye también las trampas cardinalmente adyacentes que
puedan reaccionar a `ENTRAR`. La consulta expande toda la componente conectada,
ordena los receptores con las reglas normales y evita ciclos por identidad. El
resolver entrega cada receptor una sola vez al mismo `GestorAcciones`; cada trampa
despliega su propia superficie. La adyacencia diagonal no inicia ni prolonga una
cadena.

## Items e inventario mínimo

`DefinicionItem` es un `Resource` compartido que declara `id_definicion`, `nombre`,
etiquetas semánticas, magnitudes, si admite apilado y su cantidad máxima. Una
definición no apilable exige cantidad máxima uno. Las magnitudes deben ser finitas;
solo `temperatura` admite valores negativos. Peso, capacidad de carga, cargas y
durabilidad se incorporarán cuando exista una regla que los consuma.

`ItemInstancia` representa una pila lógica con `id_instancia`, definición y
cantidad. La pila posee la identidad; sus unidades internas no tienen IDs
individuales. El ID permanece estable mientras exista la pila y la cantidad debe
estar entre uno y el máximo de su definición.

`Inventario` es un componente lógico `RefCounted` contenido por `Ficha`. En 7.1 no
tiene límite: la capacidad futura se calculará mediante peso y fuerza. Conserva
instancias únicas por ID, devuelve copias ordenadas de su contenido y permite
consultar por ID de instancia o definición.

Agregar una instancia nunca la apila automáticamente. `combinar()` es explícito,
exige la misma definición apilable y rechaza por completo una suma superior al
máximo; la pila destino conserva su ID y la de origen desaparece. `separar()` exige
una cantidad menor que la original y un ID nuevo aportado por el llamador; la pila
original conserva su identidad. Un retiro total devuelve la misma instancia; un
retiro parcial produce otra instancia con ID explícito.

Todas las operaciones validan completamente antes de modificar el contenido y
devuelven `ResultadoOperacionInventario`. Un fallo no contiene transferencia
parcial y deja intactos contenido, cantidades e identidades. En 7.1 no se emiten
señales ni se registran items en celdas.

### Presencia lógica en el suelo

`ItemSuelo` es un contenedor lógico `RefCounted`, no una representación visual.
Conserva una `ItemInstancia` y adquiere una coordenada únicamente mientras está
registrado. La futura escena o sprite observará este estado, pero nunca será la
fuente de verdad mecánica.

Desde 7.6 puede vincular temporalmente una representación `Node2D`. El escenario
la instancia desde `DefinicionItem.escena_mundo` al registrarse y la elimina al
retirarse; coordenada, identidad y cantidad continúan perteneciendo al modelo
lógico. El selector incluye items mediante el mismo protocolo por comportamiento
que los interactuables.

`TableroGrid` es la autoridad de registro mediante `items_suelo_por_id`. La misma
referencia de `ItemSuelo` aparece exactamente una vez en el índice global y en
`Celda.items_suelo`. Registrar valida por completo antes de añadir y ordena la celda
por ID de instancia. Retirar exige que índice, coordenada y referencia de celda
coincidan; un objeto diferente con el mismo ID no puede retirar el original.

Una celda solo debe existir para aceptar contenido colocado. Caminabilidad,
ocupantes y reservas no restringen el registro general: son precondiciones de la
acción futura `SOLTAR`. Regenerar el tablero invalida las coordenadas anteriores y
vacía todos los registros sin depender de nodos visuales.

### Recoger

`ItemSuelo` publica `RECOGER` y cumple el protocolo receptor, pero delega la
operación en un `TransferidorItems` compartido. El contexto conserva como objetivo
el contenedor del suelo y como `item` su misma `ItemInstancia`; declara alcance
Manhattan uno, línea de efecto `NINGUNA` y ningún coste.

`TransferidorItems` valida actor, inventario, identidad del contexto y registro
exacto en `TableroGrid`. La transferencia es síncrona: agrega primero la instancia
al inventario, la retira después del tablero y solo entonces devuelve éxito. Como
el inventario no emite señales, ningún observador puede ver el estado intermedio.
Si el retiro falla inesperadamente, se retira inmediatamente la misma instancia del
inventario y se devuelve `FALLO`; el item permanece únicamente en el suelo.

Una recogida confirmada conserva referencia, ID y cantidad y registra un cambio
`&"item_recogido"`. Un segundo intento se bloquea porque el contenedor ya no está
registrado. `GestorAcciones` continúa completamente ajeno a estas reglas.

### Soltar

`TransferidorItems` recibe `SOLTAR` directamente. El contexto transporta una pila
completa propiedad del inventario del actor, usa el transferidor como objetivo y
declara alcance Manhattan uno. En 7.4 no admite cantidades parciales.

La celda destino debe existir, ser caminable y no contener ocupantes ni reservas
distintos del actor. La ficha puede soltar en su propia celda porque su ocupación y
reserva no se consideran obstáculos ajenos. Estas restricciones pertenecen a la
acción, no al registro general de contenido colocado.

La transferencia retira primero la misma `ItemInstancia` del inventario y registra
después un nuevo `ItemSuelo` que la contiene. Si el registro falla, agrega de nuevo
la instancia original al inventario antes de devolver `FALLO`. El éxito conserva
referencia, ID y cantidad y registra un cambio `&"item_soltado"` con la coordenada
confirmada.

### Transferencias parciales

`RECOGER` y `SOLTAR` usan `ContextoAccion.cantidad_item`; `-1` o la cantidad total
transfieren la pila original y exigen `id_item_resultante` vacío. Una cantidad
parcial debe ser positiva, menor que la disponible, pertenecer a una definición
apilable y declarar un ID resultante nuevo y no duplicado.

La pila origen conserva su ID y reduce su cantidad. La porción transferida recibe
el nuevo ID y no se combina automáticamente. Una recogida parcial mantiene el
origen registrado en la celda; un soltado parcial mantiene el origen en inventario
y registra únicamente la nueva instancia en el suelo. Ante un fallo de registro,
el inventario vuelve a agregar y combinar explícitamente la porción para recomponer
la cantidad e identidad originales.

### Usar item — incremento 8.1

`ConstructorContextoAccion` recibe opcionalmente la instancia seleccionada. Para
`USAR_ITEM`, el objetivo construye un contexto que conserva esa misma referencia,
copia `DefinicionItem.etiquetas` y `DefinicionItem.magnitudes`, declara una unidad,
alcance Manhattan uno y línea de efecto `NINGUNA`.

El receptor revalida inmediatamente antes de resolver que la misma referencia siga
registrada bajo su ID en el inventario del actor y que las capacidades del contexto
coincidan con la definición. `GestorAcciones` no conoce inventarios ni combinaciones.
En 8.1 el item siempre se conserva; consumo, cargas y durabilidad quedan fuera hasta
que exista su contrato atómico.

### Selector provisional de item — incremento 8.2

Un `Interactuable` publica `Usar item…` cuando el actor expone un inventario no
vacío. Elegirla reutiliza `MenuContextualInteracciones` para mostrar todas las pilas
en el orden estable del inventario, con nombre, cantidad cuando supera uno e icono
opcional tomado de `DefinicionItem`. No se filtran compatibilidades: el receptor
decide la reacción después de la selección.

La vista continúa definida por su escena y por el `Theme` normal de Godot; los
botones heredan ese estilo y aceptan las texturas de contenido sin introducir una
UI definitiva de inventario. Cancelar cierra el flujo modal completo. En 8.2 no se
elige cantidad ni se consume el item; el futuro consumo reutilizará esta misma
instancia seleccionada.

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

### Lanzamiento lógico — incremento 9.1

`TransferidorItems` recibe `LANZAR_ITEM`, revalida que la misma instancia continúe
en el inventario y exige la etiqueta `&"arrojable"`. El contexto transporta una
unidad, copia las etiquetas y magnitudes de la definición y agrega `&"impacto"`.
En 9.1 el alcance provisional se recibió como Manhattan; trayectoria y línea física
todavía no formaban parte de ese incremento. La corrección posterior descrita en 9.4
lo sustituyó por métrica de cuadrícula para los lanzamientos.

La celda destino debe existir. `objetivo_impacto = null` representa elegir el piso;
un objetivo explícito debe pertenecer a las reacciones `IMPACTAR` de esa celda. El
objetivo directo se resuelve primero y las restantes fuentes conservan después su
orden contractual. Ningún receptor se procesa dos veces.

`DestinoItem` contiene `CONSERVAR_EN_INVENTARIO`, `CONSUMIR` y
`DEJAR_EN_CELDA`. El primer destino explícito según el orden de resolución
prevalece; si ninguna reacción declara uno, lanzar usa `DEJAR_EN_CELDA`. Una pila
de varias unidades conserva su identidad y exige `id_item_resultante` para la
unidad separada. Una pila de una unidad puede trasladar la misma instancia.

La confirmación ocurre después de resolver el impacto. Un bloqueo previo mantiene
el inventario intacto. Para dejar caer, el transferidor retira primero la unidad y
registra después el `ItemSuelo`; si el registro falla, recompone cantidad e
identidad mediante el mismo rollback de las transferencias parciales. No existe
rollback general de cambios arbitrarios producidos por las reacciones.

### Selección provisional de lanzamiento — incremento 9.2

La tecla provisional `L` reutiliza `MenuContextualInteracciones` y muestra solo
pilas cuya definición contiene `&"arrojable"`. Tras elegir una pila, el menú se
cierra y una celda es seleccionable si está visible, existe y queda dentro del
alcance provisional de cinco celdas. Desde la corrección posterior a 9.4, ese radio
usa métrica de cuadrícula y no penaliza dos veces los pasos diagonales.

Si la celda no contiene receptores `IMPACTAR` con nombre presentable, el flujo elige
el piso automáticamente. Si contiene uno o más, el menú muestra siempre `Piso`,
cada receptor en el orden de reacción y `Cancelar`; por tanto, incluso un único
objetivo nunca se selecciona automáticamente. Cancelar abandona el flujo completo
sin construir un contexto.

La integración proporciona un ID nuevo únicamente para separar una pila de varias
unidades y comprueba que no exista en el inventario ni en el suelo. La vista sigue
definida por la escena, los iconos y el `Theme` existentes. Inventario definitivo,
trayectoria, previsualización y animación quedan fuera de 9.2.

### Trayectoria y primera colisión — incremento 9.3

`ValidadorEspacialTablero.resolver_trayectoria_lanzamiento()` recorre la línea
discreta de `GeometriaGrid` y es la única fuente para la previsualización y la
resolución de `LANZAR_ITEM`. Mantiene separados cuatro datos: si se alcanzó la
celda solicitada, si hubo colisión, la celda que recibe `IMPACTAR` y la celda donde
queda una unidad superviviente.

Una celda bloquea proyectiles si su altura es 2 o superior o si alguno de sus
interactuables declara `bloquea_proyectiles_interactuable()`. La puerta devuelve
`true` cerrada y `false` abierta. Los efectos de superficie no bloquean por defecto:
humo, agua o lava sólo cambiarán esta regla si una mecánica concreta lo requiere.

La primera celda bloqueante recibe las reacciones `IMPACTAR`. Si el resultado es
`DEJAR_EN_CELDA`, la unidad se registra en la última celda libre anterior; si no hay
obstáculo, impacto y caída coinciden con el destino solicitado. Un objetivo directo
seleccionado sólo conserva prioridad cuando esa misma celda es la alcanzada; una
colisión anterior lo descarta. `CONSUMIR` y `CONSERVAR_EN_INVENTARIO` mantienen sus
contratos de 9.1.

Las reacciones de impacto distinguen dos admisiones. `reacciona_automaticamente()`
describe consecuencias de celda que ocurren incluso al elegir el piso, como una
trampa oculta. `admite_reaccion_dirigida()` describe receptores que sólo participan
si fueron elegidos, como una palanca. La UI puede descubrir ambos, pero el consultor
sólo incorpora una reacción dirigida a la resolución cuando ese receptor es el
`objetivo_impacto`. La palanca reutiliza el mismo cambio de estado de su interacción
manual y una piedra que sobreviva cae normalmente.

La escena provisional dibuja un `Line2D` recto entre los centros isométricos del
actor y la celda real devuelta por ese cálculo. Verde indica llegada despejada;
naranja indica colisión o truncamiento por alcance. El selector existente marca la
celda real. Esta línea no representa todavía tiempo de vuelo ni anima un proyectil.

### Representación temporal del vuelo — incremento 9.4

Al confirmar el objetivo, la escena conserva el `ContextoAccion` sin procesarlo e
instancia temporalmente `DefinicionItem.escena_mundo`. Un `Tween` desplaza esa
representación por las celdas del `recorrido` calculado por 9.3; la duración por
celda es una propiedad exportada de la escena. No existe una segunda trayectoria
visual ni se recalculan obstáculos desde la animación.

Mientras el vuelo está activo, el escenario mantiene el estado modal y la instancia
permanece sin cambios en el inventario. Al finalizar se oculta y libera la
representación temporal y recién entonces `GestorAcciones` procesa el contexto. Por
lo tanto, cualquier bloqueo o fallo tardío conserva la pila, y un éxito aplica una
sola vez `IMPACTAR` y el destino final de la unidad. La representación persistente
de un eventual `ItemSuelo` continúa naciendo exclusivamente del registro lógico del
tablero.

Si el item no declara `escena_mundo`, el contexto se procesa inmediatamente: la
ausencia de un asset visual no cambia la mecánica. Este incremento no incorpora
parábolas, rebotes, rotación, desviación ni efectos particulares por definición.

El alcance de lanzamiento usa `MetricaAlcance.CUADRICULA`: la distancia es
`max(abs(dx), abs(dy))`, de modo que avanzar una celda diagonal o cardinal consume
un paso. `ContextoAccion` declara la métrica y `GestorAcciones` la aplica sin conocer
el tipo concreto de acción. Las interacciones existentes conservan Manhattan por
defecto, por lo que una palanca manual continúa exigiendo adyacencia cardinal.

### Alcance según fuerza — incremento 9.5

Un actor capaz de lanzar expone `obtener_fuerza()` como entero no negativo. El
alcance máximo se calcula una sola vez mediante `max(2, 1 + fuerza)` y usa la métrica
de cuadrícula de 9.4. `TransferidorItems.construir_contexto_lanzar()` obtiene el dato
del actor; los llamadores ya no proporcionan un alcance arbitrario.

El escenario consulta al mismo transferidor para validar la celda y dibujar la
previsualización. Antes de resolver, el transferidor recalcula la fuerza y exige que
coincida con el valor inmutable del contexto. Un actor sin el contrato, con un valor
no entero o negativo produce `actor_sin_fuerza`; una discrepancia produce
`alcance_lanzamiento_incoherente`, siempre antes de retirar la unidad.

El peso del item continúa transportándose como magnitud del impacto, pero no altera
el alcance en este incremento. Su interacción con fuerza se definirá únicamente si
el diseño necesita diferenciar objetos arrojables por masa.

### Consecuencia propia del item — incremento 9.6

`DefinicionItem.reaccion_impacto` es opcional. Si existe, debe ofrecer
`validar_impacto()` y `resolver_impacto()`; `TransferidorItems` las invoca sobre la
celda real de caída después de resolver `IMPACTAR`. La ausencia de reacción mantiene
el comportamiento anterior. `GestorAcciones` permanece ajeno a definiciones concretas.

`ReaccionImpactoSuperficie` valida primero tablero, contenedor, celda caminable e ID
de efecto. Al resolver reutiliza `TableroGrid.desplegar_efecto_superficie()` y declara
`CONSUMIR`. Como se agrega después de las reacciones de la celda, conserva la regla
general de 9.1: un destino explícito anterior prevalece.

La definición `bomba_humo` configura esta reacción con radio cero y la escena neutral
`Humo`. Por tanto, una unidad se rompe y despliega una nube en su celda de caída; no
queda `ItemSuelo`. La nube pertenece a la familia `&"humo"`, bloquea visión, declara
diez turnos de duración y no bloquea trayectoria de proyectiles. Su atlas visual tiene
cuatro cuadros de `64×64`; la definición todavía no requiere icono de inventario.

## Relaciones de mecanismo — incremento 10.1

Una relación inicial conecta una palanca con un único interactuable mediante el
`id_instancia` estable del receptor. La resolución reutiliza
`TableroGrid.obtener_interactuable()`; no guarda `NodePath`, no busca por nombre de
nodo y no introduce un bus global.

La palanca transmite el nuevo estado lógico deseado como `bool`. Es una operación
idempotente para el receptor: no significa «alternar» ni contiene órdenes como
«abrir puerta». Antes de cambiar su propio estado, la palanca exige que el receptor
exista y cumpla por comportamiento:

```gdscript
func validar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> StringName
func aplicar_cambio_mecanismo(
	id_emisor: StringName,
	activa: bool
) -> ResultadoAccion
```

La primera puerta receptora interpreta `activa` como `abierta`. Su definición usa
`ModoControl.MECANISMO`, por lo que no publica `Abrir`, `Cerrar` ni `Usar item…` y
rechaza esas acciones aunque exista una llave compatible. Las puertas existentes
con `ModoControl.MANUAL_CON_CERRADURA` conservan el flujo de llave y apertura manual
y rechazan señales de mecanismo.

Una referencia vacía mantiene una palanca autónoma. Una referencia no vacía pero
inexistente, un receptor incompatible o un contrato inválido bloquean la acción
antes de modificar palanca o puerta. Al tener éxito, el `ResultadoAccion` agrega los
cambios de ambas instancias. `GestorAcciones` solo procesa la acción original y no
conoce la relación ni las clases concretas.

10.1 no define listas de receptores, combinación de emisores, inversión, retardos,
temporizadores ni persistencia adicional. Esas capacidades requieren casos e
incrementos propios.

### Varios receptores — incremento 10.2

Una palanca declara `ids_receptores_mecanismo: Array[StringName]`. La lista vacía
mantiene el comportamiento autónomo. Para una lista configurada, la palanca trabaja
sobre una copia ordenada por ID estable y rechaza antes de cualquier mutación:

- IDs vacíos o repetidos.
- IDs inexistentes en `TableroGrid`.
- Receptores sin ambos métodos del protocolo.
- Validaciones que no devuelven `StringName` o devuelven un motivo.

Solo después de prevalidar el lote completo se aplica sincrónicamente el mismo estado
neutral a cada receptor. Los mensajes y cambios se agregan en el orden estable de los
IDs; el cambio de la palanca se presenta primero. La aplicación posterior a una
validación correcta forma parte del contrato del receptor y no introduce un protocolo
genérico de rollback mientras la resolución permanezca síncrona.

Dos orientaciones visuales de una puerta pueden usar definiciones distintas con el
mismo receptor lógico. La orientación pertenece al `Resource` y no modifica la señal
ni el código de la puerta.

## `OpcionAccion`

| Campo | Tipo previsto | Regla |
|---|---|---|
| `id` | `StringName` | ID estable dentro del proveedor. |
| `tipo` | `TipoAccion` | Tipo que construirá el contexto. |
| `texto` | `StringName` | ID localizable de la etiqueta visible. |
| `objetivo` | `Object` | Receptor concreto. |
| `habilitada` | `bool` | Estado informativo para el menú; se revalida al ejecutar. |
| `motivo_bloqueo` | `StringName` | Obligatorio si está deshabilitada. |
| `secreta` | `bool` | Si es verdadera, se omite hasta ser descubierta. |
| `costes_previstos` | `Dictionary[StringName, float]` | Costes que la UI puede anticipar. |
| `prioridad` | `int` | Orden dentro del menú; menor se muestra primero. |
| `metadatos` | `Dictionary` | Datos de presentación no nucleares. |
| `tipo_linea_efecto` | `TipoLineaEfecto` | Requisito espacial que se copia al contexto al elegir la opción. |
| `politica_cobro` | `PoliticaCobro` | Determina si los costes previstos se cobran solo al tener éxito o también al fallar después de intentarlo. |

`Cancelar` pertenece al menú y no se representa como una acción resoluble. Nunca genera contexto ni coste.

## Etiquetas semánticas iniciales

Las etiquetas describen capacidades observables, no nombres de objetos ni parejas específicas.

- Sustancias: `&"agua"`, `&"fuego"`, `&"liquido"`, `&"aceite"`.
- Naturaleza física: `&"solido"`, `&"contundente"`, `&"cortante"`, `&"perforante"`, `&"inflamable"`, `&"fragil"`.
- Capacidades: `&"arrojable"`, `&"herramienta"`, `&"llave"`, `&"fuente_luz"`.
- Eventos o fuerzas: `&"impacto"`, `&"calor"`, `&"frio"`, `&"electricidad"`, `&"peso"`, `&"presion"`.

Para agregar una etiqueta debe existir al menos un emisor y un receptor actuales o planificados, su significado no debe solaparse con otra etiqueta, y debe documentarse aquí. No se admiten IDs de instancia (`llave_puerta_cripta`) ni resultados (`abre_puerta`) como etiquetas.

## Magnitudes

Las magnitudes usan `float`, unidades canónicas del juego y claves `StringName`: `&"peso"`, `&"volumen"`, `&"intensidad"`, `&"temperatura"`, `&"potencia"`, `&"fuerza_impacto"` y `&"distancia"`.

- Peso y volumen son valores no negativos en unidades abstractas del juego.
- Intensidad, potencia y fuerza de impacto son escalas no negativas; cero significa ausencia.
- Temperatura se expresa en grados Celsius para evitar escalas relativas ambiguas.
- Distancia se mide en celdas y puede ser fraccionaria durante cálculos, aunque el tablero use `Vector2i`.
- La ausencia de una magnitud significa “no aportada”; no equivale a cero.

## Validación, prioridad y agregación

La resolución es determinista y conserva este orden:

1. Validaciones estructurales: tipo, actor permitido y objetivo/celda requeridos.
2. Validaciones espaciales: existencia de celda, alcance y línea de efecto.
3. Requisitos del receptor y disponibilidad de costes.
4. Reacciones de terreno.
5. Reacciones de efectos de superficie.
6. Reacciones de interactuables.
7. Reacciones de items en el suelo.
8. Reacciones de ocupantes.
9. Aplicación de efectos y cambios en el mismo orden.
10. Cobro de costes una sola vez y emisión del resultado agregado.

Dentro de una categoría, cada reacción declara una prioridad entera ascendente y se desempata por ID estable. Nunca se usa el orden incidental de nodos o diccionarios.

Un `BLOQUEO` durante las validaciones 1 a 3 termina el flujo sin mutaciones. Durante la resolución, los resultados se agregan concatenando mensajes, efectos y cambios en orden; los costes iguales se suman; `interrumpe_movimiento` usa OR. Una reacción puede marcar el resultado como terminal para impedir reacciones posteriores, pero las consecuencias ya confirmadas se conservan.

## Niveles de información de Examinar

```gdscript
enum NivelInformacion {
	VISIBLE,
	BASICO,
	DETALLADO,
	SECRETO,
}
```

- `VISIBLE`: rasgos evidentes sin examen activo.
- `BASICO`: identidad y función aparente obtenibles en condiciones normales.
- `DETALLADO`: estado mecánico o propiedades que exigen percepción, herramienta o condiciones mejores.
- `SECRETO`: información oculta que requiere una condición explícita de descubrimiento.

Descubrir un nivel incluye los inferiores. Los descubrimientos persistentes se registrarán por ID estable del objetivo y por fragmento de información; mejorar temporalmente las condiciones no revela automáticamente secretos.

La progresión de conocimiento no obliga a presentar un mensaje separado por cada
nivel accesible. Como regla de autoría, `VISIBLE` se reserva principalmente para el
reconocimiento pasivo del mundo. Cuando el rasgo evidente y la identidad básica
describen el mismo tema, `BASICO` debe integrarlos en un único fragmento narrativo.
Así se evita repetir dos frases al examinar desde lejos sin eliminar la distinción
conceptual entre percepción pasiva y examen activo.

### Fragmentos de información examinable

La información destinada al jugador se define mediante `FragmentoInformacion`, un
`Resource` reutilizable que describe contenido narrativo y no expone propiedades
internas del receptor.

| Campo | Tipo | Regla |
|---|---|---|
| `id_fragmento` | `StringName` | ID estable dentro de una definición; obligatorio y único. |
| `nivel` | `NivelInformacion` | Clasifica el fragmento como `VISIBLE`, `BASICO`, `DETALLADO` o `SECRETO`. |
| `id_mensaje` | `StringName` | ID de presentación localizable; obligatorio. |
| `pistas_requeridas` | `Array[StringName]` | Condiciones semánticas explícitas necesarias para descubrirlo. No admite valores vacíos ni duplicados. |
| `se_recuerda` | `bool` | Indica si el descubrimiento debe incorporarse al conocimiento del observador. |

Los fragmentos `SECRETO` deben declarar al menos una pista. Una pista describe una
condición de dominio, por ejemplo `&"marca_oculta_revelable"`; no identifica la
variable, habilidad, herramienta o sistema que la produjo. Los estados transitorios,
como que una llama esté encendida en este momento, pueden representarse mediante un
fragmento con `se_recuerda = false`.

`DefinicionInteractuable` conserva los fragmentos reutilizables del tipo. Dos
instancias que comparten definición ofrecen los mismos fragmentos candidatos, pero
su estado observable y el conocimiento registrado permanecen separados.

### Condiciones de una observación

`CondicionesObservacion` es un contrato inmutable que transporta únicamente hechos
de la observación actual:

| Campo | Tipo | Regla |
|---|---|---|
| `observador` | `Object` | Sujeto que intenta obtener la información; obligatorio. |
| `distancia` | `float` | Distancia ya calculada, no negativa. |
| `objetivo_visible` | `bool` | Indica que la celda está actualmente visible, no solo explorada. |
| `linea_visual_valida` | `bool` | Resultado de la validación visual correspondiente. |
| `pistas` | `Array[StringName]` | Pistas semánticas disponibles en este intento, sin valores vacíos ni duplicados. |

Las pistas se copian defensivamente. Este contrato no contiene el conocimiento
recordado ni referencias a UI.

### Perfil y evaluación de información

`PerfilObservacion` separa los alcances de examen de las propiedades mecánicas del
objetivo. Sus valores iniciales para interactuables estáticos son:

| Campo | Valor inicial | Regla |
|---|---:|---|
| `alcance_basico` | `5.0` | Alcance de fragmentos `VISIBLE` y `BASICO`. |
| `alcance_detallado` | `1.0` | Alcance de fragmentos `DETALLADO`; no puede superar el básico. |
| `alcance_secreto` | `1.0` | Alcance adicional de fragmentos `SECRETO`; no sustituye sus pistas. |
| `requiere_objetivo_visible` | `true` | Una celda solo explorada no permite obtener información nueva. |
| `requiere_linea_visual` | `true` | Exige una línea visual ya validada. |

Cada `DefinicionInteractuable` puede declarar un perfil. Los enemigos y otras
categorías podrán usar perfiles con alcances distintos sin introducir condiciones
específicas en el evaluador.

`EvaluadorInformacion` es puro: recibe fragmentos, `CondicionesObservacion` y un
perfil, no modifica ninguno y devuelve `ResultadoEvaluacionInformacion`. Conserva
el orden declarado de los fragmentos y aplica estas reglas:

1. Rechazar contratos inválidos e IDs de fragmento duplicados.
2. Validar visibilidad actual y línea visual según el perfil.
3. Bloquear cuando la distancia supera el alcance básico.
4. Filtrar cada nivel por su alcance correspondiente.
5. Exigir todas las pistas declaradas por cada fragmento.
6. Informar si la distancia actual permite detalle, sin convertir eso en un descubrimiento persistente.

Los motivos iniciales son `condiciones_observacion_invalidas`,
`perfil_observacion_invalido`, `fragmentos_informacion_invalidos`,
`fragmentos_informacion_duplicados`, `objetivo_no_visible`,
`linea_visual_bloqueada`, `fuera_alcance_examen` y
`sin_informacion_disponible`.

### Registro de conocimiento por observador

`RegistroConocimiento` mantiene durante la ejecución únicamente IDs estables con
esta jerarquía:

```text
id_observador
└── id_instancia_objetivo
    └── id_fragmento
```

No almacena nodos, `Resource`, mensajes ni referencias a UI. La identidad del
observador se expresa mediante un `StringName` estable para que el modelo pueda
serializarse en la futura fase de persistencia, aunque en esta fase no se guarda en
disco.

`registrar_descubrimientos()` valida la solicitud completa antes de modificar el
registro, ignora fragmentos con `se_recuerda = false` y es idempotente. Devuelve un
`ResultadoRegistroConocimiento` que distingue:

- Éxito con los IDs aprendidos por primera vez, conservando el orden recibido.
- Éxito sin novedades cuando todos los fragmentos recordables ya eran conocidos.
- Fallo sin mutación parcial cuando las claves o los fragmentos son inválidos.

El registro no infiere niveles ni descubre información adicional. Almacena
exactamente los fragmentos recordables que entregue el evaluador; la inclusión de
niveles inferiores se obtiene porque el evaluador devuelve todos los fragmentos
aplicables. `obtener_ids_conocidos()` entrega una copia ordenada y
`conoce_fragmento()` permite consultar una clave concreta.

Los motivos iniciales del registro son `id_observador_vacio`, `id_objetivo_vacio`,
`fragmentos_descubrimiento_invalidos` y
`fragmentos_descubrimiento_duplicados`. El borrado selectivo, la importación y la
exportación quedan fuera de la Fase 3.

### Solicitud y servicio de examen

`SolicitudExamen` transporta el ID estable del observador y las pistas semánticas
del intento. Es inmutable, copia sus pistas y exige que el actor implemente:

```gdscript
func obtener_id_observador() -> StringName
```

El ID devuelto por el actor debe coincidir con el de la solicitud. De este modo una
acción no puede atribuir descubrimientos a otro observador. `Ficha` es la primera
implementación del protocolo mediante su propiedad `id_observador`.

`ServicioExamen` es compartido e independiente de la UI. Recibe `TableroGrid` y un
`RegistroConocimiento`, y coordina el flujo:

```text
ContextoAccion EXAMINAR
→ validar objetivo, definición, solicitud y coordenadas
→ calcular distancia Manhattan desde el contexto
→ consultar visibilidad actual en Celda
→ validar defensivamente la línea visual
→ evaluar los fragmentos provistos por el interactuable
→ registrar únicamente los fragmentos recordables nuevos
→ construir ResultadoAccion
```

Los mensajes del resultado son los IDs narrativos de todos los fragmentos
disponibles, aunque ya fueran conocidos. `cambios_estado` contiene únicamente los
nuevos descubrimientos, identificados mediante observador, objetivo y fragmento.
Repetir un examen válido vuelve a presentar su información sin duplicar cambios.

`Interactuable` publica la opción `Examinar` y delega su validación y resolución al
servicio. Puede especializar `obtener_fragmentos_informacion()` para seleccionar
variantes narrativas según su estado sin exponer la propiedad interna. La primera
antorcha utiliza este punto para elegir entre dos variantes de un único fragmento
`BASICO`: ambas presentan identidad y estado evidente en una sola frase. El registro
recuerda el ID estable `identidad`, no el valor actual de `encendida`.

El tablero inyecta un mismo servicio en los interactuables registrados. El escenario
principal instancia el gestor, el registro y el servicio, y vincula el examen al
menú contextual obligatorio sin entregar esa responsabilidad al interactuable.

### Presentación provisional

`CatalogoMensajesInteraccion` es un `Resource` intercambiable que traduce IDs de
mensajes y motivos a texto visible. Si falta una entrada conserva el ID como respaldo
diagnosticable. Este catálogo provisional podrá sustituirse por el sistema de
localización definitivo sin cambiar fragmentos, resultados ni interactuables.

`PanelResultadoAccion` recibe un título, `ResultadoAccion` y catálogo. Solo compone
y muestra textos; no evalúa condiciones, registra conocimiento ni conoce clases de
contenido. La escena expone señales de presentación y cierre, y permite personalizar
texto del botón, separador, viñeta, tema y estructura visual. Puede cerrarse mediante
su botón o `ui_cancel`.

Toda opción resuelta desde el menú contextual entrega su `ResultadoAccion` al mismo
panel reemplazable. La transición menú → resultado conserva un único estado modal:
el mundo no recupera input entre ambas vistas y el objetivo permanece seleccionado
y resaltado hasta que el resultado se cierra. El panel no conoce la opción elegida,
el constructor de contexto ni la implementación del objetivo.

La vista del menú recibe una posición de pantalla solicitada, pero es responsable de
limitar su posición final al rectángulo visible del viewport. El ajuste considera su
tamaño mínimo una vez construidas las opciones, respeta un margen configurable en los
cuatro bordes y se recalcula cuando cambia el tamaño de la ventana.

La antorcha de pie, la fogata y ambas orientaciones de antorcha de pared publican
`EXAMINAR`. Todas ofrecen un fragmento `BASICO` con variantes narrativas encendida y
apagada; la antorcha de pie conserva además sus fragmentos detallado y secreto.

No existe un atajo directo para `EXAMINAR`. Toda interacción voluntaria comienza con
el clic izquierdo, conserva la selección explícita cuando hay varios objetivos y
obliga a elegir una opción del menú antes de construir y resolver el contexto.

Para la primera fuente de luz, el diseño aprobado prevé información básica hasta
cinco celdas e información detallada solo en adyacencia. Ese alcance de observación
es independiente del radio mecánico de iluminación de la fuente. Una celda
`EXPLORADO` no permitirá descubrimientos nuevos. Los enemigos podrán declarar otro
perfil de alcance en el futuro sin cambiar estos contratos.

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
