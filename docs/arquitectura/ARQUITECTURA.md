# Arquitectura

- [[MAPA_SISTEMA_INTERACCIONES.canvas|Mapa maestro]]
- [[../CONTRATOS_SISTEMA_INTERACCIONES|Contratos completos]]

El flujo central es:

```text
Intención o evento
→ ContextoAccion
→ validaciones de GestorAcciones
→ receptor o reacciones ordenadas
→ ResultadoAccion
→ efectos, costes y cambios confirmados
→ estado persistente y presentación
```

`GestorAcciones` coordina y nunca contiene reglas específicas de contenido. El
tablero es la autoridad espacial; las referencias persistentes usan IDs estables.

## Integraciones actuales

- [Cofres](../contenido/COFRES.md): abrir pasa por el gestor; la transferencia
  desde el panel usa directamente `Inventario.transferir_a()`. Su persistencia
  todavía está pendiente.
- [Personajes](../contenido/PERSONAJES.md): modelos 3D capturados a texturas para
  una ficha que sigue siendo 2D. Hay tres modelos, con selección por clase pendiente.
