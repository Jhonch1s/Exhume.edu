# Progresión y catálogo de nivel 2

Verificado en Godot 4.7. Cada clase ofrece dos activas y dos pasivas y aprende
una sola recompensa a 100 XP. Las tres habilidades iniciales se conservan.

## Prueba jugable

`scenes/pruebas_habilidades/LaboratorioHabilidades.tscn` permite cambiar entre
las tres clases con ambas activas y ambas pasivas simultáneas. Incluye controles
para reponer recursos y reconstruir la arena, y guardados independientes por
clase. Esta excepción de pruebas usa una ficha derivada; la ficha normal sigue
rechazando más de una recompensa.

Las escenas `scenes/pruebas_habilidades/PruebaNivel2Guerrero.tscn`,
`PruebaNivel2Ladron.tscn` y `PruebaNivel2Mago.tscn` se ejecutan con F6. Abren
la elección, incluyen dos enemigos móviles de 4 PV, una placa descubierta,
fuego, humo y veneno. Cada clase usa un archivo de guardado de pruebas propio.

Controles y efectos: [README de arenas](../../scenes/pruebas_habilidades/README.md)
y [catálogo aprobado](../contenido/PROPUESTA_CATALOGO_NIVEL_2.md).

## Verificación automática

| Prueba | Resultado |
|---|---|
| `prueba_habilidades_nivel_dos.gd` | 204 comprobaciones, 0 fallos; decisión de empuje comprobada también con render |
| `prueba_arenas_nivel_dos.gd` | 25 comprobaciones con render y captura, 0 fallos |
| `prueba_laboratorio_habilidades.gd` | 66 comprobaciones con render y capturas de las tres clases y sigilo, 0 fallos |
| `prueba_clic_habilidades_hud.gd` | 42 comprobaciones con render y eventos de ratón completos, 0 fallos |
| `prueba_progresion.gd` | 18 comprobaciones, 0 fallos |
| `prueba_ataque_doble.gd` | 25 comprobaciones, 0 fallos |
| `prueba_ocultarse.gd` | 23 comprobaciones, 0 fallos |
| `prueba_bola_fuego.gd` | 29 comprobaciones, 0 fallos |
| `prueba_escenarios_habilidades.gd` | 25 comprobaciones, 0 fallos |
| `prueba_campamento.gd` | 149 comprobaciones, 0 fallos |
| `prueba_xp_indirecta_npc.tscn` | 231 comprobaciones correctas |
| `prueba_facciones_npc.tscn` | 287 comprobaciones correctas |
| Persistencia de ficha/conocimiento | Correcta |
| Recursos de movimiento y ciclo seguro de paso | Correctos |
| UI de combate, duración de superficies y turnos de Quemado | Correctos |

Los scripts SceneTree se ejecutan con los autoloads del proyecto:

```text
Godot.exe --headless --path . --script res://tests/ejecutar_con_autoloads.gd -- res://tests/interacciones/prueba_habilidades_nivel_dos.gd
```

Las arenas también se comprobaron con render OpenGL real y una captura de la
elección. En el entorno restringido, las pruebas de archivos usaron APPDATA
temporal dentro de `.godot/pruebas_usuario`; no se cambió `project.godot`.

## Casos cubiertos

- Una única elección entre las cuatro, cancelar sin perderla, clase e IDs
  válidos, JSON, guardado/carga de usos agotados y recuperación por descanso.
- Laboratorio: cambio de clase y reinicio sin duplicar habilidades, cuatro
  recompensas simultáneas, atajos 2/3/4, recuperación de las tres activas y
  límites pasivos, guardado/carga independiente y rechazo por ficha normal.
- Clic sostenido y soltado en las ranuras: iniciales de las tres clases, ambas
  activas aprendidas y Contagio; prueba también la recompensa única normal.
  Las activas agotadas no se activan y un clic en HUD no mueve la ficha ni gasta
  el uso antes de seleccionar objetivo. El estado disabled no se alterna durante
  cada actualización, para conservar la pulsación del ratón hasta soltarlo.
- Ariete con interpolación visible por casilla, bloqueo de guardado durante el
  empuje, muro, fuego y parada en trampa activada aunque permita seguir caminando.
- Agarre con movimiento real, guardado durante el arrastre, ruptura al comenzar
  turno y rechazo de una referencia guardada a un actor inexistente.
- Golpe desplazante se decide después del daño: aceptar, rechazar sin gasto,
  elegir tras el segundo golpe, no ofrecer tras fallo ni repetir tras usarlo.
  El ataque básico cierra su resultado antes de abrir la decisión; Ataque doble
  espera cada respuesta y revalida alcance. No se guarda ni carga con decisión pendiente.
- Inercia con reserva de movimiento agotada, coste de terreno, movimiento real
  y carga sin recuperar la oportunidad gastada.
- Señuelo con IA y movimiento reales, caducidad al finalizar el turno,
  interrupción por amenaza visible y respeto de la rama de liberarse de telarañas.
- Paso de sombra exige sigilo, acción adicional y destino libre; funciona en
  combate y salta sobre fuego sin pisarlo. El HUD explica el requisito pendiente.
- Oculto aplica transparencia al 40%, indica duración en HUD y restaura la
  opacidad al perder sigilo; cargar conserva la presentación.
- Escapista con movimiento real fuera de visión y persistencia del sigilo
  cuando la habilidad inicial aún conserva su uso.
- Trampero filtra placas descubiertas al entrar; las desconocidas reaccionan.
- Transposición conserva ocupación correcta y aplica peligros a ambos destinos.
  Transposición y Trasvase aceptan cinco casillas y rechazan seis; en Trasvase
  se verifican tanto el origen como el destino.
- Trasvase conserva identidad y duración, permite NPC en destino, rechaza otra
  superficie y restaura la posición trasladada sin duplicarla. Fuego y veneno
  reaccionan inmediatamente sobre el NPC con un único uso y acción principal;
  humo también admite NPC. Guardado/carga conserva superficie y estados recibidos.
- Piromancia libre crea fuego de tres turnos con el uso de Bola de fuego y
  rechaza suelo ocupado sin cobrar.
- Bola de fuego sobre enemigo prende su celda durante tres turnos salga o no
  Quemado; renueva fuego existente sin duplicarlo y mantiene los costes originales.
- Contagio se dispara con un ataque real y conserva ticks, retirada del estado
  original y límite de una oportunidad por turno.

## Límites del corte

La progresión automática llega a nivel 2; conserva la XP excedente. Los niveles
3 y superiores siguen las reglas documentadas, con implementación pendiente.
Las pruebas comprueban legalidad y persistencia; el equilibrio de las doce
opciones requiere partidas reales.
