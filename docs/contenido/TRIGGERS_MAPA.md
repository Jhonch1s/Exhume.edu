# Triggers del mapa

Los triggers ejecutan eventos al entrar en una región o cruzar un umbral del
tablero. Se configuran desde el Inspector y permanecen invisibles al jugar.

## Crear un trigger

1. Abre una zona. En `Triggers/Dialogos`, `Triggers/Mecanismos` o `Triggers/Viajes`,
   instancia `scenes/zonas/TriggerMapa.tscn` según su acción. La plantilla incluye
   los tres contenedores. En mapas anteriores puedes crearlos como `Node2D`
   bajo `Triggers`, dentro de la raíz de la zona. El gestor descubre los triggers
   también dentro de estos subgrupos.
2. Asigna `id_trigger`, por ejemplo `entrada_sala_trompo`. Debe ser único en ese
   mapa y permanecer estable. Al duplicar un trigger, cambia su ID; el editor
   advierte si hay duplicados.
3. Arrastra el nodo a una casilla. Se centra automáticamente sobre `CapaSuelo`.
4. Configura `forma`, tamaño o longitud y `frecuencia`.
5. En `accion`, crea un recurso `AccionTriggerDialogo` o
   `AccionTriggerMecanismo` o `AccionTriggerViajar` y completa sus propiedades.
6. Ejecuta la zona con F6 y atraviesa el contorno. Para verlo durante las pruebas,
   activa `mostrar_en_juego` en esa instancia.

El trigger muestra advertencias hasta colocarlo en una zona y asignarle ID y
acción. El contorno turquesa muestra la geometría; al deshabilitarlo se dibuja
gris. Una configuración inválida se omite al iniciar con un aviso que identifica
el nodo y el problema.

## Formas y frecuencia

| Propiedad | Comportamiento |
|---|---|
| `ZONA` | Rectángulo de `tamano` casillas, desde el nodo hacia +X y +Y. Se activa al pasar de fuera a dentro. |
| `UMBRAL_X` | Frontera entre la casilla del nodo y su vecina +X. `longitud_umbral` la extiende hacia +Y. |
| `UMBRAL_Y` | Frontera entre la casilla del nodo y su vecina +Y. Se extiende hacia +X. |
| `UNA_VEZ_POR_PARTIDA` | Recuerda la activación al regresar al mapa y al guardar/cargar. |
| `CADA_ENTRADA` | Se activa en cada nueva entrada o cruce. Caminar dentro de la región no lo repite. |

X e Y son los ejes del tablero, dibujados en diagonal en la vista isométrica.
Los umbrales funcionan en ambos sentidos. Una habilidad que salta de un lado a
otro también cruza el umbral si su segmento lo atraviesa. Una región se activa
por el destino: saltar por encima y aterrizar fuera no equivale a entrar.

El tamaño máximo es 64 por eje y la longitud máxima del umbral es 64. La región,
o ambos lados del umbral, deben estar dentro del terreno del tablero. Para avisos
en el editor se comprueba el suelo pintado en `CapaSuelo`.

## Mostrar un diálogo

Crea `AccionTriggerDialogo` en `accion` y asigna:

- `recurso_dialogo`: archivo `.dialogue` de Dialogue Manager.
- `punto_inicio`: etiqueta existente, normalmente `start`.

El inspector avisa si falta el recurso o la etiqueta. El diálogo recibe al jugador
y al escenario como estados adicionales. Las pruebas y consecuencias específicas
de una conversación de NPC siguen usando la
[guía de diálogos de NPC](CONSECUENCIAS_DIALOGO_NPC.md).

La ruta termina en la casilla que activó el evento. Al cerrar el diálogo, el
jugador elige su siguiente movimiento. Durante la espera y el diálogo se bloquean
interacciones, guardado, viaje y avance incompatible de turnos/NPC. Otro diálogo
o una resolución en curso aplaza la presentación.

## Activar un mecanismo

Crea `AccionTriggerMecanismo` y configura:

- `id_receptor`: ID estable del objeto, por ejemplo una puerta controlada por
  mecanismo.
- `activar`: `true` para activar/abrir; `false` para desactivar/cerrar.

El receptor implementa `validar_cambio_mecanismo` y `aplicar_cambio_mecanismo`,
el mismo contrato que usan las palancas. El trigger aporta su ID como emisor.
Esta acción establece el estado indicado: cruzar repetidamente un trigger con
`activar = true` mantiene abierta la puerta.

Si el receptor no existe o rechaza la acción, aparece un aviso y el trigger no
se consume. Después de corregir el contenido, una nueva entrada puede reintentarlo.

## Escena de prueba

Abre `tests/zonas/zona_triggers.tscn` y ejecuta F6.

- El jugador aparece en `(0, 0)`. Usa clic derecho para caminar hacia `(3, 0)`:
  al entrar en `(2, 0)` se interrumpe la ruta y aparece un diálogo de prueba.
- Cierra el diálogo y sigue hacia `(6, 0)`: al pasar de `(5, 0)` a `(6, 0)` se
  activa el umbral y se abre la puerta en `(7, 0)`.
