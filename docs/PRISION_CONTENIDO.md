# Prisión: contenido y guardias

## Contenido colocado

Las definiciones específicas están en `recursos/prision/`; las definiciones genéricas conservan su configuración.

- **Notas garabateadas**: descripción básica a distancia; al acercarse se leen el texto porcino original y la observación sobre sus trazos.
- **Cofre gastado**: aspecto de madera y herrajes; de cerca se distingue el uso repetido del cierre. Conserva su inventario vacío.
- **Peeble y Roffa**: descripciones individuales del aspecto y la vigilancia. No revelan la broma del prisionero ni la herramienta del templo.
- **Velas**: las diez se pueden examinar y describen su estado encendido/apagado. `vela_01` añade información sobre capas de cera.
- **Antorchas**: `antorcha_pie_006` añade mantenimiento reciente; `antorcha_015`, hollín acumulado. Sus propiedades de luz y encendido se conservan.

### Hallazgos añadidos al recorrido

Todos usan escenas reutilizables de `Interactuables/Guias`, ilustraciones existentes y dos fragmentos: básico y detalle a una casilla. Las casillas están expresadas como coordenadas del tablero.

| Hallazgo | Casilla | Ubicación y función |
|---|---|---|
| Advertencia arrugada | `(7, 12)` | Antes del sector de los guardias. Un aventurero cuenta un encuentro amenazante sin idioma común. |
| Registro de celdas | `(25, -1)` | Entrada del bloque central, en un espacio abierto. Dibujos y anotaciones incomprensibles muestran el uso cotidiano de las celdas. |
| Diario inconcluso | `(25, -31)` | Sector lateral de celdas. Contrasta la piedra antigua con los rastros de ocupación reciente y deja una historia sin desenlace. |
| Señal de advertencia | `(72, -12)` | En la pared del corredor más alejado. Pictogramas de celdas y peligro, sin traducción literal ni destino asegurado. |
| Estandarte remendado | `(12, 18)` | Lateral del acceso vigilado. Los remiendos sugieren apego a un emblema gastado. |

No revelan la broma del prisionero, el instrumento ni una entrada al templo todavía no implementada. El estandarte ocupa una casilla lateral; se comprueba que no corte los recorridos de los guardias.

## Guardias

Ambos usan nivel 3, 22 PV, FUE 4, DES 4, VOL 4 y 7 puntos de movimiento; tienen la misma facción y son hostiles al PJ. El radio de detección es de 4 casillas y requiere línea visual. Son valores iniciales de esta configuración, pendientes de balance jugable.

El árbol existente `recursos/ia/combate_npc.tres` se asigna en ejecución al nodo `DecisorCombate` de cada NPC. Decide patrulla, búsqueda, acercamiento y ataque. No hace falta duplicar el árbol para cada guardia.

Se eliminó un punto consecutivo repetido de la curva de Roffa: hacía que se rechazara toda su patrulla. Las demás posiciones se conservan.

## Ilustraciones

**No falta ninguna imagen para jugar con este contenido.**

Mejoras opcionales que se pueden producir:

| Imagen | Uso y orientación |
|---|---|
| `prision_cofre_gastado.png` | Examen ilustrado del cofre. Composición cuadrada o vertical, objeto completo, tablas oscuras y herrajes oxidados sobre piedra de prisión; sin texto. Se asignaría a `cofre_gastado.tres > ilustracion_examen`. |
| `peeble_portrait.png` y `roffa_portrait.png` | Ya incorporados desde `assets/characters/npcs/banga/portraits/` mediante `retrato_turno`. Ambos usan el formato vertical de los retratos del jugador: 58 × 105 px. |

Mantener fantasía oscura, pixel art, paleta terrosa y luz tenue. El pergamino ya tiene ilustración. La ficha de examen de los NPC es actualmente textual; asignar `ilustracion_examen` no añade una imagen a esa ficha.

## Verificación

`tests/interacciones/prueba_contenido_prision.gd` carga la prisión con los sistemas reales, comprueba registro y textos, diferencia examen cercano y lejano, espera dos vueltas de ambas patrullas y verifica detección, inicio de combate y decisión de ataque.

Para evaluar la nueva configuración de NPC, usar una partida nueva. Los guardados previos conservan estados y rutas anteriores y pueden ser incompatibles con estas definiciones.
