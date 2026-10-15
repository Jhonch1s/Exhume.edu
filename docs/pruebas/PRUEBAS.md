# Pruebas

La [consolidación de NPC del 15-10-2026](CONSOLIDACION_NPC.md) registra las
correcciones de estados JSON y carga desde otro encuentro, la prueba de archivo
recuperada y los conteos de rutas/FOV. Las cifras siguientes incluyen ese corte.

Consecuencias configurables: `prueba_consecuencias_dialogo_npc.tscn` pasó 162
comprobaciones de ramas, actitud/información, intento único o repetible, K/C,
guardados anteriores, memoria inválida y configuración inválida sin efectos
parciales. Escena manual: `escena_consecuencias_dialogo_npc.tscn`;
[construcción en Inspector](../contenido/CONSECUENCIAS_DIALOGO_NPC.md) y
[recorrido jugable](DIALOGOS_CON_TIRADAS.md). También pasaron el diálogo base
(87), estado NPC (21 grupos), actitud, conocimiento (6 casos) y diálogos
interactuables. Revisión manual del catálogo pendiente (15-10-2026).

Diálogo con tirada: `prueba_dialogo_tirada_npc.tscn` pasó 87 comprobaciones de
éxito/fallo, crítico/pifia, una sola presentación y registro por elección, doble
clic, animación sin azar adicional y bloqueo/liberación de K/C. Escena manual:
`escena_dialogo_tirada_npc.tscn`; [guía](DIALOGOS_CON_TIRADAS.md). También pasaron
actitud, diálogos interactuables, motor de dados, pruebas Exhume e historial.
El usuario confirmó su funcionamiento en juego (15-10-2026), sin detallar pasos.

Táctica NPC: `prueba_tactica_npc.tscn` pasó 68 comprobaciones de objetivos por
visión/bando, estados, combate real con poca vida sin huida/humo automático,
inventario, K/C y cadáver/botín. Huida y uso automático de humo quedan incompletos
y aplazados tras el problema de regreso/reentrada en combate observado por el
usuario. Escena manual: `escena_tactica_npc.tscn`; [guía vigente](TACTICA_NPC.md).
Los scripts antiguos `SceneTree` con autoloads pueden ejecutarse mediante
`tests/ejecutar_con_autoloads.gd -- res://ruta.gd`.

Campos de visión NPC: `prueba_facciones_npc.tscn` comprueba colores por relación
y bando vigente, ocultación de NPC y casillas, pared, Trompo, cadáver y alternancia.
La revisión visual de V se describe en [Campos de visión de NPC](VISION_NPC.md).
El 15-10-2026 el usuario confirmó que funciona en juego, sin detallar pasos.

XP directa/indirecta: `prueba_xp_indirecta_npc.tscn` pasó 231 comprobaciones de
veneno y quemado al cerrar turno, explosión múltiple, fuentes sin autor, bando,
exclusiones, entrega única, cierre, K/C y guardados anteriores. Escena manual:
`escena_xp_indirecta_npc.tscn`. `prueba_facciones_npc.tscn` conserva la cobertura
de daño directo, barra, aliados, entrega única y persistencia. Recorrido jugable en
[XP de NPC](XP_NPC.md). El usuario confirmó recepción de XP el 15-10-2026;
no detalló todas las fuentes ni los casos de carga del recorrido manual.

Facciones y bandos: `prueba_facciones_npc.tscn` pasó 287 comprobaciones de auxilio por visión,
prioridades, bandos, iniciativa, memoria compartida sólo entre aliados, turno
real entre NPC, K/C y migración, atomicidad, cadáver y botín. Escena manual:
`escena_facciones_npc.tscn`; [guía](FACCIONES_NPC.md). Implementación y revisión
automática del 14-10-2026. El 15-10-2026 el usuario probó la escena y comunicó
que las pruebas parecen funcionar, sin detallar la cobertura manual.

