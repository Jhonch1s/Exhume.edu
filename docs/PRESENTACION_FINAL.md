# Exhume — presentación final

**Duración objetivo:** 13 minutos, incluida una demostración de 2 minutos. Después, 10 minutos para preguntas.  
**Integrantes:** [completar nombres] · **Curso:** [completar]

Este es un primer guion basado en el repositorio. Los textos entre corchetes son datos que el equipo debe completar o confirmar. Las frases de cada diapositiva son para mostrar; el texto de «Qué decir» sirve de apoyo para ensayar, no hace falta leerlo literalmente.

## 1. Presentación — 0:40

**En pantalla**

> **EXHUME**  
> Exploración, decisiones y combate táctico  
> [Integrantes]

**Visual:** captura del juego que muestre el personaje y el escenario.

**Qué decir:** «Somos [nombres] y les presentamos Exhume. Queríamos construir una experiencia de exploración con elementos de juego de rol: recorrer un lugar desconocido, interactuar con lo que encontramos y resolver encuentros mediante decisiones tácticas. Vamos a contar cómo lo desarrollamos y a mostrarlo funcionando».

## 2. La idea y la experiencia — 1:10

**En pantalla**

- Explorar zonas y descubrir sus peligros.
- Interactuar con objetos y personajes.
- Tomar decisiones en encuentros por turnos.
- Administrar recursos y progresar.

**Visual:** captura de la prisión y, si cabe, una imagen pequeña de la interfaz o del templo.

**Qué decir:** «La propuesta une exploración y decisiones de rol. El jugador se mueve por un escenario dividido en casillas, encuentra objetos y personajes, y debe prestar atención al entorno. Hay situaciones de combate, pero también diálogos, trampas y mecanismos. La intención es que los sistemas se relacionen y que explorar tenga consecuencias».

## 3. Referentes y decisiones de diseño — 1:10

**En pantalla**

- Referentes del equipo: [agregar juegos o experiencias realmente estudiados].
- De ellos tomamos: [dos ideas concretas].
- Nuestra adaptación: exploración en casillas + interacciones + turnos.

**Qué decir:** «Como referentes observamos [referente 1] y [referente 2]. Nos interesaron [mecánicas o soluciones concretas] y las adaptamos al alcance de nuestro proyecto de esta forma: [ejemplo]. Una decisión importante fue [decisión], porque [motivo real del equipo]».

**Para completar:** confirmar los referentes y explicar qué se observó de cada uno. La documentación menciona Baldur’s Gate como inspiración específica para el campamento; eso no alcanza para afirmar que todo el juego se inspiró en él.

## 4. Tecnología y arte — 1:20

**En pantalla**

- **Godot 4 / GDScript:** escenas, nodos y lógica del juego.
- **Tablero 2D:** movimiento y reglas por casillas.
- **Personajes:** modelos 3D renderizados como imágenes para la ficha 2D.
- **Herramientas:** Dialogue Manager para diálogos y LimboAI para decisiones de NPC.

**Visual:** una captura del editor y otra del juego, o modelo/personaje junto a su representación en el tablero.

**Qué decir:** «Usamos Godot y organizamos el juego en escenas, nodos y scripts. Una decisión interesante fue separar el tablero lógico en 2D de la presentación: el proyecto renderiza modelos 3D en vistas y utiliza esas imágenes para representar la ficha. Para los diálogos integramos Dialogue Manager y para decisiones de personajes no jugadores usamos LimboAI. Elegimos Godot porque [explicar el motivo real]. El arte lo resolvimos mediante [explicar qué creó el equipo, qué recursos externos usó y con qué herramientas]».

**Para completar:** no atribuir al equipo arte o herramientas sin verificar sus autores y licencias. La conexión visual de todas las clases figura como pendiente en documentación anterior; comprobar el estado actual antes de mostrarla como terminada.

## 5. Cómo evolucionó el proyecto — 1:20

**En pantalla**

1. **Julio:** primeras escenas, mapa y movimiento.
2. **Agosto–septiembre:** [completar hitos confirmados] y desarrollo de sistemas.
3. **Octubre:** NPC, combate, inventario, niveles, interfaces y sonido.
4. **Noviembre:** ajustes, contenido y demo v0.1.

**Visual:** línea de tiempo con 3 o 4 capturas de distintas etapas, si las tienen.

**Qué decir:** «Empezamos con las bases del mapa y el movimiento. Después fuimos incorporando sistemas y contenido hasta conectar personajes, combate, inventario y escenarios. Finalmente trabajamos en ajustes y una demo. El proceso no fue lineal: [contar un problema real, cómo se resolvió y qué cambió en el juego]».

**Nota:** las fechas son aproximadas a partir del historial Git; verificar los hitos de agosto y septiembre con el equipo antes de exponer.

## 6. Equipo y forma de trabajo — 0:50

**En pantalla**

- [Nombre]: [responsabilidades y aporte concreto].
- [Nombre]: [responsabilidades y aporte concreto].
- [Nombre]: [responsabilidades y aporte concreto].
- Coordinación: [cómo organizaron tareas e integraron cambios].

**Qué decir:** «Nos distribuimos las tareas de esta manera: [explicación]. Para integrar el trabajo usamos [herramienta o dinámica real]. También colaboramos en [ejemplo]». Adaptar la cantidad de líneas al equipo.

