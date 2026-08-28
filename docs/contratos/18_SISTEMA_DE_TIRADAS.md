# Sistema de tiradas

## Alcance

Exhume es la referencia mecánica; Templo de los Lamentos aporta contenido para las
primeras zonas. El sistema digital conserva sus reglas útiles sin convertir las
decisiones futuras de combate, diálogo o contenido en reglas del núcleo.

El motor de dados es independiente de `GestorAcciones`. El elemento que solicita
una tirada elige sus parámetros, recibe un resultado estructurado y decide sus
consecuencias. El motor nunca aplica daño, estados, revelaciones ni reacciones.

## Prueba básica de Exhume

Una prueba ordinaria tira `1d6` y tiene éxito cuando el dado es menor o igual que
el atributo relevante. Los valores efectivos de prueba permanecen entre 1 y 5:
las acciones imposibles se bloquean sin tirar y las triviales pueden resolverse
automáticamente.

El orden de resolución es obligatorio:

```text
resolver ventaja/desventaja
→ lanzar
→ seleccionar dado
→ comprobar crítico/pifia
→ si no es extremo, comparar dado ≤ atributo
→ entregar resultado estructurado
→ el solicitante decide las consecuencias
→ registrar y presentar según política
```

El dado seleccionado se clasifica antes de cualquier otra regla:

- `1` natural: crítico y éxito asegurado.
- `6` natural: pifia y fallo asegurado.
- No se aplican modificadores que cambien estos extremos.
- Crítico y pifia no producen por sí mismos consecuencias concretas.

## Ventaja y desventaja

- Ventaja tira `2d6` y selecciona el menor.
- Desventaja tira `2d6` y selecciona el mayor.
- Cada fuente de ventaja cancela una fuente de desventaja.
- Tras cancelar, cualquier balance positivo es ventaja, cero es una tirada normal
  y cualquier balance negativo es desventaja.
- Las fuentes se conservan como información explicable, aunque no agregan más de
  dos dados a la prueba inicial.

Sólo se clasifica el dado seleccionado:

```text
[1, 6] con ventaja    → se elige 1 → crítico
[1, 6] con desventaja → se elige 6 → pifia
```

## Dados y cantidades

El entorno digital puede tirar dados de cualquier cantidad de caras directamente;
`1d3` devuelve 1, 2 o 3 sin convertir un `d6`. Una cantidad puede combinar términos
independientes, por ejemplo `1d6 + 1d4 - 1d3`, y conserva los resultados de cada
término. Una cantidad que no admite negativos tiene total efectivo mínimo cero.
No existe un máximo universal: cada receptor aplica límites propios, como PV
máximos al curar o vida mínima cero al recibir daño.

Los dados adicionales de cantidades no modifican el valor natural empleado para
clasificar el crítico o la pifia de una prueba.

## Origen y presentación

El origen de la tirada y su presentación son decisiones ortogonales:

```text
Origen: SOLICITADA | AUTOMATICA
Presentación: PRIMER_PLANO | SOLO_LOG
```

Una tirada automática puede mostrarse en primer plano. `SOLO_LOG` cubre inicialmente
las tiradas llamadas secretas: no interrumpen con una presentación completa, pero
el historial de la sesión informa que ocurrieron y cuál fue su resultado.

La lógica resuelve primero el resultado y la presentación reproduce después la
variante correspondiente; una animación, simulación 3D o vídeo nunca vuelve a tirar.

Desde 14.3, tanto `ResultadoTirada` como `ResultadoPrueba` conservan `origen` y
`presentacion` mediante los enums cerrados de `TiposTirada`. El motor valida ambos
antes de consumir azar. Estas propiedades son independientes: una tirada automática
puede usar `PRIMER_PLANO` y una solicitada puede usar `SOLO_LOG`.

Desde 14.4, el panel reutilizable de resultados acepta también cantidades y pruebas
ya resueltas mediante `mostrar_tirada()`. Para una prueba muestra modo, dados en orden,
dado seleccionado, atributo, clasificación y éxito/fallo; para una cantidad muestra
términos, dados, total y efectivo. Rechaza resultados inválidos y `SOLO_LOG` sin
abrirse. Presentar no recibe un motor ni consume azar. No hay animación de dados ni
integración con contenido hasta existir la vertical de 14.5.

La vertical 14.5 utilizó temporalmente la palanca de Zona 1 para probar la
integración. La Fase 16 retira esa prueba por decisión de diseño: examinar y accionar
una palanca son deterministas. Las futuras pruebas de exploración pertenecen al
contenido que realmente introduce incertidumbre, como trampas y secretos.