Actitud: `prueba_actitud_npc.tscn` cubre puntos, migración, defensa, mutaciones
reales de Dialogue Manager y K/C sin repetir consecuencias. La escena manual
`escena_actitud_npc.tscn` y su [guía](ACTITUD_NPC.md) permiten revisar el neutral
dinámico, el neutral fijo combatiente y la excepción de Trompo.
El usuario confirmó la revisión manual y el funcionamiento el 11-10-2026;
el bloque de actitud queda cerrado.

Las pruebas headless bajo `tests/` protegen contratos, atomicidad y verticales reales.

## Capas

- Contratos puros: contexto, opciones, resultados, definiciones y agregadores.
- Servicios: validación espacial, costes, examen, efectos, turnos y persistencia.
- Contenido: puertas, palancas, trampas, superficies e items.
- Integración: menú contextual, movimiento, lanzamiento y escena principal.
- Herramientas: prevalidación de zona, inspección de celdas y registro filtrable.

Una prueba se elimina cuando su comportamiento queda cubierto por otra más directa,
no solamente porque pertenezca a una fase antigua.

`tests/interacciones/prueba_antorchas_hud.tscn` cubre inventario y consumo de
antorchas, engarces, retratos, tooltips de quemado y veneno, luz inicial,
propiedades de `DefinicionAntorcha`, atenuación y apagado al agotarse. También
comprueba que la llave y la bomba de humo de prueba no aparezcan al iniciar el
escenario. `prueba_integracion_menu_contextual.gd` crea esos objetos dentro de
la propia prueba para verificar sus interacciones sin poblar el juego.

`tests/interacciones/prueba_estado_npc_persistente.tscn` comprueba el estado
inicial de Trompo, su actitud fija, la restauración de PV cero, nivel y atributo,
la memoria narrativa, el rechazo de datos inválidos y la lectura de snapshots v1.
También comprueba daño, curación, señales y aplicación de daño a un NPC mediante
`AplicadorEfectos`. Un enemigo de prueba verifica la opción `Atacar`, alcance,
tirada de FUE, daño tras acierto y esquiva fallida, coste aun al fallar y ausencia de la opción al
quedar derrotado.

`tests/interacciones/escena_npc_hostil.tscn` es una escena de revisión manual.
Desde el corte grupal del 09-10-2026 genera tres hostiles de 2 PV por defecto junto
al inicio de `Zona1`; `cantidad_enemigos` admite de uno a cinco. Estos NPC no forman
parte del contenido permanente. Clic izquierdo muestra acciones, clic derecho mueve,
K guarda en `user://prueba_npc_hostil_3_enemigos.json` y C carga de forma explícita.
Con un enemigo conserva `user://prueba_npc_hostil.json`; otras cantidades usan
su propio sufijo. El grupo reúne los detectores al iniciar y comparte agro hasta
que ninguno de los participantes vivos vea al jugador. La revisión jugable del
grupo sigue pendiente; las confirmaciones siguientes corresponden a un objetivo.
El usuario confirmó en Godot el ataque hasta 0 PV, el paso sobre la casilla del
NPC derrotado, `Examinar`, la desaparición de `Atacar` y la restauración de ese
estado con K/C. El objetivo de prueba no tiene diálogo, así que la ausencia de
`Hablar` a 0 PV sigue sin comprobación visual. La carga headless registró el
objetivo, aunque su renderer dummy no pudo capturar los retratos 3D de la ficha.

La misma escena permite revisar el primer modo de combate: `Atacar` inicia el
encuentro, arriba aparece el orden de turnos, `Pasar turno` muestra el pase del
NPC y comienza otra ronda, y K/C conservan ronda, actor activo y recursos del
jugador. Al llegar el objetivo a 0 PV desaparece el panel y vuelve exploración.
El usuario informó que el primer flujo de combate funcionó en Godot. Queda
pendiente una comprobación detallada de K/C durante un combate activo y la
revisión visual del HUD superior se hará más adelante.

