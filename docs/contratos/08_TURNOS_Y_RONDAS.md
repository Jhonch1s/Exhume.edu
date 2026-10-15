> Continuidad del 09-10-2026: las reglas acordadas de agro colectivo, incorporación
> al final de la ronda, iniciativa tirada cada ronda, bandos y costes de objetos
> están en [NPC y diálogos](../contenido/NPC_Y_DIALOGOS.md). Agro colectivo y reunión
> de enemigos al inicio, incorporación dinámica de hostiles e iniciativa 1d6 + DES
> por ronda están implementados. Desde el 14-10-2026 también hay bandos y auxilio
> local por facción para encuentros con jugador. Huida y uso de objetos por NPC
> quedan pendientes; se conserva la selección táctica de objetivos.

### XP por muerte durante un encuentro — 15-10-2026

La muerte por daño de un NPC participante del bando opuesto al jugador concede
su recompensa completa a la ficha mientras el encuentro siga activo. No consulta
daño previo ni autor: incluye estados en FIN_TURNO, explosión, terreno y daño sin
fuente. La última víctima se premia antes del cierre diferido. El bando vigente
decide la elegibilidad; aliados, ajenos al encuentro y muertes fuera de él no
premian al jugador. Los NPC aún no acumulan XP. No cambia el avance de turnos ni
procesa un turno adicional para conceder XP. K/C conserva muerte y premio juntos.

### Decisión táctica del NPC — 15-10-2026

En combate se filtran los oponentes por visión propia antes de elegir objetivo:
adyacentes, con acercamiento pagable, demás; después menor PV, distancia e ID.
El recuerdo compartido conserva su selección anterior y sólo permite persecución,
sin habilitar ataques contra posiciones actuales ocultas.

LimboAI prioriza liberarse, atacar, acercarse y pasar. Caído conserva el cierre
de turno existente. La poca vida no activa huida ni uso automático de humo.
El usuario aplazó ambos tras observar en juego un regreso a la posición habitual
que provocaba volver al combate después de lanzar humo y perder visión.
Se retiró la opción provisional `retirarse_con_poca_vida`; no hay una capacidad
de huida terminada ni un dato nuevo de persistencia. El lanzamiento del jugador
y los contratos existentes de inventario, superficies y K/C se conservan.

Política y trabajo pendiente: [NPC y diálogos](../contenido/NPC_Y_DIALOGOS.md).

La prioridad de apoyo solicitada el 15-10-2026 todavía no está conectada: curación
propia bajo el 50 % y curación de NPC aliados antes del ataque, seguida de buff
propio si no hay uno activo. Requiere medios de curación/mejora ejecutables que
aún no existen; la operación de PV `curar()` no constituye por sí sola una acción
gratuita de combate. Costes, disponibilidad y estados se respetarán al conectar
el primer medio real. El árbol actual no concede curación ni buffs automáticos.

### Bandos del encuentro — 14-10-2026

`GestorRondas.bandos` relaciona IDs de participantes con `Bando.JUGADOR` o
`Bando.OPONENTE`; `NEUTRAL` significa ajeno al encuentro. `son_oponentes()`
requiere dos lados activos diferentes. Los turnos y tiradas no dependen del lado;
los aliados NPC usan el mismo movimiento, recursos y ataque contra otro NPC.
El HUD identifica aliados y oponentes. La oposición compatible del NPC se deriva
de su bando, separado de puntos y actitud fija.

El escenario conserva IDs `defendidos` para justificar auxilio posterior: NPC
agredidos al resolver un intento, y jugador amenazado en inicio hostil o agredido.
Testigos por facción deben ver ambas partes del intento resuelto; incorporación
posterior requiere percepción pertinente a min(7, radio propio), al final de
ronda, sin usar incorporados en la misma evaluación para convocar a otros.
Defensa propia, compañero de facción y relación con jugador son la prioridad;
mejorar/empeorar puntos no cambia un bando vigente. No hay deltas colectivos.

