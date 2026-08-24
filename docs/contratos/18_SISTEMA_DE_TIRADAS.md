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

## Resultado estructurado

El contrato concreto se definirá al implementar el primer incremento, pero deberá
conservar al menos los dados obtenidos, el dado seleccionado cuando corresponda,
el valor objetivo, las fuentes de ventaja y desventaja, éxito o fallo, clasificación
de crítico o pifia, origen y política de presentación.

Las pruebas contra atributos y las tiradas de cantidad comparten el generador, pero
no necesitan una abstracción común adicional hasta que el código demuestre esa
necesidad.

## Registro, persistencia y límites

El historial del jugador es independiente de `RegistroAccionesDesarrollo`. Conserva
durante la sesión una explicación legible de todas las tiradas, incluidas las de
`SOLO_LOG`, sin exponer IDs internos ni etapas de depuración.

Los resultados ya resueltos, animaciones e historial no se persisten inicialmente.
Sí deberán persistirse en su dominio los futuros atributos, estados, ventajas,
desventajas o usos agotados que sobrevivan a una carga.

Quedan fuera hasta existir un caso jugable: combate, daño crítico, percepción,
diálogo, ayudas, repeticiones, grados de resultado y consecuencias generales de
críticos o pifias.

## Incrementos previstos

1. Motor digital mínimo para `NdM`, resultados individuales, términos positivos y
   negativos, total efectivo y generación determinista en pruebas.
2. Prueba de Exhume con `1d6 ≤ atributo`, ventaja, desventaja, crítico y pifia.
3. Origen, política de presentación e historial de sesión separado del diagnóstico.
4. Presentación mínima que consume un resultado ya resuelto.
5. Una vertical no relacionada con combate en la primera zona.

