# Decisiones arquitectónicas

- El 11-10-2026 el usuario confirmó la revisión manual y el funcionamiento de
  actitud de NPC con «ya quedó todo testeado, veo que funciona». El bloque queda
  cerrado junto con las pruebas automáticas registradas. Facciones y bandos,
  entrega de XP y presentación del alcance de visión siguen para chats posteriores;
  niveles y habilidades permanecen aplazados.

- El 11-10-2026 se acuerda actitud por instancia de -10 a +10; hostil <= -3,
  amistosa >= +3 y neutral entre ambos. Iniciales: -3, +3 y 0 según definición.
  Ataques válidos resueltos restan 2, también fallidos o esquivados; bloqueos y
  cancelaciones no afectan la relación. Una operación compartida admite deltas
  desde acciones y Dialogue Manager. No hay recuperación automática. La defensa
  dura el encuentro y respeta iniciativa; mejorar puntos no lo cancela. Un no
  hostil deja de perseguir al cerrarlo. Actitudes fijas y capacidades prevalecen,
  incluido Trompo neutral no combatiente. Snapshots anteriores migran su actitud;
  cargar no ejecuta consecuencias. Sustituye los umbrales y recuperación pendientes.

Las decisiones vigentes están desarrolladas en
[[../CONTRATOS_SISTEMA_INTERACCIONES|Contratos del sistema de interacciones]].

## Núcleo

- Código y IDs en español; `StringName` estable para contenido extensible.
- Definición, instancia y representación son conceptos separados.
- Acciones y resultados son estructurados.
- Los receptores se definen por comportamiento, no por una jerarquía única.
- Los items aportan etiquetas y magnitudes, no excepciones por pareja.
- Las referencias entre mecanismos y la persistencia usan IDs, no `NodePath`.
- Validar no muta; los bloqueos no cobran ni aplican consecuencias.
- El orden de reacciones es determinista.
- Las pruebas de Exhume usan `1d6 ≤ atributo`; el 1 natural es crítico y éxito
  asegurado, y el 6 natural es pifia y fallo asegurado.
- Ventaja y desventaja se cancelan antes de tirar; sólo el dado seleccionado se
  clasifica como crítico o pifia.
- El motor de dados devuelve resultados estructurados y el solicitante decide las
  consecuencias; `GestorAcciones` no contiene reglas de tiradas.
- Una acción puede transportar una tirada ya resuelta en `ResultadoAccion`; el
  receptor la solicita y decide sus consecuencias, y el escenario sólo la registra
  y presenta.
- El origen automático o solicitado es independiente de presentar la tirada en
  primer plano o únicamente en el historial de sesión.
- Las expresiones de daño pertenecen al contenido que las produce. Los estados las
  conservan para volver a resolverlas en cada tick; el aplicador recibe cantidades
  resueltas y no contiene tablas de daño por elemento.
- Las superficies estáticas pintadas en la zona se reconstruyen desde sus capas y
  no se incluyen en el snapshot de contenido dinámico. Pinchos hacen `1d3` sin
  salvación; telaraña usa DES y `enredado`; lodo e hielo comparten DES y caída; el
  fuego estático aplica quemado y funciona como fuente de luz sin fog propio.
- El estado de cada NPC pertenece a su instancia y se guarda como datos planos
  identificados por su ID estable; su definición aporta los valores iniciales.
  PV cero significa derrotado por ahora, y la inicialización no debe sobrescribir
  ese estado restaurado. La implementación usa un `EstadoPersonajeNPC` de tipo
  `RefCounted` por instancia y escribe snapshots v2; al cargar v1 reconstruye el
  estado de NPC desde la definición. Daño y curación limitan los PV a cero y al
  máximo de la definición; curar por encima de cero revierte la derrota.
- Un NPC de actitud fija conserva la actitud de su definición. La actitud
  dinámica se persiste hacia el jugador actual; el diseño podrá ampliarse a
  relaciones por jugador si el juego deja de ser singleplayer.
