# Contrato — registro narrativo de sesión

> Estado: primer incremento implementado el 28 de agosto de 2026.

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

## Duración

El historial pertenece exclusivamente a la sesión actual, comienza vacío y no se
incluye en partidas guardadas ni snapshots. Cerrar el juego descarta el historial.

## Primer incremento verificable

1. Crear un registro en memoria que añada entradas ordenadas.
2. Crear el panel contraíble: tres entradas en compacto y todas en el expandido.
3. Integrar una sola vertical de reacciones al movimiento: pinchos, telaraña,
   lodo, hielo y fuego.
4. Agrupar tirada y consecuencia evitando entradas duplicadas.
5. Verificar que el panel no bloquea el juego, conserva el orden y respeta la
   visibilidad.

Quedan fuera: persistencia, filtros, búsquedas, exportación, diálogos, combate,
puertas y el registro de pasos normales.

## Criterios de aceptación

- Una reacción al movimiento genera una sola tarjeta comprensible.
- El estado contraído muestra como máximo las tres últimas entradas.
- El estado expandido permite recorrer todo el historial de la sesión.
- Contraer y expandir no altera movimiento, turnos ni resultados.
- El registro técnico existente permanece sin cambios y no alimenta la interfaz.
- Una percepción secreta fallida no queda expuesta por una suscripción global al
  historial de tiradas.

## Implementación del primer incremento

`RegistroNarrativoSesion` conserva entradas ordenadas solo en memoria y emite cada
alta al panel observador. `PanelRegistroNarrativo` muestra las tres últimas en modo
compacto y todas en modo expandido; solo sigue el final si el jugador no desplazó
la vista hacia entradas anteriores.

`EscenarioBase` produce una entrada visible después de resolver un lote `ENTRAR`
de pinchos, telaraña, lodo, hielo o fuego. Usa la tirada y las consecuencias ya
resueltas del mismo `ResultadoReacciones`, por lo que genera una tarjeta por lote.
El mismo criterio cubre lava y humo venenoso porque su daño o estado es perceptible.
Las acciones visibles `INTERACTUAR` y `USAR_ITEM`, los lanzamientos y los efectos
de quemado o veneno al avanzar el turno usan el mismo canal con sus resultados ya
resueltos.
La activación de trampas forma parte del lote de movimiento; una detección secreta
solo publica el descubrimiento exitoso. Destrabarse y la expiración o transformación
de una superficie visible también producen una entrada. Las transformaciones fuera
de la visión actual no se revelan.
No observa globalmente `HistorialTiradas`, no modifica `GestorAcciones` y no incluye
el registro en guardados ni snapshots.
