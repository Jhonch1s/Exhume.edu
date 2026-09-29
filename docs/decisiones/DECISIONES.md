# Decisiones arquitectónicas

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
  Defensa, reacciones y decisiones tácticas del NPC siguen abiertas.

Si una decisión cambia, debe registrarse primero en el roadmap y después corregirse
en contratos, código y pruebas dentro del mismo cambio.
