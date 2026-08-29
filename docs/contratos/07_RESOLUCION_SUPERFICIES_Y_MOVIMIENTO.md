### Resolución y agregación de reacciones

`ResolverReaccionesCelda` recibe la lista ya ordenada, crea un `ContextoAccion`
automático dirigido a cada receptor y lo entrega a `GestorAcciones`. No abre menú
ni presenta resultados. Un mismo objeto receptor se procesa como máximo una vez
por evento, aunque aparezca repetido en la lista.

`ResultadoReacciones` conserva los resultados individuales y agrega, en orden,
mensajes, solicitudes, efectos confirmados y cambios de estado. Al finalizar el
evento deduplica las solicitudes antes de exponerlas. Los costes confirmados con la
misma clave se suman; `interrumpe_movimiento` y `terminal` se combinan mediante OR.
Un resultado terminal detiene receptores posteriores, pero conserva todo lo ya
confirmado.

`EscenarioBase` usa este flujo en los callbacks seguros de cada paso: consulta el
origen para `SALIR`, el destino para `ENTRAR` y solicita a `Ficha` la interrupción
agregada. La decisión se aplica después del paso actual y antes del siguiente
tween. Las reacciones automáticas atraviesan así el mismo gestor lógico que las
acciones voluntarias, sin construir opciones ni usar el menú contextual.

### Efectos de superficie colocados

Las zonas organizan estas entidades bajo un nodo `EfectosSuperficie`, separado de
`Interactuables`. Cada instancia pertenece al grupo Godot
`&"efectos_superficie"`, declara un ID estable y se registra por coordenada en
`Celda.efectos_superficie`. El grupo facilita el descubrimiento al cargar la zona;
la categoría mecánica procede del registro en la celda.

La primera instancia es `HumoVeneno`. Su representación es un `Sprite2D` al nivel
visual de la celda y su reacción automática a `ENTRAR` solicita el estado veneno e
interrumpe. No usa colisiones, `Area2D`, señales físicas ni menú contextual. El
mensaje y cambio se registran únicamente después de aplicar el estado deduplicado.

`Fuego` sigue el mismo contrato de superficie sin depender de una trampa concreta.
Al `ENTRAR` solicita `quemado`, añade uno al coste bajo la familia `&"fuego"` y
declara siete turnos de duración. Fuego y humo pueden coexistir y aplicar sus dos
estados; varias instancias de una misma familia producen una sola solicitud lógica
por objetivo y evento.

Desde la Fase 16, quemado conserva tres ticks de `1d2` y no aplica daño al crear el
estado. Una futura explosión de fuego resolverá por separado su daño inicial y su
salvación de Destreza; no se incorpora esa regla mientras no exista ese contenido.

`CapaPinchos` conserva el suelo base y registra en cada celda una reacción de
terreno al `ENTRAR`. Resuelve automáticamente `1d3`, aplica el total como daño
instantáneo mediante el aplicador común y adjunta la tirada como `SOLO_LOG`. No
ofrece salvación ni deja estados pendientes.

`CapaTelaraña` registra superficies permanentes con el mismo coste adicional `1`
del humo. Al entrar se realiza una salvación automática `SOLO_LOG` de Destreza: el
éxito permite continuar y el fallo interrumpe el recorrido y aplica `enredado`.
Este estado impide calcular o ejecutar rutas, pero no bloquea otras acciones.

Mientras está enredado, un clic derecho intenta `Destrabarse`: consume una acción
principal incluso al fallar y presenta una nueva prueba de Destreza en primer
plano. El éxito retira el estado; el fallo lo conserva. `enredado` no expira al
avanzar turnos y se incluye en el snapshot normal de estados de la ficha.

`CapaLodo` realiza una salvación automática `SOLO_LOG` de Destreza al entrar. El
éxito permite continuar; el fallo interrumpe el recorrido, aplica `caido` y agota
movimiento, acción principal, acción adicional y reacción restantes. El escenario
cierra entonces el turno por el flujo ordinario, incluyendo ticks pendientes, y
`caido` se retira antes de reponer los recursos del turno siguiente. El lodo no
añade coste de movimiento ni deja un estado duradero.

`CapaHielo` reutiliza exactamente la misma reacción resbaladiza que el lodo. Sólo
cambia su familia estable a `&"hielo"` para que futuras combinaciones puedan
distinguirlos sin duplicar salvaciones, estados ni cierre de turno.

`CapaFuego` reutiliza `Fuego` como una superficie permanente dibujada por el
TileMap. Entrar aplica `quemado` con tres ticks de `1d2`, sin salvación inicial, y
añade uno al coste de movimiento. Cada celda proyecta luz con radio dos y una celda
de penumbra; por ello no usa máscaras fog propias. Estos receptores estáticos no
entran en la duración ni en el snapshot de superficies dinámicas.

### Coste de un paso y peso de ruta

`Celda.calcular_coste_movimiento(actor)` compone el coste entero del paso como
`1 + adicional del terreno + adicionales lógicos de superficies`. El adicional del
terreno se carga desde el dato de tile `coste_movimiento_adicional`. Una
superficie puede aportar un entero no negativo mediante
`obtener_coste_movimiento_adicional(actor)`; no necesita implementar este método
si no modifica el coste. `HumoVeneno` aporta inicialmente `1`, por lo que entrar
en su celda cuesta `2`.

Una superficie puede declarar `obtener_familia_superficie() -> StringName`. La
celda conserva el mayor aporte de cada familia y suma familias distintas. Las
superficies sin familia se consideran contribuciones independientes para mantener
compatibilidad. Dos nubes `&"humo_veneno"` superpuestas cuestan una sola unidad
adicional; humo y fuego sí pueden sumar costes diferentes.

`TableroGrid.retirar_efecto_superficie()` elimina únicamente la instancia indicada
del registro global y de su celda y emite `efecto_superficie_retirado`. No libera el
nodo: la entidad propietaria conserva el control de su representación. Si queda otra
instancia de la misma familia, su contribución mecánica continúa activa.

### Bloqueo visual de superficies

`Celda.bloquea_vision_efectiva()` combina con OR el bloqueo propio del terreno y
el declarado por cada superficie activa mediante `bloquea_vision_superficie()`.
`FOVManager` y `ValidadorEspacialTablero` consultan esta única fuente. El FOV se
recalcula al registrar o retirar una superficie; por ello, dos bloqueos
superpuestos permanecen activos hasta retirar el último.

`Humo` bloquea visión y declara una duración de superficie de diez turnos. El valor
configurado permanece disponible desde `obtener_duracion_superficie()` y cada
instancia conserva por separado sus rondas restantes. `HumoVeneno` aplica veneno y
coste de movimiento, pero no bloquea visión: toxicidad y opacidad son propiedades
independientes.

La ficha calcula y valida ese total antes de reservar el destino o iniciar el
tween. Si no dispone de energía suficiente, permanece en el origen y no reserva
ni consume. El coste se descuenta una sola vez después de confirmar la ocupación
del destino y antes de resolver `ENTRAR`. Un coste mayor que `1` duplica la
duración del tween del paso, equivalente a caminar a la mitad de velocidad; no se
interrumpe nunca una animación entre celdas.

`Celda.calcular_peso_ruta(actor)` suma al coste de movimiento una
`penalizacion_peligro_ruta` no negativa. Esta penalización orienta el pathfinding
sin cobrar energía: la lava conserva un peso total alto mientras su daño se aplica
por separado como reacción de terreno. Veneno, quemado y otros estados tampoco se
modelan como costes de desplazamiento.
