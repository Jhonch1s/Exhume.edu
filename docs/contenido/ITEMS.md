# Ítems: estado actual y modelo de autoría

Revisado contra el código del workspace el 9 de septiembre de 2026. Esta guía
describe el estado actual, incluidos cambios locales. La ficha del final es una
plantilla de contenido; no introduce una clase nueva ni capacidades de runtime.

## Modelo existente

```text
DefinicionItem (.tres compartido): qué clase de objeto es
    ↑ referencia
ItemInstancia (RefCounted): una pila concreta, ID y cantidad
    ├── Inventario del jugador o de un cofre
    └── ItemSuelo: registro lógico en una celda
            └── Node2D instanciado desde escena_mundo: representación visual
```

La definición es compartida: no modificar sus datos para representar desgaste de
un ejemplar. Una unidad dentro de una pila no tiene ID propio. El sprite no es la
fuente de verdad del inventario, cantidad o ubicación.

## Todos los campos de definición

Fuente: [DefinicionItem](../../scripts/interacciones/items/definicion_item.gd).

| Campo | Tipo y valor inicial | Uso actual |
|---|---|---|
| `id_definicion` | `StringName`, vacío | Identifica el tipo; consultas, compatibilidad de pilas y guardado. |
| `nombre` | `String`, vacío | Nombre presentado en menús y resultados. Texto directo, no ID de traducción. |
| `icono` | `Texture2D`, null | Casilla y selector de inventario. Independiente del sprite del suelo. |
| `escena_mundo` | `PackedScene`, null | Representación al registrar en el suelo y durante el vuelo. |
| `etiquetas` | `Array[StringName]`, vacío | Capacidades/características copiadas al contexto de uso e impacto. |
| `magnitudes` | `Dictionary[StringName, float]`, vacío | Valores numéricos copiados al contexto. No ejecutan reglas por sí solos. |
| `reaccion_impacto` | `Resource`, null | Comportamiento opcional del propio ítem después de un lanzamiento. |
| `apilable` | `bool`, false | Permite cantidades mayores a uno y operaciones de apilado. |
| `cantidad_maxima` | `int`, 1; Inspector 1–999 | Máximo por pila, no máximo total en el inventario. |

`es_valida() -> bool` exige ID y nombre no vacíos, máximo al menos uno, máximo
exactamente uno para no apilables, etiquetas no vacías ni repetidas, claves de
magnitudes no vacías y valores finitos. Solo `temperatura` admite negativos.
El método no comprueba icono, escena, contrato de reacción ni unicidad global del
ID de definición. El rango 1–999 es configuración del Inspector: la validación
del método no impone el límite superior 999.

No existe un catálogo cerrado de etiquetas ni magnitudes. `arrojable` habilita
lanzamiento; `llave` participa en validación de llaves. `impacto` se añade al
contexto de lanzamiento. Añadir `fragil`, `humo`, `contundente`, `peso`, etc. no
crea automáticamente consumo, humo, daño o una regla de carga.

[DefinicionLlave](../../scripts/interacciones/items/definicion_llave.gd) hereda
todo lo anterior y añade `patron_cerradura: StringName`, inicialmente vacío.
Su `es_valida()` exige además etiqueta `llave` y patrón no vacío. Es un dato
de compatibilidad con puertas, no una etiqueta distinta para cada cerradura.

## Estado de una pila y de su presencia en el mapa

[ItemInstancia](../../scripts/interacciones/items/item_instancia.gd):

| Propiedad | Significado |
|---|---|
| `id_instancia: StringName` | Identidad de esta pila. |
| `definicion: DefinicionItem` | Referencia al recurso compartido. |
| `cantidad: int` | Unidades actuales. |

Son propiedades de lectura respaldadas por `_id_instancia`, `_definicion` y
`_cantidad`. Métodos: `_init(id, definicion, cantidad = 1)`, `es_valida()` y el
mutador interno `_establecer_cantidad(nueva_cantidad)`. Este último no valida:
el contenido debe usar las operaciones de Inventario/TransferidorItems.
El constructor tampoco rechaza datos por sí solo; `es_valida()` comprueba ID,
definición y cantidad entre uno y el máximo, y cantidad uno para no apilables.

