### Registro de conocimiento por observador

`RegistroConocimiento` mantiene durante la ejecución únicamente IDs estables con
esta jerarquía:

```text
id_observador
└── id_instancia_objetivo
    └── id_fragmento
```

No almacena nodos, `Resource`, mensajes ni referencias a UI. La identidad del
observador se expresa mediante un `StringName` estable para que el modelo pueda
serializarse en la futura fase de persistencia, aunque en esta fase no se guarda en
disco.

`registrar_descubrimientos()` valida la solicitud completa antes de modificar el
registro, ignora fragmentos con `se_recuerda = false` y es idempotente. Devuelve un
`ResultadoRegistroConocimiento` que distingue:

- Éxito con los IDs aprendidos por primera vez, conservando el orden recibido.
- Éxito sin novedades cuando todos los fragmentos recordables ya eran conocidos.
- Fallo sin mutación parcial cuando las claves o los fragmentos son inválidos.

El registro no infiere niveles ni descubre información adicional. Almacena
exactamente los fragmentos recordables que entregue el evaluador; la inclusión de
niveles inferiores se obtiene porque el evaluador devuelve todos los fragmentos
aplicables. `obtener_ids_conocidos()` entrega una copia ordenada y
`conoce_fragmento()` permite consultar una clave concreta.

Los motivos iniciales del registro son `id_observador_vacio`, `id_objetivo_vacio`,
`fragmentos_descubrimiento_invalidos` y
`fragmentos_descubrimiento_duplicados`. El borrado selectivo, la importación y la
exportación quedan fuera de la Fase 3.

### Solicitud y servicio de examen

`SolicitudExamen` transporta el ID estable del observador y las pistas semánticas
del intento. Es inmutable, copia sus pistas y exige que el actor implemente:

```gdscript
func obtener_id_observador() -> StringName
```

El ID devuelto por el actor debe coincidir con el de la solicitud. De este modo una
acción no puede atribuir descubrimientos a otro observador. `Ficha` es la primera
implementación del protocolo mediante su propiedad `id_observador`.

`ServicioExamen` es compartido e independiente de la UI. Recibe `TableroGrid` y un
`RegistroConocimiento`, y coordina el flujo:

```text
ContextoAccion EXAMINAR
→ validar objetivo, definición, solicitud y coordenadas
→ calcular distancia Manhattan desde el contexto
→ consultar visibilidad actual en Celda
→ validar defensivamente la línea visual
→ evaluar los fragmentos provistos por el interactuable
→ registrar únicamente los fragmentos recordables nuevos
→ construir ResultadoAccion
```

Los mensajes del resultado son los IDs narrativos de todos los fragmentos
disponibles, aunque ya fueran conocidos. `cambios_estado` contiene únicamente los
nuevos descubrimientos, identificados mediante observador, objetivo y fragmento.
Repetir un examen válido vuelve a presentar su información sin duplicar cambios.

`Interactuable` publica la opción `Examinar` y delega su validación y resolución al
servicio. Puede especializar `obtener_fragmentos_informacion()` para seleccionar
variantes narrativas según su estado sin exponer la propiedad interna. La primera
antorcha utiliza este punto para elegir entre dos variantes de un único fragmento
`BASICO`: ambas presentan identidad y estado evidente en una sola frase. El registro
recuerda el ID estable `identidad`, no el valor actual de `encendida`.

El tablero inyecta un mismo servicio en los interactuables registrados. El escenario
principal instancia el gestor, el registro y el servicio, y vincula el examen al
menú contextual obligatorio sin entregar esa responsabilidad al interactuable.

