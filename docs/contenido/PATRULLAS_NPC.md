# Patrullas de NPC

Implementadas para revisión el 09-10-2026. `PatrullaNPC` es una capacidad opcional
de la instancia: una ruta no vuelve hostil a un NPC ni le permite combatir.
Reutiliza el árbol de LimboAI, DES + 3 y el movimiento por casillas existente.

## Dibujar una ruta en Godot

1. Coloca una instancia de `scenes/personajes/npc.tscn` sobre el suelo de la zona
   y asigna definición e ID persistente único. Varios NPC pueden compartir definición.
2. Activa **Editable Children / Hijos editables** sobre la instancia y selecciona
   su hijo **Patrulla**. Es un `Path2D` con el script `PatrullaNPC`.
3. En **Curve**, haz el recurso único para esa instancia si corresponde. Usa las
   herramientas de edición de `Path2D` en la vista 2D para añadir o arrastrar al
   menos dos puntos distintos sobre casillas de suelo. Se numeran en su orden.
4. No repitas el primer punto al final: el circuito se cierra automáticamente.
   Los manejadores de curva no definen cómo camina: los puntos son destinos y la
   ruta real se calcula con pathfinding ortogonal, obstáculos y costes del terreno.
5. Configura **Turnos espera**: uno por defecto, cero para continuar con el
   movimiento restante al alcanzar cada punto. Guarda la escena.

Una curva vacía desactiva la patrulla. Un solo punto, puntos fuera del suelo o
puntos que caigan en la misma casilla no forman una ruta válida. Al registrarse
en el tablero, el NPC convierte los puntos visuales a coordenadas fijas del mapa;
no arrastra la ruta al caminar ni al cargar una posición distinta.

## Escena manual existente

`tests/interacciones/escena_npc_hostil.tscn` muestra el escenario en el editor.
Desde el 11-10-2026 contiene dos rutas independientes para la prueba de cruces:

- **RutaPatrulla** se aplica al NPC 1 y conserva los puntos ya dibujados.
- **RutaPatrulla2** se aplica al NPC 2 y tiene su propia curva. El usuario ya
  dibujó cuatro puntos para revisar los cruces.
- El NPC 3 no tiene ruta y permanece en reposo mientras no tenga otro objetivo.

Los tres NPC siguen creándose al ejecutar la escena. No hace falta añadir más
instancias en el editor: selecciona cada ruta en 2D y dibuja sus destinos con la
herramienta de añadir puntos de `Path2D`. Las curvas son recursos independientes.
Para el cruce, coloca los extremos de una ruta a ambos lados de una casilla y los
de la otra en el sentido perpendicular. Ajusta **Turnos espera = 0** en ambas si
quieres continuidad. Una ruta vacía deja quieto a su NPC. Guarda antes de F6.
El usuario confirmó que los NPC resuelven bien los conflictos al cruzarse.

### Comprobación de continuidad — 11-10-2026

Tras informar de una detención, el usuario autorizó ajustar las rutas y comprobar
varios circuitos. Con sus puntos originales se observaron 3 y 7 vueltas durante
40 segundos: ambos conservaban 2 PV, sin estados y renovaban el movimiento.
La primera patrulla tenía una espera de un ciclo al llegar a cada punto.
Se dejó **Turnos espera = 0** en ambas, conservando la geometría de los trazos.
La escena `tests/interacciones/prueba_continuidad_patrullas.tscn` completó con
salida cero: 9 vueltas por NPC durante 40 segundos, sin errores de scripts.
Se ejecutó sin ventana y con el jugador quieto; no reproduce una detención
permanente ni verifica el aspecto visual. Las pausas por renovación de movimiento
siguen siendo posibles aunque la espera en cada punto sea cero. Los menús modales
pausan la programación de nuevos ciclos; cerrar el menú permite reanudarla.

Las capas de interfaz y el filtro CRT del escenario se guardan ocultos para
dejar libre el mapa en el editor. Se muestran al ejecutar la escena. Si estaba
abierta al recibir este cambio, vuelve a abrirla para actualizar la vista.

Corrección del 11-10-2026: desplazar el nodo **Escenario** dejaba al jugador en
coordenadas locales tratadas como globales y la cámara miraba fuera del mapa.
La creación y carga de la ficha convierten ahora el centro de la casilla a
coordenadas globales; los clics convierten la posición del ratón al espacio local
del suelo. Se conservan la posición editada del escenario y los puntos de ruta.
Este ajuste no se ejecutó en el juego ni se comprobó con pruebas automatizadas.

