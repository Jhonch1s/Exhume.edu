# Cofres e inventarios de almacenamiento

Estado revisado el 8 de septiembre de 2026. Esta guía describe lo implementado;
los pendientes están en [Continuidad de interfaces](../PENDIENTES_INTERFAZ.md).

## Archivos y responsabilidades

| Pieza | Ubicación | Función |
|---|---|---|
| Cofre del mundo | `scenes/interactuables/cofres/cofre_interactuable.tscn` | Sprite y máscaras, identidad de instancia. |
| Comportamiento | `scripts/interacciones/interactuables/cofres/cofre_interactuable.gd` | Apertura, representación y contenido inicial. |
| Tipo de cofre | `scripts/interacciones/interactuables/cofres/definicion_cofre.gd` | Columnas, filas e imagen de interfaz; hereda información examinable. |
| Definición actual | `scenes/interactuables/cofres/cofre_pequeno.tres` | Recurso compartido del cofre pequeño. |
| Entrada inicial | `scripts/interacciones/items/entrada_inventario_inicial.gd` | Definición de item y cantidad, editables en Inspector. |
| Panel | `scenes/ui/inventario/panel_inventario_cofre.tscn` y `.gd` | Cuadrícula, recoger todo y cerrar. |
| Casilla | `scenes/ui/inventario/casilla_inventario.tscn` y `.gd` | Presentación de una pila o un espacio vacío. |

## Contenido y transferencia

Cada `CofreInteractuable` crea su propio `Inventario`. Compartir definición o
variante visual no comparte contenido. La capacidad se calcula en
`obtener_inventario()` como `columnas * filas`; un espacio contiene una pila.
El jugador conserva capacidad ilimitada (`-1`). No hay apilado automático.

`contenido_inicial` se configura en la instancia del mapa. Cada entrada contiene
una `DefinicionItem` y una cantidad válida. `_ready()` lo carga fuera del editor:
prepara un inventario completo, valida todas las entradas y solo entonces lo
asigna. Un error se informa mediante `push_error`; no se aplica una carga parcial.
Los IDs se forman como `<id_instancia>:contenido:<indice>`, por lo que cada cofre
colocado necesita un ID propio. Reabrir el panel no vuelve a generar contenido;
reiniciar la escena sí vuelve a crearlo.

`Inventario.transferir_a(destino, id_item)` agrega primero al destino y elimina
la misma referencia del origen únicamente si hubo éxito. Conserva ID y cantidad,
rechaza destino nulo o idéntico, IDs repetidos y falta de capacidad.
`Recoger todo` recorre las pilas por orden del inventario y se detiene ante el
primer fallo. Lo ya transferido permanece en el jugador; lo restante, en el cofre.
El panel se reconstruye después. El motivo del fallo se muestra hoy en Salida,
no en una notificación para el jugador.

## Apertura, panel y examen

`abrir_cofre` es una acción `INTERACTUAR` de alcance uno. El gestor valida la
interacción y el receptor establece `abierto = true`. Ante éxito,
`EscenarioBase._presentar_resultado_contextual()` llama a
`panel.mostrar(cofre, ficha_jugador.obtener_inventario())`.
El panel pertenece a `CanvasLayer` y participa del estado modal del escenario.
Cerrar o Escape oculta el panel; el cofre permanece abierto en el mundo.

El panel genera todas las casillas, ocupadas primero y vacías al final. Al pasar
el cursor por una pila muestra nombre, cantidad, descripción y su ilustración de
examen o, si no existe, el icono. No hay
posiciones de slots persistentes: al retirar una pila, las restantes se compactan.
`configurar(null)` limpia icono y cantidad y deshabilita el botón. Una pila usa
`DefinicionItem.icono`; `escena_mundo` no se convierte automáticamente en icono.
Sin icono, el objeto sigue existiendo y puede transferirse.

