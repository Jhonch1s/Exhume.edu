## Niveles de información de Examinar

```gdscript
enum NivelInformacion {
	VISIBLE,
	BASICO,
	DETALLADO,
	SECRETO,
}
```

- `VISIBLE`: rasgos evidentes sin examen activo.
- `BASICO`: identidad y función aparente obtenibles en condiciones normales.
- `DETALLADO`: estado mecánico o propiedades que exigen percepción, herramienta o condiciones mejores.
- `SECRETO`: información oculta que requiere una condición explícita de descubrimiento.

Descubrir un nivel incluye los inferiores. Los descubrimientos persistentes se registrarán por ID estable del objetivo y por fragmento de información; mejorar temporalmente las condiciones no revela automáticamente secretos.

La progresión de conocimiento no obliga a presentar un mensaje separado por cada
nivel accesible. Como regla de autoría, `VISIBLE` se reserva principalmente para el
reconocimiento pasivo del mundo. Cuando el rasgo evidente y la identidad básica
describen el mismo tema, `BASICO` debe integrarlos en un único fragmento narrativo.
Así se evita repetir dos frases al examinar desde lejos sin eliminar la distinción
conceptual entre percepción pasiva y examen activo.

### Fragmentos de información examinable

La información destinada al jugador se define mediante `FragmentoInformacion`, un
`Resource` reutilizable que describe contenido narrativo y no expone propiedades
internas del receptor.

| Campo | Tipo | Regla |
|---|---|---|
| `id_fragmento` | `StringName` | ID estable dentro de una definición; obligatorio y único. |
| `nivel` | `NivelInformacion` | Clasifica el fragmento como `VISIBLE`, `BASICO`, `DETALLADO` o `SECRETO`. |
| `id_mensaje` | `StringName` | ID de presentación localizable; obligatorio. |
| `pistas_requeridas` | `Array[StringName]` | Condiciones semánticas explícitas necesarias para descubrirlo. No admite valores vacíos ni duplicados. |
| `se_recuerda` | `bool` | Indica si el descubrimiento debe incorporarse al conocimiento del observador. |

Los fragmentos `SECRETO` deben declarar al menos una pista. Una pista describe una
condición de dominio, por ejemplo `&"marca_oculta_revelable"`; no identifica la
variable, habilidad, herramienta o sistema que la produjo. Los estados transitorios,
como que una llama esté encendida en este momento, pueden representarse mediante un
fragmento con `se_recuerda = false`.

`DefinicionInteractuable` conserva los fragmentos reutilizables del tipo. Dos
instancias que comparten definición ofrecen los mismos fragmentos candidatos, pero
su estado observable y el conocimiento registrado permanecen separados.

### Condiciones de una observación

`CondicionesObservacion` es un contrato inmutable que transporta únicamente hechos
de la observación actual:

| Campo | Tipo | Regla |
|---|---|---|
| `observador` | `Object` | Sujeto que intenta obtener la información; obligatorio. |
| `distancia` | `float` | Distancia ya calculada, no negativa. |
| `objetivo_visible` | `bool` | Indica que la celda está actualmente visible, no solo explorada. |
| `linea_visual_valida` | `bool` | Resultado de la validación visual correspondiente. |
| `pistas` | `Array[StringName]` | Pistas semánticas disponibles en este intento, sin valores vacíos ni duplicados. |

Las pistas se copian defensivamente. Este contrato no contiene el conocimiento
recordado ni referencias a UI.

### Perfil y evaluación de información

`PerfilObservacion` separa los alcances de examen de las propiedades mecánicas del
objetivo. Sus valores iniciales para interactuables estáticos son:

| Campo | Valor inicial | Regla |
|---|---:|---|
| `alcance_basico` | `5.0` | Alcance de fragmentos `VISIBLE` y `BASICO`. |
| `alcance_detallado` | `1.0` | Alcance de fragmentos `DETALLADO`; no puede superar el básico. |
| `alcance_secreto` | `1.0` | Alcance adicional de fragmentos `SECRETO`; no sustituye sus pistas. |
| `requiere_objetivo_visible` | `true` | Una celda solo explorada no permite obtener información nueva. |
| `requiere_linea_visual` | `true` | Exige una línea visual ya validada. |

Cada `DefinicionInteractuable` puede declarar un perfil. Los enemigos y otras
categorías podrán usar perfiles con alcances distintos sin introducir condiciones
específicas en el evaluador.

`EvaluadorInformacion` es puro: recibe fragmentos, `CondicionesObservacion` y un
perfil, no modifica ninguno y devuelve `ResultadoEvaluacionInformacion`. Conserva
el orden declarado de los fragmentos y aplica estas reglas:

1. Rechazar contratos inválidos e IDs de fragmento duplicados.
2. Validar visibilidad actual y línea visual según el perfil.
3. Bloquear cuando la distancia supera el alcance básico.
4. Filtrar cada nivel por su alcance correspondiente.
5. Exigir todas las pistas declaradas por cada fragmento.
6. Informar si la distancia actual permite detalle, sin convertir eso en un descubrimiento persistente.

Los motivos iniciales son `condiciones_observacion_invalidas`,
`perfil_observacion_invalido`, `fragmentos_informacion_invalidos`,
`fragmentos_informacion_duplicados`, `objetivo_no_visible`,
`linea_visual_bloqueada`, `fuera_alcance_examen` y
`sin_informacion_disponible`.

