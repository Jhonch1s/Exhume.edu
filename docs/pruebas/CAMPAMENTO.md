# Campamento: primer corte

Estado del 20-10-2026. Implementación local, sin commit y conservando los cambios
de otros chats. Este documento diferencia acuerdos y comportamiento provisional.

## Revisión jugable

Abrir `tests/interacciones/escena_prueba_campamento.tscn` en Godot y ejecutar F6.
Arranca Zona1 con cuatro PV menos y energía 50/200 para revisar la recuperación,
y entra al campamento. También se puede entrar desde cualquier escenario basado
en EscenarioBase con **B** o el botón **Campamento [B]**.

- Entrar es gratis y admite visitas ilimitadas. `DescansoCuevas.tscn` se carga como
  escenario explorable con su propio tablero, niebla, cámara, personaje y HUD. Tiene
  suelo y paredes editables, entrada y fogata interactuable; el escenario de origen
  permanece vivo y suspendido.
- Al interactuar con la **fogata** se despliegan Descansar, Volver, Guardar y
  Cargar junto a sus acciones de luz. No hay panel fijo sobre el escenario.
  **Descansar** abre un segundo menú junto a la fogata con el coste. Cancelar conserva todo.
  Confirmar gasta **1 ración** y recupera **todos los PV, la energía y los usos de
  habilidades activas**, según la
  elección explícita del usuario. Confirmar dos veces no gasta dos unidades.
- **Volver a explorar**, **B** o **Esc** regresan al mismo punto. Con cero
  provisiones se puede visitar y salir; el descanso queda deshabilitado.
- **F5/Guardar** y **F9/Cargar**, dentro del campamento, usan la partida normal
  `user://partida.json`. La prueba automática usa un archivo temporal distinto.
  No guardar/cargar ni regresar mientras la confirmación está abierta.
- Durante combate, movimiento de jugador/NPC, acciones, lanzamiento, diálogos o
  paneles modales no se puede entrar. El botón muestra el motivo al apuntarlo.

El escenario de prueba es un fixture: sus PV/energía iniciales son deliberados.
El flujo normal de creación del aventurero no cambia.

Para diseñar el descanso, abre `scenes/DescansoCuevas/DescansoCuevas.tscn` en el
editor. F6 permite probarlo como cualquier zona. La escena se creó a partir de
`scenes/ZonaPlantilla/zona_plantilla.tscn`; su README indica cómo crear otras zonas.
El estado del mapa de descanso (posición, niebla e interactuables) se reinicia al
entrar. En este corte, el estado persistente sigue siendo el del origen y la
recuperación opcional; no se guardan cambios de diseño jugados dentro del descanso.

## Acuerdos y límites

Acceso, visitas, bloqueo, descanso opcional, coste y recuperación están acordados.
La **suspensión del mundo es provisional**: no avanzar patrullas, estados ni
superficies conserva el origen sin introducir horas o turnos ficticios. Sigue
pendiente la respuesta a esa regla de simulación. No se ejecuta la tirada 5+
del panfleto ni se simulan ocho horas. Descansar no repone acciones por turno,
no elimina veneno y no consume antorchas.

Las provisiones usan `Ficha.raciones`, ahora persistido. No hay inventario de
comida ni reposición. «Ataque doble» del Guerrero ya guarda un uso propio `1/1`
y se recupera al descansar; las próximas habilidades seguirán esa regla.

El guardado se carga desde el mismo mapa de origen. Otra zona se rechaza antes
de cambiar datos. El Templo ya tiene identidad propia; los guardados antiguos
que llamaban `zona1` a cualquier mapa se aceptan sólo si todo su contenido es
compatible. No hay nuevo selector de partidas ni viaje automático entre mapas.

## Persistencia

- El escenario de origen no se libera, reemplaza ni vuelve a generar al visitar.
  Conserva NPC/cadáveres, objetos, posición, niebla y estado de ficha. Se pausan
  sus sonidos y procesamiento; la fogata del campamento tiene ambiente propio.
