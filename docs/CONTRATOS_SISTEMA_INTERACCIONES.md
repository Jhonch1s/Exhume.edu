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
    celda_objetivo: Vector2i
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

Las validaciones iniciales comprueban actor, objetivo, coordenadas requeridas, alcance y contrato del receptor. El alcance espacial se mide mediante distancia Manhattan para coincidir con las cuatro direcciones conectadas por el movimiento actual. Costes disponibles y agregación de varios receptores se incorporarán mediante contratos específicos antes de cerrar la Fase 1.

## Servicio espacial

La línea de efecto se declara mediante `TipoLineaEfecto`: `NINGUNA` no requiere servicio, `VISUAL` representa observación y luz, y `FISICA` queda preparada para herramientas, trayectorias e impactos. No se deduce únicamente del tipo de acción porque una misma acción puede dirigirse a un objetivo del mundo o a una posesión propia.

`GestorAcciones` recibe un servicio separado mediante `configurar_validador_espacial()`. Cuando el contexto requiere línea, el servicio debe cumplir:

```gdscript
func validar_linea_efecto(contexto: ContextoAccion) -> StringName
```

Devuelve `&""` si la línea está despejada o un motivo de bloqueo. La validación no modifica estado. La ausencia del servicio solo bloquea contextos que lo requieren.

`ValidadorEspacialTablero` implementa actualmente la línea `VISUAL` sobre `TableroGrid`. Usa `GeometriaGrid.trazar_linea()`, utilidad Bresenham compartida con `FOVManager`, y aplica estas reglas: origen y destino deben existir; un hueco intermedio bloquea; las celdas intermedias con `bloquea_vision` bloquean; la celda de destino puede ser opaca porque debe ser posible examinar una pared. `FISICA` devuelve `linea_fisica_no_implementada` hasta definir obstáculos, alturas y colisiones apropiados.

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

El contexto se construye con copias de etiquetas, magnitudes y metadatos. Los receptores no deben modificarlo.

## `ResultadoAccion`

| Campo | Tipo previsto | Regla |
|---|---|---|
| `estado` | `EstadoResolucion` | Fuente única para éxito, fallo o bloqueo. |
| `motivo` | `StringName` | Código legible/localizable; obligatorio para fallo y bloqueo. |
| `mensajes` | `Array[StringName]` | IDs de mensajes de presentación, en orden. |
| `efectos_aplicados` | `Array` | Efectos confirmados, no propuestas. |
| `cambios_estado` | `Array[Dictionary]` | Registro descriptivo de cambios confirmados. |
| `costes_consumidos` | `Dictionary[StringName, float]` | Energía, acciones, turnos, cargas o cantidad realmente cobrados. |
| `interrumpe_movimiento` | `bool` | Solicita detener la ruta tras el paso confirmado. |

Las propiedades derivadas `exitosa`, `consumio_accion` y `consumio_turno` se calculan desde `estado` y `costes_consumidos`; no se almacenan como fuentes de verdad duplicadas.

Un resultado de `BLOQUEO` debe tener vacíos `efectos_aplicados`, `cambios_estado` y `costes_consumidos`. Los fallos no consumen nada por defecto. Cada coste debe declararse en la opción y cobrarse una sola vez después de resolver.

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
principal instancia el gestor, el registro y el servicio, pero todavía no vincula
el examen al menú contextual de la Fase 4.

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

La antorcha de pie, la fogata y ambas orientaciones de antorcha de pared publican
`EXAMINAR`. Todas ofrecen un fragmento `BASICO` con variantes narrativas encendida y
apagada; la antorcha de pie conserva además sus fragmentos detallado y secreto.

El atajo `E` permanece únicamente como activación técnica heredada hasta el cierre
4.7. Selecciona el primer examinable y no resuelve múltiples objetivos, por lo que
no forma parte del flujo definitivo y debe retirarse junto con sus helpers.

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

`LANZAR_ITEM` valida actor, item, coste y trayectoria. Al terminar la representación del vuelo se crea `IMPACTAR` con el item, celda real, etiquetas (`impacto`, por ejemplo) y magnitudes como `fuerza_impacto`. Los receptores reaccionan por propiedades; ninguno necesita conocer la definición concreta del item.