Segundo corte confirmado por el usuario el 05-10-2026: al pasar turno estando adyacente,
el NPC debe intentar una tirada de FUE, registrar acierto o fallo y gastar su
acción principal. Si está lejos, debe pasar sin atacar ni acercarse. Guardar y
cargar con K/C durante el turno del NPC debe conservar su recurso restante
para evitar repetir un ataque ya resuelto. Si el jugador llega a 0 PV, el
encuentro termina y no debe permitirle seguir actuando.

El usuario confirmó guardado OK con F7, pero F8 detenía la ejecución. El log
señaló que `Ficha._aplicar_visual_clase()` intentaba volver a añadir el sprite
y sus partículas, que ya tenían padre. La corrección reutiliza esos nodos.
`tests/interacciones/prueba_carga_visual_ficha.tscn` verifica tres restauraciones
desde JSON con nodos visuales existentes, conserva PV y acción gastada y comprueba
la creación inicial del sprite. Los cuatro grupos pasaron en Godot headless;
queda pendiente la comprobación manual de C durante el combate. El cierre al
pulsar F8 persistía por el atajo de parada del editor de Godot; F7 es pausa.
Las teclas de la escena se cambiaron a K para guardar y C para cargar.

El usuario confirmó que cargar con C funciona. La observación posterior de que
la piedra cambiaba de aspecto motivó guardar su `variante_visual`.
`tests/interacciones/prueba_variante_item_suelo.tscn` usa el receptor de registro
de `EscenarioBase` para comprobar cargas repetidas, las tres variantes de piedra,
posición y cantidad, compatibilidad con guardados anteriores y rechazo de índices
inválidos. Al cargar un guardado antiguo, el siguiente guardado ya incluye la variante.
Estas comprobaciones pasaron en Godot headless el 05-10-2026.

`tests/interacciones/prueba_esquiva_automatica.tscn` pasó 20 casos el 05-10-2026:
ataque y esquiva simétricos para jugador y NPC, críticos y pifias, esquiva con
reacción agotada, daño sólo tras esquiva fallida y pago de acción al intentar.
Comprueba que un fallo de FUE no tira DES, que las copias de resultado conservan
ambas pruebas y que el registro explica la esquiva sin anunciar daño.
Fuera de alcance, atributo inválido, defensor derrotado o acción ya gastada
bloquean el intento sin consumir azar ni recursos. También pasaron los 21 grupos
de `prueba_estado_npc_persistente.tscn` y los 3 de `prueba_resultado_accion.gd`.
La revisión jugable básica de esta esquiva quedó confirmada por el usuario
el 06-10-2026, junto con inicio/orden de combate, ataque adyacente y pase desde
lejos, K/C durante el turno del jugador conservando PV/ronda/recursos, apariencia
de la piedra al cargar y derrota con examen, paso y fin de combate.
El usuario informó que toda la lista funciona. La carga en mitad de la resolución
automática del turno del NPC y el ejemplo interactivo de LimboAI no formaban
parte de esa lista.

## Revisión pendiente: movimiento compartido y persecución — 06-10-2026

Este incremento se importó y la escena hostil se abrió en el editor headless sin
errores de scripts. No se añadieron ni ejecutaron pruebas del movimiento nuevo.
La comprobación con `--check-only --script` aislada no admite los autoloads
`EstadoPartida`/`CursorJuego`; sus mensajes no equivalen a una ejecución del proyecto.

Revisión manual propuesta en `tests/interacciones/escena_npc_hostil.tscn` con F6:

1. Mover la ficha en exploración: dirección visual, coste de terreno, consumo de
   energía y movimiento, renovación de turnos y reacciones conservadas.
2. Iniciar combate con `Atacar`, alejarse y pasar turno: el NPC se acerca por
   casillas libres. Si llega adyacente con acción principal, intenta atacar en
   ese mismo turno; el registro muestra movimiento y FUE/DES.
3. Alejarse más que su reserva: debe detenerse al agotarla y pasar. Probar una
   ruta con coste adicional y un destino sin camino: sin atravesar bloqueos,
   ocupar la ficha ni repetir decisiones indefinidamente.
4. Examinar la casilla anterior y la nueva del NPC: sólo debe estar registrado
   en la nueva; a 0 PV conserva el comportamiento de derrota existente.
