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