La definición actual habilita Examinar mediante perfil de observación y fragmento
`descripcion`, cuyo mensaje es `examen.cofre_pequeno.basico`. Una descripción base
sola no habilita el examen. Si el examen tiene éxito y hay `ilustracion_examen`,
el escenario muestra el panel ilustrado; sin ella muestra el resultado normal.
Esto examina el cofre, no los items de las casillas.

## Composición de la interfaz

```text
PanelInventarioCofre (Control)
└── Fondo (TextureRect)
    ├── AreaItems (MarginContainer)
    │   └── Proporcion (AspectRatioContainer)
    │       └── Contenido (GridContainer)
    └── Botones (Control)
        ├── RecogerTodos (Button)
        └── Cerrar (Button)
```

Se redimensiona `Fondo` desde el editor. Sus hijos usan anclajes proporcionales;
`Proporcion.ratio = columnas / filas` y separaciones de cuadrícula cero mantienen
las casillas cuadradas y centradas. Los botones son planos sobre las tablas de
la ilustración, sin título ni cabecera. La imagen actual está en
`assets/ui/inventario/cofre_pequeno.png`.

Los anclajes están ajustados a esa imagen concreta. Una ilustración con otro
hueco o botones en otras posiciones requerirá ajustar la composición; cambiar
`imagen_interfaz` por sí solo no detecta esas zonas. El texto no escala
proporcionalmente con la imagen y los controles conservan mínimos del tema.

## Arte, niebla y colocación

- Normal: `assets/interactuables/cofres/source/cofres_basicos.png`.
- Oculto: `assets/interactuables/cofres/fog_masks/cofres_basicos_fog_hidden.png`.
- Explorado: `assets/interactuables/cofres/fog_masks/cofres_basicos_fog_explored.png`.

Las tres hojas son de 128 × 192 píxeles: tres filas de variantes y dos columnas
(cerrado/abierto), con frames de 64 × 64. Los sprites comparten posición inicial
`(0, -16)`, filtro Nearest y región. El selector `variante` (1–3) y `abierto`
actualizan las tres regiones en conjunto, incluso en el editor.

Las máscaras cubren la silueta del cofre; no incluyen el suelo. Visible apaga
ambas máscaras, explorado enciende `FogExplorado` y oculto enciende `FogOculto`.
El sprite normal permanece debajo cuando las dos rutas están asignadas. No se
conserva una imagen del último estado visto fuera de visión.

Las rutas deben apuntar a hijos propios: `Sprite2D`, `FogOculto`, `FogExplorado`.
Se corrigieron las estatuas `templo_estatua_11` y `templo_estatua_12`, cuyas rutas
apuntaban a la estatua 10; se verificaron los tres estados sin alterar esa estatua.
Revisar estas referencias al duplicar interactuables.

Activar `ajustar_a_celda_en_editor` ajusta la raíz a `CapaSuelo` de la zona.
La mayor altura de la tapa no amplía la huella, actualmente de una celda.
Los contenedores de organización, incluido `Interactuables/Cofres`, necesitan
Y Sort activado; el cofre y sus sprites se ordenan como conjunto, con Z Index 0.
`permite_caminar_interactuable()` devuelve `false`: la celda del cofre bloquea
el paso tanto abierto como cerrado. La apertura no cambia su huella ni este bloqueo.
El bloqueo de visión y proyectiles sigue heredando los valores de `Interactuable`.

## Límites actuales

No están implementados menú de click derecho por item, examen de items,
recogida individual desde la casilla, depósito ni selección de cantidades.
La transferencia del panel llama directamente al inventario, sin producir una
acción del gestor, coste de turno ni entrada narrativa por cada pila.

El guardado conserva la apertura y cada pila restante mediante ID de instancia,
definición, ruta y cantidad. La carga valida primero el documento completo,
comprueba la capacidad y la unicidad de IDs entre cofres, jugador y suelo, y luego
reemplaza el inventario del cofre sin recrear el contenido ya saqueado.
