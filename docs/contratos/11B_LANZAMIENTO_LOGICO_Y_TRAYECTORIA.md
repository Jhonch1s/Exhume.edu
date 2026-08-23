### Lanzamiento lógico — incremento 9.1

`TransferidorItems` recibe `LANZAR_ITEM`, revalida que la misma instancia continúe
en el inventario y exige la etiqueta `&"arrojable"`. El contexto transporta una
unidad, copia las etiquetas y magnitudes de la definición y agrega `&"impacto"`.
En 9.1 el alcance provisional se recibió como Manhattan; trayectoria y línea física
todavía no formaban parte de ese incremento. La corrección posterior descrita en 9.4
lo sustituyó por métrica de cuadrícula para los lanzamientos.

La celda destino debe existir. `objetivo_impacto = null` representa elegir el piso;
un objetivo explícito debe pertenecer a las reacciones `IMPACTAR` de esa celda. El
objetivo directo se resuelve primero y las restantes fuentes conservan después su
orden contractual. Ningún receptor se procesa dos veces.

`DestinoItem` contiene `CONSERVAR_EN_INVENTARIO`, `CONSUMIR` y
`DEJAR_EN_CELDA`. El primer destino explícito según el orden de resolución
prevalece; si ninguna reacción declara uno, lanzar usa `DEJAR_EN_CELDA`. Una pila
de varias unidades conserva su identidad y exige `id_item_resultante` para la
unidad separada. Una pila de una unidad puede trasladar la misma instancia.

La confirmación ocurre después de resolver el impacto. Un bloqueo previo mantiene
el inventario intacto. Para dejar caer, el transferidor retira primero la unidad y
registra después el `ItemSuelo`; si el registro falla, recompone cantidad e
identidad mediante el mismo rollback de las transferencias parciales. No existe
rollback general de cambios arbitrarios producidos por las reacciones.

### Selección provisional de lanzamiento — incremento 9.2

La tecla provisional `L` reutiliza `MenuContextualInteracciones` y muestra solo
pilas cuya definición contiene `&"arrojable"`. Tras elegir una pila, el menú se
cierra y una celda es seleccionable si está visible, existe y queda dentro del
alcance provisional de cinco celdas. Desde la corrección posterior a 9.4, ese radio
usa métrica de cuadrícula y no penaliza dos veces los pasos diagonales.

Si la celda no contiene receptores `IMPACTAR` con nombre presentable, el flujo elige
el piso automáticamente. Si contiene uno o más, el menú muestra siempre `Piso`,
cada receptor en el orden de reacción y `Cancelar`; por tanto, incluso un único
objetivo nunca se selecciona automáticamente. Cancelar abandona el flujo completo
sin construir un contexto.

La integración proporciona un ID nuevo únicamente para separar una pila de varias
unidades y comprueba que no exista en el inventario ni en el suelo. La vista sigue
definida por la escena, los iconos y el `Theme` existentes. Inventario definitivo,
trayectoria, previsualización y animación quedan fuera de 9.2.

### Trayectoria y primera colisión — incremento 9.3

`ValidadorEspacialTablero.resolver_trayectoria_lanzamiento()` recorre la línea
discreta de `GeometriaGrid` y es la única fuente para la previsualización y la
resolución de `LANZAR_ITEM`. Mantiene separados cuatro datos: si se alcanzó la
celda solicitada, si hubo colisión, la celda que recibe `IMPACTAR` y la celda donde
queda una unidad superviviente.

Una celda bloquea proyectiles si su altura es 2 o superior o si alguno de sus
interactuables declara `bloquea_proyectiles_interactuable()`. La puerta devuelve
`true` cerrada y `false` abierta. Los efectos de superficie no bloquean por defecto:
humo, agua o lava sólo cambiarán esta regla si una mecánica concreta lo requiere.

La primera celda bloqueante recibe las reacciones `IMPACTAR`. Si el resultado es
`DEJAR_EN_CELDA`, la unidad se registra en la última celda libre anterior; si no hay
obstáculo, impacto y caída coinciden con el destino solicitado. Un objetivo directo
seleccionado sólo conserva prioridad cuando esa misma celda es la alcanzada; una
colisión anterior lo descarta. `CONSUMIR` y `CONSERVAR_EN_INVENTARIO` mantienen sus
contratos de 9.1.

Las reacciones de impacto distinguen dos admisiones. `reacciona_automaticamente()`
describe consecuencias de celda que ocurren incluso al elegir el piso, como una
trampa oculta. `admite_reaccion_dirigida()` describe receptores que sólo participan
si fueron elegidos, como una palanca. La UI puede descubrir ambos, pero el consultor
sólo incorpora una reacción dirigida a la resolución cuando ese receptor es el
`objetivo_impacto`. La palanca reutiliza el mismo cambio de estado de su interacción
manual y una piedra que sobreviva cae normalmente.

La escena provisional dibuja un `Line2D` recto entre los centros isométricos del
actor y la celda real devuelta por ese cálculo. Verde indica llegada despejada;
naranja indica colisión o truncamiento por alcance. El selector existente marca la
celda real. Esta línea no representa todavía tiempo de vuelo ni anima un proyectil.

