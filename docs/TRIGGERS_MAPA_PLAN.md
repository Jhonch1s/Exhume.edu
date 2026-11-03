# Plan de triggers del mapa

Propuesta del 2026-10-30, aprobada e implementada el 2026-11-03.
La configuración vigente se documenta en [Triggers del mapa](contenido/TRIGGERS_MAPA.md).

## Objetivo

Colocar y configurar eventos invisibles en los mapas desde Godot: al entrar en
una zona o cruzar un umbral, el jugador activa un diálogo u otra acción. Cada
trigger puede ejecutarse una vez por partida o en cada nueva entrada/cruce.

## Lo que ya existe

- `scripts/interacciones/dialogos/disparador_dialogo_area.gd` detecta proximidad
  con `Area2D`, abre diálogos y ofrece una ejecución única en memoria local.
  Su método estático `mostrar()` permite reutilizar la presentación de diálogos.
- `scripts/movimiento/movimiento_por_casillas.gd` confirma cada paso y proporciona
  origen, destino, procesamiento de entrada e interrupción antes del paso siguiente.
- `scenes/escenario_base/escenario_base.gd` coordina las reacciones de movimiento,
  los diálogos y el estado modal.
- `scripts/estado_partida.gd` conserva memoria narrativa y participa del guardado
  mediante `scripts/interacciones/persistencia/persistencia_partida.gd`.
- `docs/contratos/03_MOVIMIENTO_Y_REACCIONES_DE_CELDA.md` exige callbacks de entrada
  y salida síncronos, sin abrir UI. El tablero es la autoridad espacial.

## Decisiones propuestas

### 1. Detectar el paso confirmado

Usar las coordenadas anterior y nueva del jugador. Una zona se activa cuando el
origen está fuera y el destino dentro. Caminar entre sus casillas interiores no
cuenta como otra entrada. Un umbral representa una frontera entre casillas:
atravesarla constituye un cruce, inicialmente en cualquiera de los dos sentidos.

El volumen físico del personaje no determina cuándo se activa un evento. Esto
mantiene alineadas la detección, la ocupación del tablero y las reacciones del
terreno. La misma integración debe cubrir los desplazamientos por habilidades
que ya pasan por el procesamiento de entrada.

### 2. Crear una escena reutilizable para el editor

Proponer `TriggerMapa`, un `Node2D` con script `@tool`, colocado en un contenedor
`Triggers` de cada zona. Mostrar el contorno y el ID solamente en el editor;
opcionalmente también en una vista de depuración durante las pruebas.

Primero: región rectangular ajustada a casillas, proyectada correctamente al
tablero isométrico. Después: umbral sobre bordes del tablero. Las regiones
irregulares pueden añadirse cuando exista contenido que las necesite.

Propiedades iniciales:

- ID estable, único dentro de la zona.
- Habilitado.
- Geometría y tamaño.
- Frecuencia: una vez por partida o cada entrada/cruce.
- Acción configurada y sus parámetros.

El objetivo inicial es solamente el jugador principal. Validar ID duplicado,
geometría vacía o fuera del tablero y acción incompleta con advertencias del editor.
Duplicar una instancia exige asignar un ID nuevo; no usar el nombre ni la ruta del
nodo como identidad persistente.

### 3. Separar la detección de la acción

El trigger decide si corresponde activarse. La acción decide qué hacer.
Proponer una acción configurable como `Resource`, con un primer tipo
`AccionTriggerDialogo` que exporte recurso de diálogo y etiqueta inicial.

Añadir otra acción debe requerir un tipo concreto adicional, sin modificar las
reglas de detección. Las acciones que cambien objetos del mundo utilizarán los
contratos existentes de interacciones. Un ejemplo posterior puede activar un
mecanismo para comprobar que el sistema es independiente del diálogo.

El estado de ejecución pertenece a cada trigger/partida: los recursos de acción
pueden compartirse entre instancias y no deben guardar si un evento fue consumido.

### 4. Ejecutar en un momento seguro

Flujo previsto:

```text
Paso confirmado y reacciones del terreno
-> comprobar entrada/cruce y condiciones
-> registrar activación pendiente sin duplicarla
-> solicitar interrupción si la acción requiere diálogo
-> terminar el movimiento actual
-> ejecutar la acción fuera del callback de entrada
-> confirmar la activación
```

Reutilizar el mecanismo de presentación de diálogos existente. Integrar el bloqueo
modal y la coordinación de turnos para impedir nuevos movimientos o avances de
simulación incompatibles durante el diálogo. La ruta pendiente queda cancelada;
al cerrar el diálogo el jugador elige su siguiente movimiento.

Si hay otro diálogo o una resolución en curso, conservar el evento pendiente
hasta un punto seguro. Ordenar coincidencias por ID estable y procesarlas en
serie. La reserva pendiente evita duplicados. Si la acción no puede comenzar por
configuración inválida, informar el error y no consumir el trigger. Para el
diálogo, confirmar el consumo cuando se crea correctamente su presentación.

No persistir eventos en ejecución: bloquear guardado y transiciones de zona
durante la resolución, aprovechando las restricciones existentes de actividad.
Verificar específicamente la coordinación con el avance de turnos y el combate.

### 5. Conservar el estado por partida

Registrar los consumidos en `EstadoPartida`, identificados por zona e ID del
trigger. Conservarlos al viajar, serializarlos con la memoria narrativa y borrarlos
al crear una partida nueva.

Actualizar validadores y compatibilidad de guardados: un guardado anterior sin
este campo se interpreta con cero triggers consumidos. No basta con agregar una
clave: la validación actual de memoria narrativa exige exactamente una clave.

Cargar una partida o colocar inicialmente al personaje dentro de una zona no
equivale a entrar caminando. Inicializar la referencia espacial tras restaurar
el estado, sin disparar eventos por el propio proceso de carga.

## Entregas y criterios de aceptación

1. **Zona + diálogo.** Escena instanciable en una zona de prueba; elegir tamaño,
   diálogo y etiqueta desde el inspector. Un paso de fuera a dentro abre un único
   diálogo, al finalizar el paso. El trigger no bloquea caminos ni aparece al jugar.
2. **Frecuencia + guardado.** Probar reentrada, salida y regreso al mapa, guardar y
   cargar, partida nueva y compatibilidad con guardados anteriores. La ejecución
   única y el modo repetible cumplen sus reglas sin duplicados.
3. **Umbral + otra acción.** Configurar un cruce entre casillas y una acción sobre
   un mecanismo mediante el sistema de interacciones existente. Cruzar activa el
   evento; caminar paralelo no lo activa.
4. **Integración.** Actualizar plantilla de zona y guía de contenido. Probar dos
   triggers coincidentes, otro diálogo abierto, movimiento por habilidad, combate,
   jugador incapacitado por terreno y carga dentro de la zona. Ejecutar regresiones
   de movimiento, diálogo y persistencia.

Cada entrega debe incluir una prueba pequeña automatizada de su lógica y una
comprobación en una escena jugable. La primera entrega usa una zona de prueba
aislada; el primer evento narrativo real se coloca cuando se decida su contenido.

## Fuera del primer alcance

Editor visual de secuencias, lenguaje genérico de condiciones, polígonos libres,
cruce direccional, activación por NPC y cadenas de acciones con reversión. Añadir
estas capacidades solamente cuando un evento concreto las requiera.

## Referencias de Godot

- [Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html):
  alternativa de detección física, utilizada por el disparador existente.
- [Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html):
  datos configurables y compartibles desde el inspector.
