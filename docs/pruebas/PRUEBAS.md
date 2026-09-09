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

## Estado de las comprobaciones de cofres — 8 de septiembre de 2026

- El usuario ejecutó la prueba de capacidad y la prueba visual de casilla y confirmó
  sus resultados. La generación de contenido fue comprobada manualmente en juego;
  los items sin icono existen aunque su imagen no aparezca.
- `prueba_layout_panel_cofre.gd` verificó cuatro tamaños con casillas estáticas.
  Después el panel pasó a generar casillas en `mostrar()`. La prueba debe adaptarse
  para abrir un cofre con contenido y exigir el número esperado de casillas: tal
  como está, su bucle puede pasar sin comprobar ninguna casilla.
- La prueba propuesta de panel dinámico no fue ejecutada por el usuario. No hay
  cierre de regresión de apertura, recogida total, modal ni persistencia de cofres.
- Las rutas corregidas de las estatuas 11 y 12 se comprobaron mediante una prueba
  temporal en Godot: visible, explorado y oculto, sin modificar la estatua 10.
  Esa prueba temporal no forma parte de la suite conservada.

- `prueba_cofre_no_caminable.gd` verifica la caminabilidad efectiva de una celda
  con cofre abierto/cerrado y después de retirarlo. Es una comprobación puntual;
  no sustituye la regresión pendiente del flujo de inventario.