- La memoria narrativa de `trompo_conocido` pertenece al estado de partida y se
  incluye en el guardado. Ejecutar la escena con F6 inicia una prueba fresca y no
  carga automáticamente un guardado de usuario; cargar progreso sigue siendo una
  operación explícita.
- Estados temporales de NPC se incorporarán a persistencia después de definir sus
  reglas de duración y expiración. Las capacidades de combate e inventario siguen
  siendo opcionales y sus datos no forman parte obligatoria del estado común.
- Las acciones de NPC se incorporan por casos completos mediante `OpcionAccion`,
  `ContextoAccion` y `ResultadoAccion`. El primer caso usa `puede_combatir` y la
  actitud hostil para ofrecer un ataque básico; no se crea todavía un catálogo
  general de habilidades.
- A 0 PV, un NPC permanece visible y registrado, conserva `Examinar` si tiene
  contenido de observación, deja de hablar y actuar, y su celda se vuelve
  caminable. Curarlo por encima de cero revierte esos comportamientos. Pose de
  derrota, cadáver, botín y XP quedan para incrementos posteriores.
- Al iniciarse un combate, el juego entra en un modo de combate explícito. La
  interfaz muestra arriba el orden de turnos y destaca a quién le toca. Durante
  su turno, cada participante puede decidir cómo gastar sus recursos disponibles.
  La integración jugable del modo precede a las acciones autónomas del NPC.
- Primer corte jugable: seleccionar `Atacar` contra un NPC hostil inicia un
  encuentro de ficha y objetivo; iniciativa base descendente, empate por ID.
  El NPC pasa automáticamente, `Pasar turno` avanza la ficha y el encuentro
  termina al quedar el objetivo a 0 PV o incapacitarse la ficha. Se guardan
  ronda, orden y actor activo; la carga no inicia turnos de nuevo. Detección,
  varios rivales, huida y acciones de NPC quedaron para cortes posteriores.
- Segundo corte del encuentro aislado: un NPC hostil combatiente ataca al
  jugador si está adyacente y conserva una acción principal; usa tirada de
  FUE, daño provisional de 1 PV y paga la acción al intentar. Si no alcanza,
  pasa sin moverse. Sus reservas de turno pertenecen al estado de instancia y
  se guardan; cargar durante su turno no debe repetir una acción consumida.
  En este segundo corte, defensa, reacciones y decisiones tácticas quedaron abiertas.
- El 05-10-2026 se acordó la esquiva automática para jugador y NPC: tras un
  ataque acertado con `1d6 ≤ FUE`, el defensor tira `1d6 ≤ DES`; si supera la
  prueba evita el daño completo. No consume reacción y se permite aunque esa
  reserva esté agotada. Fallar el ataque no provoca una tirada de defensa.
  El atacante paga su acción principal aunque falle o sea esquivado. Ambas
  pruebas mantienen los extremos normales del motor; el daño sigue en 1 PV
  provisional. La esquiva se presenta en el registro, sin decisión modal.

- El 06-10-2026 se acordó extraer el movimiento por casillas de `Ficha` como
  capacidad compartida. `MovimientoPorCasillas` conserva la ejecución del recorrido
  por instancia; los actores aportan permisos, cobro y orientación, y el escenario
  aporta integración con tablero y reacciones. La ficha mantiene su energía;
  `PersonajeNPC` usa su reserva de movimiento sin inventar una reserva de energía.
- El NPC cambia su registro de presencia al confirmar cada paso. La carga restaura
  posiciones móviles después de validar las ubicaciones finales del conjunto;
  los interactuables estáticos conservan la exigencia de coordenada coincidente.
  Se reutiliza el campo de posición del snapshot v2. No se guardan rutas ni tweens.
- El árbol real de combate de LimboAI se evalúa manualmente: comunica una intención
  y el escenario ejecuta movimiento o el ataque existente. Se vuelve a evaluar tras
  moverse, permitiendo acercarse y atacar en el mismo turno. Comparte tareas genéricas
  con el ejemplo de aprendizaje, pero tiene un recurso de árbol independiente.
  Los estados temporales del NPC y el inicio de combate por detección quedan para
  incrementos posteriores.

