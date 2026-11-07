# Criaturas de nivel 1

Decisiones y primer incremento del 03-11-2026. Se comienza por los Sirvientes de
Eek. Las otras dos criaturas permanecen como propuesta, sin implementación.

## Acuerdos del usuario

- Telaraña y chillido tienen alcance de 3 casillas y consumen una acción principal.
- Liberarse usa DES, consume una acción principal al intentar y se permite una vez
  por turno, aunque el actor tenga varias acciones principales.
- Las duraciones cuentan los próximos N turnos del afectado, con expiración al
  final. El incendio de Escupe Infierno causa daño al comienzo del turno.
- El aturdimiento impide también la esquiva automática. El 04-11-2026 el usuario
  cambió su duración a un único turno del afectado.
- El usuario delegó la propuesta de estadísticas y la recomendación de impacto
  y daño regular. Se comienza con Sirvientes de Eek.

## Balance inicial propuesto

Estos valores son decisiones iniciales de implementación, ajustables tras jugar;
no son estadísticas del texto original proporcionado por el usuario.

| Criatura | FUE | DES | VOL | PV | Movimiento | Detección | XP |
|---|---:|---:|---:|---:|---:|---:|---:|
| Sirviente de Eek | 2 | 3 | 1 | 8 | 5 | 6 | 10 |
| Terror Nocturno | 2 | 4 | 2 | 10 | 6 | 6 | 15 |
| Escupe Infierno | 3 | 2 | 2 | 12 | 4 | 6 | 15 |

Una casilla ocupada por criatura, actitud hostil fija, sin diálogo ni botín
inicial. Facción por especie; 1 acción principal, 0 adicionales y 1 reacción.
La iniciativa conserva 1d6 + DES por ronda. Los alcances a distancia usan la
métrica de cuadrícula de las demás habilidades a distancia; mordida exige una
casilla ortogonal adyacente.

## Sirviente de Eek — primer incremento

Viuda negra de medio metro de altura, inteligente y al servicio de la reina Eek.

- **Mordida venenosa:** 1 acción principal. La víctima tira FUE; si falla recibe
  exactamente **1d6+3** de daño inmediato. No hay ataque previo, esquiva adicional,
  bono de FUE del atacante, reducción de armadura ni veneno periódico añadido.
- **Lanzar telaraña:** 1 acción principal, un objetivo visible hasta **3 casillas**,
  con trayectoria física libre. La víctima tira DES; si falla queda
  `inmovilizado` **1d3 turnos**. La tirada de duración se realiza solo al fallar
  la salvación y queda registrada separada de esta.
- Sin reserva por descanso ni enfriamiento adicional: el presupuesto de acción
  limita cada uso. La IA evita renovar una presa que ya está atrapada.
- `inmovilizado` bloquea movimiento voluntario normal, conserva acciones y la
  participación en rondas. Termina al liberarse o al finalizar N turnos propios.
  No causa daño y no ocupa el canal `enredado` de las superficies existentes.
- Renovar usa el máximo de turnos pendientes, sin sumar ni acortar. Liberación
  exitosa retira ambas telarañas si coinciden. Un nuevo impacto en el mismo turno
  no concede otro intento. El intento se restablece al cerrar el turno propio,
  nunca al cargar o simplemente reponer recursos.
- IA: prioriza liberarse si está atrapada; contra un móvil visible lanza telaraña
  si tiene alcance y trayectoria; contra una presa atrapada se acerca y muerde en
  adyacencia. Tras gastar su acción, si sigue adyacente y tiene movimiento, se
  separa un paso seguro y pagable. Sin ruta pasa; no atraviesa ocupantes, ignora
  peligros ni consulta la posición actual de objetivos ocultos.

Capturar, transportar y entregar presas vivas a Eek sigue siendo trasfondo. No se
implementa daño no letal ni un sistema de captura.

## Terror Nocturno

Escena de laboratorio del Terror Nocturno: `res://tests/interacciones/escena_terror_nocturno.tscn` (F6).
El prefab reutilizable es `res://scenes/personajes/terror_nocturno.tscn` y utiliza
el perfil compartido con combate habilitado. Para colocar varios en un mapa,
asignar un `id_instancia` distinto y estable a cada uno dentro de
`Interactuables/Personajes`, en una casilla transitable. El chillido consulta VOL a distancia de
hasta tres casillas y su recarga se guarda como estado de tres cierres propios.
Existe cierre automático para turno aturdido, pero requiere validación completa
con todas las habilidades y estados de la ficha, carga y cambios de encuentro.
La IA se acerca fuera de alcance y chilla cuando puede; durante la recarga pasa
si está en alcance. Aún no implementa el reposicionamiento propuesto. La escena
es experimental y no acredita balance ni presentación visual revisados.

