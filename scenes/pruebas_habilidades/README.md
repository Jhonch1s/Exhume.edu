# Escenarios de prueba de habilidades

## Laboratorio: tres clases y todas las habilidades

Abre **`LaboratorioHabilidades.tscn`** y ejecútala con **F6**. El selector de la
izquierda cambia entre Guerrero, Ladrón y Mago. Cada clase empieza en nivel 2
con sus **dos activas y sus dos pasivas** desbloqueadas, además de la inicial.

| Tecla | Función |
|---|---|
| **1** | Habilidad inicial |
| **2 / 3** | Primera / segunda activa de nivel 2; clic izquierdo elige objetivo |
| **4** | Contagio (Mago): No / Veneno / Quemado; el Guerrero decide empujar después de acertar |
| **Esc / clic derecho** | Cancelar apuntado sin gastar; clic derecho sin apuntar mueve |
| **B** o **Reponer** | Recuperar PV, energía y usos; quitar estados y reiniciar recursos y límites del turno |
| **P** | Consultar habilidades aprendidas |
| **F5 / F9** | Guardar / cargar el laboratorio de la clase actual |

También puedes activar las habilidades con **clic izquierdo en su ranura del
HUD** y después elegir el objetivo en el mapa. Contagio se alterna con clic en
su ranura. Las habilidades sin usos o recursos quedan desactivadas; las pasivas
automáticas no necesitan pulsarse.

Las dos pasivas están disponibles a la vez. Inercia, Escapista, Trampero y
Piromancia libre actúan automáticamente; las transferencias y empujes opcionales
se controlan con **4** para Contagio, o con **Empujar / No empujar** tras causar
daño para Golpe desplazante. Pasa el cursor sobre las ranuras para leer efectos y
costes. El botón **Reiniciar enemigos y superficies** reconstruye la arena;
cambiar de clase también la reinicia. Los controles esperan a que terminen las
acciones o el turno enemigo.

Pruebas sugeridas:

- **Guerrero:** acércate a un enemigo y usa Ariete (2) para empujarlo; repón y
  prueba Agarre (3), caminando dos pasos. Usa Ataque doble (1) y decide el empuje
  después de acertar. Derrota un enemigo para probar los dos pasos de Inercia.
- **Ladrón:** usa Señuelo (2) fuera del radio de detección y camina para que
  avance la exploración. Ocúltate (1) y usa Paso de sombra (3): funciona también
  en combate con una acción adicional libre. Si Ocultarse ya la consumió,
  espera al siguiente turno o repón en el laboratorio. Oculto transparenta la
  ficha y muestra los turnos restantes en el HUD. En combate,
  pierde la línea de visión al moverte para activar Escapista. Pisa la placa
  descubierta para comprobar Trampero.
- **Mago:** Transposición (2) alcanza 5 casillas. Trasvase (3) pide
  primero una superficie y después un destino sin otra superficie, que puede
  contener un NPC. El peligro reacciona al colocarlo sobre él. Bola de fuego (1) puede
  crear fuego sobre suelo vacío y siempre prende la celda enemiga aunque no
  aplique Quemado. Origen y destino de Trasvase pueden estar a 5 casillas.
  Pisa fuego o veneno, elige Contagio con 4 y
  causa daño directo a un enemigo superviviente para transferir el estado.

Los guardados usan `user://laboratorio_habilidades_<clase>.json`. Aquí **B**
repone directamente en lugar de abrir el campamento. La partida normal y las
escenas de elección mantienen la regla de **una sola recompensa** de nivel 2.

## Nivel 2

Abre y ejecuta con **F6** una de estas escenas:

- `PruebaNivel2Guerrero.tscn`
- `PruebaNivel2Ladron.tscn`
- `PruebaNivel2Mago.tscn`

Arrancan con 100 XP y abren la elección de **una** entre dos activas y dos
pasivas. Conservas la inicial. El escenario incluye dos enemigos de 4 PV, fuego,
humo, veneno y una placa de presión descubierta. F6 reinicia para probar otra
elección. Cada clase guarda en su propio archivo `user://prueba_nivel_dos_…json`,
también al guardar desde el campamento; no sobrescribe `partida.json`.

**P** consulta la progresión o retoma una elección pendiente, fuera de combate.
**1** usa la habilidad inicial y **2** la nueva activa. Golpe desplazante ofrece
«Empujar / No empujar» después de causar daño. En Contagio arcano, 2 alterna «No»,
«Veneno» y «Quemado». Las otras pasivas funcionan automáticamente.

Activa con 2 y apunta con clic izquierdo; **Esc** o clic derecho cancela sin
gastar. Trasvase requiere dos clics: superficie de origen y celda de destino
sin otra superficie; puede contener un NPC. Paso de sombra exige estar oculto y conservar una acción adicional,
en exploración o combate. Piromancia libre usa **1**, apuntando
a suelo vacío. Los destinos de empujes, arrastres y teletransportes activan
sus peligros. El campamento **B** recupera los usos al confirmar descanso.

El catálogo está en `docs/contenido/PROPUESTA_CATALOGO_NIVEL_2.md` y la cobertura
en `docs/pruebas/PROGRESION_NIVEL_2.md`.

## Habilidades iniciales

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
