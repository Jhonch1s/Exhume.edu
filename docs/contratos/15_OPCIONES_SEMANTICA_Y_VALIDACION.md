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

