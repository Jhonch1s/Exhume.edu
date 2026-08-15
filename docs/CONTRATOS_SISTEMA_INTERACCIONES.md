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

## Flujos de referencia

### Palanca

El jugador elige `Accionar`; se crea `INTERACTUAR` con `id_accion = &"accionar"`, actor y palanca. Se valida objetivo y alcance. La palanca reacciona cambiando su estado, devuelve `EXITO` y registra el cambio. El gestor cobra el coste declarado y emite el resultado. La UI solo lo presenta.

### Trampa al entrar

Tras confirmar ocupación se crea `ENTRAR` con origen, destino y ficha. La trampa registrada como interactuable reacciona una vez, produce sus efectos y marca `interrumpe_movimiento`. Se aplican las consecuencias y la ruta se detiene en la celda de destino.

### Item arrojado

`LANZAR_ITEM` valida actor, item, coste y trayectoria. Al terminar la representación del vuelo se crea `IMPACTAR` con el item, celda real, etiquetas (`impacto`, por ejemplo) y magnitudes como `fuerza_impacto`. Los receptores reaccionan por propiedades; ninguno necesita conocer la definición concreta del item.