5. Guardar con K durante el turno del jugador, dejar que el NPC se desplace y
   cargar con C: vuelven posición visual, ubicación lógica, PV, ronda y reservas
   guardadas. Repetir la carga para comprobar que no quedan presencias duplicadas.
6. K/C durante una animación de ficha o NPC: operación rechazada, sin cambiar
   la partida. Fuera de la animación, cargar un turno de NPC debe reevaluar desde
   sus reservas restauradas.

El usuario confirmó que el movimiento funciona. Los estados temporales compartidos
se incorporaron después, en el incremento del 08-10-2026 descrito abajo.

## Revisión pendiente: estados compartidos y liberación — 08-10-2026

La importación y apertura de la escena hostil en el editor de Godot terminaron
sin errores de scripts. No se añadieron ni ejecutaron pruebas de este incremento.

El usuario confirmó el 08-10-2026 que realizó la revisión de telaraña y caída.
Esto no confirma por separado quemado, veneno ni guardado/carga con estados activos.

Revisión manual propuesta con F6 en `tests/interacciones/escena_npc_hostil.tscn`:

1. Hacer que el NPC cruce hielo/lodo: si falla DES y cae, detiene la ruta y pasa
   el turno una sola vez. Repetir con la ficha durante combate: no debe renovar
   recursos ni continuar moviéndose hasta su siguiente turno.
2. Hacer que el NPC entre en telaraña: se detiene e intenta liberarse primero,
   incluso adyacente al jugador. El registro identifica al NPC y la prueba DES.
3. Si falla al liberarse, conserva enredado y paga la acción. Sin acciones pasa;
   no ataca mientras sigue atrapado. En su próximo turno vuelve a priorizar liberarse.
4. Si acierta, retira enredado y puede usar el movimiento restante; no recibe
   otra acción principal por haberse liberado.
5. Guardar con K un NPC enredado durante el turno del jugador y cargar con C:
   conserva posición, estado y reservas. La carga no libera ni consume ticks.
6. Revisar quemado/veneno en el NPC: daño y expiración al cerrar su propio turno;
   K/C debe conservar los ticks. Un guardado anterior sin `estados` de NPC debe
   restaurarlo sin efectos temporales de la ejecución actual.

La ruta evita terrenos costosos cuando tiene alternativa; puede ser necesario
colocar la superficie en un paso obligado para observar estas reacciones.

## Revisión pendiente: agro de cuatro casillas — 08-10-2026

La escena hostil busca primero una posición a cinco casillas; si no existe una
visible y accesible, usa cuatro, tres o dos. Una posición inicial dentro del radio
puede iniciar combate automáticamente. No se añadieron ni ejecutaron pruebas
automáticas de este incremento.

Revisión manual propuesta con F6:

1. Con el ajuste del 09-10-2026, a cinco casillas y visión despejada el goblin
   ya inicia combate: su alcance actual es doce. Al entrar en ese alcance se detiene
   la ruta de exploración; el registro identifica al detector.
2. Dentro del alcance con una pared, puerta cerrada o humo entre ambos, no detecta.
   Despejar la línea permite iniciar el encuentro sin pulsar Atacar.
3. Un NPC neutral, derrotado o sin combate no inicia encuentros. Trompo mantiene
   su actitud fija neutral. La iniciativa determina quién actúa primero.
4. K/C durante combate conserva ronda, PV y reservas sin reiniciar el encuentro.
   Cargar una exploración dentro del agro permite una nueva detección desde las
   posiciones restauradas. Perder detección durante combate devuelve exploración.

## Revisión pendiente: movimiento DES + 3 — 08-10-2026

La importación y apertura de escena en el editor de Godot terminaron sin errores
de scripts. No se añadieron ni ejecutaron pruebas de este incremento.
Revisión manual propuesta:

1. Un NPC con DES 2 sin movimiento fijo dispone de cinco puntos; una ficha con
   DES 4 dispone de siete. Al pasar turnos se recupera el máximo propio de cada uno.
   El goblin hostil de F6 usa ahora movimiento fijo cuatro, manteniendo DES 2.