La memoria de oponentes se comparte sólo dentro del propio lado; atacar exige
visión propia. La memoria elige el conocido más cercano, desempate por ID;
el turno prioriza sus objetivos visibles según la política táctica anterior.
Sin detección por ningún NPC del encuentro se cierra combate, conservando la
búsqueda de hostiles y limpiando la de aliados/defensores no hostiles. Un aliado
vivo no impide terminar por muerte del último oponente. Liberación, estados,
iniciativa por ronda y reglas de incorporación conservan sus contratos.

Las secciones anteriores al 14-10-2026 que asumen todos los NPC enemigos
describen cortes históricos. El detalle vigente está en
[NPC y diálogos](../contenido/NPC_Y_DIALOGOS.md) y la migración en persistencia.

### Recursos separados del turno

`RecursosTurnoActor` conserva cuatro reservas independientes para ficha y NPC:
`movimiento`, `accion_principal`, `accion_adicional` y `reaccion`. Desde el
08-10-2026 el máximo de movimiento es **DES + 3**, calculado con la destreza
actual de cada instancia al iniciar el turno; las otras reservas siguen siendo
configurables y por defecto valen uno. Reponer el turno restaura máximos,
no energía persistente ni usos por descanso. `ProveedorCostesFicha` valida y cobra
estas claves mediante el mismo diccionario de costes ya usado por `GestorAcciones`.

Cada paso confirmado consume de `movimiento` el coste real de la celda y continúa
consumiendo `energia_actual` según la regla histórica. Fuera de combate, una ruta
que agota movimiento ejecuta un `FIN_TURNO`, repone recursos y continúa sólo si el
actor sigue vivo. En combate la ruta se detiene y no inicia otro turno.

La previsualización de combate recorta la ruta por la suma de costes reales, no por
cantidad de celdas. En exploración muestra la ruta completa que podrá encadenar
turnos. Destrabarse consume una acción principal al intentar; descansos y otros
usos especiales en combate todavía necesitan reglas propias.

`RecursosTurnoActor.calcular_movimiento()` es la fórmula común. DES 2, 3, 4 y 5
permiten 5, 6, 7 y 8 puntos respectivamente. Son casillas en terreno de coste uno;
los costes adicionales reducen la distancia recorrida. El NPC utiliza sus
atributos de instancia, incluidos valores iniciales propios o restaurados,
sin depender sólo de la destreza de su definición. El HUD y la previsualización
consultan la reserva efectiva. `DefinicionPersonaje.movimiento_fijo` permite fijar
el movimiento de un NPC: -1 conserva DES + 3. El goblin hostil de la escena manual
usa cuatro puntos por turno y radio de visión/agro doce por defecto, configurable
en la escena manual mediante `radio_vision_enemigos`, sin alterar su DES para
esquivar. El alcance de detección es independiente del movimiento y sigue exigiendo
línea visual; perderlo termina el modo combate como se describe más abajo.

El usuario aclaró que cuatro puntos fijos y la apariencia de goblin pertenecen
únicamente a estas pruebas. La regla del juego para los NPC sigue siendo DES + 3;
el contenido real no debe adoptar `movimiento_fijo = 4` como valor universal.
Con DES dos corresponden cinco puntos y con DES uno, cuatro. La existencia de
goblins en el contenido final no está decidida; las capacidades son comunes a NPC.

Doce es el ajuste provisional después de que el usuario encontrase demasiado fácil
escapar por distancia con visión seis. El mismo radio también rige el inicio de
detección; no se separaron alcances de activación y persecución. Perder visión por
paredes o humo sigue permitiendo la salida automática si ningún participante detecta.

### Primera integración del modo de combate

