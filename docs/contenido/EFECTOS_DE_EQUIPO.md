# Efectos de equipo en Forja de ítems

Implementados en el editor y en el juego. Consulta `tools/forja_items/README.md` para crearlos y exportarlos.

## Contrato

`DefinicionItem.efectos_equipo` es `Array[Dictionary]`, con un máximo de 16 filas validadas. Las fichas antiguas sin esta propiedad conservan una lista vacía.

| tipo | Parámetros | Activación |
| --- | --- | --- |
| atributo | atributo: fuerza/destreza/voluntad; valor entero −5..5, distinto de cero | Mientras esté equipado, sobre el portador. |
| dano | valor entero 1..99; alcance: arma/directo | Suma daño al ataque que lo causa. |
| tirada | prueba: ataque/esquiva/fuerza/destreza/voluntad; modo: ventaja/desventaja | Tiradas correspondientes del portador. |
| estado | estado: veneno/quemado; valor 1..99 por turno; duracion 1..99; alcance; salvacion | Al causar daño, sobre el objetivo vivo. |
| penalizacion | atributo; valor 1..5 a restar; duracion 1..99; alcance; salvacion | Al causar daño, sobre el objetivo vivo. |

`alcance=arma` exige una pieza compatible con mano principal y solo se activa al llevarla en esa ranura. Se aplica a los ataques básicos, incluidos los dos golpes de Ataque doble. `alcance=directo` se aplica a esos ataques y a Bola de fuego. No incluye daño de superficies ni pulsos de estados. Ariete sigue siendo un desplazamiento, no un ataque de arma.

`salvacion` es vacío (sin salvación) o fuerza/destreza/voluntad. Cada fila con salvación se comprueba de forma independiente. Resistir tiene feedback narrativo. Fallar, esquivar o no causar daño no activa los efectos.

## Modelo y persistencia

`EquipoActor` pertenece a Ficha y conserva las ranuras 0..8 de PanelInventarioEquipo. Equipar valida compatibilidad y mueve la instancia; reemplazar devuelve la pieza anterior. Desequipar con mochila llena conserva el equipo. No se permite la misma instancia en dos ranuras. Los bonos se suman por pieza, no por cantidad de pila.

`Ficha.obtener_estado_persistente` añade equipo sin modificar los atributos base. Equipo e inventario comparten la validación de recursos de Inventario. Se rechazan IDs repetidos entre mochila, equipo, NPC/cofres y suelo al restaurar la partida. Los guardados anteriores sin equipo siguen siendo válidos. El peso equipado sigue contando.

## Estadísticas, tiradas y estados

Los getters de atributos devuelven el valor efectivo con mínimo 1. Los atributos base, progresión y PV máximos no se alteran. FUE efectiva controla carga; DES efectiva controla movimiento. Un cambio limita pasos disponibles sin reponerlos. Guardado y carga reconstruyen el presupuesto y respetan la sobrecarga.

`EfectosEquipo.resolver_prueba` pasa al MotorDados los atributos base y modificadores separados, junto a las fuentes de ventaja/desventaja. Se conservan las reglas de crítico 1 y pifia 6. Las pruebas integradas incluyen combate, esquiva, desarme, percepción de trampas, destrabarse, salvaciones de superficies y diálogo. El indicador de probabilidad de ataque considera bonos y ventaja.

Las penalizaciones temporales usan debilitado_fuerza/destreza/voluntad y expiran mediante ServicioTurnos sin causar daño. Su persistencia y su efecto sobre NPC están incluidos. Repetir un mismo estado renueva conservando la intensidad y duración mayores; no acumula magnitud. Veneno y quemado conservan sus reglas de daño por turno.

## Validación

Pruebas de exportación JS en `tools/forja_items/tests/core.test.cjs`; recursos nativos y dados en `prueba_exportador_items_web.gd`; equipamiento, reemplazos, retirada de bonos, fallo/esquiva/acierto, salvaciones, expiración, sobrecarga y persistencia en `prueba_equipo_forja.gd`.
