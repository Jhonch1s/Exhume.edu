# Templo de las Trampas

El Templo de las Trampas es una zona del Templo de los Lamentos. El templo
antiguo y su relación con los muertos constituyen la dirección narrativa
acordada; Maese Klink instaló después su taller en parte de las ruinas. El
origen de los lamentos queda abierto: el viento es una posibilidad, no una
explicación confirmada.

## Primer incremento jugable

- La placa 001 abre el [pasaje de paredes móviles](PAREDES_MOVILES.md): cuatro
  bloques se desplazan dos casillas hacia +X y liberan el acceso al túnel.

- `tunel_dialogo` abre el comentario «Esto no pinta nada bien...» y aconseja
  avanzar con cuidado. Su umbral Y tiene longitud 2 para caber en el corredor.
  Los diálogos de triggers muestran la ilustración del protagonista según clase.
  `tests/zonas/prueba_dialogo_tunel.gd` comprueba el texto y los tres retratos.

- Dos triggers de diálogo, únicos por partida, sugieren los lamentos y la
  diferencia entre la piedra antigua y los mecanismos posteriores. Su fuente es
  `dialogues/templo/lamentos.dialogue`. Tras editarla, regenerar el recurso usado
  por la escena ejecutando `tests/zonas/compilar_dialogo_templo.gd` con Godot.
- Dos Sirvientes de Eek reutilizan el prefab existente en la sala oriental.
  Cada uno otorga 25 XP según su definición compartida; su balance debe probarse.
- `zona_aranas` sugiere buscar una pista entre las telarañas una vez por partida.
  `cadaver` comenta el derrumbe y se repite al volver a entrar. Ambos muestran
  la ilustración del protagonista.
- Se conservan el trazado, las trampas, las estatuas y Trompo existentes.

## Derrumbe y vuelta a Prisión

El umbral `casi_trampa_fatal` se activa una vez al pasar de `(2,-51)` a
`(2,-52)`. La pieza de roca 4×8 cae con vibración en ambos ejes y se asienta
en la posición del tile original `(-1,-46)`. Las cinco casillas transitables
de su huella quedan bloqueadas detrás del personaje. Al cargar, se restaura
el estado de las rocas sin repetir el efecto. Los guardados anteriores a
este mecanismo conservan la niebla explorada y empiezan con el paso abierto.

`vuelta_prision` está junto a la entrada del templo y lleva a
`entrada_prision`, en `(79,-26)`. El spawn queda fuera del umbral de ida.
Una vez caídas las rocas, la ruta hacia la entrada queda cortada y el tramo
posterior todavía necesita su propia salida.

## Placas y provisiones

| Placa | Conexión |
|---|---|
| `trampa_superficie_001` | Cuatro paredes móviles. |
| `trampa_superficie_002` | `estatua_templo_001`. |
| `trampa_superficie_003` | Señuelo: se hunde sin superficie ni receptor. |
| `trampa_superficie_004` | `estatua_templo_003`. |

La estatua `estatua_templo_002` permanece como parte del engaño. El señuelo usa
`placa_senuelo`; una placa neutra vacía conservaba por defecto veneno, por lo que
no basta con cambiar su fila visual.

| Cofre | Contenido inicial |
|---|---|
| `cofre_pequeno_001` | 1 poción, 1 bomba de humo, 2 antorchas. |
| `cofre_pequeno_002` | 3 piedras, 1 poción. |
| `cofre_pequeno_003` | 3 antorchas. |
| `cofre_pequeno_004` | 3 raciones de viaje. |
| `cofre_pequeno_005` | 2 pociones, 2 bombas de humo. |
| `cofre_pequeno_006` | Amuleto del Pulso Firme y Ganzúa mecánica de Klink. |

La nota examinable `templo_nota_tras_estatua_001`, junto a la gran estatua, sugiere
que la piedra detrás del que no tiene rostro suena hueca. Trompo conserva además
su mención a una pared secreta. La nota reutiliza la ilustración de pergamino.

El contenedor `Interactuables/Cofres` debe ser un Node2D de organización sin
script de cofre: ese script en el contenedor bloqueaba la validación y dejaba sin
registrar todas las interacciones. Cada cofre/placa/estatua debe usar su propio
sprite y máscaras, evitando rutas heredadas a otra instancia al duplicar.

## Probar

Abrir `scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn` y ejecutar F6.
Recorrer el corredor de entrada y continuar hacia el taller para comprobar los
dos diálogos; explorar la sala oriental para encontrar las arañas. Los triggers
no vuelven a mostrarse en una partida donde ya se hayan consumido.

