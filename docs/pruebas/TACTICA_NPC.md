# Táctica NPC: selección de objetivos

Alcance actualizado el 15-10-2026 tras la prueba jugable del usuario. Se conserva
la selección táctica; **huida y uso automático de humo quedan incompletos y
aplazados**. El prototipo podía perder detección, regresar a su posición habitual
y reentrar automáticamente en combate. El usuario pidió no completar esa parte
por ahora. No hay opción activa de retirada ni uso de bombas por la IA.

## Escena manual

Abrir `res://tests/interacciones/escena_tactica_npc.tscn` y ejecutar con F6.
Hereda la escena de facciones: Guardia hostil, compañero fijo, amistoso, compañero
lejano y Trompo no combatiente. La variante prepara al Guardia con 4/15 PV y dos
bombas en inventario; **no las usa automáticamente**. Conserva visión doce y
movimiento DES + 3. Los objetos restantes pueden recogerse del cadáver.

El cartel muestra PV, bandos, posición y bombas. Clic izquierdo abre acciones;
derecho mueve; V alterna los campos de visión. K guarda y C carga en reposo,
usando exclusivamente `user://prueba_tactica_npc.json`. En el nodo raíz pueden
ajustarse `vida_guardia` y `bombas_guardia`; F6 reinicia.

1. Iniciar el encuentro y pasar turno. El Guardia herido se acerca o ataca
   normalmente: no se retira ni lanza humo aunque lleve bombas.
2. Colocar jugador y amistoso a su vista: prioriza un adyacente, después uno
   con acercamiento pagable y menor PV actual. Desempata por distancia e ID.
   Nunca elige un compañero de bando como objetivo del ataque.
3. Ocultar al objetivo tras pared o humo: sólo puede perseguir el recuerdo del
   propio bando. No elige según la vida ni la posición actual del enemigo oculto.
4. Probar telaraña y caída: liberarse prevalece y caído cierra su turno. Los pasos
   conservan costes, reservas y reacciones existentes. Sin recursos pasa.
5. Guardar antes y después de un turno; cargar dos veces. Se restauran PV,
   casilla confirmada, acción disponible/gastada y las mismas bombas, sin ataques
   repetidos ni consumo automático. K durante movimiento y C en reposo mantienen
   el contrato anterior; no se guarda una nueva modalidad de huida.
6. Derrotar al Guardia: permite paso, examen y botín con las bombas sin usar.
   K/C conserva cadáver e inventario. Trompo mantiene su excepción.

El lanzamiento del jugador y el humo existente siguen disponibles. El cierre
por pérdida de agro y los comportamientos de búsqueda, regreso y patrulla
conservan sus reglas anteriores. La continuidad de una futura huida entre estos
estados sigue sin resolver; no se considera una función terminada.

## Verificación automática

La prueba dirigida pasó **68 comprobaciones** en Godot 4.7 sin ventana:
selección por visión/bando, débil inaccesible, empates, estados, poca vida sin
retirada/humo, turno real de ataque, inventario, K/C repetida y cadáver/botín.
Los desempates tienen identidades esperadas por distancia e ID; cambiar los
ocultos no cambia el recuerdo perseguido. Una decisión con un visible distante
consulta cuatro rutas, y atrapado/caído/sin movimiento no consulta rutas de ataque.
Usa slots `prueba_tactica_npc_automatica.json*`, separados del slot manual y normal.
También pasaron facciones/XP/visión (287 comprobaciones), exploración autónoma,
lanzamiento lógico del jugador (seis pruebas) y bloqueo de visión por humo.

```powershell
C:\godot\Godot.exe --headless --path C:\godot\exhum_edu res://tests/interacciones/prueba_tactica_npc.tscn
```

Las comprobaciones anteriores del prototipo de huida eran automáticas y no
cubrieron el problema descubierto por el usuario. Se sustituyeron por pruebas
del alcance vigente. Los scripts antiguos `SceneTree` que dependen de autoloads
pueden cargarse diferidos:

```powershell
C:\godot\Godot.exe --headless --path C:\godot\exhum_edu --script res://tests/ejecutar_con_autoloads.gd -- res://tests/interacciones/prueba_lanzar_item_logico.gd
```

Las pruebas de archivo requieren escritura en `user://`. La escena conserva la
advertencia previa de UID de palanca con carga por ruta. La revisión visual del
alcance reducido sigue pendiente; la huida se aplazó a partir del informe jugable.
