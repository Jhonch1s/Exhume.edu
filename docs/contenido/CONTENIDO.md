# Contenido

Consulta [[../GUIA_CREAR_CONTENIDO_INTERACCIONES|Crear y diagnosticar contenido]]
para duplicar, colocar, conectar y validar contenido real.

## Familias implementadas

- Interactuables: fuentes de luz, puertas, palancas y trampas.
- Items: piedra, llave y bomba de humo.
- Superficies: humo, humo venenoso y fuego.
- Terreno reactivo: lava.

Una variante reutiliza escena y definición. Un comportamiento nuevo implementa su
receptor o reacción fuera de `GestorAcciones` y deja una prueba headless pequeña.
