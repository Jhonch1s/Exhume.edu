# Pruebas

Las pruebas headless bajo `tests/` protegen contratos, atomicidad y verticales reales.

## Capas

- Contratos puros: contexto, opciones, resultados, definiciones y agregadores.
- Servicios: validación espacial, costes, examen, efectos, turnos y persistencia.
- Contenido: puertas, palancas, trampas, superficies e items.
- Integración: menú contextual, movimiento, lanzamiento y escena principal.
- Herramientas: prevalidación de zona, inspección de celdas y registro filtrable.

Una prueba se elimina cuando su comportamiento queda cubierto por otra más directa,
no solamente porque pertenezca a una fase antigua.

`tests/interacciones/prueba_antorchas_hud.tscn` cubre inventario y consumo de
antorchas, engarces, retratos, tooltips de quemado y veneno, luz inicial,
propiedades de `DefinicionAntorcha`, atenuación y apagado al agotarse. También
comprueba que la llave y la bomba de humo de prueba no aparezcan al iniciar el
escenario. `prueba_integracion_menu_contextual.gd` crea esos objetos dentro de
la propia prueba para verificar sus interacciones sin poblar el juego.

`tests/interacciones/prueba_estado_npc_persistente.tscn` comprueba el estado
inicial de Trompo, su actitud fija, la restauración de PV cero, nivel y atributo,
la memoria narrativa, el rechazo de datos inválidos y la lectura de snapshots v1.
También comprueba daño, curación, señales y aplicación de daño a un NPC mediante
`AplicadorEfectos`. Un enemigo de prueba verifica la opción `Atacar`, alcance,
tirada de FUE, daño por acierto, coste aun al fallar y ausencia de la opción al
quedar derrotado.

`tests/interacciones/escena_npc_hostil.tscn` es una escena de revisión manual.
Genera un objetivo hostil de 2 PV junto al inicio de `Zona1`, separado del
contenido permanente. Clic izquierdo muestra acciones, clic derecho mueve,
F7 guarda en `user://prueba_npc_hostil.json` y F8 carga de forma explícita.
El usuario confirmó en Godot el ataque hasta 0 PV, el paso sobre la casilla del
NPC derrotado, `Examinar`, la desaparición de `Atacar` y la restauración de ese
estado con F7/F8. El objetivo de prueba no tiene diálogo, así que la ausencia de
`Hablar` a 0 PV sigue sin comprobación visual. La carga headless registró el
objetivo, aunque su renderer dummy no pudo capturar los retratos 3D de la ficha.

La misma escena permite revisar el primer modo de combate: `Atacar` inicia el
encuentro, arriba aparece el orden de turnos, `Pasar turno` muestra el pase del
NPC y comienza otra ronda, y F7/F8 conservan ronda, actor activo y recursos del
jugador. Al llegar el objetivo a 0 PV desaparece el panel y vuelve exploración.
El usuario informó que el primer flujo de combate funcionó en Godot. Queda
pendiente una comprobación detallada de F7/F8 durante un combate activo y la
revisión visual del HUD superior se hará más adelante.

Segundo corte pendiente de revisión manual: al pasar turno estando adyacente,
el NPC debe intentar una tirada de FUE, registrar acierto o fallo y gastar su
acción principal. Si está lejos, debe pasar sin atacar ni acercarse. Guardar y
cargar con F7/F8 durante el turno del NPC debe conservar su recurso restante
para evitar repetir un ataque ya resuelto. Si el jugador llega a 0 PV, el
encuentro termina y no debe permitirle seguir actuando.

## Estado de las comprobaciones de cofres — 14 de septiembre de 2026

- El usuario ejecutó la prueba de capacidad y la prueba visual de casilla y confirmó
  sus resultados. La generación de contenido fue comprobada manualmente en juego;
  los items sin icono existen aunque su imagen no aparezca.
- `prueba_layout_panel_cofre.gd` verificó cuatro tamaños con casillas estáticas.
  Después el panel pasó a generar casillas en `mostrar()`. La prueba debe adaptarse
  para abrir un cofre con contenido y exigir el número esperado de casillas: tal
  como está, su bucle puede pasar sin comprobar ninguna casilla.
- La prueba propuesta de panel dinámico no fue ejecutada por el usuario. No hay
  cierre de regresión de apertura, recogida total ni modal.
- `prueba_persistencia_cofre.gd` verifica apertura, pilas restantes y rechazo de
  contenido inválido. La prueba completa de archivo incluye ahora el cofre real.
- Las rutas corregidas de las estatuas 11 y 12 se comprobaron mediante una prueba
  temporal en Godot: visible, explorado y oculto, sin modificar la estatua 10.
  Esa prueba temporal no forma parte de la suite conservada.

- `prueba_cofre_no_caminable.gd` verifica la caminabilidad efectiva de una celda
  con cofre abierto/cerrado y después de retirarlo. Es una comprobación puntual;
  no sustituye la regresión pendiente del flujo de inventario.