**Terror Nocturno:** murciélago de dos metros, verde muy oscuro, grandes orejas y
ojos rojos. Chillido a un objetivo visible hasta 3 casillas, 1 acción principal,
VOL o `aturdido` durante 1 turno; sin daño. Recomiendo una separación mínima de tres
turnos propios entre usos (turnos 1, 4, 7) para evitar cadenas continuas de
incapacidad. No repetir sobre un objetivo ya aturdido. Acercarse hasta alcance,
chillar y reposicionarse; sin ataque físico nuevo. Vuelo inicialmente visual,
sin reglas de paso o inmunidades adicionales. Aturdido conserva turno y condición
de objetivo, pero no mueve, actúa, reacciona, se libera ni esquiva automáticamente.

## Escupe Infierno — pendiente de implementación

**Escupe Infierno:** escarabajo naranja del tamaño de un perro grande, abdomen
transparente con una llama constante. Recomiendo alcance 3, objetivo único,
trayectoria física libre, 1 acción principal y sin enfriamiento adicional.
Para acertar usar la regla actual de ataque FUE y esquiva DES. Al conectar,
reutilizar el daño regular sin arma (1d2+1 más bono FUE/equipo menos armadura,
mínimo 1). Después realizar otra prueba DES independiente contra incendio;
fallarla aplica **1d3 turnos** con **1d3 de daño al comienzo de cada turno**.
Evitar otra esquiva o daño inmediato extra en esa salvación. Reposicionarse para
conservar distancia y preferir blancos que no estén ardiendo.

El brillo propuesto ilumina radio 1 más 1 de penumbra, respeta obstáculos y se
apaga al morir. Requiere emisor móvil conectado al tablero/FOV; no es fuego en el
suelo. Para quemaduras coincidentes recomiendo un único Quemado: conservar el
mayor dado y el máximo de turnos pendientes. Si interviene Escupe Infierno,
prevalece 1d3 al inicio; no se ejecuta además un tick al final. Esta renovación
puede prolongar el perfil mayor hasta la duración conservada. Quemados sin esta
criatura mantienen su perfil actual. Es una recomendación para su futuro
incremento, todavía sin implementar.

## El Guardián — implementación inicial

El Guardián es una cockatrice de nivel 4, del tamaño de un caballo grande,
con alas de murciélago y cola de lagarto. Fue una sacerdotisa druídica,
obligada a conservar esta forma para proteger el templo. Su aparición o
proximidad se anuncia con un llanto que combina voces de ave y mujer.
El modelo recibido está en `assets/characters/knight3d/polloModelo.glb`;
no contiene esqueleto ni animaciones.

Balance inicial acordado para un jugador de nivel 2 con una habilidad adicional:

- Dos ataques por turno, como máximo un picotazo y una barrida, a alcance.
- Picotazo: ataque con daño moderado; si impacta, el objetivo tira FUE y,
  al fallar, queda petrificado durante su siguiente turno. Tras petrificar,
  el Guardián no puede aplicar de nuevo ese efecto en sus próximos dos turnos.
- Barrida: el objetivo tira DES; si falla recibe el estado `caido` existente.
  La barrida no causa daño adicional. Se respetan las reglas actuales de caída,
  incluida su resolución al cerrar el turno del afectado.
- El Guardián se acerca para atacar; el vuelo inicialmente es visual. Empezar
  las pruebas con 20 PV y ajustar atributos y daño tras probar el encuentro.

Prefab reutilizable: `res://scenes/personajes/guardian.tscn`; definición:
`res://recursos/personajes/guardian.tres`. Instanciar bajo
`Interactuables/Personajes` y asignar un `id_instancia` único. La criatura
ocupa una huella de 2 × 2 casillas respecto de su ancla; no se ha añadido a ningún mapa existente. Tiene FUE 3,
DES 2, VOL 3, 20 PV, movimiento 4 y 40 XP. El picotazo usa el ataque y daño
naturales actuales; se realiza antes de la barrida. La recarga se consume al
final del turno en que petrifica y de los dos siguientes. Los estados y la
recarga se guardan con la partida.
La huella completa se comprueba al desplazarse; Agarre y Transposición no se
aplican a personajes de varias casillas, mientras se adaptan esas habilidades.