- El 08-10-2026 el usuario fijó la primera prioridad del NPC atrapado: intentar
  liberarse antes de atacar o perseguir. Reutiliza DES y una acción principal al
  intentar. Si no dispone de esa acción, termina el turno estando atrapado.
  Los estados se comparten por composición entre ficha y NPC, con persistencia
  compatible y procesamiento mediante el `ServicioTurnos` existente.

- El 08-10-2026 el usuario confirmó la revisión de telaraña y caída, y acordó un
  radio de agro de cuatro casillas para ofrecer margen frente a la antorcha del
  jugador, cuyo radio base es cinco. Se interpreta como distancia circular entre
  centros de casilla, sin cono de orientación, con línea visual despejada.
  Sólo un NPC vivo, hostil y combatiente inicia el encuentro automáticamente.
  El escenario interrumpe la ruta de exploración al detectar y conserva el orden
  de iniciativa existente. Si varios detectan, el primer encuentro usa al más
  cercano y desempata por ID; varios enemigos y pérdida del objetivo siguen pendientes.

- El 08-10-2026 el usuario eligió **movimiento = DES + 3** para jugador y NPC.
  Es una reserva de puntos por turno; el terreno conserva su coste real por paso.
  La fórmula común se calcula con la DES de la instancia al iniciar su turno.
  Los máximos de movimiento dejan de configurarse por separado en ficha y definición.
  Los snapshots nuevos guardan el máximo para validar la regla; los antiguos usan
  siete y se adaptan conservando los puntos gastados. Ganar distancia y terminar
  el combate al perder al objetivo son incrementos distintos.

- El 09-10-2026 el usuario aceptó pérdida del objetivo y huida: detección a cuatro
  casillas con visión; al perderla, búsqueda en la última posición conocida;
  al llegar sin redetectar, abandono del combate. Liberarse conserva primera prioridad.
  La memoria se persiste por NPC y no se actualiza desde una posición oculta del
  jugador. Sin recuerdo o sin camino se abandona para evitar un encuentro bloqueado.
  El cierre procesa estados y ronda antes de volver a exploración. Regreso al
  origen y patrullas se reservan para el siguiente incremento.

- El 09-10-2026 el usuario corrigió el momento de salida: perder agro del jugador
  termina inmediatamente la modalidad combate y devuelve el movimiento normal.
  Sustituye la espera hasta finalizar búsqueda. La búsqueda sigue fuera de combate
  y luego el NPC regresa a su origen, sin curarse. Avanza por turno de exploración
  del jugador, con DES + 3, costes y estados comunes; liberarse sigue primero.
  Un origen bloqueado u ocupado obliga a esperar y reintentar. Redetectar abre otro
  encuentro por iniciativa. Se persisten recuerdo y origen, no una ruta ni otro
  estado de fase: ésta se deduce de recuerdo, posición actual y origen.

- El 09-10-2026 el usuario solicitó movimiento cuatro y visión seis para el goblin
  hostil. Se fija movimiento por perfil sin cambiar DES ni la esquiva, y se amplía
  el radio de detección existente a seis. -1 en `movimiento_fijo` mantiene DES + 3
  para otros NPC. La misma configuración rige combate, búsqueda y regreso.
  Guardados anteriores con máximo DES + 3 migran conservando el gasto del turno.

- El 09-10-2026 el usuario fijó movimiento simultáneo de jugador y NPC fuera de
  combate. Renovar movimiento del jugador encola el avance NPC sin esperar sus
  animaciones. Las reservas impiden superponer casillas. El inicio de combate
  invalida la cola y termina los pasos actuales antes de ejecutar las acciones
  por turnos. Cada cierre del jugador procesa superficies una vez; el NPC cierra
  sus estados al terminar su propio avance. Los avances transitorios no se guardan.