[ItemSuelo](../../scripts/interacciones/items/item_suelo.gd) añade `item`,
`coordenada_mapa` (Vector2i registrado o null) y `esta_registrado`. Guarda
internamente el transferidor y una referencia visual. No añade durabilidad,
propietario persistente, equipamiento ni propiedades físicas.

| Métodos de ItemSuelo | Función |
|---|---|
| `_init(item)`, `es_valido()` | Construcción y validación de la pila contenida. |
| `configurar_transferidor_items(transferidor)` | Conecta el servicio compartido. |
| `obtener_id_objetivo_interaccion()`, `obtener_nombre_interaccion()` | Identidad y presentación ante el selector. |
| `vincular_representacion(node)`, `obtener_representacion()` | Relación con la escena visual. |
| `establecer_resaltado(activo)` | Delega al nodo visual, si ofrece ese método. |
| `obtener_opciones_accion(actor = null)` | Ofrece RECOGER si está registrado y tiene transferidor. |
| `construir_contexto_accion(opcion, actor, origen, celda, item = null)` | Construye el contexto de recogida compatible. |
| `validar_accion(contexto)`, `resolver_accion(contexto)` | Delegan recogida al transferidor. |
| `_configurar_registro(coordenada)`, `_limpiar_registro()` | Internos: los administra el tablero. |

El tablero publica `validar_registro_item_suelo`, `registrar_item_suelo`,
`validar_retiro_item_suelo`, `retirar_item_suelo`, `obtener_item_suelo` y
`validar_colocacion_item_suelo`. Mantiene `items_suelo_por_id` y
`Celda.items_suelo`; emite `item_suelo_registrado`/`item_suelo_retirado`.
Registrar contenido solo exige una celda existente y coherencia de identidad;
SOLTAR añade restricciones de caminabilidad, ocupación y reservas.

## Inventario: todos sus métodos

Fuente: [Inventario](../../scripts/interacciones/items/inventario.gd).
`capacidad = -1` significa sin límite. Otro valor no negativo limita pilas, no
unidades ni peso. El jugador usa -1; cada cofre usa columnas × filas.

| Método | Resultado y comportamiento |
|---|---|
| `obtener_contenido()` | Copia del array ordenado por ID; las instancias siguen compartidas. |
| `obtener_por_id(id)` | Instancia o null. |
| `obtener_por_definicion(id)` | Array de pilas del tipo indicado. |
| `esta_lleno()` | Consulta el número de entradas frente a capacidad. |
| `validar_agregado(item)` | Motivo StringName; vacío significa válido. |
| `agregar(item)` | Añade una pila; no combina automáticamente. |
| `validar_retiro(id, cantidad = -1, nuevo_id = vacío)` | Prevalida retiro total o parcial. |
| `retirar(id, cantidad = -1, nuevo_id = vacío)` | Total devuelve la misma pila; parcial crea otra con el ID explícito. |
| `combinar(id_origen, id_destino)` | Mismo ID de definición apilable; suma completa o fallo. Sobrevive ID destino. |
| `separar(id_origen, cantidad, nuevo_id)` | Crea otra pila en el mismo inventario; requiere capacidad libre. |
| `transferir_a(destino, id_item)` | Mueve pila completa; conserva referencia, ID y cantidad. |
| `_ordenar()` | Interno: orden lexicográfico por ID de instancia. |

Las mutaciones devuelven [ResultadoOperacionInventario](../../scripts/interacciones/items/resultado_operacion_inventario.gd):
`exitosa`, `motivo`, `item`, `cantidad`, `id_origen`, `id_destino`, expuestos
mediante getters. Tiene constructor y fábricas `crear_exito(...)` y
`crear_fallo(motivo)`. Un fallo deja item null, cantidad cero e IDs vacíos.
Los métodos de validación devuelven motivo, no ese objeto resultado.

No hay señales propias de Inventario ni slots persistentes. Combinar no llena
parcialmente una pila: si excede el máximo, falla. Recoger todo en el cofre son
varias transferencias individuales y puede terminar con éxito parcial del lote.

