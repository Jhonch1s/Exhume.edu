# Comprobación de XP directa e indirecta por derrota de NPC

Regla vigente del 15-10-2026: la muerte de cada NPC participante del bando
oponente durante un encuentro activo concede al jugador su recompensa completa.
No importa quién causó el daño mortal ni si hubo golpes previos. Incluye veneno,
quemado, explosión, terreno y daño sin autor. Fuera del encuentro, NPC ajenos y
aliados no conceden XP al jugador. Sólo la ficha acumula XP por ahora.

## Escena manual de muertes indirectas

Abrir `res://tests/interacciones/escena_xp_indirecta_npc.tscn` y ejecutar con F6.
Hereda la escena de facciones y prepara combatientes con 1 PV y 50 XP de premio.
`agro_automatico = true` por defecto: Guardia y Compañero fijo comienzan hostiles,
detectan al jugador sin golpes e inician la persecución en sus turnos. Para
comprobar muertes fuera de combate, desactivar `agro_automatico` en el nodo raíz
y reiniciar con F6; vuelve la preparación neutral. No cambia contenido permanente
ni el slot normal de guardado.

El cartel muestra XP, PV y bando. `objetivo_prueba` en el nodo raíz elige uno de
los cuatro combatientes (1 = Guardia; no incluye a Trompo). Estos controles son
exclusivos de esta escena de diagnóstico:

| Tecla | Efecto de prueba |
|---|---|
| B | Abrir el encuentro contra el objetivo, sin hacerle daño previo. |
| 1 | Aplicar un tick de veneno de 1 PV. Se resuelve al finalizar su turno. |
| 2 | Aplicar un tick de quemado de 1 PV. Se resuelve al finalizar su turno. |
| 3 | Resolver una explosión lógica de radio cero y 1 PV sobre su celda, sin autor. |
| 4 | Aplicar 1 PV de daño sin autor. |
| K / C | Guardar / cargar en reposo en `user://prueba_xp_indirecta_npc.json`. |
| F6 | Reiniciar para repetir un caso independiente. |

No son ataques nuevos del jugador ni acciones gratis disponibles en el juego.
La explosión prueba el daño existente, sin añadir una animación visual.

1. **Sin encuentro:** desactivar `agro_automatico`, reiniciar y pulsar 3 o 4. El Guardia muere
   pero la XP permanece en cero. F6 para reiniciar.
2. **Daño sin autor:** con agro automático basta esperar la detección y pulsar 4;
   en modo neutral, pulsar B y después 4. La víctima es oponente del encuentro
   y la XP pasa a 50 aunque el jugador nunca la haya golpeado. Esperar el cierre
   del encuentro: no debe añadirse otro premio.
3. **Explosión:** reiniciar y pulsar 3 durante el encuentro (B si el inicio es
   neutral). Debe conceder las mismas 50 XP. Los
   NPC ahora reciben explosiones desde su registro como interactuables del tablero;
   una misma víctima no recibe dos solicitudes por aparecer en dos registros.
4. **Veneno y quemado:** reiniciar, pulsar B y después 1 o 2. Si es turno del
   jugador, pasar turno. Al finalizar el turno del NPC el estado lo mata y suma
   50 XP. La prueba no necesita atribuir el estado al jugador ni a un aliado.
5. **Rebobinar:** pulsar B, esperar al turno del jugador, aplicar 1 o 2 y guardar
   con K antes de pasar turno y procesar el tick. Dejar
   morir al NPC y cargar con C: vuelve vivo con el estado pendiente y la XP previa.
   Dejar que muera de nuevo: esa línea temporal concede una sola recompensa.
6. **Conservar:** guardar después de morir y cargar dos veces. Cadáver y XP se
   conservan; repetir 3/4, examinar o recoger botín no conceden más XP.

Las exclusiones de aliados y de NPC ajenos al encuentro se comprueban de forma
dirigida en la prueba automática. No basta con su actitud persistente para
determinar si una baja concede XP: se consulta el bando del encuentro.

Los controles respetan modales y movimiento en curso: si no responden, cerrar la
interacción o esperar reposo. No alteran la iniciativa ni procesan un turno extra.

## Ataque directo y aliado

La escena anterior `res://tests/interacciones/escena_facciones_npc.tscn` sigue
sirviendo: `vida_combatientes = 1`, `inicio_hostil = false` y F6. Atacar al Guardia
hasta matarlo concede 50 XP; en modo hostil, un aliado que lo mate también permite
el premio. Una baja de un oponente a manos de otro oponente ahora concede XP
igualmente: importa el bando de la víctima dentro del encuentro.

La barra del HUD muestra el total y el siguiente umbral. Llegar a 100 llena la
barra, sin subir de nivel automáticamente. Los futuros integrantes del grupo
recibirán el premio completo cada uno; no hay grupo ni XP de aliados NPC todavía.

## Verificación automática

`res://tests/interacciones/prueba_xp_indirecta_npc.tscn` pasó **231 comprobaciones**
en Godot 4.7 sin ventana. Cubre estados reales mediante `GestorRondas`/FIN_TURNO,
fuentes sin autor y de ambos bandos, daño ambiental, explosión simultánea sobre
varios oponentes y entrega antes del cierre, exclusiones, recompensa cero, K/C
repetida y snapshots anteriores sin XP ni bandos. También verifica los controles
de la escena manual. No se añaden versión, historial de daño ni marcador de premio.
Incluye el inicio hostil de los dos guardias, agro sin intervención del jugador
y una intención de persecución válida desde la posición inicial.

```powershell
C:\godot\Godot.exe --headless --path C:\godot\exhum_edu res://tests/interacciones/prueba_xp_indirecta_npc.tscn
```

El corte de [consolidación](CONSOLIDACION_NPC.md) añade archivos JSON con fuego y
humo venenoso reales, carga y ejecución del tick restaurado, sin duplicar XP.

Pasaron además facciones/XP/visión (287 comprobaciones), táctica (68), persistencia
NPC (21 grupos), esquiva (20), daño/explosión, combinación de fuego, humo venenoso
y gestor de rondas. Las pruebas de archivo requieren escritura en `user://`.
Se conserva la advertencia previa de UID de palanca con carga por ruta.
La importación del editor en sandbox conserva los errores previos de permisos
de configuración y tema de Dialogue Manager; las ejecuciones de juego/pruebas
anteriores no presentan errores de scripts. No se modificó el addon.
El 15-10-2026 el usuario confirmó en juego el agro automático, la persecución
de los duendes y la recepción de XP en esta escena. Queda confirmada la entrega
básica jugable de XP. No detalló qué fuentes de muerte ni qué pasos de K/C probó;
la cobertura completa de esos casos corresponde a las pruebas automáticas.