Actualización de actitud del 11-10-2026: un NPC vivo combatiente admite agresión
independientemente de su relación. La orden válida abre encuentro tras comprobar
atributos, alcance y costes; el golpe espera el turno de iniciativa. Al resolver
el intento se restan 2 puntos una vez, aunque falle o se esquive. Un bloqueo no
abre defensa ni modifica relación. Los participantes tienen oposición de encuentro
separada de sus puntos, incluyendo neutrales y amistosos. Usan ataque/detección
normales mientras dura el encuentro; mejorar puntos no los pacifica a mitad de éste.
Cerrar limpia oposición y, para los no hostiles, también la persecución. Los hostiles
conservan búsqueda y agro existentes. Actitud fija no impide defensa si hay capacidad
de combate; Trompo continúa sin ella. La incorporación de otros neutrales, bandos y
facciones no se amplía en este incremento.

Elegir `Atacar` contra un NPC hostil y combatiente inicia el modo de combate con
la ficha y ese objetivo. `GestorRondas` ordena por iniciativa descendente y una
franja superior muestra ronda, orden, actor activo y participantes derrotados.
La ficha conserva movimiento y acción principal como recursos independientes:
puede moverse y atacar mientras sea su turno y tenga recursos. `Pasar turno`
procesa sus estados, avanza al NPC y, cuando vuelve a la ficha, repone sus
recursos. El control del mapa se bloquea durante el turno del NPC.

En el segundo corte, un NPC hostil combatiente tiene su propio
`RecursosTurnoActor`. Si está a una celda Manhattan del jugador y conserva
acción principal, intenta un ataque básico automático: tirada de FUE con la
misma regla provisional del jugador, 1 PV de daño si acierta y coste de una
acción principal también si falla. El resultado aparece en el registro
narrativo. Si no está junto al jugador, pasa; todavía no se mueve ni elige
entre varias capacidades. Tras resolverlo, pasa el turno y la ronda continúa.
El incremento del 05-10-2026 añade esquiva automática al ataque de ambos bandos:
primero `1d6 ≤ FUE`; sólo si acierta, el defensor intenta `1d6 ≤ DES`. Una esquiva
exitosa evita todo el daño; fallarla permite el daño provisional de 1 PV. Ambas
pruebas respetan 1 crítico y 6 pifia, y el ataque crítico también admite esquiva.
La esquiva no consume reacción, no depende de su reserva y no repone recursos.
El atacante consume su acción principal incluso si falla o su ataque se esquiva.
El registro conserva las dos pruebas. No hay animación de esquiva. La persecución
se incorpora en el incremento del 06-10-2026, descrito abajo.

El combate termina si el objetivo llega a 0 PV o la ficha deja de poder actuar.
Al salir, la ficha viva repone recursos para continuar en exploración. Esto es
una regla provisional para el encuentro aislado: quedan por decidir detección
e inicio autónomo, varios enemigos, huida, otras defensas, más acciones del NPC y qué
interacciones se permiten durante el turno de combate. La iniciativa base del
NPC pertenece a `DefinicionPersonaje`; el objetivo de la escena de revisión usa
`-1` para que la ficha actúe primero. Trompo sigue siendo neutral y no entra en
combate.

### Movimiento compartido y decisión del NPC — 06-10-2026

`MovimientoPorCasillas` es un `RefCounted` por actor, usado por `Ficha` y
`PersonajeNPC`. Ejecuta pasos ortogonales adyacentes: valida permisos y coste,
reserva destino, orienta y anima, procesa `SALIR`, confirma la posición, cobra el
paso y procesa `ENTRAR`. Revalida el destino al confirmar. Una interrupción termina
en una casilla confirmada; si falla la confirmación, cancela la reserva y vuelve al
origen. El actor conserva su estado, sus reglas de gasto y su presentación.

Contrato del actor para usar esta capacidad:

| Miembro | Responsabilidad |
|---|---|
| `coordenada_mapa` | Ubicación confirmada |
| `puede_actuar()` / `puede_moverse()` | Permisos actuales |
| `validar_paso_movimiento(coste)` | Límites propios y recursos persistentes |
| `validar_coste_turno(clave, coste)` | Reserva disponible del turno |
| `consumir_paso_movimiento(coste)` | Cobro de un paso confirmado |
| `orientar_paso_movimiento(origen, destino)` | Presentación según dirección |
| `calcular_duracion_paso(coste)` | Duración de la animación |

El escenario aporta callbacks de reserva, confirmación, cancelación, coste y
reacciones. La ficha reenvía `paso_dado` y `movimiento_terminado` para conservar sus
consumidores. Sigue gastando energía y movimiento; el NPC sólo gasta movimiento.
La renovación automática de turnos durante una ruta sigue limitada a exploración
de la ficha. El movimiento actual del NPC ocupa una casilla.

Si la ficha cae al fallar DES en hielo o lodo, se interrumpe la ruta y se agotan
sus recursos. En combate el cierre usa `GestorRondas` y avanza al participante
siguiente; la ficha sólo repone recursos cuando vuelve a tocarle. En exploración
se conserva el cierre y renovación automática. El cierre de exploración rechaza
llamadas mientras el escenario está en combate.

`DecisorCombateNPC` usa un `BTPlayer` manual con
`recursos/ia/combate_npc.tres`: atacar si está adyacente y tiene acción principal;
acercarse si tiene movimiento y una ruta válida; terminar turno en otro caso.
Busca rutas a las cuatro casillas adyacentes al jugador, compara sus pesos y recorta
la elegida por el coste real disponible. Los empates conservan un orden estable.

El escenario ejecuta la intención y vuelve a consultar al árbol tras moverse. Por
ello el NPC puede acercarse y atacar en el mismo turno si termina adyacente y
conserva acción principal. Sin ruta o sin recursos pasa. Una ruta interrumpida
termina su actuación, salvo si quedó enredado: reevalúa para intentar liberarse.
Una acción bloqueada no se reintenta indefinidamente.
El registro muestra desplazamiento, movimiento restante y las tiradas del ataque.

Los callbacks consultan reacciones para el actor que se mueve. El NPC admite daño
instantáneo, trampas y, desde el 08-10-2026, los estados compartidos descritos abajo.
La detección se incorpora el 08-10-2026; patrullas e inventario siguen pendientes.

### Estados compartidos y liberación prioritaria — 08-10-2026

`Ficha` y `PersonajeNPC` delegan los estados en `EstadosTemporalesActor`. Telaraña
y lodo consultan el contrato del actor y su DES; fuego y humo venenoso pueden usar
el mismo protocolo de estados. El NPC aporta VOL para resistir el veneno.

El árbol real consulta **liberarse → atacar → acercarse → terminar turno**.
Mientras esté enredado, nunca elige atacar o moverse. Intentar liberarse usa la
misma prueba de DES que la ficha y consume una acción principal incluso si falla.
Sin acción principal pasa. Si acierta, retira `enredado` y reevalúa con los recursos
restantes; si falla, sólo puede reintentar mientras conserve acciones principales.
Entrar en una telaraña interrumpe el recorrido y permite esta reevaluación en el
mismo turno. El estado no expira por ticks: dura hasta liberarse.

Caer en hielo o lodo interrumpe el movimiento, agota recursos y cierra el turno
del actor activo mediante `GestorRondas`. `ServicioTurnos` retira `caido` en ese
cierre. El recorrido del NPC detecta el cambio de actor y no cierra el turno dos
veces. Una caída restaurada también obliga al NPC a cerrar su turno antes de
tomar otras decisiones. Quemado y veneno se procesan al finalizar el turno del
actor afectado, con las mismas reglas que la ficha.

### Detección automática — 08-10-2026