- Regresa a la región del diálogo: no se repite en esa partida.
- Activa `mostrar_en_juego` en los triggers para ver los contornos de prueba.
- Camina desde `(0, 2)` hacia `(0, 3)`: el umbral `PasoAlTemplo` cambia al
  Templo de las Trampas y coloca al jugador en su spawn `entrada`.

El mapa utiliza una región de 2×2 casillas, un umbral de mecanismo de longitud 3
y un umbral de viaje de longitud 2.

## Viajar a otro mapa y elegir el spawn

En `accion`, crea `AccionTriggerViajar` y configura:

| Campo | Ejemplo |
|---|---|
| `escena_destino` | `res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn` |
| `id_spawn_destino` | `entrada` |

Para elegir otra entrada, abre el mapa de destino, instancia
`scenes/zonas/PuntoSpawnZona.tscn` bajo `PuntosSpawn`, arrástralo sobre una casilla
libre y asigna un `id_spawn` único, por ejemplo `desde_prision`. En el trigger
de origen usa exactamente ese valor en `id_spawn_destino`. Se utiliza el ID del
marcador, independientemente del nombre del nodo en el árbol.

Para un paso de ida y vuelta, crea un trigger en cada mapa y apunta cada uno al
spawn correspondiente del otro. Usa `CADA_ENTRADA` si se puede viajar repetidamente.
Las rutas de escenas se guardan como texto para que ambos mapas puedan apuntarse
entre sí sin referencias circulares entre recursos. Godot puede serializar la
selección como `uid://`; la acción lo resuelve a la ruta del mapa antes de viajar.

El viaje se permite fuera de combate, una vez terminados los movimientos y las
acciones en curso. Se prepara el destino antes de abandonar el mapa actual. Si
la escena, el spawn o el estado guardado del destino son inválidos, se conserva
el origen y no se consume el trigger. La llegada al spawn no cuenta como entrada
a un trigger, por lo que no provoca un viaje de regreso automático.

Se conservan vida, energía, inventario, equipo, progresión y memoria narrativa.
Los mapas visitados conservan sus objetos, superficies y exploración al regresar,
y se incluyen en los archivos de guardado. Agarre, señuelos y continuidad de un
recorrido se limpian al cambiar de zona porque referencian al mapa anterior.

`tests/zonas/zona_viaje_destino.tscn` incluye un spawn adicional `desde_prueba`;
la suite de viajes comprueba esa entrada distinta a `entrada`, el retorno al
origen y un viaje al templo real.

## Estado e integración

`GestorTriggersMapa` consulta los pasos confirmados recibidos por
`EscenarioBase._procesar_entrada_paso_actor()`, después de las consecuencias
del terreno y las habilidades. El callback reserva eventos e interrumpe rutas;
la presentación sucede después, desde el procesamiento del escenario.

Se registran únicamente entradas del jugador principal. Aparecer inicialmente,
cargar una partida o restaurar la posición no dispara eventos. Si el jugador
queda incapacitado antes de presentar el evento, se descarta lo pendiente sin
consumirlo. Los eventos coincidentes se ordenan por ID y se ejecutan de uno en uno.

Los consumidos se guardan en `EstadoPartida`, por zona e ID. La memoria narrativa
acepta guardados anteriores sin este campo y los interpreta con cero consumos.
Crear un aventurero nuevo reinicia la memoria. Los recursos de acción pueden
compartirse entre triggers: no contienen estado de ejecución.

Para agregar otra acción, extiende `AccionTrigger`, implementa
`validar_configuracion()` y `ejecutar(escenario, trigger)`. El segundo devuelve
un `StringName` vacío al confirmar la acción o un motivo de fallo. Las acciones
pueden esperar una operación asíncrona: el gestor mantiene el bloqueo y confirma
el consumo cuando `ejecutar()` devuelve éxito. Una presentación de diálogo
registra su globo con `gestor_triggers.esperar_globo()` y conserva el bloqueo
hasta que se cierre. Un viaje cancela los demás eventos del mapa abandonado.

## Verificación automatizada

```powershell
$env:APPDATA = 'C:/godot/exhum_edu/tmp/godot-triggers'
$env:LOCALAPPDATA = $env:APPDATA
C:/godot/Godot_v4.7-stable_win64_console.exe --headless --path C:/godot/exhum_edu --script res://tests/ejecutar_con_autoloads.gd -- res://tests/zonas/prueba_triggers_mapa.gd
```

La suite comprueba geometría, umbrales en ambos sentidos, interrupción segura,
diálogo y cierre, mecanismos, eventos coincidentes, combate, desplazamiento por
habilidad, guardado/carga, compatibilidad, ID duplicado, configuración fallida,
frecuencia repetible y partida nueva.

Los viajes se verifican con el mismo lanzador, usando
`res://tests/zonas/prueba_viaje_entre_zonas.gd`: 26 comprobaciones de cambio real,
spawn elegido, conservación de ficha y mundo, guardado/carga, retorno, destinos
inválidos, selección de destino por UID y rechazo de mapas guardados corruptos.
