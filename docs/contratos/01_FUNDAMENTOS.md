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