`PersonajeNPC.puede_detectar_jugador()` exige estar vivo, ser hostil, tener combate
habilitado y una definición con `radio_agro > 0`. El radio base es cuatro casillas,
medido por distancia euclídea entre centros, inclusivo y sin cono de orientación.
La línea usa `ValidadorEspacialTablero.validar_linea_visual()` y respeta bloqueos
de visión del tablero, superficies opacas y esquinas cerradas. No consulta el fog
ni la luz del jugador. La antorcha del jugador mantiene radio cinco antes de atenuarse.

El escenario evalúa después de cada paso confirmado y mientras está en reposo,
para detectar también cambios de puertas o superficies. No inicia encuentros
durante restauración, interacción modal ni lanzamiento en vuelo. Al detectar
interrumpe la ruta, borra la previsualización e inicia el encuentro existente por
iniciativa; el registro identifica al detector más cercano, con desempate por ID.
Desde el primer corte grupal del 09-10-2026, reúne al objetivo y a todos los hostiles
vivos combatientes que detectan al jugador en ese momento. El corte siguiente
incorpora nuevos hostiles durante el encuentro, según se describe abajo.
Desde el 09-10-2026 perder la detección cierra el combate inmediatamente.

### Combate grupal y memoria compartida — 09-10-2026

El grupo se forma desde percepción propia, sin consultar facciones ni activar NPC
lejanos. `GestorRondas` recibe a la ficha y al conjunto de NPC del encuentro, con
iniciativa 1d6 + DES por ronda. Cada uno dispone de su turno y
reservas; los derrotados se omiten y las superficies siguen avanzando una sola
vez al completar la ronda. El panel presenta el conjunto y su actor activo.

Antes de evaluar pérdida de agro, el escenario consulta a todos los participantes
vivos. Si alguno detecta al jugador, copia la posición observada al recuerdo de
todos los NPC vivos del encuentro. No actualiza recuerdos cuando ninguno detecta,
ni comparte información con NPC ajenos al encuentro.

Durante combate, `DecisorCombateNPC.elegir()` recibe `perseguir_recuerdo = true`:
si no dispone de visión propia puede elegir `acercarse` hacia una casilla adyacente
a la posición recordada por el grupo. No elige buscar, olvidar o regresar mientras
exista ese conocimiento compartido. `Atacar` sigue exigiendo visión propia,
adyacencia y acción principal; liberarse sigue teniendo primera prioridad.
La ejecución comprueba detección conjunta después de pasos y cambios del mundo.

Si ningún oponente vivo detecta, termina el modo combate y conserva esos recuerdos
individuales para búsqueda y regreso en exploración. Derrotar a un oponente no
termina el encuentro si quedan otros vivos y detección. Si cae el último detector,
los demás sólo conservan lo observado antes de esa caída; no obtienen posiciones
nuevas del jugador oculto. El combate también termina al derrotar a todos los
oponentes o dejar de poder actuar la ficha.

La incorporación posterior exige que el nuevo hostil vivo combatiente vea a un
participante vivo a `min(7, radio_agro propio)` casillas, con línea visual. Se
compara contra el conjunto presente al comenzar la evaluación y se incorporan
candidatos por ID ascendente. La pertenencia a facción no interviene. Ver a un
compañero no da conocimiento de la posición oculta del jugador.

`incorporar_actor()` prevalida contrato e ID único y añade al final de la ronda
actual. No cambia ronda, actor activo, iniciativas existentes ni recursos; el
nuevo actor repone sólo al comenzar su propio turno y tira desde la siguiente
ronda. El escenario conserva la ejecución del turno NPC en curso, sin programarla
otra vez. Bandos aliados/neutrales y combate sin jugador siguen pendientes.

### Pérdida del objetivo, búsqueda y huida — 09-10-2026

El NPC recuerda la última casilla donde él o un compañero vivo del encuentro
detectó al jugador. Se actualiza al entrar en combate, tras pasos confirmados y
al evaluar detección conjunta. Sin visión propia el decisor usa ese recuerdo,
no lee la coordenada actual del jugador para elegir ataque ni ruta. La memoria
pertenece a `EstadoPersonajeNPC` y se guarda.

