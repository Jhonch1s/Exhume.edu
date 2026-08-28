# Contrato — registro narrativo de sesión

> Estado: propuesta aprobada para la Fase 17; implementación no iniciada.

## Objetivo

Mostrar al jugador por qué el mundo reaccionó mediante un historial legible de
eventos de la sesión. Este registro es independiente de
`RegistroAccionesDesarrollo`: el primero comunica ficción y consecuencias; el
segundo conserva información técnica para desarrollo y depuración.

## Presentación

- Contraído: ventana flotante discreta con las tres entradas más recientes y un
  control para expandirla. No bloquea movimiento ni interacciones.
- Expandido: historial cronológico completo, desplazable y contraíble.
- Las entradas nuevas desplazan la vista al final salvo cuando el jugador está
  consultando entradas anteriores.
- Un acontecimiento completo ocupa una tarjeta. No se separan en líneas
  independientes la tirada, el daño y el estado resultante.

Ejemplo:

```text
[Telaraña]
DES 3 → 5, fallo
Quedas enredado
```

## Entrada mínima

Cada entrada contiene únicamente:

- número de secuencia;
- categoría (`tirada`, `daño`, `estado`, `movimiento`, `objeto` o `sistema`);
- mensaje principal;
- detalles opcionales, incluido el resultado de tirada ya resuelto;
- política de visibilidad.

El registro recibe resultados ya resueltos. No calcula dados, daño, estados ni
consecuencias. El panel solo observa el registro y no participa en el juego.

## Visibilidad y agrupación

- Una reacción lógica produce una sola entrada, aunque incluya tirada y efecto.
- Las tiradas automáticas con consecuencias perceptibles pueden figurar en la
  tarjeta de esa consecuencia sin abrir una presentación completa de dados.
- No se conectará el panel indiscriminadamente a todas las tiradas: una prueba
  secreta sin consecuencia visible, como una percepción fallida, no debe revelar
  por accidente el objetivo ni la razón de la prueba.
- El productor del acontecimiento determina su política de visibilidad; el panel
  se limita a respetarla.

## Duración y persistencia

El historial pertenece a la sesión actual, comienza vacío y no se incluye todavía
en partidas guardadas ni snapshots. Esta decisión puede revisarse cuando exista
una necesidad narrativa concreta de conservarlo entre cargas.

## Primer incremento verificable

1. Crear un registro en memoria que añada entradas ordenadas.
2. Crear el panel contraíble: tres entradas en compacto y todas en el expandido.
3. Integrar una sola vertical de reacciones al movimiento: pinchos, telaraña,
   lodo, hielo y fuego.
4. Agrupar tirada y consecuencia evitando entradas duplicadas.
5. Verificar que el panel no bloquea el juego, conserva el orden y respeta la
   visibilidad.

Quedan fuera de este incremento: persistencia, filtros, búsquedas, exportación,
diálogos, combate, puertas, palancas, items y el registro de pasos normales.

## Criterios de aceptación

- Una reacción al movimiento genera una sola tarjeta comprensible.
- El estado contraído muestra como máximo las tres últimas entradas.
- El estado expandido permite recorrer todo el historial de la sesión.
- Contraer y expandir no altera movimiento, turnos ni resultados.
- El registro técnico existente permanece sin cambios y no alimenta la interfaz.
- Una percepción secreta fallida no queda expuesta por una suscripción global al
  historial de tiradas.
