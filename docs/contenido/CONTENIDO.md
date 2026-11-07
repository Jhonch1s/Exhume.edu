# Contenido

Duraciones actuales y compatibilidad de guardados: [Superficies](SUPERFICIES.md).

Consulta [[../GUIA_CREAR_CONTENIDO_INTERACCIONES|Crear y diagnosticar contenido]]
para duplicar, colocar, conectar y validar contenido real.

## Familias implementadas

- Interactuables: fuentes de luz, puertas, palancas, estatuas, trampas y cofres.
- Items: piedra, llave y bomba de humo.
- Superficies: humo, humo venenoso y fuego.
- Terreno reactivo: lava.

Una variante reutiliza escena y definición. Un comportamiento nuevo implementa su
receptor o reacción fuera de `GestorAcciones` y deja una prueba headless pequeña.

## Guías específicas

- [Templo de las Trampas](TEMPLO_DE_LAS_TRAMPAS.md): contenido, botín, conexiones y estado de implementación.

- [Gestor de VFX](VFX.md): sacudidas por acontecimientos e integración con cámara y paredes.

- [Paredes móviles](PAREDES_MOVILES.md): placa, deslizamiento y apertura persistente del pasaje del Templo.

- [Cofres](COFRES.md): autoría desde el Inspector, contenido inicial, interfaz y niebla.
- [Personajes](PERSONAJES.md): modelos 3D de Guerrero, Mago y Ladrón y su integración en la ficha 2D.
- [NPC y diálogos](NPC_Y_DIALOGOS.md): estado actual, reglas de encuentros, patrullas, actitud, muerte y próximos incrementos.
- [Construir diálogos de NPC con pruebas y consecuencias](CONSECUENCIAS_DIALOGO_NPC.md): guía permanente de autoría, recursos del Inspector, ramas, actitud, información e intentos guardables.
- [Patrullas de NPC](PATRULLAS_NPC.md): configurar puntos en Godot, circuito, esperas y retorno tras la búsqueda.
- [Visión, iluminación y niebla de guerra](VISION_ILUMINACION_Y_NIEBLA.md): separación acordada entre luz, percepción por actor y conocimiento del jugador.
- [Pendientes de interfaz](../PENDIENTES_INTERFAZ.md): continuidad acordada para otra sesión.
