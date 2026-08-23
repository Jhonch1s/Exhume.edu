# Decisiones arquitectónicas

Las decisiones vigentes están desarrolladas en
[[../CONTRATOS_SISTEMA_INTERACCIONES|Contratos del sistema de interacciones]].

## Núcleo

- Código y IDs en español; `StringName` estable para contenido extensible.
- Definición, instancia y representación son conceptos separados.
- Acciones y resultados son estructurados.
- Los receptores se definen por comportamiento, no por una jerarquía única.
- Los items aportan etiquetas y magnitudes, no excepciones por pareja.
- Las referencias entre mecanismos y la persistencia usan IDs, no `NodePath`.
- Validar no muta; los bloqueos no cobran ni aplican consecuencias.
- El orden de reacciones es determinista.

Si una decisión cambia, debe registrarse primero en el roadmap y después corregirse
en contratos, código y pruebas dentro del mismo cambio.
