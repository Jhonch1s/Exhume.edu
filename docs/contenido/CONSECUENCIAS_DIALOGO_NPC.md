# Configurar pruebas y consecuencias de diálogo

Referencia permanente de autoría de NPC y diálogos dentro de la documentación
central del proyecto. Se accede desde el [índice general](../00_INDICE.md), la
[guía de creación de contenido](../GUIA_CREAR_CONTENIDO_INTERACCIONES.md) y el
[catálogo de contenido](CONTENIDO.md).

El catálogo disponible permite **cambiar puntos de actitud** y **revelar información
del NPC que habla**. Se configura con recursos del Inspector: otros NPC pueden
usar estas operaciones sin añadir lógica GDScript. El texto y las ramas siguen
escribiéndose en Dialogue Manager.

## Preparar un tema

1. En la definición del NPC, habilitar `puede_dialogar` y añadir un `DialogoNPC`
   en `dialogos`. Asignar su ID, título, recurso `.dialogue` y punto de inicio.
2. En `DialogoNPC.pruebas`, crear un `PruebaDialogoNPC` por elección con tirada.
   Darle un `id_prueba` estable y único entre todos los temas de ese NPC, un
   título y el atributo: fuerza, destreza o voluntad. Se usa el valor actual del
   jugador y la prueba normal existente de 1d6. Crítico sigue éxito y pifia sigue
   fallo; no tienen listas independientes en este primer catálogo.
3. Elegir `una_sola_vez`. Activado por defecto, recuerda éxito **o fallo** de esa
   instancia. Al volver a solicitarla continúa por el resultado guardado, sin
   dados ni nuevas consecuencias. Desactivado, cada elección vuelve a tirar y
   aplica su lista. Los cambios de actitud pueden acumularse hasta sus límites;
   una información conocida no se registra dos veces.
4. Añadir recursos `ConsecuenciaDialogoNPC` a `consecuencias_exito` y
   `consecuencias_fallo`. Las listas pueden estar vacías y se aplican en orden.

| Tipo | Campo que configurar | Resultado |
|---|---|---|
| `CAMBIAR_ACTITUD` | `puntos_actitud`, de −20 a 20, distinto de cero | Suma o resta puntos; respeta actitud fija, límites −10/10 y umbrales existentes. |
| `REVELAR_INFORMACION` | `id_fragmento` | Recuerda y muestra el fragmento de esa instancia al jugador. |

Para información, crear primero un `FragmentoInformacion` válido y recordable en
`DefinicionPersonaje.fragmentos_informacion`. Usar su mismo ID en la consecuencia
y añadir su `id_mensaje` al catálogo del escenario. Un ID inexistente, duplicado
o no recordable invalida la configuración. La información se muestra en el
registro narrativo y queda en `RegistroConocimiento`; puede condicionar otras
líneas mediante `conoce_informacion_dialogo(id)`. Las reglas de examen conservan
sus propios alcances y pistas.

Los recursos son plantillas compartibles. Para cambiar la configuración de un
NPC sin cambiar otros que usen el mismo `.tres`, crear otro recurso o hacerlo
único en el Inspector. El resultado de la prueba pertenece a cada instancia,
aunque compartan exactamente la misma plantilla.

## Pedir la prueba desde el texto

```text
~ start
Custodio: ¿Puedo confiar en tu palabra?
- Intentar convencerlo [VOL].
    do realizar_prueba_dialogo_configurada("confianza_custodio")
    if not prueba_dialogo_resuelta
        Custodio: No podemos resolver esa prueba ahora.
        => END
    elif prueba_dialogo_exitosa
        Custodio: Confío en ti.
        => END
    else
        Custodio: Mantengo mis dudas.
        => END
```

En otra línea del mismo NPC se puede escribir:

```text
if conoce_informacion_dialogo("confidencia")
    Custodio: Ya conoces mi secreto.
```

El ID de la llamada debe coincidir con el de `PruebaDialogoNPC` del tema activo.
Las dos listas se validan **antes de consumir azar o cambiar el mundo**. Los
errores aparecen en la salida de Godot y dejan `prueba_dialogo_resuelta = false`;
conviene conservar esa rama de seguridad en el texto. No se usan nombres de
métodos arbitrarios como consecuencias.

## Momento de aplicación y guardado

La elección tira y registra una vez, presenta el resultado existente y espera el
cierre del panel. Después aplica la lista elegida, recuerda el intento si es único
y continúa la respuesta. La animación no tira ni aplica efectos. Una segunda
selección durante la espera se ignora. K/C permanece bloqueado hasta terminar la
conversación completa; no hay un snapshot a medio aplicar.

Los intentos únicos se guardan por ID en el campo opcional `pruebas_dialogo` del
estado de cada NPC. Cambiar esos IDs después de publicar contenido equivale a
crear otra prueba. Se conserva el formato v2: snapshots anteriores al campo
restauran la memoria vacía; los datos inválidos se rechazan antes de restaurar.
Actitud, conocimiento e intento se rebobinan juntos al cargar un momento anterior.
Cargar después no tira ni aplica otra vez las consecuencias.

La conversación inicial sin consecuencias sigue disponible y conserva los
intentos libres mediante `realizar_prueba_dialogo(atributo, titulo)`. Las pruebas
configuradas son opcionales para cada tema, sin migrar los demás diálogos.

## Ejemplo listo para editar

- `recursos/dialogos/custodio_consecuencias.tres`: tema y prueba, éxito con +3 de
  actitud y confidencia; fallo con −1; intento único.
- `recursos/dialogos/confidencia_custodio.tres`: fragmento recordable.
- `dialogues/personajes/prueba_consecuencias.dialogue`: texto, llamada por ID y
  condiciones de resultado y conocimiento.
- `tests/interacciones/escena_consecuencias_dialogo_npc.tscn`: escena F6. Seleccionar
  el nodo raíz y desplegar **Tema consecuencias → Pruebas** en el Inspector.

La [guía de revisión](../pruebas/DIALOGOS_CON_TIRADAS.md) describe K/C y los dos
resultados; el [registro de pruebas](../pruebas/PRUEBAS.md) conserva el estado de
validación. Las escenas de prueba sirven como ejemplos; los pasos de autoría de
esta guía también se aplican al contenido permanente de las zonas.

## Mantenimiento

Esta es la referencia de construcción para estas pruebas y consecuencias.
Cuando cambien los campos de `DialogoNPC`, `PruebaDialogoNPC` o
`ConsecuenciaDialogoNPC`, actualizar sus instrucciones y ejemplos en el mismo
cambio. Mantener aquí el procedimiento vigente y registrar la evolución y los
resultados de validación en el roadmap y las guías de pruebas correspondientes.
