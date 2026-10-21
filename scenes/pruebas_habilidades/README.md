# Escenarios de prueba de habilidades

Abre `PruebaLadron.tscn` o `PruebaMago.tscn` en Godot y ejecútala con **F6**.
Cada escena crea al personaje de esa clase en una arena editable y sitúa un
enemigo inmóvil a cuatro casillas. El enemigo detecta a dos casillas, por lo
que la zona empieza fuera de combate.

- **Ladrón:** acércate a tres casillas, pulsa **1** para ocultarte fuera de
  combate y avanza. Al terminar el sigilo, el enemigo te detectará; puedes
  probar la misma habilidad durante tu turno de combate tras descansar.
- **Mago:** pulsa **1** para apuntar y haz clic en la casilla del enemigo
  iluminado para lanzar Bola de fuego fuera de combate. **Esc** cancela el
  apuntado. También puedes acercarte hasta su
  radio de detección para entrar en combate antes de lanzar el hechizo.

El clic derecho mueve al personaje. Las teclas **1–4** corresponden a las
ranuras de habilidades y **5–8** a las de objetos rápidos; también funciona
el teclado numérico. Por ahora solo está activa la primera habilidad de cada
clase y el uso rápido de objetos aún no está implementado. La fogata del
campamento permite recuperar el uso gastado.

Ambas escenas usan `zona_prueba_habilidades.tscn`, derivada de ZonaPlantilla.
Puedes editar allí el suelo, el punto de entrada y el enemigo común.