El sprite de cuatro vistas se obtuvo del modelo original con
`tools/render_guardian.py`, con cuadros de 256 × 256 y filtrado lineal. Su
escala visual se ajustó a la huella de 2 × 2; el contorno puede sobresalir por
las alas y la altura. Las vistas comparten el centro de apoyo y una proyección
2:1, en el orden de `DefinicionPersonaje`. El paso dura 0,32 segundos y el
Guardián se orienta hacia el objetivo antes de atacar. No hay animación de
caminar o vuelo ni cadáver específico.
El sprite se desplaza `(32, 0)` respecto del ancla: es el centro geométrico de
las cuatro celdas en el TileSet de 64 × 32 y layout actual. El apoyo del modelo
se proyecta en `(128, 192)` dentro de cada cuadro y usa offset `(0, -64)`;
`prueba_apoyo_visual_guardian.gd` verifica la alineación con la huella.
Como audio provisional de proximidad se usa `assets/sonidos/animales/gallo.wav`;
queda pendiente un llanto que combine ave y mujer. La escena aislada
`res://tests/interacciones/escena_guardian.tscn` se ejecuta con F6; K/C guardan
y cargan su partida de prueba. Las pruebas automáticas son
`prueba_guardian.gd`, `prueba_barrida_guardian.gd` y
`prueba_escena_guardian.gd` y `prueba_huella_guardian.gd`. El balance y la presentación visual requieren
prueba manual con un personaje de nivel 2.
`prueba_seleccion_guardian.gd` comprueba el flujo de clic y selección con las
cuatro casillas desde los cuatro lados: el ataque usa el borde del cuerpo más
cercano al jugador, no la casilla de anclaje del NPC.

## Recursos, autoría y validación

Prefab: `res://scenes/personajes/sirviente_eek.tscn`. Definición editable:
`res://recursos/personajes/sirviente_eek.tres`. Instanciar bajo
`Zona/Interactuables/Personajes`, colocar con ajuste a casilla y asignar un
`id_instancia` único. No se añaden criaturas a los mapas del usuario.

El prefab usa una hoja 2x2 de vistas estáticas de 128 × 128 píxeles capturadas del modelo 3D de araña,
en el orden de DefinicionPersonaje. El modelo original se conserva en
`assets/characters/npcs/sirviente_eek/source/arana.glb`; no contiene animaciones.
Faltan retrato y cadáver del sirviente y los sprites de las otras especies. Telaraña y quemado reutilizan
recursos existentes. No se han generado imágenes. Los sonidos candidatos de araña
se asignan desde assets/sonidos/animales.

Escena F6: `res://tests/interacciones/escena_sirviente_eek.tscn`. Un sirviente,
combate real, clic derecho para liberarse, K/C con archivo de prueba propio.
Prueba automática: `res://tests/interacciones/prueba_sirviente_eek.gd`, mediante
`tests/ejecutar_con_autoloads.gd`. Verifica dados, alcance/obstáculos, costes,
duración sin daño, intentos persistentes, compatibilidad, IA y prefab.

Las acciones NPC conservan la política de acontecimientos solo durante combate.
Quemado, aturdimiento y luz móvil no se implementan en este primer incremento.

### Resultado de validación del primer incremento

- `prueba_sirviente_eek.gd`: **658 comprobaciones, 0 fallos**, incluyendo escena
  real, ejecución de ambas habilidades, retirada y guardado/carga completo.
- Pasan ocho regresiones: táctica NPC (68), exploración NPC autónoma, turnos de
  quemado, gestor de rondas, ResultadoAccion, fuego/combinaciones, registro
  narrativo y persistencia de partida en archivo (9).
- `prueba_estado_npc_persistente` falla dos expectativas del antiguo daño fijo de
  1 PV; el ataque regular vigente usa dados. `prueba_habilidades_nivel_dos`
  registra 23 fallos de aprendizaje/guardado/empuje y callbacks sobre un escenario
  liberado. Ambos resultados se reproducen en una copia de contraste con los
  scripts de HEAD anteriores a este incremento, conservando los recursos y mapas
  actuales. No se modifican esas reglas ni pruebas ajenas en este trabajo.
- El cierre de las pruebas integradas informa recursos/ObjectDB pendientes,
  también observados en el contraste. El balance jugable requiere revisión manual.
