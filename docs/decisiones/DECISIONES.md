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
- Las pruebas de Exhume usan `1d6 ≤ atributo`; el 1 natural es crítico y éxito
  asegurado, y el 6 natural es pifia y fallo asegurado.
- Ventaja y desventaja se cancelan antes de tirar; sólo el dado seleccionado se
  clasifica como crítico o pifia.
- El motor de dados devuelve resultados estructurados y el solicitante decide las
  consecuencias; `GestorAcciones` no contiene reglas de tiradas.
- Una acción puede transportar una tirada ya resuelta en `ResultadoAccion`; el
  receptor la solicita y decide sus consecuencias, y el escenario sólo la registra
  y presenta.
- El origen automático o solicitado es independiente de presentar la tirada en
  primer plano o únicamente en el historial de sesión.
- Las expresiones de daño pertenecen al contenido que las produce. Los estados las
  conservan para volver a resolverlas en cada tick; el aplicador recibe cantidades
  resueltas y no contiene tablas de daño por elemento.
- Las superficies estáticas pintadas en la zona se reconstruyen desde sus capas y
  no se incluyen en el snapshot de contenido dinámico. Pinchos hacen `1d3` sin
  salvación; telaraña usa DES y `enredado`; lodo e hielo comparten DES y caída; el
  fuego estático aplica quemado y funciona como fuente de luz sin fog propio.

Si una decisión cambia, debe registrarse primero en el roadmap y después corregirse
en contratos, código y pruebas dentro del mismo cambio.
