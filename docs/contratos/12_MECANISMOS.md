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

