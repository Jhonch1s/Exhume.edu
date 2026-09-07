### Trampas que despliegan superficies

`TrampaSuperficie` participa automáticamente en `ENTRAR` e `IMPACTAR`. Mientras
está oculta no ofrece opciones voluntarias. Una vez descubierta ofrece desarme
adyacente mediante FUE, DES o VOL; no se agrega un tipo de acción nuevo, sino
variantes identificadas de `INTERACTUAR`.

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

El ciclo de estado es `OCULTA → DESCUBIERTA → ACTIVADA | DESACTIVADA`. Oculta y
descubierta permanecen transparentes. Al descubrirla, la placa parpadea tres veces
y vuelve a ocultarse: recordar su celda es responsabilidad del jugador. Activada
muestra la placa presionada; desactivada deja de reaccionar y permanece oculta.

El atlas inicial usa celdas de `64×32`: la primera columna representa la placa
armada y la segunda la placa presionada. El destello usa el mismo sprite y un
`Tween` local; no requiere controles de UI.

`traps_isometric.png` reserva la fila 0 para veneno, la fila 1 para fuego y la
fila 2 para placas neutras que accionan mecanismos remotos. `fila_atlas` expone
esas tres alternativas en el inspector. La cuarta fila del archivo no tiene uso
asignado todavía.

Una placa neutral declara los receptores en `ids_receptores_mecanismo`, usando los
`id_instancia` estables del mismo modo que una palanca. La lista se prevalida
completa antes de hundir la placa. Al activarse envía `true` una sola vez, no
despliega una superficie local y no participa de cadenas de placas adyacentes.

Una trampa `OCULTA` puede provocar una única percepción
automática secreta por observador. Debe estar en una celda visible, a distancia de
cuadrícula máxima cuatro y con línea visual. La prueba usa Voluntad: el éxito cambia
el estado a `DESCUBIERTA`; el fallo no cambia la trampa. La tentativa se guarda
en `RegistroConocimiento`, por lo que mover o recargar no concede otra tirada.

Desarmar consume una acción principal al intentarlo y presenta la tirada en primer
plano. Por defecto se tira con desventaja; un Guerrero tira normal. El éxito lleva
la trampa a `DESACTIVADA`. El fallo la activa y aplica su consecuencia configurada.
El resultado transporta la tirada y la consecuencia juntas para presentación y
registro narrativo.

Una trampa consultada incluye también las trampas cardinalmente adyacentes que
puedan reaccionar a `ENTRAR`. La consulta expande toda la componente conectada,
ordena los receptores con las reglas normales y evita ciclos por identidad. El
resolver entrega cada receptor una sola vez al mismo `GestorAcciones`; cada trampa
despliega su propia superficie. La adyacencia diagonal no inicia ni prolonga una
cadena.