- El 09-10-2026 el usuario autorizó recorridos simultáneos de varios NPC y
  recálculo al ocupar alguien su ruta. Cada NPC conserva su destino y los puntos
  restantes; si no hay alternativa, espera cambios espaciales sin gastar recursos
  ni olvidar el recuerdo. La capacidad de movimiento es común y no depende de
  hostilidad. Un nuevo turno cierra una espera mediante FIN_TURNO antes de renovar
  recursos. Esto no amplía todavía los participantes del encuentro de combate.

- El 09-10-2026 el usuario definió los próximos incrementos de NPC: agro colectivo
  hasta que ningún enemigo participante detecte al jugador, incorporación al final
  de la ronda actual e iniciativa nuevamente tirada para todos cada ronda. La
  respuesta de otros NPC se limita por su propia visión; la facción no activa
  automáticamente a todos sus miembros. El alcance de incorporación acordado es
  siete casillas, sujeto a percepción del encuentro. No sustituye la visión seis
  del goblin ni define la fórmula de iniciativa, que sigue pendiente.
- Se acordó distinguir iluminación del mapa, percepción de cada actor y memoria
  del terreno. Estar iluminado o explorado no concede conocimiento omnisciente de
  los ocupantes. La política de oscuridad y capacidades especiales de visión queda
  por definir antes de completar esa capacidad compartida.
- El usuario aceptó defensa inmediata frente a una agresión, separada de los puntos
  persistentes de actitud y su umbral de hostilidad. También solicitó patrullas con
  varios puntos editables, coste de acción para equipar/usar/consumir, cadáver con
  botín y XP al derrotar. La acción adicional, umbrales y atribución de XP siguen
  pendientes. Se conserva la restricción actual de guardar/cargar durante movimiento
  o espera. Estas decisiones fijan trabajo futuro; no certifican implementación.

- El 09-10-2026 el usuario confirmó que iluminación y niebla de guerra deben
  separarse: luz de la casilla, percepción propia de cada actor y memoria del
  jugador no son equivalentes. Una habitación iluminada detrás de una pared
  permanece oculta; al dejar de verla se recuerda terreno, no sus ocupantes
  actuales. Nunca visto, recordado y visible ahora son estados de conocimiento,
  no niveles de luz. La oscuridad y capacidades especiales de visión siguen
  pendientes de definición.
- El usuario pidió registrar toda esta conversación y volver a centrar el trabajo
  en NPC. Los acuerdos completos, estado real y orden propuesto de implementación
  están en `docs/contenido/NPC_Y_DIALOGOS.md`; el diseño y diagnóstico de visión
  están en `docs/contenido/VISION_ILUMINACION_Y_NIEBLA.md`. El primer corte propuesto
  es combate con varios enemigos y agro colectivo sobre la detección existente;
  la separación completa de percepción y luz se retoma como incremento propio.

- El 09-10-2026 el usuario autorizó el primer corte de combate grupal. Al iniciar,
  el escenario reúne al objetivo y a los hostiles vivos que detectan al jugador
  por su radio y línea visual. Mientras un participante vivo detecte, comparte
  la posición observada con los otros NPC del encuentro. El árbol puede acercarse
  a ese recuerdo sin visión propia, pero atacar exige detección propia. Cuando
  ninguno detecta, se conserva memoria individual y vuelven búsqueda/regreso en
  exploración. Se reutilizan turnos, HUD y snapshot v2; no se implementan todavía
  incorporación dinámica ni iniciativa por ronda. La escena manual admite uno
  a cinco enemigos, tres por defecto, y separa archivos K/C por cantidad para
  conservar el guardado anterior. Importación/carga en el editor sin errores de
  scripts; revisión jugable pendiente, sin ejecutar juego ni pruebas.