`ResultadoAccion` puede transportar el resultado de tirada ya resuelto. El escenario
lo registra en `HistorialTiradas` y presenta dados y mensajes narrativos en el panel
existente. `GestorAcciones` continúa sin conocer reglas de dados, atributos, éxito,
críticos, pifias ni consecuencias de la tirada.

## Resultado estructurado

Desde 14.1, `MotorDados` recibe directamente una lista de términos con `cantidad`,
`caras` y `signo` (`1` o `-1`). Prevalida la expresión completa y el mínimo efectivo
antes de consumir el `RandomNumberGenerator`; un rechazo devuelve motivo estable,
ningún término y no avanza el generador. Una resolución válida devuelve
`ResultadoTirada`, que conserva copias defensivas de los términos resueltos, sus
resultados individuales ordenados, subtotales, total calculado y total efectivo.

El generador puede inyectarse ya configurado con una semilla para pruebas. El motor
crea y aleatoriza uno propio cuando no se inyecta. No requiere nodos ni árbol activo.

Desde 14.2, `MotorDados.resolver_prueba()` acepta un atributo efectivo entero entre
1 y 5 y listas de IDs de fuentes de ventaja y desventaja. Conserva ambas listas y
las cancela por cantidad: balance positivo tira `2d6` y selecciona el menor, balance
negativo selecciona el mayor y balance cero tira `1d6`. Sólo el dado seleccionado
se clasifica. Un `1` natural es crítico y éxito; un `6` natural es pifia y fallo;
los demás tienen éxito cuando son menores o iguales al atributo.

`ResultadoPrueba` conserva copias defensivas de los dados y fuentes, el atributo,
modo, dado seleccionado, clasificación y éxito. Un atributo fuera de `1..5` o una
fuente vacía se rechaza antes de consumir azar. El bloqueo de acciones imposibles y
la resolución automática de triviales pertenecen al solicitante, no al motor.

`HistorialTiradas` acepta resultados válidos de cantidad o prueba y guarda durante
la sesión una línea explicable por resolución, incluidas las de `SOLO_LOG`. Expone
copias defensivas, puede limpiarse y no observa `GestorAcciones`, imprime en consola,
presenta UI ni persiste datos. Los resultados inválidos no se registran.

Las pruebas contra atributos y las tiradas de cantidad comparten el generador, pero
no necesitan una abstracción común adicional hasta que el código demuestre esa
necesidad.

## Daño variable y estados

Desde la Fase 16, una `SolicitudEfecto` de estado puede transportar términos de
daño para sus ticks. La expresión se conserva en `EstadoActor`, se persiste con la
ficha y `ServicioTurnos` la resuelve nuevamente en cada tick como tirada automática
`SOLO_LOG`. El contenido configura la expresión; `AplicadorEfectos` sólo recibe el
total ya resuelto.

El humo venenoso solicita primero una salvación automática de Voluntad. Un éxito
evita el estado; un fallo aplica dos ticks y cada uno resuelve `1d2`. Renovar el
veneno restaura los dos ticks, pero nunca produce daño inmediato. Tanto la salvación
como los ticks se registran en el historial de la sesión durante exploración.

Quemado reutiliza el mismo mecanismo con tres ticks de `1d2`. Aplicar o renovar el
estado no causa daño inmediato. La salvación de Destreza contra el daño inicial de
una explosión de fuego pertenece a la futura explosión que la solicite, no a la
superficie ni al estado persistente.

## Registro, persistencia y límites

El historial del jugador es independiente de `RegistroAccionesDesarrollo`. Conserva
durante la sesión una explicación legible de todas las tiradas, incluidas las de
`SOLO_LOG`, sin exponer IDs internos ni etapas de depuración.

Los resultados ya resueltos, animaciones e historial no se persisten inicialmente.
Sí deberán persistirse en su dominio los futuros atributos, estados, ventajas,
desventajas o usos agotados que sobrevivan a una carga.

La percepción de trampas es el primer consumidor secreto: prueba Destreza con radio
cuatro, celda visible y línea visual. Usa `AUTOMATICA` + `SOLO_LOG`; el resultado se
registra y el intento por observador/trampa se persiste, pero no abre el display.

Quedan fuera hasta existir un caso jugable: combate, daño crítico, diálogo, ayudas,
repeticiones, grados de resultado y consecuencias generales de críticos o pifias.

## Incrementos previstos

1. Motor digital mínimo para `NdM`, resultados individuales, términos positivos y
   negativos, total efectivo y generación determinista en pruebas.
2. Prueba de Exhume con `1d6 ≤ atributo`, ventaja, desventaja, crítico y pifia.
3. Origen, política de presentación e historial de sesión separado del diagnóstico.
4. Presentación mínima que consume un resultado ya resuelto.
5. Una vertical no relacionada con combate en la primera zona.