## 7. Conocimiento aplicado: del tablero a las interacciones — 1:30

**En pantalla**

> Acción del jugador → validación → resultado → cambios en el mundo

- Coordenadas, movimiento y alcance en una cuadrícula.
- Reglas para objetos, trampas y mecanismos.
- Separación entre lógica del juego y presentación.

**Visual:** diagrama de cuatro cajas o captura de una placa y la pared que abre.

**Qué decir:** «Una parte importante del aprendizaje fue transformar reglas en sistemas. El tablero representa posiciones y permite comprobar distancias y movimiento. Cuando el jugador intenta una acción, se construye un contexto, se valida y se produce un resultado que puede modificar el estado del mundo. En el templo, por ejemplo, una placa está conectada con paredes móviles que liberan un paso. Esta separación permite sumar contenido sin colocar todas las reglas en un único lugar».

## 8. Conocimiento aplicado: NPC y estado — 1:10

**En pantalla**

- Percepción: línea de visión y detección.
- IA: patrullar, buscar, acercarse y atacar.
- Diálogos y cambios que pueden persistir en la partida.
- Pruebas para verificar reglas y regresiones.

**Qué decir:** «Los NPC necesitan información para actuar. Los guardias de la prisión, por ejemplo, patrullan y detectan al jugador según su alcance y línea visual; su árbol de comportamiento decide cómo reaccionar. También trabajamos con diálogos y con el guardado de información de la partida. Como los sistemas interactúan, usamos pruebas para comprobar casos concretos y detectar errores al hacer cambios».

## 9. Demostración en vivo — 2:00

**En pantalla:** cambiar al juego. Una persona juega y otra explica.

**Recorrido propuesto, ensayar y ajustar a la versión que se va a presentar:**

1. **0:00–0:25:** cargar una partida preparada en prisión; mover al personaje y señalar la visibilidad.
2. **0:25–0:55:** examinar un objeto o conversar con Roffa; explicar que el entorno y los personajes ofrecen información.
3. **0:55–1:25:** mostrar un encuentro con un guardia y una acción de combate por turnos.
4. **1:25–1:55:** si hay una partida preparada en el templo, cargarla y activar la placa de paredes móviles. Si el cambio demora demasiado, mostrar una captura o video corto preparado.
5. **1:55–2:00:** volver a la presentación.

**Preparación:** probar el recorrido completo en el equipo y la versión finales; guardar partidas cerca de cada situación, desactivar notificaciones y comprobar sonido, resolución y controles. Grabar un video de respaldo del mismo recorrido. Si alguno de los pasos no funciona de forma confiable, sustituirlo por otro que sí se haya ensayado.

## 10. Conclusiones — 1:50

**En pantalla**

- Convertimos una idea en una experiencia jugable.
- Aprendimos a integrar reglas, arte, interfaz y contenido.
- Lo más desafiante: [problema real del equipo].
- Próximos pasos: [2 mejoras concretas y realistas].

**Qué decir:** «Este proyecto nos permitió pasar de una idea a un juego con varios sistemas conectados. Aprendimos [aprendizaje técnico] y [aprendizaje de trabajo en equipo]. Uno de los mayores desafíos fue [problema] y lo abordamos [solución]. Si continuáramos, nos gustaría [mejora 1] y [mejora 2]. Muchas gracias; quedamos a disposición para las preguntas».

**Total:** 13:00. Hay hasta 2 minutos de margen sobre el límite superior de 15 minutos; no consumir los 10 minutos reservados para preguntas.

## Preparación para preguntas

- **¿Por qué eligieron Godot?** Responder con los motivos reales del equipo y relacionarlos con escenas, herramientas y alcance; no afirmar una comparación que no hayan hecho.
- **¿Cómo funciona la IA?** Explicar percepción y árbol de comportamiento con el ejemplo de los guardias; no presentar huida automática como terminada: figura aplazada en la documentación.
- **¿Cómo se conecta una placa con una pared?** Describir la activación y la conexión mediante identificadores; el estado de la apertura puede restaurarse al cargar.
- **¿Qué fue lo más difícil?** Preparar un caso concreto: problema, diagnóstico, solución y aprendizaje.
- **¿Qué quedó pendiente?** Mencionar limitaciones verificadas en la versión presentada y qué harían después; evitar prometer funciones no comprobadas.
- **¿El arte y el sonido son propios?** Preparar una lista precisa de autores, recursos externos y licencias.

## Fuentes del proyecto para terminar el material

- `project.godot`: configuración, motor y plugins.
- `docs/arquitectura/ARQUITECTURA.md`: flujo de acciones y tablero.
- `docs/contenido/PERSONAJES.md`: relación entre modelos 3D y ficha 2D; documento fechado, verificar cambios posteriores.
- `docs/PRISION_CONTENIDO.md` y `docs/contenido/TEMPLO_DE_LAS_TRAMPAS.md`: ejemplos para la demostración.
- `docs/pruebas/PRUEBAS.md`: ejemplos de pruebas y límites de verificación.
- Historial Git: fechas aproximadas de evolución, que deben contrastarse con los recuerdos del equipo.
