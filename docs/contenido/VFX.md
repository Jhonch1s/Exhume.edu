# Gestor de VFX del escenario

`EscenarioBase/GestorVFX` concentra las solicitudes visuales de acontecimientos.
El primer incremento implementa sacudidas de cámara con perfiles diferenciados;
`efecto_emitido(tipo, posicion)` permite añadir después partículas u otras
presentaciones locales desde el mismo punto.

## Conexiones actuales

| Acontecimiento | Perfil |
|---|---|
| Comienza el deslizamiento de paredes | `piedra_moviendo`, durante su animación |
| Encajan los bloques | `piedra_encajada`, golpe breve |
| Se activa una trampa de superficie o una estatua lanza fuego | `trampa` |
| Daño confirmado de un ataque | `impacto`, con dirección del golpe |
| Chillido del Terror Nocturno, resistido o no | `chillido` |
| Resultado/solicitud con clave `explosion` | `explosion` |

`derrumbe` queda disponible para conectar cuando se implemente el derrumbe del
templo. Una bomba de humo no provoca una sacudida de explosión. El daño periódico
de quemado/veneno y las acciones fallidas tampoco provocan sacudidas.

El gestor observa `GestorAcciones.accion_finalizada` y las señales de las paredes;
no cambia sus resultados, costes, tiradas ni estados. No usa el generador aleatorio
del juego. Las cuatro paredes se agrupan en un temblor y un encaje por frame.
Solo atiende sucesos en celdas actualmente visibles y dentro de la pantalla.

## Cámara e intensidad

Las sacudidas suman un aporte temporal a `Camera2D.offset`, separado de su posición
de seguimiento, pan, zoom y límites. La amplitud combinada máxima es 8 píxeles de
pantalla, compensada por zoom. Al terminar se retira el aporte y se conserva el
offset anterior. La interfaz en CanvasLayer permanece estable.

En el Inspector, seleccionar `EscenarioBase/GestorVFX` y ajustar
`intensidad_sacudida`: 1 es la intensidad normal; 0 la desactiva. El parámetro es
de escena, no una nueva preferencia persistente del menú de opciones.

Al cargar una partida, entrar al campamento, morir o retirar el escenario se
limpian los efectos. No se guardan sacudidas ni se reproducen al restaurar paredes.

Para un acontecimiento nuevo, desde presentación:

```gdscript
gestor_vfx.solicitar(&"derrumbe", posicion_global)
```

Los perfiles e intensidades viven en `scripts/render/gestor_vfx.gd`. Los efectos
visuales ya existentes conservan su funcionamiento; este incremento evita una
migración masiva del VFX de combate o de superficies.

## Pruebas

- Abrir `tests/render/escena_prueba_vfx.tscn` y ejecutar F6. Teclas 1–7 permiten
  comparar perfiles; 0 alterna sacudidas. El laboratorio carga el templo y las
  conexiones reales siguen activas: se puede probar la placa 001.
- `tests/render/prueba_gestor_vfx.gd`: offset, límites, zoom, cámara libre,
  intensidad cero, FOV/pantalla, clasificación, acciones bloqueadas, daño
  periódico y ausencia de consumo del RNG global.
- `tests/zonas/prueba_paredes_moviles.gd`: conexión real de cuatro bloques con
  un único temblor y golpe final, manteniendo movimiento y guardado.

Las pruebas headless verifican comportamiento; el ajuste de sensación requiere
revisión visual. La suite `prueba_camara_libre.gd` conserva dos fallos de
guardado/carga que también se reproducen con el gestor VFX desconectado.