## Acciones y dónde viven

El ítem no ofrece `usar()`, `equipar()`, `examinar()`, `recoger()` ni `lanzar()`.
Su definición aporta datos; otros objetos coordinan y resuelven las acciones.

| Acción | Implementación actual |
|---|---|
| Recoger del suelo | ItemSuelo → TransferidorItems; pila entera o cantidad parcial por API. |
| Soltar | TransferidorItems; pila entera o parcial por API. |
| Usar sobre objetivo | Interactuable construye/revalida contexto; el receptor concreto decide. |
| Llave en puerta | PuertaInteractuable compara patrón y desbloquea; conserva llave. Abrir es otra acción. |
| Lanzar | TransferidorItems, selección de arrojables en EscenarioBase y resolución espacial. |
| Impactar | Reacciones de celda/receptor y reacción opcional de la definición. |
| Transferir entre inventarios | Inventario.transferir_a; actualmente utilizado por Recoger todo. |

RECOGER/SOLTAR usan alcance Manhattan uno, política SOLO_EXITO y costes vacíos
en sus contextos. Uso genérico declara una unidad; verifica misma instancia en
inventario y etiquetas/magnitudes idénticas a la definición. El Interactuable
base devuelve `reaccion_item_no_implementada`: que aparezca Usar no garantiza
una reacción. No hay consumo universal implementado para USAR_ITEM.

Lanzar exige `arrojable`, lanza una unidad y calcula alcance **7 + fuerza del
actor** con métrica de cuadrícula. Peso no modifica ese alcance. Resuelve primera
colisión, celda de impacto y celda de caída. Sin decisión de reacción, el objeto
queda en el suelo; los destinos admitidos son CONSERVAR_EN_INVENTARIO, CONSUMIR y
DEJAR_EN_CELDA. No existe un booleano global `consumible`.

[TransferidorItems](../../scripts/interacciones/items/transferidor_items.gd)
expone `_init(tablero, gestor = null)`, `construir_contexto_recoger`,
`validar_recoger`, `recoger`, `construir_contexto_soltar`,
`construir_contexto_lanzar`, `calcular_alcance_lanzamiento`, `validar_accion` y
`resolver_accion`. Los contextos aceptan actor, ítem, origen/destino y, cuando
procede, cantidad e ID resultante; lanzar admite objetivo de impacto opcional.

Sus auxiliares internos son `_validar_lanzar`, `_lanzar`,
`_confirmar_destino_lanzamiento`, `_validar_reaccion_impacto_item`,
`_resolver_reaccion_impacto_item`, `_obtener_prefijo_efecto_impacto`,
`_recoger_parcial`, `_validar_cantidad_transferencia` y `_revertir_retiro`.
Centralizan comprobaciones, destino y recuperación de transferencias fallidas.

La reacción opcional debe ofrecer:

```text
validar_impacto(tablero, contexto, coordenada, prefijo_id) -> StringName
resolver_impacto(tablero, contexto, coordenada, prefijo_id) -> ResultadoAccion
```

[ReaccionImpactoSuperficie](../../scripts/interacciones/items/reaccion_impacto_superficie.gd)
ya cumple ese contrato: `escena_superficie: PackedScene`, `radio: int = 0`
(Inspector 0–8), `id_mensaje: StringName = vacío`. Despliega la superficie y
devuelve CONSUMIR. La duración y comportamiento de la superficie pertenecen a
su escena/script, no a ItemInstancia.

## Assets y presentación

Cada ítem actual usa una escena Node2D con un hijo llamado exactamente Sprite2D
y el script compartido [RepresentacionItemSuelo](../../scripts/interacciones/items/representacion_item_suelo.gd).
Este solo ofrece `establecer_resaltado(activo)`: crea un outline blanco al
necesitarlo. Las escenas usan filtro Nearest. No hay dimensiones obligatorias
de sprite impuestas por DefinicionItem.