2. Comprobar que terreno difícil y telaraña consumen sus costes reales y la
   previsualización no permite superar la reserva; caída y liberación conservan
   sus reglas de interrupción, coste y prioridad.
3. K/C después de gastar movimiento: mantiene los restantes y la ronda. Cargar
   atributos diferentes a los actuales debe calcular el máximo con DES guardada.
4. Un archivo anterior sin `movimiento_maximo` migra desde siete conservando el
   gasto: DES 2 con cuatro restantes pasa a dos restantes de un máximo cinco.
   Un máximo explícito que no corresponda a DES se rechaza antes de modificar la partida.

Desde el 09-10-2026 perder agro termina el encuentro; ver la revisión siguiente.

## Revisión pendiente: búsqueda y huida — 09-10-2026

Importación y apertura de escena en Godot sin errores de scripts. No se añadieron
ni ejecutaron pruebas de este incremento. Revisión manual propuesta con F6:

1. Iniciar combate y alejarse fuera del radio configurado de todos los goblins
   (doce por defecto tras el ajuste de balance): inmediatamente aparece
   `Has escapado`, se oculta el panel y vuelve el movimiento de exploración.
   En los turnos de exploración el NPC busca la última casilla donde te detectó
   y luego regresa al origen, sin usar la nueva posición oculta.
2. Ocultarse tras una esquina o puerta: busca el recuerdo. Si una puerta deja
   toda la ruta bloqueada, conserva el recuerdo y espera. No abre puertas;
   si una casilla se despeja, recalcula con el movimiento restante. Si el origen
   está ocupado, aplica la misma regla sin atravesar al ocupante.
3. Volver a estar dentro de radio y visión mientras busca: detiene el plan en
   una casilla confirmada e inicia otro combate por iniciativa.
4. Agotar movimiento antes de llegar: pasa y continúa el próximo turno. En
   telaraña intenta liberarse primero; caer cierra su turno una sola vez.
5. K/C en reposo después de perder detección: conserva el origen, el recuerdo
   y los recursos, sin actualizarlo desde la posición oculta restaurada.
   Un archivo antiguo sin recuerdo sólo lo obtiene si vuelve a detectar.
6. Fin por huida no añade un turno ni una ronda artificial, mantiene PV del NPC
   y permite otro combate al reentrar en agro. Los estados continúan durante los
   turnos de exploración. Memorias y orígenes mal formados o fuera del tablero se
   rechazan antes de modificar la partida.

## Estado de las comprobaciones de cofres — 14 de septiembre de 2026

- El usuario ejecutó la prueba de capacidad y la prueba visual de casilla y confirmó
  sus resultados. La generación de contenido fue comprobada manualmente en juego;
  los items sin icono existen aunque su imagen no aparezca.
- `prueba_layout_panel_cofre.gd` verificó cuatro tamaños con casillas estáticas.
  Después el panel pasó a generar casillas en `mostrar()`. La prueba debe adaptarse
  para abrir un cofre con contenido y exigir el número esperado de casillas: tal
  como está, su bucle puede pasar sin comprobar ninguna casilla.
- La prueba propuesta de panel dinámico no fue ejecutada por el usuario. No hay
  cierre de regresión de apertura, recogida total ni modal.
- `prueba_persistencia_cofre.gd` verifica apertura, pilas restantes y rechazo de
  contenido inválido. La prueba completa de archivo incluye ahora el cofre real.
- Las rutas corregidas de las estatuas 11 y 12 se comprobaron mediante una prueba
  temporal en Godot: visible, explorado y oculto, sin modificar la estatua 10.
  Esa prueba temporal no forma parte de la suite conservada.

- `prueba_cofre_no_caminable.gd` verifica la caminabilidad efectiva de una celda
  con cofre abierto/cerrado y después de retirarlo. Es una comprobación puntual;
  no sustituye la regresión pendiente del flujo de inventario.