- El 09-10-2026, tras ejecutar la escena grupal, el usuario consideró demasiado
  fácil escapar caminando lejos. Ante las opciones de huida explícita o espera,
  propuso aumentar visión para acompañar las distancias de movimiento. Se ajusta
  provisionalmente a doce en los goblins manuales, configurable por
  `radio_vision_enemigos`, conservando movimiento cuatro. El jugador con DES cuatro
  mueve siete; desde la colocación inicial de hasta cinco, ese recorrido no supera
  un radio doce si la línea visual sigue despejada. La salida automática al perder
  todos los detectores sigue vigente. El mismo radio amplía la activación inicial;
  paredes y humo conservan sus bloqueos. No se agrega acción Huir ni espera por
  rondas. El ajuste numérico está pendiente de revisión jugable; no se ejecutaron
  juego ni pruebas.

- El 09-10-2026 el usuario recordó que la regla general de movimiento de NPC es
  DES + 3. El valor fijo cuatro es únicamente una excepción de estas pruebas:
  el perfil manual mantiene DES dos, que normalmente daría cinco puntos. La
  apariencia de goblin y su visión doce son provisionales; no comprometen una
  especie ni valores del contenido final y puede que no haya goblins en el juego.
  Las capacidades siguen siendo comunes a actores. Se documenta el alcance de
  la excepción; no se cambia DES ni el comportamiento de la escena manual.

- El 09-10-2026 el usuario confirmó iniciativa **1d6 + DES**, mayor total primero,
  empate por mayor DES y después ID ascendente. Se implementa al iniciar y cada
  ronda nueva; no aplica críticos ni pifias. Un hostil vivo combatiente que ve a
  un participante vivo a `min(7, radio_agro propio)` casillas se añade al final
  de la ronda actual, con línea visual y sin activación global de facción. No
  reinicia el turno activo ni repone recursos al incorporarse. Guardar/cargar
  conserva orden y tiradas; snapshots anteriores empiezan a tirar la próxima
  ronda. Bandos aliados/neutrales y encuentros sin jugador quedan pendientes.
  Importación y apertura de escena en el editor sin errores de scripts.
  No se ejecutaron juego ni pruebas; falta revisión jugable.

- El 09-10-2026 el usuario aprobó patrullas con puntos editables, circuito, espera,
  interrupción al detectar y retorno tras buscar al jugador. Se implementa
  `PatrullaNPC` como hijo opcional `Path2D`: puntos de `Curve2D` proyectados a
  casillas fijas, espera en turnos de exploración y retorno al punto pendiente.
  La búsqueda y liberación siguen teniendo prioridad. Los neutrales con ruta
  obtienen movimiento sin combate. Índice y espera se guardan en snapshot v2;
  una configuración diferente se rechaza antes de restaurar. La escena manual
  existente contiene una ruta editable para el primer NPC. No se añadieron ni
  ejecutaron pruebas automatizadas, ni se ejecutó el juego; revisión jugable pendiente.
  Importación y apertura de escena en el editor sin errores de scripts.

- El 11-10-2026 el usuario aclaró que los NPC deben moverse autónomamente durante
  exploración, también con el jugador quieto. Sus ciclos se disparan por tiempo
  de juego (un segundo provisional configurable) y no por los turnos del jugador.
  Conservan movimiento paralelo, reserva de movimiento y espera por ciclos;
  entrar en combate cancela los avances y respeta el paso en curso. Las
  superficies y los estados del jugador conservan sus cierres anteriores.
  El usuario autorizó explícitamente la comprobación local. La escena dirigida
  de exploración autónoma completó varios ciclos con el jugador quieto y comprobó
  conservación de curva, recursos intactos y pausa/reanudación de la modalidad,
  con salida cero en Godot 4.7. No se comprobó la presentación visual.

- El 11-10-2026 el usuario definió la recompensa de subir de nivel: mejorar un
  atributo en +1 y adquirir una habilidad o pasiva. No se implementó progresión.
  Quedan pendientes la curva de XP, las elecciones y el tratamiento de atributos
  al máximo; los atributos base de pruebas actualmente permanecen entre 1 y 5.