Cuando ningún oponente del encuentro detecta al jugador por radio y visión, el
escenario registra `Has escapado`, oculta el panel y devuelve exploración con la
reposición existente. Interrumpe las rutas en la casilla confirmada y cancela la
ejecución pendiente del turno NPC. Esta salida no ejecuta un `FIN_TURNO` artificial
ni avanza una ronda. Conserva el recuerdo del NPC para buscar fuera de combate.

Desde el 11-10-2026 un reloj de tiempo de juego permite avances autónomos a los
NPC con capacidad de movimiento y vivos, también con el jugador quieto. El
intervalo provisional es un segundo, configurable en el escenario. Los cierres
del jugador ya no añaden avances de NPC. Se lanzan por ID estable pero sus recorridos
avanzan simultáneamente, junto al jugador. El jugador renueva movimiento inmediatamente
y continúa su ruta en paralelo a todos ellos. Se conserva como máximo un avance
pendiente para evitar renovar al NPC mientras aún ejecuta su recorrido anterior
o acumular turnos atrasados. El reloj se reinicia en combate, carga, modales o
cuando el jugador no puede actuar; no acumula avances durante esas pausas.
El NPC busca el recuerdo con su reserva efectiva (DES + 3 o movimiento fijo)
y los costes/reacciones comunes. Al llegar sin detectar, olvida el recuerdo y
vuelve a su casilla de origen con la reserva restante. Una ruta bloqueada no
borra la memoria: recalcula y, si no hay alternativa, espera conservando el destino.
Sin recuerdo retorna directamente. Si el origen está ocupado o bloqueado, espera
y reintenta al cambiar la ocupación del tablero con los puntos restantes. Un nuevo
turno permite cerrar esa espera y renovar la reserva normalmente. Al llegar queda
en reposo, sin curarse.

El selector consulta **liberarse → atacar → acercarse → buscar → terminar búsqueda
→ regresar → pasar**. Liberarse conserva primera prioridad; caer termina su
movimiento y su `FIN_TURNO` procesa levantarse una sola vez. Fuera de combate,
los NPC procesan sus estados al finalizar su propio turno. Las superficies avanzan
una vez por cierre del turno del jugador, sin esperar a las animaciones del NPC.
No se abre una modalidad de combate para buscar o regresar. Las reservas del tablero
impiden que varios actores entren a una misma casilla; cada paso vuelve a validar
su destino. Ningún recorrido espera a otro NPC para comenzar. El siguiente avance
del conjunto comienza cuando los actuales terminaron o cerraron su espera por un
nuevo ciclo automático; no se renuevan reservas a mitad de una animación.

Cada paso confirmado vuelve a evaluar detección. Redetectar interrumpe el recorrido
y abre otro encuentro por iniciativa, sin curar ni continuar el antiguo turno.
Al iniciar combate se cancelan los avances de exploración pendientes y ambos
terminan el paso en curso. Las acciones de combate esperan esa transición;
una ejecución de exploración cancelada no aplica después otro `FIN_TURNO` al NPC.
No se incorpora una acción para abrir puertas. Los bandos siguen pendientes.

### Patrullas por puntos — 09-10-2026

`PersonajeNPC` admite un hijo `Patrulla` (`PatrullaNPC`, extendiendo `Path2D`).
Una curva vacía mantiene el comportamiento previo. Una ruta válida proyecta dos
o más puntos distintos a casillas de suelo al registrarse, cerrando el circuito.
Las casillas quedan fijas aunque el actor se desplace. NPC neutrales con ruta
habilitan recursos de movimiento sin habilitar combate; el máximo sigue siendo
DES + 3 salvo la excepción fija ya configurada en el contenido manual.

