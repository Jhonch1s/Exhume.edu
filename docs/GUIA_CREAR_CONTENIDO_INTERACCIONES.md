# Crear y diagnosticar contenido de interacciones

Esta guía usa las escenas y `Resource` existentes como plantillas. Agregar contenido
común no requiere modificar `GestorAcciones`.

## Crear y colocar un interactuable

1. Duplica la escena y el recurso del caso más cercano:
   - Puerta: `scenes/interactuables/puertas/puerta_interactuable.tscn` y
     `assets/interactuables/puertas/puerta/puerta.tres`.
   - Palanca: `scenes/interactuables/mecanismos/palanca_interactuable.tscn` y
     `assets/interactuables/mecanismos/palanca/palanca.tres`.
   - Trampa: `scenes/interactuables/trampas/TrampaSuperficie.tscn`.
   - Superficie: una escena bajo `scenes/efectos_superficie/`.
2. Asigna un `id_definicion` único al recurso y completa sus campos exportados.
3. Instancia la escena bajo `Interactuables` o `EfectosSuperficie` en la zona.
4. Asigna un `id_instancia` único y coloca el nodo sobre una celda existente.
5. Ejecuta la zona. La prevalidación informa todos los IDs, definiciones,
   coordenadas, contratos o relaciones inválidos antes de registrar contenido.

Las escenas base ya pertenecen al grupo correcto. Si se crea una escena desde cero,
los interactuables deben heredar `Interactuable`; las superficies deben pertenecer
al grupo `efectos_superficie` e implementar `obtener_id_reaccion()` y
`configurar_registro()`.

## Conectar una palanca

En `ids_receptores_mecanismo`, agrega los `id_instancia` de los receptores. No uses
`NodePath` ni nombres de nodos. Cada receptor debe implementar:

```gdscript
func validar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> StringName
func aplicar_cambio_mecanismo(id_emisor: StringName, activa: bool) -> ResultadoAccion
```

La prevalidación detecta IDs vacíos, repetidos, inexistentes o incompatibles antes
de registrar la zona.

## Diagnosticar una celda

En la escena principal, coloca el cursor sobre una celda y pulsa `F3`. La consola
muestra terreno, presencia efectiva, coste, ocupantes, reservas, interactuables,
items, superficies, iluminación y reacción de terreno.

Para seguir una acción, añade
`scripts/interacciones/debug/registro_acciones_desarrollo.gd` como nodo y llama:

```gdscript
registro.observar_gestor(gestor_acciones)
registro.configurar_filtros(id_actor, celda_objetivo, tipo_accion)
```

Cada ciclo informa inicio, resultado base y resultado final. `limpiar_filtros()`
restaura el registro completo y `limpiar()` vacía el historial.

## Comprobación mínima

El contenido nuevo debe dejar una prueba headless pequeña que instancie la zona o
el receptor real, ejecute una acción válida y compruebe al menos un rechazo sin
mutación. Reutiliza la estructura de `tests/interacciones/` y ejecuta:

```text
Godot.exe --headless --path C:\godot\exhum_edu --script res://tests/interacciones/prueba_elegida.gd
```

No existe todavía una plantilla de contenedor ni generación desde marcadores. Se
añadirán cuando haya un contenedor jugable o suficiente contenido repetitivo para
justificar ese flujo.
