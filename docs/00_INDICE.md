# Exhume — documentación técnica

## Empezar aquí

- [[arquitectura/MAPA_SISTEMA_INTERACCIONES.canvas|Mapa visual del sistema]]
- [[CONTRATOS_SISTEMA_INTERACCIONES|Contratos del sistema de interacciones]]
- [[GUIA_CREAR_CONTENIDO_INTERACCIONES|Crear y diagnosticar contenido]]
- [[contratos/19_REGISTRO_NARRATIVO_SESION|Registro narrativo de sesión]] — primer incremento implementado.
- [Cofres e inventarios de almacenamiento](contenido/COFRES.md).
- [Personajes y modelos 3D](contenido/PERSONAJES.md).
- [NPC y diálogos](contenido/NPC_Y_DIALOGOS.md) — estado de Trompo y próximos incrementos.
- [Construir diálogos de NPC con pruebas y consecuencias](contenido/CONSECUENCIAS_DIALOGO_NPC.md) — guía permanente de autoría en el Inspector, actitud, información e intentos por NPC.
- [Patrullas de NPC](contenido/PATRULLAS_NPC.md) — rutas visuales, esperas, retorno y persistencia.
- [Comprobación de actitud de NPC](pruebas/ACTITUD_NPC.md) — escena manual, transiciones, defensa y guardado compatible.
- [Facciones y bandos de NPC](pruebas/FACCIONES_NPC.md) — auxilio por visión, aliados, encuentros y migración del guardado.
- [XP por derrota de NPC](pruebas/XP_NPC.md) — bajas directas/indirectas por bando, guardado y escena manual.
- [Diálogos con tiradas](pruebas/DIALOGOS_CON_TIRADAS.md) — custodio de prueba, VOL, ramas y bloqueo modal de K/C.
- [Campos de visión de NPC](pruebas/VISION_NPC.md) — tecla V, colores, ocultación y escena manual.
- [Táctica de combate NPC](pruebas/TACTICA_NPC.md) — selección de objetivos y K/C; huida/humo automático aplazados.
- [Consolidación de NPC](pruebas/CONSOLIDACION_NPC.md) — correcciones de guardado/carga, limpieza y regresiones antes de integrar la rama.
- [Visión, iluminación y niebla de guerra](contenido/VISION_ILUMINACION_Y_NIEBLA.md) — diseño acordado, diagnóstico actual y decisiones pendientes.
- [HUD del jugador y antorcha en mano](arquitectura/HUD_JUGADOR.md).
- [Continuidad: pulido de interfaces](PENDIENTES_INTERFAZ.md) — punto de partida para el próximo chat.
- [Roadmap de implementación](../ROADMAP_SISTEMA_INTERACCIONES.md)

## Áreas

- [[arquitectura/ARQUITECTURA|Arquitectura]] — componentes, límites y flujos.
- [[contenido/CONTENIDO|Contenido]] — items, interactuables, superficies y recetas.
- [[decisiones/DECISIONES|Decisiones]] — razones que deben sobrevivir al código actual.
- [[pruebas/PRUEBAS|Pruebas]] — qué protege la regresión automatizada.

## Regla de mantenimiento

El código y las pruebas demuestran el comportamiento. Los contratos lo especifican,
el roadmap registra su evolución y el canvas permite recorrerlo visualmente. No se
duplica información detallada entre esos formatos.

Las guías de autoría enlazadas aquí forman parte de la documentación permanente
del proyecto. Se mantienen junto con los recursos y APIs que describen; el
procedimiento de construcción no debe quedar sólo en notas de una rama, el
roadmap o escenas de prueba.
