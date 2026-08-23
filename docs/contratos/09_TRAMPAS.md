### Trampas que despliegan superficies

`TrampaSuperficie` es un interactuable únicamente automático: participa en la
categoría `INTERACTUABLE` al resolver `ENTRAR`, pero devuelve cero opciones
voluntarias. Por ello no puede seleccionarse, resaltarse ni examinarse a distancia
desde el menú contextual. La inspección adyacente y el desarme quedan fuera de
este incremento.

Cada instancia configura una `PackedScene` de superficie y un radio entero. Las
trampas son de un solo uso. Al activarse, `TableroGrid` instancia la superficie sobre las
celdas caminables comprendidas por distancia Manhattan, le asigna un ID estable,
la coloca bajo `EfectosSuperficie` y la registra en la celda correspondiente. El
resultado informa esos cambios e interrumpe la ruta después de que la ficha haya
terminado el tween y confirmado su ocupación.

Desde 9.2 una trampa armada también publica reacción automática a `IMPACTAR` cuando
el contexto transporta un item con la etiqueta `&"impacto"`. Esto se aplica aunque
la trampa esté oculta y se haya elegido el piso: el impacto pertenece a toda la
celda. Reutiliza sin duplicación el mismo despliegue de superficie y la misma cadena
cardinal de `ENTRAR`. La trampa no declara `destino_item`; la unidad lanzada conserva
por defecto `DEJAR_EN_CELDA`.

La consulta de reacciones usa una instantánea: el humo creado sobre la celda de
la trampa no se ejecuta retroactivamente en el mismo evento `ENTRAR`. Sí modifica
el coste y reacciona en entradas posteriores. Una explosión instantánea permanece
como consecuencia separada y nunca se registra como superficie.

La presentación visual es independiente de la reacción y admite `OCULTA`,
`INDICIO` y `VISIBLE`. `OCULTA` transparenta el sprite; `INDICIO` usa el sprite creado
con opacidad reducida; `VISIBLE` lo muestra completo. Estos estados no conceden
por sí mismos opciones de interacción ni conocimiento al actor.

El atlas inicial usa celdas de `64×32`: la primera columna representa la placa
armada y la segunda la placa presionada. `INDICIO` usa alpha `0.7`, `OCULTA`
alpha `0.0` y `VISIBLE` alpha `1.0`. Activar la trampa cambia la región del sprite
sin intervención de la UI.

Una trampa consultada incluye también las trampas cardinalmente adyacentes que
puedan reaccionar a `ENTRAR`. La consulta expande toda la componente conectada,
ordena los receptores con las reglas normales y evita ciclos por identidad. El
resolver entrega cada receptor una sola vez al mismo `GestorAcciones`; cada trampa
despliega su propia superficie. La adyacencia diagonal no inicia ni prolonga una
cadena.