EscenarioBase instancia `escena_mundo` al registrar, la sitúa en la celda y la
elimina al retirar. También usa esa escena para animar el lanzamiento con Tween;
la duración por paso se configura en el escenario, no en el ítem. Colocar solo
la escena de representación en el editor no crea una pila lógica registrada.

| Ítem | Recursos y datos actuales |
|---|---|
| Piedra | `assets/items/piedra/piedra.tres`; sprite `sprites/piedra_isometrica.png`; mundo `scenes/items/piedra_suelo.tscn`; fuente `assets/art_source/items/piedra/piedra_isometrica.ase`. |
| Bomba de humo | `assets/items/bomba_humo/bomba_humo.tres`; sprite `sprites/bomba_humo_isometric1.png`; mundo `scenes/items/bomba_humo_suelo.tscn`; fuente `assets/art_source/items/bomba_humo/sprites/bomba_humo_isometric1.ase`. |
| Llave | `assets/items/llave_prueba/llave_prueba.tres`; `llave_placeholder.svg` como sprite e icono; mundo `scenes/items/llave_suelo.tscn`. |

| Tipo | Etiquetas | Magnitudes | Apilado | Icono asignado | Particularidad |
|---|---|---|---|---|---|
| `piedra` | mineral, solido, contundente, arrojable | peso 3.0 | 99 | No | Sin reacción propia; caída normal al lanzar. |
| `bomba_humo` | arrojable, fragil, humo | peso 1.0 | 10 | No | Reacción de superficie Humo, radio 2, mensaje bomba_humo.activada. |
| `llave_prueba` | llave, solido | Vacío | No, máximo 1 | Sí | Patrón cripta_simple. |

Humo usa `scenes/efectos_superficie/Humo.tscn` y
`assets/tiles/surface_effects/smoke/source/smoke_isometric.png`: cuatro frames
64×64, animación a 4 fps y duración lógica predeterminada de diez turnos;
bloquea visión. Existe `assets/sonidos/varios/editados/bomba humo.wav`, pero no
está conectado en la definición, representación o escena de humo examinadas.
No hay campos generales de sonido en DefinicionItem.

CasillaInventario.configurar(item) muestra icono y cantidad si supera uno;
sin icono no toma automáticamente la textura de escena_mundo. El selector
contextual usa nombre, cantidad e icono opcional. El panel del cofre implementa
Recoger todo y Cerrar; no conecta aún recogida individual desde la casilla,
depósito, examen ni menú propio por ítem. El suelo publica solo RECOGER.
Los ítems no tienen máscaras de niebla ni protocolo propio de fog equivalente
al de los interactuables en sus escenas actuales.

## Creación de contenido y guardado

Para cofres existe EntradaInventarioInicial (Resource) con `definicion` y
`cantidad = 1`. No define métodos propios. Se coloca en `contenido_inicial` de
cada CofreInteractuable. Al iniciar, el cofre valida todas las entradas antes de
asignar el inventario y crea IDs `<id_cofre>:contenido:<indice>`.
La cantidad de una entrada debe caber en una pila; no se desborda a otras.

Los tres objetos de prueba del suelo se crean expresamente en EscenarioBase:
`_colocar_piedra_prueba`, `_colocar_llave_prueba`, `_colocar_bomba_humo_prueba`.
No existe todavía un nodo genérico de autoría de ItemSuelo con definición,
cantidad e ID exportados para colocarlo desde el Inspector.

Ficha guarda sus pilas como `id`, `definicion_id`, `definicion_path`, `cantidad`.
PersistenciaContenidoDinamico guarda además `coordenada` para ítems en suelo.
Restaurar carga el recurso por ruta y comprueba ID, cantidad y definición. Las
definiciones de contenido persistente deben guardarse en archivos; renombrar su
ruta o ID necesita considerar las partidas existentes.

El contenido y apertura de los cofres todavía no se guardan. Reiniciar la escena
recrea su contenido inicial. Ver [límites de cofres](COFRES.md).

