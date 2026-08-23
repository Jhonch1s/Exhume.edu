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

