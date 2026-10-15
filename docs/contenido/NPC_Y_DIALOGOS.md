# NPC y diálogos

Estado del código revisado el 15 de octubre de 2026. Este documento distingue
los datos ya configurables de los comportamientos realmente conectados al juego.
Trompo es el primer personaje no jugador colocado en una zona.

La [consolidación posterior a la auditoría](../pruebas/CONSOLIDACION_NPC.md)
corrige estados de dados en JSON y memoria al cargar desde otro encuentro,
recupera la prueba de archivo y reduce consultas repetidas. Las cifras de las
secciones de progreso siguientes describen sus cortes originales; el estado
actual de regresión está en esa referencia y en [Pruebas](../pruebas/PRUEBAS.md).

Para construir contenido nuevo, usar la
[guía central de creación de contenido](../GUIA_CREAR_CONTENIDO_INTERACCIONES.md#crear-un-npc-con-diálogo)
y la [referencia permanente de pruebas y consecuencias](CONSECUENCIAS_DIALOGO_NPC.md).
Estas instrucciones de autoría se mantienen junto con los recursos; las secciones
de progreso de este documento registran el estado de implementación y revisión.

El próximo alcance de consolidación se limita a más decisiones de IA en combate,
XP por muertes indirectas y diálogos con tiradas. Las reglas aún abiertas y los
demás frentes futuros están registrados en el
[roadmap](../../ROADMAP_SISTEMA_INTERACCIONES.md).
La IA conserva la selección táctica de objetivo; la huida y el uso automático
de la bomba de humo quedan aplazados. La regla vigente de XP paga al bando opuesto
por una muerte en encuentro activo sin consultar el daño previo; por ahora sólo
se acumula en la ficha. XP indirecta y el primer diálogo con tirada ya están
implementados. La recepción de XP y el primer diálogo con ramas de éxito/fallo
están confirmados en juego. El catálogo de consecuencias queda disponible para
revisión jugable.

## Consecuencias configurables — 15-10-2026

Cada `DialogoNPC` puede declarar pruebas `PruebaDialogoNPC` con atributo, título,
ID estable, opción de intento único y listas de éxito/fallo. El catálogo inicial
`ConsecuenciaDialogoNPC` cambia puntos de actitud o revela información del NPC;
el usuario confirmó ambos tipos. Se edita en el Inspector y el texto sólo llama
`realizar_prueba_dialogo_configurada(id)`. Las dos listas se validan antes de tirar.

Las consecuencias se aplican al cerrar los dados, antes de la respuesta. En modo
único se recuerda tanto éxito como fallo por instancia y se reutiliza su rama
sin repetir tiradas ni efectos. En modo repetible cada elección permite otro
intento. K/C conserva relación, información e intento; los snapshots anteriores
al campo opcional `pruebas_dialogo` se restauran sin intentos previos.

La [guía de construcción](CONSECUENCIAS_DIALOGO_NPC.md) explica los campos y
contiene un ejemplo `.dialogue`. Escena F6: `escena_consecuencias_dialogo_npc.tscn`.
Pasaron 162 comprobaciones del catálogo, las 87 del diálogo anterior y las
regresiones de estado NPC, actitud, conocimiento y diálogo interactuable. El
catálogo requiere revisión jugable; la conversación base ya fue confirmada.

## Diálogo con tirada — 15-10-2026

`escena_dialogo_tirada_npc.tscn` añade un custodio neutral de prueba. Hablar ofrece
convencerlo con VOL o despedirse sin tirar. La elección llama
`realizar_prueba_dialogo("voluntad", titulo)` del escenario mediante los estados
temporales de Dialogue Manager. El adaptador admite fuerza, destreza y voluntad,
obtiene el atributo actual de la ficha y resuelve una prueba normal con el motor
existente, sin bonos nuevos. Historial y registro narrativo reciben una entrada.

El panel existente anima el valor ya resuelto. La mutación espera su cierre y
la condición `prueba_dialogo_exitosa` elige la respuesta. Mientras se resuelve una
línea, el globo ignora selecciones repetidas; no se tira otra vez al animar,
revelar o continuar. K/C se bloquea durante toda la conversación y se libera al
terminarla. El resultado se limpia al terminar y no se serializa.

Esta primera conversación no otorga premios ni cambia relación, XP, PV o recursos.
Se puede repetir al volver a hablar. El catálogo opcional descrito arriba añade
intentos únicos y consecuencias configuradas a otros temas. La prueba automática pasó 87
comprobaciones; la [guía de revisión](../pruebas/DIALOGOS_CON_TIRADAS.md) describe
la escena F6. El usuario confirmó que funcionó muy bien en juego el 15-10-2026;
no detalló cada paso del recorrido manual.

## Decisiones tácticas en combate — 15-10-2026

El selector `DecisorCombateNPC`/LimboAI se aplica a los dos bandos de encuentros
con jugador. El escenario filtra oponentes vivos por bando y visión propia antes
de consultar sus PV o elegir destino. Primero prefiere adyacentes, después los
que tienen un acercamiento pagable y finalmente los demás. Dentro de cada grupo
elige menor PV actual, menor distancia euclídea y menor ID. No compara la vida
de enemigos ocultos. Sin visión conserva el recuerdo compartido existente para
persecución normal, sin leer la posición actual del objetivo oculto.

Prioridad vigente: **liberarse → atacar → acercarse → pasar**. Caído cierra su
turno como antes. Tener poca vida no modifica esta política. Se conservan
iniciativa, recursos, bandos, actitud fija, Trompo, estados, cadáver/botín,
guardado/carga y movimiento de exploración/patrullas.

### Curación y mejoras: prioridad solicitada, pendiente de medios utilizables

El 15-10-2026 el usuario fijó estas prioridades para encuentros existentes:

- Con **menos del 50 % de sus PV máximos** (`PV × 2 < máximo`), el NPC intenta
  curarse si tiene un medio utilizable. Estar exactamente al 50 % no activa
  esta prioridad de autocuración.
- Si puede curar a otro NPC aliado herido, prioriza esa curación antes de atacar.
  La autocuración bajo el umbral tiene prioridad sobre el ataque igualmente.
- Si no tiene un buff activo, intenta mejorarse con un item de su inventario o
  una habilidad propia antes de atacar o dedicar su acción a otro fin. Las
  curaciones disponibles preceden a esta preparación.
- Sólo considera medios reales disponibles y acciones legales, con sus costes,
  usos, alcance, percepción y bandos. No cura muertos ni usa objetos inexistentes.
  Sin un medio válido sigue tomando una decisión normal. Los impedimentos de
  estados y capacidades conservan su contrato.

**Estado: reglas registradas; no conectadas todavía a acciones de apoyo.** Existe
`PersonajeNPC.curar()` como operación de PV limitada por el máximo y la muerte,
pero no hay objetos curativos, buffs funcionales ni habilidades de combate.
`AplicadorEfectos` sólo admite daño y los estados negativos actuales; no hay un
catálogo de habilidades ni un efecto beneficioso persistente que la IA pueda usar.
No se crean pociones ni habilidades implícitamente a partir de esta prioridad.

Antes de activarla en juego falta elegir el primer medio real y definir su efecto,
coste y uso. También quedan por concretar el criterio entre varios aliados heridos
y qué mejoras cuentan como «buff activo». La huida y el humo automático permanecen
aplazados. La prioridad vigente del árbol sigue siendo la indicada arriba hasta
que exista un medio de apoyo ejecutable y comprobado.

### Huida y uso automático de humo: incompletos y aplazados

El usuario probó la huida y la descartó por ahora: observó al NPC lanzar humo,
moverse al centro y, al perder visión y salir del combate, intentar volver a su
posición habitual, provocando una nueva entrada automática en combate.
La implementación no resuelve la continuidad entre huida, búsqueda y regreso.
El usuario decidió que no es esencial y pidió dejarla sin completar.

Se retiraron las ramas activas de retirada y humo del árbol y del ejecutor, así
como la opción `retirarse_con_poca_vida` y su control en la escena manual. La IA
no huye ni usa bombas automáticamente, aunque tenga poca vida y bombas reales.
El objeto y su lanzamiento por el jugador siguen disponibles. Las bombas del
inventario NPC permanecen como botín y se guardan normalmente.

Si se retoma la huida, la preferencia acordada era activación booleana por perfil,
no una regla universal. Quedan pendientes su umbral y, sobre todo, el comportamiento
tras perder detección para evitar el regreso inmediato al combate. No se considera
cerrada ni validada por las pruebas automáticas del prototipo anterior.
Escena y verificación del alcance vigente: [Táctica NPC](../pruebas/TACTICA_NPC.md).

## Campos de visión — vigente desde el 15-10-2026

V alterna los campos de visión de los NPC que el jugador puede ver ahora. Cada
casilla coloreada exige visibilidad actual para el jugador y línea visual propia
del NPC dentro de su `radio_agro`; paredes y humo opaco recortan el campo. Rojo
indica hostilidad o bando oponente, verde amistad o bando aliado y gris relación
neutral. En combate prevalece el bando temporal, sin modificar puntos de actitud.
Un NPC derrotado no aporta campo. Trompo visible conserva el suyo en gris aunque
no pueda combatir. [Recorrido manual](../pruebas/VISION_NPC.md).

## XP por derrota, incluida muerte indirecta — vigente desde el 15-10-2026

Cada definición declara `experiencia_recompensa_derrota` (cero si no otorga).
Si un NPC participante del bando oponente muere durante un encuentro activo, la
ficha recibe esa cantidad completa una sola vez. No exige golpes previos ni un
autor del daño mortal: cuentan ataque, veneno, quemado, explosión, terreno, otro
oponente y daño sin fuente. Las explosiones consultan tanto ocupantes como NPC
interactuables del tablero y generan una sola solicitud por objetivo alcanzado.

Una muerte fuera de encuentro, de un NPC ajeno a él o de un aliado no concede XP
al jugador. Manda el bando vigente de la víctima, no su actitud ni su facción.
La señal de muerte por daño sólo se emite al pasar de vivo a cadáver; golpear el
cadáver, examinarlo, saquearlo o repetir un tick no repite la recompensa. La
última baja se acredita antes del cierre diferido del encuentro.

Se conserva el acuerdo de recompensa íntegra para cada integrante del futuro
grupo, sin reparto; hoy sólo acumula XP la ficha y no se crea XP para aliados NPC.
La autoría de daño puede seguir existiendo para otras mecánicas, pero no decide
este premio. No hay historial de contribuciones ni marcador nuevo de guardado.

La XP está en `Ficha.experiencia_acumulada`; K/C restaura cadáver y XP juntos.
Cargar antes de la muerte devuelve vida, estados y XP anteriores; cargar después
no vuelve a premiar. Guardados antiguos sin XP cargan cero y los cadáveres
anteriores no conceden premios retroactivos, incluso en encuentros sin bandos
que migran al formato actual. El HUD muestra el total y el siguiente umbral,
sin subir niveles ni entregar mejoras automáticamente.

Verificación: `prueba_xp_indirecta_npc.tscn` pasó 197 comprobaciones de fuentes,
estados reales al cerrar turno, explosión múltiple, exclusiones, cierre, K/C,
migración y controles manuales. [Escena y pasos de revisión](../pruebas/XP_NPC.md).
El usuario confirmó el 15-10-2026 el agro automático, la persecución de los
duendes y la recepción de XP en esta escena. La entrega básica queda confirmada
en juego; no detalló qué fuentes ni qué casos de K/C probó manualmente.

## Facciones y bandos — vigente desde el 14-10-2026

El usuario aprobó este corte para encuentros con jugador. `faccion_id` es un
`StringName` fijo de `DefinicionPersonaje`: se asigna en el recurso del perfil,
sin modificarlo durante la partida. Se puede compartir un perfil o crear perfiles
distintos con el mismo ID de facción. Vacío significa sin facción; dos vacíos no
son aliados. Distintas facciones son neutrales por defecto; no hay diplomacia,
cambios de pertenencia ni una reputación global.

`GestorRondas.Bando` distingue jugador, oponente y neutral fuera del encuentro.
Cada participante pertenece a uno de los dos lados activos. La facción habilita
auxilio, la actitud conserva la relación individual y el bando decide quién
puede atacar a quién. Defensa propia prevalece sobre auxilio al compañero de
facción, y éste sobre actitud hacia el jugador. Así, un amistoso puede defender
a su compañero contra el jugador sin perder sus puntos. Un fijo combatiente
puede ayudar conservando su actitud; Trompo sigue neutral fijo y no combatiente.

Un intento válido resuelto, incluido fallo o esquiva, permite auxilio a testigos
vivos combatientes que vean tanto agresor como agredido con su radio y línea
visual propios. Al agredido por jugador se le restan los dos puntos existentes;
ningún testigo recibe ese delta. Diálogos tampoco propagan puntos. Los amistosos
ayudan al jugador ante una amenaza hostil detectada o un ataque hostil resuelto,
pero una agresión del jugador contra un neutral no los recluta automáticamente.
Una agresión nueva al propio aliado establece su defensa contra el jugador;
cambiar puntos por sí solo no modifica su bando durante el encuentro.

Para incorporarse más tarde se debe percibir a un compañero agredido, o a un
participante pertinente según la relación, dentro de `min(7, radio_agro)`. Los
hostiles mantienen la incorporación anterior. Se evalúan los candidatos contra
los participantes previos, sin cadenas dentro de esa evaluación, y se agregan
por ID al final de la ronda. Si varios compañeros defendidos ofrecen lados
distintos, el ID ascendente hace determinista la elección. No se renuevan recursos
ni iniciativa al incorporar; tiran al comenzar la siguiente ronda.

Cada bando comparte sólo posiciones observadas por sus NPC vivos participantes.
La memoria elige el oponente conocido más cercano, desempate por ID; conserva el
último recuerdo si nadie de su lado lo vuelve a ver. Atacar requiere visión
propia, adyacencia y acción; movimiento, esquiva, estados y primera prioridad
de liberación siguen compartidos. Los aliados pueden atacar NPC oponentes.
Sin aliados, la pérdida del último detector conserva la huida anterior. Con
aliados el encuentro sigue mientras algún NPC participante vea a un oponente.
Al no haber ninguna detección termina; también termina al morir el último
oponente o dejar de actuar el jugador. Los aliados y defensores no hostiles
olvidan la persecución al cerrar y retoman su comportamiento habitual.

Se guardan `rondas.bandos` y `rondas.defendidos`, y el ID del objetivo recordado
cuando es otro NPC, reutilizando la coordenada de memoria. La facción fija
continúa en el contenido. Bandos, referencias e iniciativa se validan antes de
restaurar; la carga no resuelve agresiones ni aplica puntos. V2 sin bandos migra
al jugador contra todos sus NPC participantes; sin ID de objetivo, la memoria
mantiene el significado anterior de posición del jugador. V1 sigue inicializando
desde definición. No cambia la versión del snapshot ni las reglas K/C.

Escena, casos y comprobaciones: [Facciones y bandos](../pruebas/FACCIONES_NPC.md).
El usuario probó la escena el 15-10-2026 y comunicó que parece funcionar, sin
detallar cada caso. Los apartados del 09 y 11 de
octubre siguientes conservan la historia previa; este acuerdo sustituye sus
pendientes de facciones para encuentros con jugador.

## Acuerdos vigentes y foco de trabajo — 09-10-2026

Esta sección registra la conversación completa sobre los próximos incrementos.
Son reglas acordadas y pendientes, salvo donde se indique implementación actual.
Los apartados posteriores conservan la historia de los cortes anteriores.

### Encuentros con varios participantes y agro colectivo

- Si hay cinco enemigos participantes y uno todavía detecta al jugador, los cinco
  conservan agro e intentan acercarse. El modo combate termina por huida cuando
  el último deja de detectar al jugador; entonces vuelve el movimiento normal y
  continúan la búsqueda y el regreso fuera de combate.
- Incorporar a otros NPC depende de su propia percepción, no de activar toda una
  facción automáticamente. Compartir facción no concede visión del jugador.
- La persecución compartida usa posiciones observadas por participantes del
  encuentro; no consulta la posición oculta del jugador como información global.
- El usuario quería conocer el alcance de visión del NPC al examinarlo, además
  de sus atributos. El acceso general con V se implementó el 15-10-2026.
- Tras ejecutar el grupo, el usuario observó huida automática demasiado fácil al
  alejarse y propuso ampliar visión. La escena manual usa provisionalmente doce
  casillas mediante `radio_vision_enemigos` en el Inspector; movimiento sigue en
  cuatro. Perder visión de todos aún termina combate automáticamente. El mismo
  radio también inicia detección; paredes y humo siguen bloqueándola. Este ajuste
  de balance fue valorado favorablemente por el usuario y se conserva como referencia
  para estos goblins; no confirma por separado obstáculos, K/C ni todos los turnos.
- Implementado para revisión: el encuentro reúne a la ficha, al objetivo y a todos
  los hostiles vivos combatientes que detectan al jugador en el inicio. Los NPC
  participantes conservan la posición que observa cualquiera de ellos; pueden
  perseguirla sin visión propia, pero atacar sigue requiriendo detección propia.
  Desde el siguiente corte del mismo día también se incorporan hostiles durante
  el encuentro, como se detalla abajo.

### Incorporación, bandos e iniciativa

- Implementado para revisión: un NPC hostil vivo combatiente se incorpora si ve
  a un participante vivo (ficha u otro NPC) a `min(7, radio_agro propio)` casillas.
  Usa distancia y línea visual, sin atravesar paredes o humo opaco. No depende de
  la facción ni de la iluminación. Ver al compañero no revela al jugador oculto.
- El nuevo participante entra al final de la ronda actual. En la siguiente ronda
  participa de la tirada de iniciativa, que se repite para todos cada ronda.
- Fórmula confirmada e implementada: **1d6 + DES actual**, mayor total primero;
  empate por mayor DES y luego por ID ascendente. Se tira al iniciar y cada ronda
  nueva para los actores vivos. Uno y seis son valores normales, sin críticos
  ni pifias. El HUD y el registro muestran la cuenta. Guardar/cargar no vuelve a
  tirar ni renovar recursos; los guardados antiguos conservan su orden hasta la
  próxima ronda. Incorporarse no altera el actor activo ni los recursos en curso.
- El comportamiento depende de los bandos: acercarse a un encuentro con aliados
  y enemigos incorpora al actor a esa secuencia. En un enfrentamiento entre NPC
  neutrales, golpear a uno establece oposición inmediata contra ese objetivo.
  Este corte histórico se amplía con las reglas del 14-10-2026 anteriores.
  El combate autónomo entre NPC sin jugador continúa pendiente.

### Acciones y recursos

- La regla general de movimiento para jugador y NPC es **DES + 3**, calculada con
  la DES actual de la instancia. Los cuatro puntos fijos son sólo una excepción
  temporal de la escena manual: allí DES es dos, que por la fórmula daría cinco.
  Un NPC con DES uno tendría cuatro puntos aplicando la regla normal.
- Los goblins de esa escena son representaciones provisionales para ejercitar
  capacidades comunes. No confirman una especie ni un enemigo del contenido final;
  puede que no existan goblins en el juego. Visión doce también es balance de esta
  escena, no una regla universal para los futuros NPC.
- Equipar un objeto, usarlo (por ejemplo, lanzar una granada de humo) o consumirlo
  (por ejemplo, beber una poción) consume una acción en combate.
- El usuario está considerando la acción adicional. Existe una reserva en el
  código, pero no está decidido qué usos admitirá ni cómo se asignan estos costes
  entre acción principal y adicional.
- Liberarse de una telaraña conserva siempre la primera prioridad. El intento
  actual usa DES y acción principal. El movimiento de los NPC del juego deriva
  de DES + 3; el valor fijo del perfil manual se conserva sólo para esas pruebas.

### Muerte, cadáver, botín y experiencia

- Morir deja un cadáver examinable del que obtener botín. La definición declara
  la XP de recompensa; este corte la entrega a la ficha por bajas elegibles.
- Todavía no existe el asset de cadáver; debe poder incorporarse cuando esté
  disponible. Su ausencia no debe confundirse con ausencia de estado de muerte.
- Desde el 11-10-2026 cero PV representa muerte persistente: curar o asignar vida
  positiva no lo revive. Permanece examinable, permite pasar y no actúa. Permite
  recoger su inventario de botín si tiene esa capacidad.
- XP indirecta ya se concede por bando sin atribución de daño. Pendientes: composición del
  futuro grupo y progresión de nivel. La entrega única y su carga ya funcionan.

### Muerte persistente — implementación del 11-10-2026

- `EstadoPersonajeNPC` protege los PV una vez que llegan a cero. `curar()` devuelve
  cero sobre un cadáver; tampoco admite revivirlo asignando `vida_actual` positiva.
  `esta_muerto()` expresa ese estado; `esta_derrotado()` conserva compatibilidad
  con turnos, combate, detección, interacción y pathfinding.
- Morir interrumpe el recorrido, borra el recuerdo de persecución y agota los
  recursos del turno. El NPC muerto no vuelve a reponerlos ni retoma la patrulla.
  La interrupción del movimiento respeta el cierre del paso que ya está en curso.
- El mismo nodo permanece como cuerpo, con el mismo ID, posición e inventario.
  Permite atravesar su celda y conserva las opciones de examen y botín.
  Su nombre de interacción pasa a `Cadáver de <nombre>`; examinarlo añade un texto
  de muerte que no se recuerda como descubrimiento permanente.
- `DefinicionPersonaje.textura_cadaver` es opcional: una imagen única sin frames,
  con el mismo offset del sprite. Cuando exista ese asset puede asignarse allí;
  mientras falta conserva el sprite y orientación actuales.
- K/C conserva muerte y botín mediante los PV y el inventario existentes, sin
  añadir indicadores duplicados ni cambiar la versión del guardado. Los snapshots
  anteriores con cero PV cargan como cadáveres. Cargar uno donde aún estaba vivo
  restaura ese momento; no equivale a curarlo durante la partida.
- No se añadieron ni ejecutaron pruebas ni se abrió Godot. Se adaptaron las
  expectativas y reinicios de las pruebas existentes de estado persistente y
  esquiva, que antes asumían curación desde cero. Revisión jugable pendiente.

### Progresión — acuerdo parcial del 11-10-2026

- El usuario ajustó el reparto: nivel 1 otorga una habilidad o pasiva inicial;
  nivel 2 otorga otra habilidad o pasiva; nivel 3 otorga +1 a un atributo a
  elección. Sustituye otorgar ambas mejoras en cada subida. No está implementado.
- El usuario confirmó repetir el patrón: niveles 3, 6, 9 y siguientes múltiplos
  de tres otorgan +1 a un atributo a elección; los demás otorgan una habilidad
  o pasiva. La recompensa de nivel 1 se obtiene al crear el personaje.
- El usuario confirmó conservar el máximo de 5 para FUE, DES y VOL. En niveles
  de atributo el jugador elige uno que esté por debajo de ese máximo; cuando los
  tres están en 5, recibe una habilidad o pasiva en lugar del +1. Los PV máximos
  actuales de la ficha son FUE + DES + VOL. Falta definir las habilidades y su
  selección.
- Curva inicial aprobada, ajustable después: XP acumulada total de 0, 100, 300,
  600 y 1.000 para niveles 1..5; cada salto cuesta 100 × nivel actual.
  El umbral total para alcanzar el nivel N es 50 × N × (N − 1).
- También siguen como propuestas: subida de varios niveles con una recompensa
  grande, atribuir el daño mortal y los efectos causados a su responsable, y no
  conceder XP por una muerte ambiental sin responsable. La entrega única por
  instancia y su persistencia deben evitar duplicar recompensas.

### Botín de NPC — implementación del 11-10-2026

- Activar `puede_tener_inventario` en `DefinicionPersonaje`. En la instancia del
  NPC, rellenar `contenido_inicial` con recursos `EntradaInventarioInicial`
  (definición de item y cantidad). Cada NPC crea sus propias pilas con IDs
  derivados de su `id_instancia`; compartir entradas no comparte inventarios.
- `presentacion_botin` reutiliza un `DefinicionCofre` para la cuadrícula y la
  imagen del panel. Por defecto usa la presentación de cuatro espacios del cofre
  pequeño. No representa un cofre físico ni crea otro nodo en el mapa.
- A cero PV conserva `Examinar` y añade `Recoger botín`. Exige estar junto al
  cuerpo (alcance uno) y un actor con inventario; no ofrece esta acción en vida.
  Un cuerpo sin contenido aún permite abrir el panel vacío.
- `Recoger todo` usa la transferencia existente: sólo retira una pila del cuerpo
  si se agregó al destino. Si el inventario del jugador está lleno, el resto
  permanece en el cuerpo. El panel conserva los detalles de cada item.
- Abrir y recoger usan el comportamiento actual de los cofres, sin gastar acción.
  El contenido es fijo y configurable; no se sortea ni se genera otra vez al morir.
- K/C guarda las pilas restantes, incluso la lista vacía después de recogerlas.
  Valida cantidades, definiciones, capacidad e IDs únicos entre jugador, cofres,
  NPC y suelo. Un guardado anterior sin el campo `inventario` restaura el contenido
  inicial, porque todavía no registraba botín.
- La escena `tests/interacciones/escena_npc_hostil.tscn` configura dos piedras
  por NPC. Revisión manual sugerida: derrotar uno, acercarse, recoger, cerrar,
  abrir de nuevo y repetir tras K/C; el cuerpo debe seguir vacío. K/C requiere
  que los recorridos hayan terminado, igual que antes.
- El usuario confirmó la revisión jugable del botín con «chequeado» el 11-10-2026.
  No se ejecutaron pruebas automáticas de este incremento. XP y asset de cadáver
  siguen pendientes; la muerte persistente se implementó después para revisión.

### Actitud y facciones

- Diálogos y acciones modifican puntos de actitud. Malas opciones y agresiones
  pueden reducirlos hasta alcanzar hostilidad persistente.
- Una agresión provoca defensa inmediata en el encuentro aunque aún no se haya
  alcanzado ese umbral de actitud. Esta defensa y la relación persistente son
  conceptos separados.
- Se planteó contagio de hostilidad a la facción; la aclaración posterior limita
  la respuesta de los NPC por visión y descarta activar a toda la facción de forma
  automática. El alcance de cambios persistentes de relación dentro de una facción
  aún requiere definición; no se presupone una reacción de miembros lejanos.
- Desde el acuerdo del 11-10-2026: escala -10..+10, hostil <= -3, amistosa >= +3,
  neutral entre ambos; ataque resuelto -2, incluso fallido o esquivado, y ninguna
  recuperación automática. Trompo mantiene su actitud fija neutral y no combatiente.

### Puntos de actitud — implementación del 11-10-2026

`EstadoPersonajeNPC` conserva puntos por instancia y deriva la etiqueta efectiva.
Inicializa neutral en 0, amistosa en +3 y hostil en -3. `PersonajeNPC` publica
`obtener_puntos_actitud()` y `modificar_actitud_hacia_jugador(delta: int) -> int`:
devuelve el cambio realmente aplicado tras limitar a -10..+10; devuelve cero
para actitudes fijas o al alcanzar el límite. Acciones y diálogos usan la misma
operación. La definición compartida no se modifica durante la partida.

Dialogue Manager ya recibe NPC y ficha; una opción puede usar
`do modificar_actitud_hacia_jugador(1)` o `do modificar_actitud_hacia_jugador(-1)`.
Cada ejecución de la opción aplica una vez su delta; volver a elegirla es otra
acción. Abrir o cerrar la conversación no concede puntos. La recuperación requiere
opciones o acciones positivas explícitas; no ocurre por tiempo ni por cargar.

El jugador puede atacar a cualquier NPC vivo combatiente. Se comprueban capacidades,
atributos, alcance y recursos antes de abrir oposición. Seleccionar una orden válida
abre el encuentro y respeta iniciativa; si actúa primero el NPC, todavía no se ha
resuelto el golpe ni aplicado penalización. Cuando el jugador resuelve su ataque,
resta 2 una sola vez, tanto con fallo como con esquiva o daño. Recibir daño ambiental
no cambia la relación. Las demás acciones pueden invocar la operación compartida
cuando su contenido declare una consecuencia; no se añade reputación automática.

`en_oposicion_encuentro` permite al defensor neutral detectar y atacar durante
el encuentro; no altera su etiqueta persistente. La respuesta usa turnos y recursos
normales. Una mejora no cancela oposición ya iniciada. Al cerrar, un NPC no hostil
olvida la persecución y regresa/patrulla; un hostil conserva búsqueda y agro actuales.
La actitud fija bloquea puntos, no la defensa de un combatiente. Trompo no adquiere
combate. El corte del 14-10-2026 añade auxilio local por facción sin propagar puntos.

Snapshots v2 escriben `puntos_actitud` y la etiqueta derivada compatible. Se validan
tipo entero, rango y coherencia antes de restaurar. Si faltan puntos, se migra la
etiqueta antigua a 0/+3/-3; v1 conserva inicialización desde definición. Actitudes
fijas no guardan relación. La oposición se reconstruye desde `rondas`, sin un campo
duplicado ni repetir agresiones, mutaciones de diálogo, costes o iniciativa.

Escena y pasos: [Comprobación manual de actitud](../pruebas/ACTITUD_NPC.md).

Comprobación automática del 11-10-2026 en Godot 4.7 sin ventana: actitud,
persistencia NPC (21 grupos), esquiva (20 casos) y exploración autónoma pasaron.
La prueba de actitud incluye defensa con el árbol/turno reales. El usuario
confirmó después la revisión manual y el funcionamiento el 11-10-2026;
el bloque de actitud queda cerrado.

### Patrullas y movimiento fuera de combate

- Implementado para revisión: hijo `Patrulla` con `PatrullaNPC` (`Path2D`) y
  puntos editables de `Curve2D`, circuito y espera configurable en turnos de
  exploración. Buscar y liberarse tienen prioridad. Después de buscar retoma el
  punto pendiente; sin ruta sigue regresando al origen. Admite NPC neutrales sin
  darles combate. Índice y espera se guardan; rutas incompatibles se rechazan.
  La [guía de patrullas](PATRULLAS_NPC.md) explica autoría y persistencia.
- Fuera de combate, jugador y NPC deben moverse simultáneamente. Ya se implementó
  movimiento paralelo y recálculo ante ocupación de la ruta: conservan destino y
  recursos, toman una alternativa si existe o esperan cambios del tablero.
  Desde el 11-10-2026 los ciclos de NPC son automáticos (un segundo provisional
  configurable), también con el jugador quieto, sin depender de `Pasar turno`.
  Los NPC sin ruta ni destino permanecen en reposo.
- Desde el ajuste del 11-10-2026 K guarda la última casilla confirmada durante
  recorridos; C exige reposo. No se guardan rutas, reservas ni animaciones.

### Visión: registrada para otro incremento

Iluminación del mapa, visión propia de cada actor y niebla de guerra del jugador
son capacidades distintas. Una habitación iluminada detrás de una pared puede
seguir oculta; terreno recordado no revela ocupantes actuales. La oscuridad y
capacidades especiales aún requieren reglas. La discusión y el diagnóstico del
código están en [Visión, iluminación y niebla de guerra](VISION_ILUMINACION_Y_NIEBLA.md).

### Orden propuesto para continuar con NPC

El usuario confirmó el 11-10-2026 que primero se termina el trabajo de NPC y
después se pasa a las otras capas. La progresión acordada queda documentada;
su implementación se pospone. La muerte persistente del NPC está implementada
para revisión, conservando el cuerpo examinable y su botín ya operativo.

1. Revisar el encuentro con varios enemigos y agro colectivo, ya implementado
   usando distancia y línea visual existentes. Cada NPC conserva primera prioridad
   de liberarse, recursos, estados y memoria de posiciones observadas.
2. Revisar incorporación de hostiles e iniciativa por ronda, ya implementadas;
   después definir y conectar bandos aliados/neutrales y encuentros sin jugador.
3. Revisar patrullas de varios puntos y esperas, ya implementadas con edición visual.
4. Muerte permanente, cadáver, botín y XP.
5. Puntos de actitud y respuesta local de facciones; ampliar acciones y tácticas.

Este orden es una propuesta de implementación, no una nueva regla del juego.
La separación completa de luz, percepción y niebla queda documentada sin bloquear
el primer corte de combate grupal basado en la detección que ya existe.

## Modelo actual

| Capa | Implementación | Responsabilidad actual |
|---|---|---|
| Definición | `scripts/personajes/definicion_personaje.gd` | Atributos base, vida máxima, nivel, iniciativa, recursos por turno, radio de agro, XP de recompensa, actitud inicial, capacidades, sprite, ilustración y temas de diálogo. |
| Instancia | `scripts/personajes/personaje_npc.gd` | Nombre único, configuración inicial opcional, interacción, bloqueo del paso y selección visual del sprite. |
| Estado de instancia | `scripts/personajes/estado_personaje_npc.gd` | PV, atributos, nivel, actitud efectiva, estados, recursos de turno y última posición conocida del jugador. |
| Estados temporales | `scripts/interacciones/efectos/estados_temporales_actor.gd` | Capacidad por actor compartida con la ficha; renovación, retiro y persistencia. |
| Patrulla | `scripts/personajes/patrulla_npc.gd` | Puntos visuales por instancia, circuito, índice y espera guardables; usa el movimiento compartido. |
| Movimiento | `scripts/movimiento/movimiento_por_casillas.gd` | Recorrido compartido por casillas, reservas, animación, confirmación e interrupción. |
| Decisión del NPC | `scripts/personajes/decisor_combate_npc.gd` | Selector manual de LimboAI: liberarse, atacar, acercarse, buscar, terminar búsqueda, regresar o pasar turno. |
| Estado guardado | `PersistenciaInteractuables` y `PersistenciaPartida` | Datos planos por ID de instancia y memoria narrativa de la partida. |
| Tema de diálogo | `scripts/personajes/dialogo_npc.gd` | ID, título, recurso `.dialogue` y punto de inicio. |
| Representación | `scenes/personajes/npc.tscn` | Sprite de 2 × 2 orientaciones de 64 × 96 px, con offset `(0, -32)` y marcador de diálogo. |

La definición de Trompo está en `recursos/personajes/goblin_unico.tres`. Tiene
15 PV máximos, nivel 3, atributos 5/5/5, recompensa declarada de 120 XP,
actitud inicial neutral y fija, diálogo habilitado y combate deshabilitado.
`puede_tener_inventario` habilita un inventario propio desde el 11-10-2026;
su contenido inicial se configura en la instancia y se recoge al estar derrotado.
La instancia `goblin_001`, llamada Trompo, está en
`scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn`, bajo
`Interactuables/Personajes`. Los atributos y la vida de la definición se usan
como valores iniciales cuando la instancia no trae otros valores configurados.

## Funciona actualmente

- El tablero registra al NPC como interactuable con ID estable. Un NPC con PV
  bloquea su celda; al quedar derrotado permite atravesarla.
- El hover sigue los píxeles opacos del sprite y la visibilidad de la celda. El
  outline y el menú contextual proceden del sistema de interactuables.
- `PanelInfoNPC` muestra nombre, nivel y PV actuales/máximos mientras está bajo
  el cursor. El menú ofrece `Hablar` por cada tema válido y usa alcance 1.
- Al elegir `Hablar`, `EscenarioBase` abre Dialogue Manager con NPC y ficha como
  estados, muestra las ilustraciones de ambos y mantiene la interacción modal
  hasta terminar. El panel y las respuestas están dentro del filtro CRT.
- `dialogues/personajes/trompo.dialogue` contiene la presentación inicial y
  ramas de conversación. `EstadoPartida.trompo_conocido` recuerda si ya se
  presentó, se reinicia al crear una partida nueva y se guarda con la partida.
- El estado de cada NPC se inicializa una vez desde su definición. El snapshot
  conserva PV actuales, fuerza, destreza, voluntad y nivel. Para NPC de actitud
  dinámica conserva también la actitud hacia el jugador. Trompo tiene actitud
  fija neutral y rechaza cambios de actitud.
- `vida_actual == 0` indica muerte y se conserva al cargar. La versión 2 del
  snapshot incluye `memoria_narrativa.trompo_conocido`. La carga de versión 1
  inicializa los NPC desde su definición y asume que Trompo aún no es conocido.
- `PersonajeNPC.recibir_danio()` y `curar()` limitan los PV entre cero y el
  máximo de la definición. Emiten cambios de vida y de derrota; curar desde cero
  no tiene efecto. `AplicadorEfectos` puede aplicar daño a un NPC mediante
  su contrato existente. Recibir daño no altera la actitud fija de Trompo.
- A 0 PV, el NPC permanece visible y registrado. `puede_actuar()` devuelve
  `false`, `Hablar` y `Atacar` desaparecen del menú y las acciones de diálogo
  antiguas se bloquean al resolverlas. `Examinar` permanece si su definición
  tiene perfil de observación y fragmentos; esta es la condición de contenido
  que exige el sistema de examen. La celda queda caminable y el pathfinding
  consulta ese estado al recalcular rutas. Sólo cargar un estado anterior vivo
  restaura las opciones y el bloqueo del paso.
- Un NPC con `puede_combatir` ofrece `Atacar` mientras tiene PV. La acción
  usa el menú contextual, alcance 1, una prueba de FUE del jugador y consume una
  acción principal aunque falle o se esquive. Tras un acierto, el NPC intenta
  automáticamente `1d6 ≤ DES`; si falla esa esquiva recibe 1 PV fijo.
  Crítico y pifia siguen las reglas de cada prueba, sin daño adicional. La prueba
  integrada usa un enemigo creado solo para ese caso: no se añadió uno al
  contenido permanente de la zona.
- `tests/interacciones/escena_npc_hostil.tscn` monta `EscenarioBase` con un
  grupo de tres hostiles de 2 PV por defecto, generados cerca del jugador y teñidos
  de rojo para distinguirlos del sprite provisional de Trompo. La propiedad
  `cantidad_enemigos` permite de uno a cinco. En esta escena de revisión,
  clic izquierdo abre las acciones, clic derecho mueve, K guarda en
  `user://prueba_npc_hostil_3_enemigos.json` y C carga ese archivo. Con un enemigo
  usa `user://prueba_npc_hostil.json`; otras cantidades usan su propio sufijo.
  F6 inicia de cero;
  la carga sigue siendo explícita. La escena no modifica el Templo ni el slot
  normal `user://partida.json`.
- `tools/dialogue_editor.html` permite importar, editar, duplicar puntos o
  bloques y exportar `.dialogue`. Su vista previa muestra la sintaxis generada
  y advierte sobre errores frecuentes de condiciones, saltos y autoloads.
- `Ficha` ya declara nivel y XP acumulada y los incluye en su estado guardado.
- Jugador y NPC resuelven ataques con `ResolverAtaqueBasico`: FUE del atacante
  y, sólo al acertar, DES del defensor. La esquiva evita el daño completo y no
  consume reacción, incluso si está agotada. El registro muestra ambas pruebas;
  el historial conserva la esquiva como automática y `SOLO_LOG`.

## Límites comprobados en el código

- Los puntos de actitud conectan diálogos y ataques con transiciones de relación.
  Los bandos de encuentro se distinguen de la relación persistente. Facciones y
  auxilio local están conectados; reputación global y consecuencias de otras
  acciones de contenido siguen pendientes.
- `PersonajeNPC` implementa muerte persistente e inventario de botín
  y patrullas opcionales. El regreso al origen se ejecuta fuera de combate desde el 09-10-2026.
  `experiencia_recompensa_derrota` concede XP al jugador por bajas elegibles.
- El escenario inicia combate al elegir `Atacar` o por detección de un NPC hostil
  combatiente dentro de su radio configurado, con línea visual despejada. El radio
  base es cuatro; los goblins de la escena hostil usan doce por defecto.
  `GestorRondas` incluye a la ficha, al objetivo y a los detectores del inicio;
  el panel superior muestra
  ronda, orden y actor activo. El NPC consulta su árbol de LimboAI: intenta
  liberarse primero si está enredado; intenta un ataque de FUE si está adyacente
  y tiene acción, o se acerca por una ruta válida
  usando su movimiento restante. Reevalúa al llegar y puede atacar en ese turno.
  El corte táctico del 15-10-2026 conserva la selección de objetivos según la política
  descrita al principio. Otras acciones y defensas adicionales siguen pendientes.
  El usuario confirmó movimiento, telaraña y caída;
  también confirmó después que funciona el agro. Obstáculos y K/C durante un
  encuentro automático quedan registrados por separado.
- La muerte todavía no tiene pose, animación ni cadáver separado. Admite una
  textura opcional de cadáver. `Examinar` añade una observación de muerte a los
  fragmentos de la definición.
- La ficha almacena XP, recibe recompensas por derrota y alimenta la barra del
  HUD. La curva acordada se muestra; la subida de nivel sigue aplazada.
- El inventario de NPC forma parte del snapshot desde el 11-10-2026.
  Los estados temporales se guardan desde el 08-10-2026.
- Los diálogos pueden escribir condiciones y mutaciones de Dialogue Manager.
  El custodio de prueba ya conecta una elección con el motor, el panel existente
  y ramas de éxito/fallo; faltan casos narrativos definitivos con consecuencias.

## Decisiones acordadas para el modelo de estado (26 y 28-09-2026)

- **Definición:** `DefinicionPersonaje` es la plantilla compartida con valores
  base, actitud inicial, capacidades y presentación. No recibe cambios propios
  de una instancia durante la partida.
- **Instancia:** cada `PersonajeNPC` conserva identidad y ubicación, con estado
  de ejecución independiente inicializado desde su definición.
- **Estado guardado:** se serializa como datos planos asociados al ID estable de
  la instancia, usando los métodos de estado persistente que ya delega
  `PersistenciaInteractuables`. No se serializan nodos ni referencias a recursos.
- **Derrota:** por ahora equivale a `vida_actual == 0`. La inicialización desde
  la definición debe distinguirse explícitamente de la restauración para no
  reponer PV a una instancia derrotada. A 0 PV permanece visible y examinable
  cuando tiene contenido de examen, no habla ni actúa y permite pasar por su
  casilla. Desde el 11-10-2026 la curación ya no revierte esta situación.
- **Actitud:** la actitud fija de Trompo prevalece sobre cualquier sistema de
  relaciones y permanece neutral. Para NPC dinámicos se guarda la actitud
  efectiva hacia el jugador; el juego es actualmente de un solo jugador.
- **Memoria narrativa:** `trompo_conocido` se guarda en el snapshot de
  partida, separado del estado individual de Trompo.
- **Capacidades opcionales:** combate e inventario no se vuelven requisitos del
  estado común. Sus datos específicos se incorporarán cuando esas capacidades
  tengan implementación.
- **Estados temporales:** quedan fuera del primer incremento de persistencia.
  Antes de guardarlos definiremos duración, ticks, expiración y qué ocurre al
  cambiar de zona o cargar una partida.
- **Prueba de desarrollo:** F6 debe iniciar la escena desde valores iniciales,
  como primera visita, sin cargar automáticamente `user://partida.json`. La
  carga de progreso guardado seguirá siendo explícita. Actualmente el proyecto
  no tiene un cargador automático en `_ready`; `EstadoPartida` empieza con
  `trompo_conocido = false` y solo se carga guardado mediante
  `EscenarioBase.cargar_partida()`.

## Próximos incrementos sugeridos

### Aprendizaje de decisiones con LimboAI (05-10-2026)

El usuario eligió LimboAI e instaló su GDExtension v1.8.1. Su escena
`scenes/pruebas LimboAI/prueba_ia.tscn` usa un `BTPlayer` manual y el recurso
`prueba_ia.tres`. Se preparó un ejemplo interactivo con selector, dos secuencias
y condiciones sobre distancia, acción principal, movimiento y camino.
La decisión y el recorrido aparecen en pantalla. El usuario confirmó el
06-10-2026 que el ejemplo funciona correctamente con F6. La guía está en
[Aprender el árbol del NPC](../pruebas/APRENDER_ARBOL_NPC.md).

El incremento del 06-10-2026 usa `MovimientoPorCasillas` por instancia tanto en
la ficha como en el NPC. `DecisorCombateNPC` consulta un árbol real independiente,
`recursos/ia/combate_npc.tres`, que comparte las tareas genéricas del ejemplo.
El escenario ejecuta las intenciones, el tablero actualiza la presencia del NPC
por paso y K/C restaura su posición y reservas. La importación y carga de escena
en el editor terminó sin errores de scripts; el usuario confirmó después que
el movimiento funciona. También confirmó después telaraña y caída; quemado,
veneno y K/C con estados activos siguen pendientes por separado.

### Incrementos de personajes

1. **Estado común del NPC y memoria narrativa persistentes: implementado.**
   `EstadoPersonajeNPC` guarda PV, atributos, nivel y actitud dinámica.
   `PersistenciaPartida` guarda `trompo_conocido`, valida antes de restaurar y
   acepta snapshots v1. F6 sigue iniciando sin carga automática.
2. **Ciclo vital común: implementado.** Daño y curación respetan los límites de
   vida, notifican cambios y mantienen la derrota definida por PV cero.
3. **Estados temporales: implementados para revisión el 08-10-2026.** Ficha y NPC
   comparten `EstadosTemporalesActor` y persistencia. Caer termina el turno;
   liberarse tiene primera prioridad, usa DES y consume una acción principal.
   Enredado permanece hasta liberarse; quemado y veneno se procesan al cerrar turno.
4. **Relaciones dinámicas.** Puntos y defensa de encuentro implementados el
   11-10-2026, con operación compartida, actitud fija respetada y persistencia
   compatible. Revisión manual confirmada el 11-10-2026; bloque de actitud cerrado.
5. **Modo de combate: cuatro cortes implementados.** `Atacar` inicia un encuentro
   con el objetivo; hay orden visible, actor activo, `Pasar turno`, límite de
   movimiento por recursos, salida al derrotarlo y guardado de ronda y actor.
   El usuario informó que este primer flujo funcionó en Godot. El segundo corte
   añade ataque adyacente del NPC y recursos propios persistentes; el usuario
   confirmó que ataca estando junto al jugador y pasa desde lejos. El tercero
   añade esquiva automática con DES para ambos bandos y está comprobado en headless.
   El usuario confirmó la revisión básica de combate, esquiva y K/C el 06-10-2026.
   El cuarto extrae movimiento compartido y conecta acercamiento y ataque con
   LimboAI; el usuario confirmó que funciona. Se incorporaron estados de NPC;
   combate e inventario siguen siendo capacidades opcionales.
6. **Progresión y diálogos con tiradas.** XP por derrota y primer diálogo con
   prueba implementados. Revisar el custodio en juego; definir y aplicar niveles
   después. Las tiradas usan el motor compartido mediante el escenario.

## Progreso

- **Completado:** inspección de `DefinicionPersonaje`, `PersonajeNPC`, `Ficha`,
  `EstadoActor` y los contratos actuales de persistencia. Se acordó el modelo
  definición/instancia/snapshot, la derrota por PV cero, la persistencia de
  actitud dinámica y memoria narrativa, y el reinicio limpio de F6.
- **Implementado:** `EstadoPersonajeNPC` es un `RefCounted` por instancia. El
  snapshot actual es v2 y acepta v1 con estado de NPC vacío; la prueba
  `prueba_estado_npc_persistente.tscn` verificó la restauración y la compatibilidad.
- **Implementado:** operaciones de daño y curación, señales de vida y derrota, y
  recepción de daño mediante `AplicadorEfectos`. `Atacar` usa la misma ruta de
  opciones, contexto y `GestorAcciones`; se comprobó con un enemigo de prueba.
- **Implementado:** comportamiento de derrota acordado para visibilidad,
  interacción y paso; escena aislada con objetivo hostil y guardado propio para
  revisión manual. El usuario confirmó en Godot que puede atacarlo hasta 0 PV,
  atravesar su casilla, examinarlo, ver que `Atacar` desaparece y restaurar el
  estado derrotado con K/C. La escena de prueba no tiene diálogo; el bloqueo
  de `Hablar` al estar derrotado está implementado, pero no se verificó allí.
- **Primer corte, comprobado inicialmente por el usuario:** `Atacar` entra en
  combate con ficha y NPC, panel superior de orden y ronda, avance desde
  `Pasar turno`, pase automático inicial del NPC, bloqueo de entrada fuera del
  turno del jugador y salida cuando el
  objetivo llega a 0 PV. K/C de la escena aislada guardan y restauran un
  combate activo sin reponer recursos al cargar. El usuario informó que el
  flujo funcionó en Godot; falta comprobar por separado cada caso de K/C
  durante el combate. El diseño visual del HUD superior se revisará más adelante.
- **Comprobado por el usuario el 05-10-2026:** un NPC hostil con capacidad de combate
  dispone de reservas de turno; si está adyacente y conserva acción principal,
  intenta un ataque de FUE que causa 1 PV al acertar. Si no está junto al
  jugador, pasa. El resultado va al registro narrativo. Las reservas se guardan
  y se restauran; los snapshots v2 previos siguen admitidos. El ataque adyacente
  y el pase desde lejos están confirmados; K/C durante el combate sigue pendiente.
- **Implementado para revisión jugable el 05-10-2026:** esquiva automática
  con DES tras cada ataque acertado de jugador o NPC. No consume reacción.
  `prueba_esquiva_automatica.tscn` pasó 20 casos en ambos sentidos, incluidos
  críticos, pifias, reacción agotada, bloqueos y consumo de acciones; el registro
  muestra FUE y DES y no presenta daño al esquivar. Las pruebas existentes de
  `ResultadoAccion` y estado persistente de NPC también pasaron.
- **Pendiente:** revisar el daño provisional de 1 PV y confirmar el combate
  grupal, incorporación e iniciativa implementados; añadir otras acciones, defensas, tácticas de IA y
  completar la revisión de muerte persistente. Pérdida del objetivo, búsqueda y regreso individuales ya
  están implementados; las reglas nuevas se detallan al comienzo del documento.
- **Implementado para revisión el 08-10-2026:** semántica y persistencia compartida
  de enredado, caído, quemado y veneno. La importación en Godot no dio errores
  de scripts; no se añadieron ni ejecutaron pruebas de este incremento.
- **Confirmado por el usuario el 08-10-2026:** revisión de telaraña y caída.
  No confirma por separado quemado, veneno ni guardado/carga con estados activos.

## Punto de continuidad para otra PC (actualizado el 08-10-2026)

- **Revisión básica confirmada por el usuario el 06-10-2026:** tras ejecutar
  la escena hostil con F6, informó que funciona toda la lista de revisión:
  inicio y orden de combate, FUE y esquiva DES para ambos, daño de 1 PV sólo
  si la defensa falla, ataque adyacente del NPC y pase desde lejos, K/C durante
  el turno del jugador conservando PV/ronda/recursos, apariencia de la piedra
  al cargar y derrota con fin de combate, examen y paso por su casilla.
  Esta confirmación no incluye la escena de aprendizaje de LimboAI ni la carga
  en mitad de la resolución automática del turno del NPC.

- **Implementado y confirmado por el usuario:** el primer modo de combate se
  inicia con `Atacar`, muestra orden y actor activo, permite pasar turno y sale
  al derrotar al objetivo. También se comprobó antes la derrota a 0 PV, el
  examen y paso sobre el NPC derrotado, y K/C para ese estado.
- **Implementado y confirmado por el usuario el 05-10-2026:** el segundo corte hace
  que el NPC hostil ataque con FUE y gaste una acción principal si está
  adyacente. Si está lejos, pasa sin moverse. El resultado aparece en el
  registro narrativo; sus recursos se guardan y restauran. El daño de 1 PV
  sigue siendo provisional.
- **Para retomar:** abrir `tests/interacciones/escena_npc_hostil.tscn` en Godot,
  ejecutar la escena y revisar K/C durante el combate, especialmente después
  de un ataque del NPC. El usuario confirmó guardado OK, pero F8 detenía la ejecución.
  El registro identificó llamadas repetidas a `add_child` del sprite y sus partículas
  en `Ficha._aplicar_visual_clase()`. Se corrigió para unirlos sólo si no tienen padre;
  la prueba `prueba_carga_visual_ficha.tscn` comprobó tres restauraciones consecutivas
  con PV y acciones gastadas. El cierre persistió porque F8 es el atajo de parada
  del editor de Godot (F7 es pausa). La escena ahora usa K para guardar y C para
  cargar; el usuario confirmó que C carga correctamente. Queda revisar por separado
  ronda, actor activo y reservas, especialmente durante el turno del NPC.
- **Ejemplo de IA confirmado por el usuario el 06-10-2026:** funciona la escena
  `scenes/pruebas LimboAI/prueba_ia.tscn`, con decisiones y recorrido visibles.
- **Implementado para revisión el 06-10-2026:** movimiento compartido para ficha
  y NPC, registro de ubicación por paso, restauración de posiciones móviles y
  selector real de LimboAI para acercarse, atacar o pasar. Guardar/cargar se bloquea
  durante el movimiento de cualquiera de ellos. No se ejecutaron pruebas de este
  incremento; la importación y apertura de escena en el editor no dio errores.
- **Movimiento confirmado por el usuario:** el recorrido compartido funciona.
  Se corrigió el cierre del turno de la ficha al caer en hielo durante combate
  y el orden visual del NPC en Zona1. El usuario confirmó telaraña y caída;
  la revisión visual queda registrada por separado.
- **Implementado el 08-10-2026:** estados temporales compartidos y persistentes.
  El árbol real prioriza liberarse, atacar, acercarse y terminar turno. La telaraña
  interrumpe el recorrido y permite intentar liberarse en ese mismo turno si hay
  acción; sin acción pasa. Caer en hielo/lodo agota reservas y termina el turno.
  El registro identifica al NPC afectado. Los guardados anteriores siguen admitidos.
- **Implementado el 08-10-2026:** agro configurable con radio base cuatro y línea
  visual en todas las direcciones. Un NPC vivo, hostil y combatiente inicia el
  encuentro e interrumpe la ruta de exploración en una casilla confirmada. El
  más cercano entra primero, con desempate por ID. La antorcha conserva radio base
  cinco; su atenuación u obstáculos pueden reducir la ventana del jugador.
- **Agro confirmado por el usuario:** informó que el incremento funciona.
  Obstáculos y K/C durante combate automático quedan por revisar por separado.
  La escena busca colocar al NPC
  a cinco casillas; si no hay una posición visible y accesible, usa una más cercana.
  La importación y apertura de escena no dieron errores de scripts; no se ejecutó
  el juego ni pruebas de este incremento. Después definir pérdida del objetivo,
  búsqueda y regreso. K/C con estados activos sigue pendiente por separado.
- **Implementado para revisión:** movimiento **DES + 3** para ficha y NPC, usando
  la destreza de instancia. El objetivo de prueba con DES 2 tiene cinco puntos;
  una ficha con DES 4 tiene siete. Los guardados anteriores se adaptan conservando
  puntos gastados; los nuevos conservan exactamente restantes y máximo.
- **Implementado el 09-10-2026 para revisión:** al perder agro por distancia o
  visión termina el modo combate y vuelve exploración. El NPC conserva la última
  casilla donde detectó al jugador; busca allí y después regresa al origen durante
  los turnos de exploración, con DES + 3 y las reacciones comunes. Liberarse sigue
  primero. Sin camino conserva el recuerdo y espera; si el origen está ocupado
  o bloqueado espera y reintenta. Al llegar queda en reposo, sin recuperar PV.
  Redetectar interrumpe el plan y abre otro combate. Memoria y origen se guardan;
  archivos antiguos siguen admitidos usando el origen inicial de la escena.
- **Ajuste del goblin hostil — 09-10-2026:** cuatro puntos de movimiento por turno
  y visión/agro seis. El perfil fija `movimiento_fijo = 4` y `radio_agro = 6`,
  manteniendo DES 2 para las esquivas. Otros NPC conservan DES + 3 salvo que su
  definición fije movimiento. La ubicación inicial a cinco casillas puede iniciar
  combate al abrir F6; ya no representa una ventana fuera del agro.
  Guardados anteriores con máximo cinco migran conservando el gasto.

- **Movimiento simultáneo en exploración — 09-10-2026:** el jugador continúa
  su ruta mientras el NPC busca o regresa. Los avances NPC se encolan sin bloquear
  movimiento, previsualización ni Pasar turno del jugador. Cada paso conserva
  reserva y validación de casilla. Detectar combate cancela esa cola y termina
  los pasos en curso antes de permitir las acciones por turnos.

- **Varios recorridos y bloqueo dinámico — 09-10-2026:** los NPC con movimiento
  ejecutan sus avances simultáneamente entre sí y con el jugador. Si alguien ocupa
  su ruta, recalculan hacia el mismo destino; sin alternativa esperan hasta que
  cambie el tablero, conservando memoria y puntos restantes. Esa espera no cobra
  movimiento ni añade ticks. La capacidad no consulta actitud: sirve para un NPC
  amistoso que admita movimiento. No añade patrullas a NPC sin esa capacidad ni
  amplía aún el encuentro de combate, que sigue incluyendo jugador y un objetivo.

- **Primer corte de combate grupal — 09-10-2026:** al iniciar entran el objetivo
  y los hostiles que detectan al jugador. Los participantes comparten la última
  posición observada; perseguir no exige visión propia mientras el grupo mantenga
  detección, pero atacar sí. Ninguno comienza a regresar mientras quede un detector
  vivo. Cuando ninguno detecta, todos conservan el recuerdo para buscar/regresar
  fuera de combate. Los derrotados se omiten en turnos y detección. El orden fijo
  y snapshot v2 existentes admiten el conjunto; no hay tiradas nuevas de iniciativa.
  La escena manual ahora prepara tres goblins, con slot propio de K/C por cantidad.
  La importación y carga de la escena en el editor terminó sin errores de scripts;
  no se ejecutaron el juego ni pruebas de este corte.
- **Siguiente paso actualizado:** revisión del grupo, huida y K/C; después
  incorporación e iniciativa por ronda, y patrullas. Las reglas de visión quedan
  registradas para un incremento propio. Movimiento paralelo y rutas bloqueadas
  siguen pendientes de revisión jugable por separado.
- **Al cambiar de PC:** F6 inicia sin cargar partida. K/C usan
  `user://prueba_npc_hostil.json`, que pertenece a la instalación local de
  Godot y no viaja con el repositorio; en la otra PC se crea un guardado nuevo.

Al continuar esta línea de trabajo, actualizar aquí el estado real de cada
incremento y registrar decisiones de arquitectura en
`docs/decisiones/DECISIONES.md` cuando queden acordadas.