- Se añaden a snapshots v2 los campos opcionales `escena_zona`, `en_campamento`,
  `celdas_exploradas`, `ficha.raciones`, `ficha.usos_ataque_doble`,
  `ficha.usos_ocultarse`, `ficha.turnos_oculto` y `ficha.usos_bola_fuego`. Se validan
  antes de restaurar. Los snapshots antiguos sin raciones toman 3; sin el uso de
  la habilidad toman `1/1`; sin marca de campamento abren mundo.
- Se guarda el terreno conocido y se reconstruye la máscara antes del único
  recálculo desde la ficha restaurada. La visibilidad actual sigue siendo derivada.
  Guardados antiguos sin exploración no contienen el recorrido previo recuperable.

## Comprobado

Godot 4.7 estable, prueba `tests/interacciones/prueba_campamento.gd`: **149
comprobaciones, cero fallos** en Zona1 y Templo. Cubre ida/vuelta repetida con
nodos idénticos, posición, niebla, puerta modificada, cadáver, objeto de suelo,
superficie con duración y conocimiento; apertura/cancelación/confirmación única;
bloqueos de combate/modal/movimiento/acción; guardado/carga desde campamento y
exploración, una nueva instancia, migración y rechazo atómico de datos corruptos.
También comprueba que se carga DescansoCuevas, que la fogata despliega las acciones
sin perder el encendido/apagado y que la ficha visible refleja los recursos del
origen y su recuperación.
La prueba `tests/interacciones/prueba_ataque_doble.gd` añade 25 comprobaciones
de uso, coste, objetivo inválido, dos golpes, muerte al primer golpe, HUD,
guardado/carga, descanso y probabilidad al apuntar un enemigo bajo el filtro CRT.
Las pruebas `prueba_ocultarse.gd` (20) y `prueba_bola_fuego.gd` (20) cubren
percepción, daño periódico, ataque que revela, duración, alcance, daño inicial,
ambos resultados de Quemado, uso, HUD, guardado/carga y descanso.
`prueba_escenarios_habilidades.gd` comprueba las dos arenas manuales, su clase,
la separación inicial sin agro, el uso fuera de combate y los atajos numéricos.

Las cámaras que generan las texturas direccionales de Guerrero, Mago y Ladrón
usan mundos 3D propios. La prueba verifica que los seis mundos del origen y del
campamento sean distintos: compartirlos superponía el modelo pausado del origen
con el modelo que gira al capturar las direcciones del campamento.

Regresiones: guardado completo (9), cámara (64), inicio de percepción (22),
ampliación por fuentes (22), luz/percepción (65), ficha/conocimiento, contenido
dinámico, bandos/combate (287) y diálogo con tirada (87). Cero fallos en las
ejecuciones finales registradas. También se renderizó y revisó una captura real
de la escena con OpenGL; la revisión manual completa del jugador queda pendiente.

Algunos tests existentes precargan scripts antes de los autoloads con `--script`;
para esas regresiones se usó un lanzador temporal en `.godot` que carga la prueba
de forma diferida. No se cambiaron sus reglas para evitar ese problema del runner.
La prueba nueva se puede ejecutar directamente:

```powershell
Start-Process C:/godot/Godot.exe -WindowStyle Hidden -Wait -ArgumentList '--headless','--path','C:/godot/exhum_edu','--script','res://tests/interacciones/prueba_campamento.gd','--log-file','C:/godot/exhum_edu/.godot/prueba_campamento.log'
Get-Content C:/godot/exhum_edu/.godot/prueba_campamento.log -Tail 20
```

El editor headless mostró errores previos de configuración del plugin Dialogue
Manager bajo el sandbox; las pruebas de juego y la captura no tuvieron errores
de scripts. Persiste el aviso previo de UID de la palanca de Zona1, resuelto por
Godot usando su ruta textual. No se modificaron esos recursos ajenos al corte.
