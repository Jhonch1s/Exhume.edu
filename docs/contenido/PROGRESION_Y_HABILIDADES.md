# Progresión y habilidades: punto de partida

Estado revisado el 21-10-2026. Este documento distingue reglas ya acordadas,
comportamiento implementado y propuestas para el próximo corte. Las propuestas
no son reglas vigentes.

## Implementado y comprobado

- `Ficha` guarda nivel, XP acumulada y atributos FUE, DES y VOL. La XP por muerte
  de un oponente del encuentro llega una sola vez a la ficha y sobrevive a la
  carga. La barra del HUD muestra XP real y el siguiente umbral.
- `GestorAcciones` ya valida alcance, línea de efecto, costes, resultados y
  efectos; `RecursosTurnoActor` lleva acción principal, adicional, reacción y
  movimiento. Se pueden reutilizar para habilidades activas.
- La primera ranura activa «Ataque doble», «Ocultarse» o «Bola de fuego» según
  la clase y muestra su uso `1/1` o `0/1`. Estas habilidades iniciales se conservan.
- La base del corte de nivel 2 ya convierte 100 XP en nivel 2 y una recompensa
  pendiente persistida. Migra guardados antiguos con XP suficiente y conserva
  recursos gastados. La XP excedente permanece acumulada; este corte todavía
  no concede niveles 3 o superiores.

## Corte jugable de nivel 2

**Regla actualizada por el usuario:** en nivel 2 se ofrecen, por clase,
**dos habilidades activas y dos pasivas**. Se aprende **exactamente una de las
cuatro**, además de conservar la habilidad inicial. El usuario quiere efectos
que abran posibilidades creativas de juego. Esto reemplaza la preferencia
anterior por ofrecer solo pasivas de clase.

El usuario aprobó las doce recompensas del
[catálogo de nivel 2](PROPUESTA_CATALOGO_NIVEL_2.md). Están implementadas:
Guerrero (Ariete, Agarre, Golpe desplazante, Inercia), Ladrón (Señuelo,
Paso de sombra, Escapista, Trampero), Mago (Transposición, Trasvase,
Piromancia libre, Contagio arcano).

**P** o el botón «Progresión» abre la elección fuera de combate, movimientos,
acciones, diálogos y otros paneles. Se ven las cuatro opciones, sus efectos y
costes. El panel muestra la clase, los iconos y el detalle de la opción; no
preselecciona ninguna y «Aprender» nombra la elegida antes de confirmarla.
«Aprender» confirma exactamente una; cerrar o elegir después conserva
el premio pendiente. Aprender no cura ni recupera recursos gastados. La activa
nueva nace con su propio uso `1/1` y aparece en la ranura **2**; la primera
habilidad continúa en **1**. Las pasivas aparecen también en la ranura 2 y en
el resumen de progresión.

Una flecha intermitente junto al retrato señala que hay una elección pendiente.
Al pulsarla se abre el panel cuando no hay combate ni otra interacción activa;
el indicador permanece al posponer y desaparece al aprender. El panel recibe
el mismo filtro CRT que el escenario y el HUD, también en las arenas de prueba.

**Golpe desplazante:** después de causar daño se ofrece Empujar / No empujar;
no se configura antes del ataque. Rechazar conserva la oportunidad del turno.
En Ataque doble puedes decidir después de cada golpe que cause daño: si empujas
tras el primero y pierde alcance, no se ejecuta el segundo. **Contagio arcano:** 2 alterna desactivado,
Veneno y Quemado. Las demás pasivas son automáticas.

La ficha persiste pendientes, activas y pasivas aprendidas, usos independientes,
modos opcionales, oportunidades gastadas, pasos de Inercia, Agarre y señuelos.
Se validan clase e IDs; los vínculos con NPC y casillas se validan antes de
restaurar el mundo. Cargar no repone usos ni límites por turno. Descansar
recupera los usos de las activas aprendidas además de los iniciales.

Ver [arenas y controles](../../scenes/pruebas_habilidades/README.md) y
[verificación del corte](../pruebas/PROGRESION_NIVEL_2.md).

## Reglas acordadas (implementación completa pendiente)

- Cada salto cuesta `100 × nivel actual` XP; llegar al nivel N requiere
  `50 × N × (N − 1)` XP total. Así, nivel 2 comienza en 100 XP, nivel 3 en 300
  y nivel 4 en 600.
- En nivel 1 y 2 se elige una habilidad o pasiva. Se repite esa recompensa en
  los niveles que no sean múltiplos de tres. Los múltiplos de tres dan +1 a FUE,
  DES o VOL a elección, hasta un máximo de 5.
- Si los tres atributos ya están en 5, el premio de atributo se reemplaza por
  una habilidad o pasiva. La XP no se divide entre futuros integrantes del grupo.