En exploración, después de buscar y borrar el recuerdo, el árbol elige esperar,
avanzar punto o patrullar. Alcanzar el punto avanza el índice una sola vez y crea
la espera de `turnos_espera` avances posteriores. Esperar cierra el turno del NPC,
procesando estados sin moverse. Cero permite continuar con la reserva restante.
Desde el 11-10-2026 los avances son autónomos y dependen del tiempo de juego,
sin esperar turnos de la ficha. Durante combate global no se ejecutan patrullas.

La detección compartida cancela la espera de los participantes, pero conserva
el punto pendiente. Tras perder agro primero busca y luego retoma ese punto.
El recorrido reutiliza reserva, costes, superficies, replanificación y espera
ante ocupantes, sin saltar puntos bloqueados. La autoría y snapshot opcional
están en [Patrullas de NPC](../contenido/PATRULLAS_NPC.md).

### Iniciativa y rondas

Cada actor declara un ID estable y su DES actual. `GestorRondas` prevalida la lista
completa y rechaza IDs vacíos o duplicados. El escenario aporta `MotorDados` para
tirar **1d6 + DES** al comenzar y en cada ronda nueva, sólo para actores vivos.
Ordena por total descendente, DES descendente e ID ascendente. Uno y seis no
tienen significado crítico ni pifia. `obtener_iniciativa_ronda(id)` entrega una
copia de dado, DES usada y total; HUD y registro sólo los consultan, sin tirar.
El constructor sin motor conserva el contrato anterior de iniciativa fija para
sus consumidores existentes; el escenario de juego siempre aporta motor.

Al comenzar, el primer actor vivo repone sus recursos si los tiene. Finalizar el
turno procesa sus estados mediante `ServicioTurnos` cuando admite esa capacidad,
selecciona el siguiente actor vivo e invoca `iniciar_turno` en éste. El NPC
combatiente repone sus recursos al comenzar su turno; sus estados temporales
usan el mismo contrato de `ServicioTurnos` que la ficha. Pasar desde el
final del orden al principio aumenta
la ronda y vuelve a tirar antes de seleccionar al primero del nuevo orden.
Los actores sin vida se omiten. Si ninguno
puede actuar, no queda actor activo.

Cada transición devuelve `ResultadoAvanceTurno` con ronda, actor finalizado, actor
activo siguiente, marca de nueva ronda y el `ResultadoAccion` de `FIN_TURNO`.
Un fallo al procesar estados conserva el actor activo y no avanza el orden.
Sorpresa, retrasar turno y salida individual dinámica siguen pendientes.

### Duración y transformación de superficies

`ProcesadorSuperficies` usa el registro existente de `TableroGrid`, prevalida todas
las superficies temporales y las procesa por `id_instancia` léxico. Cada instancia
es la única fuente de sus rondas restantes. `GestorRondas` invoca el procesador una
sola vez al pasar del último actor vivo al primero; cambiar de actor dentro de la
misma ronda no reduce duraciones.

Al llegar a cero la superficie se retira mediante `TableroGrid` y su nodo queda bajo
control del procesador. `Humo` y `HumoVeneno` desaparecen. `Fuego` instancia `Humo`
en la misma celda y posición con ID derivado estable, y el humo comienza con sus diez
rondas completas. Las señales existentes de registro y retiro actualizan visión sin
acoplar el procesador a `FOVManager`.

El resultado de la transición conserva un `ResultadoAccion` adicional con cambios
`superficie_tick`, rondas restantes, expiración e ID resultante cuando corresponde.
Propagación, superficie mojada, explosión con veneno y una matriz general de
combinaciones quedan fuera de 11.5.

En exploración, cada `FIN_TURNO` del jugador procesa sus estados, avanza todas las
superficies una vez y repone sus recursos si continúa vivo y no comenzó otro combate.
Encola además un avance de los NPC combatientes vivos, ejecutado en paralelo al
jugador. Humo, humo venenoso y fuego conservan su duración en turnos; el recorrido
del NPC no vuelve a reducir esa duración.