No están modelados hoy: descripción, ilustración de examen, rareza, precio,
categoría de equipo, daño de arma, ranura de equipo, requisitos de uso, cargas,
durabilidad por ejemplar, propietario persistente, recetas, sonidos generales,
acciones de comer/beber/equipar ni un inventario por peso. Antorchas y raciones
de Ficha son contadores separados, no definiciones de ítem de este sistema.

## Modelo general a adoptar

Reutilizar DefinicionItem + ItemInstancia + escena visual. Crear un .tres por
tipo, no un script nuevo por objeto. Usar DefinicionLlave si necesita patrón;
usar ReaccionImpactoSuperficie si despliega una superficie al lanzarse.
Una mecánica nueva exige implementar su receptor o contrato correspondiente:
una etiqueta inventada no basta. Datos mutables futuros, como durabilidad,
pertenecerían a ItemInstancia y requerirían definir apilado y guardado.

Organización propuesta, compatible con las rutas existentes:

```text
assets/items/<id>/<id>.tres
assets/items/<id>/sprites/<id>_mundo.png
assets/items/<id>/icons/<id>_icono.png       # solo si necesita imagen distinta
scenes/items/<id>_suelo.tscn
assets/art_source/items/<id>/...            # editable, cuando exista
```

La carpeta icons es una convención nueva opcional; puede reutilizarse la misma
textura del mundo como icono. No duplicar imágenes sin necesidad.

Ficha copiable para cada nuevo objeto (los apartados de diseño no son campos
exportados adicionales):

```text
IDENTIDAD
id_definicion:
nombre:
función jugable y aspecto buscado:                 [documentación]

RECURSOS
archivo de definición:
icono:                                          [asignar explícitamente]
escena_mundo:                                   [Node2D + Sprite2D]
textura de mundo:
editable de arte:                               [opcional]

REGLAS
clase de definición: DefinicionItem / DefinicionLlave
etiquetas: []
magnitudes: {}
apilable: false
cantidad_maxima: 1
patron_cerradura:                               [solo llave]
reaccion_impacto: null / ReaccionImpactoSuperficie
  escena_superficie:
  radio:
  id_mensaje:

COMPORTAMIENTO ESPERADO                         [documentación]
se puede lanzar:                                [requiere arrojable]
reacción al impacto y destino de la unidad:
objetivos que aceptan su uso y resultado:
reglas nuevas que todavía requieren desarrollo:

APARICIÓN                                      [dato de cada colocación]
lugar: cofre / suelo / inventario
ID de instancia o ID del cofre generador:
cantidad inicial:
celda:                                         [solo suelo]

ACEPTACIÓN
definición y cantidad válidas:
sprite e icono visibles al tamaño de juego:
recogida/transferencia sin pérdida ni duplicado:
apilado o separación, si corresponde:
uso correcto e incompatible, si corresponde:
lanzamiento, caída o consumo, si corresponde:
guardado/restauración en jugador y suelo:
limitación de guardado de cofres reconocida:
```

Procedimiento mínimo: duplicar el recurso y escena del caso más cercano,
cambiar ID/nombre/arte, completar las reglas que ya existen y asignarlo a una
entrada inicial de cofre o registrarlo lógicamente en el suelo. Para un ítem
mundano basta la definición base; para pociones bebibles o armas equipables,
primero falta acordar e implementar esas mecánicas.

## Verificación disponible

Hay pruebas existentes para inventario, capacidad, registro en suelo, recoger,
soltar, uso contextual, llave/puerta, selector y lanzamiento. Entre ellas:
`tests/interacciones/prueba_inventario.gd`, `prueba_capacidad_inventario.gd`,
`prueba_items_suelo.gd`, `prueba_recoger_item.gd`, `prueba_soltar_item.gd`,
`prueba_usar_item_contexto.gd`, `prueba_puerta_usar_llave.gd` y
`prueba_lanzar_item_logico.gd`. Se pueden ejecutar con Godot headless y --script.
Esta revisión no las ejecutó ni cambió lógica: no afirma que pasen hoy.

Los contratos históricos contienen apartados por incremento; para capacidades
actuales se contrastaron con el código, por ejemplo transferencias parciales y
consumo por lanzamiento que aparecían como futuros en apartados antiguos.