## Propuesta original del primer corte (referencia histórica)

1. Registrar premios pendientes separados de la XP y del nivel. Al alcanzar el
   umbral, mostrar una notificación. Resolver elecciones fuera de combate y de
   paneles modales, de a un nivel por vez si se ganaron varios. Guardar y cargar
   tanto lo aprendido como cualquier elección pendiente.
2. Hacer una pantalla de elección que muestre el efecto, el coste y el tipo de
   premio antes de confirmar. Integrar también la elección inicial de nivel 1
   en la creación o en el primer ingreso al escenario. No restablecer acciones
   gastadas ni sanar automáticamente al subir, salvo que se acuerde lo contrario.
3. Probar la canalización completa con una habilidad activa y una pasiva reales:
   adquisición, botón del HUD, legalidad del turno, costes, resultado y carga.
   Luego ampliar el catálogo por clase sin duplicar el gestor de acciones.

Una habilidad ofensiva a distancia necesitaría además selección de objetivo,
percepción y línea de efecto; un buff duradero necesitaría definir duración,
acumulación y guardado del estado.

## Referencia de mesa: Exhume_Panfleto_3.md

El panfleto aportado por el usuario es material orientativo, no una ampliación
automática de las reglas vigentes. Propone como habilidades especiales básicas:
Guerrero ataca dos veces por turno, Ladrón se oculta de inmediato y Mago
manipula un elemento. Cada uso exige 1d6 y con 5+ impide repetir la habilidad
hasta descansar ocho horas. La magia ofensiva incluye tiradas de combate y daño
de `1d6 × nivel de mago`.

Estas tres ideas pueden inspirar el primer catálogo por clase, pero necesitan
adaptación concreta. Doble ataque debe respetar acciones principales y defensa;
ocultarse requiere reglas de percepción, ruptura del sigilo y guardado; magia
elemental necesita objetivos, alcance, coste y efectos definidos. El juego aún
no tiene un descanso de ocho horas que pueda recuperar usos. Aplicar literalmente
el daño mágico del panfleto desbalancearía los PV y el daño actuales.

La mesa sube un nivel cada cuatro sesiones y da `1d6` PV más una habilidad
inventada en cada subida. Eso difiere de la curva de XP y del patrón de premios
ya acordados para el videojuego. También recomienda evitar cambios de
estadísticas, mientras que el acuerdo vigente sí da +1 atributo cada tres
niveles. Las reglas de mesa no reemplazan esos acuerdos sin decisión explícita.

## Descanso y recursos de habilidades

El 20-10-2026 el usuario confirmó que le interesa que haya recursos de
habilidades que requieran descansar para recuperarse. Luego definió el flujo
general inspirado en Baldur's Gate: desde cualquier lugar y tantas veces como
quiera, el jugador puede ir a un **escenario de campamento** con una fogata
central. Allí decide si descansar **usando provisiones**. Entrar en el
campamento y confirmar el descanso son decisiones distintas; la visita no debe
gastar provisiones por sí sola. Se acordó bloquear el acceso durante combate,
movimiento de actores, resolución de acciones, diálogos y menús modales. Durante
la implementación el usuario eligió **1 ración para recuperar todos los PV y
la energía**. Este flujo ya está implementado y comprobado en Godot 4.7.

`Ficha.raciones` es ahora un contador persistido de provisiones, inicialmente 3.
La confirmación descuenta una unidad; abrir, cancelar, volver o cargar no cobra.
Con cero raciones se puede visitar y regresar, pero no descansar. Los snapshots
anteriores sin contador recuperan las tres raciones iniciales. No se añadieron
objetos de comida al inventario ni abastecimiento: esa procedencia sigue abierta.
Las acciones, adicionales, reacciones, movimiento y estados conservan sus reglas
de turno. El descanso no los reinicia ni elimina. No hay reloj de aventura;
el temporizador de patrullas mide segundos reales, no horas.

Los **usos hasta descansar** están separados de las acciones de turno y de la
energía. La ficha persiste los usos de «Ataque doble», «Ocultarse» y «Bola de
fuego» y los recupera al confirmar un descanso. Cada habilidad tiene su propio
contador.

**Regla acordada el 21-10-2026:** cada habilidad activa tendrá su propio uso
`1/1` hasta descansar; no habrá una reserva compartida. Al ejecutar la habilidad
se gastará su uso aunque falle la tirada; cancelar la selección o elegir un
objetivo inválido no lo gastará. Solo confirmar el descanso repondrá los usos
agotados. El estado de cada habilidad deberá persistir en el guardado y mostrarse
en su ranura del HUD (`1/1` o `0/1`). Las pasivas no tienen usos.

