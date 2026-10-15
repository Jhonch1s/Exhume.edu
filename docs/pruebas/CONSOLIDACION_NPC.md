# Consolidación de NPC — 15-10-2026

La revisión crítica de `npc-combat` incluyó sus commits frente a la base común
`62cea88`, los cambios locales y los recursos nuevos. Esta consolidación corrige
los defectos detectados y conserva las reglas jugables acordadas para integrar
la rama en `main`, sin introducir acciones de apoyo, huida o humo automático.

## Guardado y restauración

- Los términos de daño de quemado/veneno se validan como números finitos y
  exactamente enteros y se reconstruyen como `int` al leer JSON. El motor de dados
  mantiene su contrato estricto. Se cargan archivos anteriores sin cambiar versión.
- Cargar exploración descarta el gestor del encuentro anterior antes de limpiar
  su presentación: sus bandos no borran memoria ni recursos recién restaurados.
  Una carga rechazada conserva el encuentro y el estado anteriores.
- Ficha, cofres y botín NPC usan las operaciones de persistencia de `Inventario`.
  La validación compartida conserva las rutas absolutas que admitía Ficha, además
  de `res://`, y sigue comprobando existencia, tipo, ID, cantidad y duplicados.
- La prueba de archivo espera la preparación de ficha/HUD, usa la variante sin
  render y crea su propio cofre, item de suelo y superficie. Comprueba restauración
  completa y rechazo sin estado parcial; no depende de que Zona1 contenga un cofre.

## Decisión y movimiento

`DecisorCombateNPC.elegir()` recibe sólo la lista de oponentes visibles filtrada
por el escenario. Selecciona objetivo y conserva la ruta evaluada en esa misma
decisión; sin visibles persigue la coordenada recordada. No guarda caminos entre
decisiones ni consulta los PV o la posición actual del oponente oculto.

Los desempates se comprueban con un objetivo esperado por distancia euclídea y
por ID, invirtiendo la lista visible. Mover y cambiar PV de enemigos ocultos no
modifica el plan hacia el recuerdo. Los impedimentos de estados se resuelven
antes de buscar caminos de ataque.

Se retiró el callback de espera de ruta, que no tenía llamadas útiles. Sin camino
se cierra el avance y se reintenta en el próximo ciclo, dejando disponible la
carga en reposo. Se conservan reservas, recálculo durante recorridos, paso en curso
al cancelar y continuidad de patrullas.

## Trabajo repetido

| Caso dirigido | Antes | Después |
|---|---:|---:|
| Consultas de ruta, un oponente visible distante | 8 | 4 |
| Consultas de ataque, atrapado/caído o sin movimiento | Hasta 4 por candidato | 0 |
| Recálculos completos de FOV al trasladar un NPC no opaco | 2 | 0 |

FOV conserva la opacidad efectiva por casilla para distinguir cambios visuales
de ocupación. Puertas y humo opaco actualizan inmediatamente los rayos; fuentes
de luz conservan su actualización. Registro y retirada de bloqueadores también
invalidan la visión. V usa revisión de visión, posición, PV, radio, visibilidad
y color del NPC; reservar una casilla no reconstruye su campo.
Registro y retirada consideran la huella completa del bloqueador y recalculan
una sola vez, incluso si otra entidad mantiene opaca la casilla de origen.

Son conteos de operaciones, no mediciones de FPS ni de presupuesto de cuadro.
La separación futura entre percepción del jugador, luz y niebla sigue pendiente.

## Regresiones específicas

- `prueba_facciones_npc.tscn`: 287 comprobaciones, incluidos carga desde ambos
  bandos, actitud fija/dinámica, recuerdo, recursos y rechazo sin mutación.
- `prueba_xp_indirecta_npc.tscn`: 231 comprobaciones, incluidos fuego/humo venenoso
  reales en ficha/NPC, archivo JSON y ejecución del tick restaurado con XP única.
- `prueba_tactica_npc.tscn`: 68 comprobaciones, incluidos desempates explícitos,
  independencia de ocultos y conteo de rutas.
- `prueba_persistencia_ficha_conocimiento.gd`: archivo/copia JSON, compatibilidad
  de rutas y rechazo de términos fraccionarios, no finitos o de tipos incorrectos.
- `prueba_persistencia_partida_archivo.gd`: nueve comprobaciones de integración.
- `prueba_humo_bloquea_vision.gd`: humo superpuesto, traslado/muerte NPC y
  registro, apertura, cierre y retirada de puertas, incluidas huellas solapadas.

Las pruebas SceneTree se ejecutan mediante `tests/ejecutar_con_autoloads.gd`;
el lanzador registra autoloads antes de cargar el script y llama `_initialize`
cuando la prueba usa ese callback. La prueba de capacidad de inventario es ahora
SceneTree: no requiere ejecutar un EditorScript.

## Batería general y límites

La preparación de la integración retira logs, extracciones de PDF de `tmp`,
copias de recarga de LimboAI y el diagnóstico puntual de anclajes de luz.
`.gitignore` excluye nuevas salidas temporales. Se conservan las bibliotecas
originales, las capturas de dados documentadas y las escenas de regresión.

Se ejecutaron 90 pruebas distintas del proyecto en Godot 4.7 sin ventana. Tras
corregir los fallos y repetir las afectadas, las 90 terminaron con salida 0,
sin errores de script y con su marcador final. Se revisaron también los logs:
no quedan errores de ejecución aparte de los avisos de recursos al cerrar.

Las pruebas de integración comparten `tests/soporte/escenario_sin_render.gd`,
esperan la preparación de ficha/HUD y controlan sus turnos. El menú contextual
usa inventario explícito, un recorrido corto despejado y comprueba que una
trampa oculta recibe el impacto al piso sin aparecer como objetivo seleccionable.
Las pruebas de creación, transición y dados respetan el diccionario tipado,
esperan el fin real de la transición y pulsan los dados, incluido doble clic.

El cofre tiene un mínimo de fondo de 300 × 300: evita el desborde del botón
Cerrar observado al forzar 200 px de alto. Su prueba verifica el límite, el
centrado, las casillas cuadradas, el detalle del item y el arrastre.

Persisten advertencias de UID de palanca (resuelto por ruta) y de
ObjectDB/recursos/RID vivos al cerrar el motor. Los resultados no demuestran ni
descartan una fuga durante juego. Quedan fuera la medición de FPS/tiempos de
cuadro y la revisión visual del HUD, V y el catálogo de consecuencias.

La [guía de consecuencias](../contenido/CONSECUENCIAS_DIALOGO_NPC.md) sigue siendo
la referencia permanente de autoría. La revisión jugable de su catálogo continúa
pendiente; el usuario ya confirmó el diálogo base y la recepción de XP, sin
detallar todas las fuentes o los casos de carga. Las cifras de cortes anteriores
en roadmap y documentos de contenido conservan su carácter histórico.