- El mismo 11-10-2026 el usuario ajustó ese reparto: habilidad o pasiva en nivel
  1 y en nivel 2; +1 a un atributo a elección en nivel 3. Sustituye entregar ambas
  mejoras en cada subida. Después confirmó repetir el patrón: los múltiplos de
  tres otorgan atributo y los demás habilidad o pasiva, incluido el nivel 1 al
  crear el personaje. No se implementó progresión.

- El 11-10-2026 el usuario aprobó la curva inicial de progresión: cada salto
  cuesta 100 × nivel actual; alcanzar el nivel N requiere 50 × N × (N − 1) XP
  acumulada. Los valores se refinarán posteriormente. La curva está documentada,
  todavía sin implementación.

- El 11-10-2026 el usuario confirmó conservar el máximo de 5 por atributo.
  Cuando FUE, DES y VOL están en 5, los niveles que otorgarían +1 a un atributo
  otorgan una habilidad o pasiva en su lugar. La progresión sigue documentada,
  todavía sin implementación.

- El 11-10-2026 el usuario pidió centrar el trabajo en NPC y terminarlo antes
  de pasar a las otras capas. Las reglas de XP y niveles acordadas se conservan
  como documentación; implementar la progresión queda para después de NPC.

- El 11-10-2026 el usuario autorizó muerte persistente de NPC, conservando examen,
  botín y guardado. Cero PV deja de ser reversible mediante curación o asignación
  de vida. Se deriva la muerte de los PV para mantener el formato de snapshots;
  cargar un momento anterior vivo restaura ese estado. Se conserva el mismo nodo
  como cuerpo y se admite una textura opcional futura. Se adaptaron pruebas
  existentes a la regla, sin añadirlas ni ejecutarlas; revisión jugable pendiente.

- El 11-10-2026 el usuario informó bloqueo de guardado con paneles cerrados y
  actores aparentemente quietos. Los logs disponibles no muestran errores de
  scripts. Se separan los motivos de bloqueo de guardar/cargar y se recalcula
  el estado modal antes de comprobarlo. La escena manual muestra el motivo
  traducido y lo registra en la salida, con identidad del NPC si está moviéndose
  o esperando una ruta. La causa del caso informado sigue pendiente de identificar
  en ejecución; no se eliminaron protecciones ni se ejecutaron pruebas.

- El 11-10-2026 el diagnóstico del usuario mostró movimiento o espera de ruta
  de Goblin 1 al intentar guardar con los NPC quietos. Se elimina la espera
  dentro del recorrido de exploración: sin camino cierra el avance y reintenta
  en el siguiente ciclo, dejando disponible el guardado en reposo. Dos patrullas
  con destinos mutuamente ocupados intentan resolver el intercambio apartando
  al NPC de menor ID a una casilla vecina libre, conservando el punto pendiente.
  Si no hay espacio siguen esperando entre ciclos. No se ejecutaron pruebas ni
  Godot; la corrección requiere revisión jugable.

- El 11-10-2026 el usuario pidió guardar incluso cuando se mueve un personaje,
  usando su última posición. Se permite guardar durante recorridos y ciclos de
  IA con las últimas casillas confirmadas, recursos y estados actuales de todos
  los actores. Se reutiliza el snapshot síncrono existente, sin serializar tweens,
  reservas ni rutas en curso ni interrumpir el movimiento. Cargar conserva la
  exigencia de reposo y ambas operaciones mantienen el bloqueo modal. No se
  ejecutaron pruebas ni Godot; revisión jugable pendiente.

- El 11-10-2026 el usuario confirmó que funcionó el punto de estabilización de
  NPC (guardado durante movimiento, desbloqueo de patrullas y conservación de
  cadáver/botín al cargar). Se registra como revisión manual. Pidió continuar
  en chats nuevos los cuatro bloques restantes: Actitud primero, luego facciones
  y bandos, XP por muerte y presentación del alcance de visión. Este chat prepara
  el prompt de Actitud; no inicia la implementación de esos bloques.

Si una decisión cambia, debe registrarse primero en el roadmap y después corregirse
en contratos, código y pruebas dentro del mismo cambio.