La prueba automática `tests/zonas/prueba_contenido_templo.gd` carga la escena,
valida interactuables y triggers, comprueba el registro por ID y los visuales
propios, activa las placas 002/004 contra sus estatuas y comprueba suelo y
obstáculos de las casillas de las arañas.
`tests/zonas/prueba_tramo_final_templo.gd` verifica placa, derrumbe,
persistencia y vuelta a Prisión desde el arranque de F6.
Ejecutarla con `tests/ejecutar_con_autoloads.gd` y la ruta de la prueba como
argumento. No sustituye una prueba visual ni de combate.

## Objetos del cofre 006

`cofre_pequeno_006` contiene un Amuleto del Pulso Firme y una Ganzúa mecánica de
Klink. El amuleto ocupa el cuello y concede ventaja en todas las pruebas de
Destreza, incluidas las esquivas que usan DES, mientras esté equipado. No aumenta
el atributo; las reglas existentes cancelan ventaja y desventaja.

La ganzúa usa el patrón `reja_metal`, compatible con la reja de la celda de
Roffa. Se consume únicamente al desbloquear con éxito; un patrón incompatible
conserva el objeto. Abrir la puerta sigue siendo una acción posterior. No es una
llave universal. `DefinicionLlave.consumir_al_usar` permite este comportamiento
sin consumir las llaves anteriores.

Visuales generados con la herramienta integrada `image_gen`: originales con
transparencia en `assets/items/amuleto_klink/` y `assets/items/ganzua_mecanica/`.
Prompts exactos en `assets/items/prompts_items_templo.json`. Las versiones son
icono 24×24, suelo 64×32 e ilustración 100×100. Para regenerar los tamaños desde
los originales, ejecutar `tools/preparar_visuales_items_templo.gd` con Godot.
`tests/interacciones/prueba_items_templo.gd` comprueba tamaños, equipamiento,
ventaja, persistencia del equipo, consumo de la ganzúa y contenido del cofre.

Los inventarios ya guardados conservan su contenido anterior. Probar el botín
en una partida que todavía no haya guardado el estado del templo.

## Pendiente

Quedan pendientes la expansión física, la salida después del derrumbe y el
encuentro con el élite. Hay que calcular la XP alcanzable desde Prisión antes
de fijar encuentros y garantizar la progresión a nivel 2 antes del élite.

## Cierre de sesión del 05-11-2026

El templo usa los TileSets de decoración de Prisión, con conversión de los IDs
de las nueve celdas caminables pintadas para conservar su aspecto. El tile de
suelo del atlas `(1,1)` se configuró como caminable y familia `terreno` en el
TileSet compartido, con coste normal, altura cero y sin bloqueo de visión.

El examen ilustrado y el menú contextual usan marco rocoso oscuro y texto claro.
Se corrigieron los márgenes de escalado para mantener los cuatro bordes; el
examen reserva 45 % del ancho a la imagen y 55 % al texto.

Duraciones vigentes: [Superficies](SUPERFICIES.md). Coordinación de sacudidas y
laboratorio: [Gestor de VFX](VFX.md). Las cuatro paredes generan un único temblor
y un golpe de encaje, sin multiplicar la intensidad por cuatro.

Pasaron las pruebas específicas de contenido, placas/estatuas, objetos, paredes,
diálogo con retratos de tres clases, superficies y gestor VFX. También pasó la
regresión de llaves normales, el examen ilustrado y el menú contextual. Forja:
119 comprobaciones JS y 258 en Godot. Esto no acredita balance ni revisión visual
completa. Hay avisos de recursos/ObjectDB/RID al cerrar diversas pruebas.

Pendientes técnicos conocidos: la suite general de triggers presenta cinco
fallos ligados a guardado/carga/consumos; CámaraLibre presenta dos fallos de
guardado/carga reproducidos con VFX desconectado. El generador de catálogo de
Forja requiere `sharp`, ausente en el entorno; el catálogo existente se actualizó
y verificó directamente. Las raciones de inventario no incrementan el contador
separado usado para descansar en campamento; revisar esa integración.

El usuario edita el mapa simultáneamente. Antes de convertir tiles recién
colocados, pedir que guarde la escena si aún no figuran en el archivo. No usar
importación global del editor sobre el proyecto activo ni inspección del
escritorio sin consultarlo. Los cambios de esta sesión están en el directorio
de trabajo, sin commit; conservar las demás modificaciones locales.