Para observarla sin detección automática, configura **Radio vision enemigos = 0**
en la raíz antes de F6. Desde el 11-10-2026 los avances del NPC se producen
automáticamente, también con el jugador quieto. **Intervalo exploracion npc** en
el escenario regula los ciclos (un segundo provisional); **Turnos espera** cuenta
esos ciclos. No hace falta pulsar **Pasar turno** para activar la patrulla.
Los NPC sin ruta ni destino permanecen quietos. Devuelve el radio a doce
para continuar el combate de esta escena. Cuatro puntos de movimiento y aspecto
de goblin siguen siendo excepciones de este contenido manual, no reglas generales.

El corte inicial del 09-10-2026 se importó y abrió en el editor sin errores de
scripts, sin ejecutar el juego ni pruebas. El cambio de activación automática del
11-10-2026 se comprobó con autorización del usuario en
`tests/interacciones/prueba_exploracion_npc_autonoma.tscn`: curva guardada,
varios ciclos con el jugador quieto, recursos del jugador intactos, cola limitada
y pausa/reanudación por modalidad de combate. Godot terminó con salida cero.
La prueba usa texturas de sustitución sin ventana y no comprueba el aspecto visual.

## Prioridades y retorno

```text
Liberarse → Atacar → Acercarse → Buscar → Terminar búsqueda
→ Esperar en patrulla → Avanzar punto → Patrullar → Regresar al origen → Pasar
```

La patrulla sólo se elige fuera de combate, sin recuerdo pendiente del jugador.
Al alcanzar un punto, selecciona el siguiente y termina ese avance si hay espera.
Los próximos `turnos_espera` ciclos automáticos del NPC se consumen esperando;
los estados temporales siguen procesándose al cerrar cada uno. Con cero puede
visitar más de un punto en el mismo avance, pagando cada paso de su reserva.

Detectar al jugador interrumpe el recorrido en una casilla confirmada. En un
participante que obtiene una posición observada se cancela la espera pendiente,
conservando el próximo punto. Perder el agro colectivo mantiene primero la búsqueda
de la última casilla conocida. Tras terminarla, vuelve al punto pendiente del
circuito; sin ruta configurada, regresa al origen. No elige el punto más cercano
ni se teletransporta. Los NPC ajenos al encuentro también pausan sus recorridos
durante el modo combate global existente; no se cambió ese comportamiento.

Si un ocupante bloquea el destino o la ruta, recalcula y toma una alternativa
si existe. Sin alternativa conserva el punto y cierra el avance; vuelve a intentar
en el próximo ciclo automático. Desde el 11-10-2026 esa espera no mantiene un
movimiento abierto ni impide guardar en reposo. Nunca salta al punto siguiente
por no tener camino. Los actores reservan destinos y pueden moverse simultáneamente.

Si dos patrullas quieren la casilla ocupada por la otra, el NPC con menor ID
se aparta a una casilla vecina libre que pueda pagar con su movimiento. Conserva
su punto pendiente; no se teletransporta ni cambia la curva. Si no tiene espacio
para apartarse, ambos esperan entre ciclos y el guardado sigue disponible en
reposo. Esto cubre el intercambio entre dos NPC, no todos los bloqueos de grupos
o pasillos sin espacio. El ajuste todavía no se ejecutó en Godot.

## Guardado y carga

El campo opcional `estado.patrulla` del NPC guarda coordenadas del circuito,
espera configurada, índice del próximo punto y turnos de espera restantes.
Se valida la configuración, los rangos y los enteros antes de restaurar nada.
Modificar una ruta que ya está en un guardado provoca rechazo de ese guardado;
no se reinterpreta el índice sobre otra ruta. Un snapshot anterior sin patrulla
reinicia el índice en el primer punto y la espera en cero, conservando el resto
de sus datos.

Desde el 11-10-2026 **K** permite guardar durante movimiento y ciclos de IA:
conserva la última casilla confirmada y sus recursos y estados, sin detener al NPC.
No guarda la animación, reservas ni ruta calculada. **C** sigue exigiendo recorridos
y ciclos terminados. Al cargar, el NPC aparece en la casilla guardada y decide su
ruta desde el punto de patrulla pendiente. Ambas operaciones exigen cerrar los
paneles modales. La espera entre puntos es un contador lógico entre avances,
guardable en reposo; no añade un timer ni una animación en curso. Cargar conserva
ese contador sin consumirlo, iniciar turnos ni reponer recursos.

Los NPC neutrales con ruta habilitan `RecursosTurnoActor` para moverse y liberarse,
sin habilitar ataques. Un NPC neutral sin ruta conserva su estado anterior.