**Implementado — Guerrero, «Ataque doble»:** durante su turno de
combate, el guerrero elige un enemigo adyacente y gasta una acción principal y
su uso `1/1`. Resuelve dos ataques básicos consecutivos contra ese mismo
enemigo; cada uno hace su propia tirada de FUE, admite esquiva de DES y causa
1 punto de daño si acierta. Si el primer golpe derrota al enemigo, no se tira
el segundo. Un intento válido consume la acción y el uso aunque ambos golpes
fallen; cancelar o elegir un objetivo inválido no los consume. No gasta
energía adicional. En este primer corte el Guerrero dispone de ella desde el
inicio y se conserva al aprender la recompensa de nivel 2. El botón del HUD
activa la selección de objetivo sobre el mapa; pulsarlo de nuevo o usar Esc
cancela la selección. Ambos golpes se registran en el historial y el panel
de resultado muestra la última tirada.
En combate, al apuntar a un oponente visible aparece junto al cursor la
probabilidad de que el ataque básico cause daño: acierto de FUE multiplicado
por fallo de esquiva de DES. Fuera de alcance o sin acción principal se muestra
`0%` con el motivo.

**Implementado — Ladrón, «Ocultarse»:** en combate o exploración puede
ocultarse de inmediato incluso a plena vista. Gasta una acción adicional y su
uso `1/1`; moverse no lo revela. Los NPC dejan de detectarlo y de elegirlo como
objetivo visible. Dura dos turnos del jugador, contando el turno en que se
activa; atacar o recibir cualquier daño lo termina antes, incluido el daño
periódico de veneno o fuego. Si nadie más mantiene el encuentro, termina el
combate por pérdida de percepción. La duración y el uso se guardan.
Mientras está Oculto, la ficha se muestra al 40% de opacidad y el HUD indica
los turnos restantes. Perder el sigilo devuelve su opacidad completa.

**Implementado — Mago, «Bola de fuego»:** en combate o exploración elige un
enemigo visible hasta cuatro casillas de distancia. Gasta una acción principal
y su uso `1/1`, causa 1 punto de daño de fuego y tiene un 50 % de probabilidad
de aplicar Quemado, el mismo estado de tres ticks de `1d2` usado por el fuego
del escenario. Su celda siempre queda ardiendo tres turnos, salga o no Quemado;
si ya había fuego, renueva la duración sin duplicarlo. El alcance, la línea de visión y el bando se validan antes del
gasto; elegir un objetivo inválido o cancelar la selección no cobra. El uso se
guarda y se recupera al descansar. El impacto inicial no tiene tirada de
ataque ni esquiva. Lanzarlo desde exploración inicia el encuentro.

La primera ranura de habilidad se activa con **1** en las tres clases. Las
ranuras 1–4 usan las teclas numéricas 1–4 y las de objetos rápidos, 5–8;
también se acepta el teclado numérico. Las ranuras sin implementación siguen
desactivadas. Hay [escenarios de prueba para Ladrón y Mago](../../scenes/pruebas_habilidades/README.md).

La escena de campamento conserva el escenario de origen vivo y suspende su
procesamiento; al salir reaparecen exactamente sus nodos y la ficha. Guardar
dentro conserva el snapshot completo del mundo, la ruta real de zona y la marca
`en_campamento`. Cargar desde la misma zona recupera también la estancia; otra
zona se rechaza antes de mutar. No se implementó navegación automática entre
zonas ni una pantalla nueva de continuar partida. El snapshot guarda casillas
exploradas; la visibilidad actual se reconstruye desde la ficha. Guardados viejos
sin esa información conservan la compatibilidad, pero no pueden recuperar una
exploración que nunca almacenaron.

**Comportamiento provisional de este corte, no regla acordada del mundo**:
durante visita y descanso no avanzan patrullas, estados ni superficies. La
pregunta al usuario sobre ese avance permanece abierta. Tampoco se fijaron
horas exactas, tirada 5+ ni abastecimiento. No se aplican
automáticamente las reglas del panfleto. Véase [prueba jugable y cobertura](../pruebas/CAMPAMENTO.md).

## Decisiones abiertas para ampliar las habilidades

- ¿Adaptamos las tres habilidades emblemáticas del panfleto como opciones
  iniciales de clase, o partimos de otro catálogo?
- ¿La elección inicial ocurre al crear el personaje o antes del primer turno?
- El catálogo de nivel 2 ya fue aprobado e implementado. El balance y las
  opciones de los niveles siguientes requieren nuevas pruebas y contenido.
- Al subir FUE o DES, ¿el aumento de PV máximos o movimiento disponible aplica
  de inmediato, o desde el siguiente turno? El guardado actual deriva PV máximos
  de FUE+DES+VOL y movimiento máximo de DES+3; hay que migrarlo con cuidado.
