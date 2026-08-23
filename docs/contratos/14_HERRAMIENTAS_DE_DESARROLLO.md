## Validación de contenido de zona — incremento 13.1

`ValidadorContenidoZona` inspecciona una zona instanciada después de que
`TableroGrid` genere sus celdas y antes de registrar interactuables o superficies.
La validación no modifica la escena ni los índices del tablero y devuelve todos sus
errores como textos ordenados y aptos para consola y pruebas headless.

El validador comprueba IDs vacíos o duplicados, definiciones de interactuables,
coordenadas dentro del tablero y el protocolo mínimo de las superficies. Para las
palancas también comprueba IDs de receptores vacíos, repetidos, inexistentes o sin
el contrato de mecanismo. No ejecuta acciones ni llama validaciones que dependan de
un registro ya configurado.

`EscenarioBase` registra contenido únicamente cuando la prevalidación completa no
produce errores. Así una entidad inválida no deja el resto de la zona parcialmente
registrado. Las validaciones defensivas de `TableroGrid` y de cada receptor se
mantienen porque también protegen el contenido creado dinámicamente.

## Inspección lógica de celdas — incremento 13.2

`InspectorCeldaDesarrollo` consulta una celda ya generada sin modificarla y produce
un resumen textual. Incluye terreno, altura, visibilidad, caminabilidad y bloqueo
de visión base y efectivos, bloqueo de proyectiles, coste de movimiento y peso de
ruta. También lista ocupantes, reservas, interactuables, items de suelo, superficies,
iluminación y la reacción de terreno.

Los contenidos se identifican mediante los protocolos de IDs estables existentes y
se ordenan antes de presentarse. Una superficie añade sus turnos restantes cuando
implementa ese contrato. Los objetos sin ID usan únicamente su nombre de nodo o su
clase como respaldo diagnóstico; ese texto no participa en persistencia ni lógica.

En la escena principal, `F3` imprime el resumen de la celda bajo el cursor. Es un
control exclusivo de desarrollo: no abre una vista modal, no selecciona objetivos y
no ejecuta acciones.

## Registro filtrable y autoría — incremento 13.3

`RegistroAccionesDesarrollo` continúa observando únicamente las señales públicas de
`GestorAcciones`. Cada ciclo identifica tipo, actor, objetivo, origen y destino;
después informa estado, motivo y cantidades de solicitudes, efectos y cambios; al
final conserva costes e interrupción confirmados.

Los filtros opcionales se combinan por ID estable de actor, `celda_objetivo` y tipo
de acción. Filtrar solo afecta las entradas observadas: no evita señales, validaciones
ni resolución. La celda objetivo es el criterio espacial porque identifica el
contenido diagnosticado tanto en acciones voluntarias como automáticas.

El proceso de autoría está documentado en
[`GUIA_CREAR_CONTENIDO_INTERACCIONES.md`](GUIA_CREAR_CONTENIDO_INTERACCIONES.md).
Las escenas existentes son las plantillas verificadas; no existe una abstracción
adicional de plantilla ni un generador de marcadores mientras no haya repetición que
los justifique.

