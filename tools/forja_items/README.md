# Exhume · Forja de ítems

Editor web del inventario de este proyecto, en español. Funciona sin instalar dependencias y sin conexión: abre **[dist/index.html](dist/index.html)** en tu navegador. Conserva la carpeta `dist` completa.

También puedes servirlo con `node tools/forja_items/preview.cjs` desde la raíz del proyecto y abrir `http://127.0.0.1:8139`. Para detener el servidor, pulsa Ctrl+C. El archivo HTML y cada dirección de servidor mantienen bibliotecas locales independientes.

## Crear un objeto

1. Pulsa **Nuevo ítem**. Puedes partir de un objeto vacío o de cinco plantillas del juego: bomba de humo, piedra, ración, llave y antorcha.
2. En **Información**, completa nombre, ID estable, descripción, peso, apilado y etiquetas de equipo. La vista previa muestra la ranura y calcula el peso de una pila.
3. En **Imágenes y audio**, selecciona o arrastra el icono, sprite de suelo e ilustración. También puedes pegar una imagen sobre su recuadro. Se convierten a PNG y se incluyen en la ficha. Admite sprites con varias filas/columnas, escala de suelo y sonidos WAV, OGG o MP3.

El sprite de suelo se centra en la celda. Si dibujas un sprite de una sola celda de 64×32, usa ancho en suelo 64 y una fila y columna; la escena exportada deja su posición en `(0, 0)`.
4. En **Comportamiento**, configura curación al usar o una superficie al impactar: humo, fuego o veneno. Para una poción escribe `1d6` en **Curación al usar**: recuperará entre 1 y 6 PV con una tirada nueva en cada uso. También admite cantidades fijas (`5`) y dados más un bono (`1d6+2`, entre 3 y 8 PV). `0` desactiva la curación. El radio muestra las casillas afectadas. La duración de la superficie y los pulsos/dados del estado se ajustan por separado. Llaves y antorchas tienen sus propios campos.
5. Revisa la vista previa en **Inventario**, **Suelo** o **Examen** y corrige los avisos antes de exportar. Puedes duplicar fichas y buscar por nombre o ID.

Las fichas se guardan automáticamente en IndexedDB de ese navegador. **Copia de seguridad** descarga un JSON con toda la biblioteca, imágenes y sonidos. Haz copias para trasladar el trabajo o antes de borrar datos del navegador. **Importar proyecto** permite añadir fichas o reemplazar la biblioteca; antes de reemplazar se descarga una copia de la actual. Al añadir IDs repetidos, se generan otros libres.

Puedes importar este [ejemplo editable de poción curativa 1d6](ejemplos/pocion_curativa_1d6.forja.json), con imágenes, apilado y curación ya configurados.

## Llevar los objetos a Godot

1. Pulsa **Exportar para Godot**. Elige el ítem seleccionado o toda la biblioteca. Puedes inspeccionar el `.tres` antes de descargar.
2. Con el juego detenido, extrae el ZIP en la raíz de este proyecto, donde está `project.godot`, conservando `assets/`. Godot importará las imágenes y audios.
3. Cada nuevo objeto aparece en `res://assets/items/forja/<id>/<id>.tres`. Es un recurso nativo `DefinicionItem`, `DefinicionLlave` o `DefinicionAntorcha`; incluye escena de suelo, superficies y archivos multimedia.
4. Para colocarlo en una zona, añade un `ItemSueloZona` dentro de `ItemsSuelo` y asigna el recurso a `definicion`, con ID de instancia único y cantidad válida. Para un cofre o inventario inicial, asigna el recurso a una `EntradaInventarioInicial`.
5. Prueba el objeto en el juego. Para el acceso rápido, arrástralo desde la mochila al HUD.

El ZIP incluye instrucciones y `ficha.forja.json` para volver a editar cada objeto. Exportar por sí solo no añade objetos a una partida ni a un mapa.

Las plantillas crean variantes con IDs nuevos. **Actualizar el original del juego** conserva su ID, ruta y UID; al extraer ese paquete se reemplaza la definición compartida original. Haz una copia del proyecto antes de utilizar esta opción.

## Efectos compatibles hoy

- Curación: `recuperacion_pv` guarda la cantidad fija o bono; `recuperacion_pv_dados` y `recuperacion_pv_caras` guardan los dados. El taller genera esas magnitudes y la etiqueta `consumible` automáticamente. Admite de 1 a 9 dados, de 2 a 100 caras y bono de 0 a 9999. El juego tira al usar, limita la curación a los PV máximos y registra fórmula y resultado. Para beber la poción, deja **Sin efecto** al impactar y quita la etiqueta **Arrojable**: el acceso rápido prioriza lanzar si la conserva.
- Impacto: las superficies existentes de humo, fuego y humo venenoso. El objeto se consume al impactar; el veneno conserva la salvación de Voluntad.
- Llaves: patrón de cerradura, comparado por ID.
- Antorchas: duración, radio de visión, atenuación, intensidad, escala y color. **El encendido desde el acceso rápido aún depende del ID `antorcha` en el juego**. Una variante con otro ID se puede equipar; para cambiar la antorcha que sí se enciende, edita la plantilla y actualiza el original.
- Equipo: las etiquetas determinan las ranuras compatibles. En **Información → Clases que pueden equiparlo**, deja todas sin marcar para uso universal o marca una o varias clases. Marca **Arma a dos manos** para impedir el uso de la mano secundaria. Configura sus bonificaciones en **Comportamiento → Efectos de equipo**. Las magnitudes adicionales guardan datos para otras reglas; escribir `curacion = 5` ahí no crea una curación.

## Desarrollo y comprobaciones

Aplicación estática sin paquetes de ejecución: `dist/core.js` contiene el contrato, validaciones y exportador ZIP; `dist/app.js` contiene la interfaz y persistencia. `dist/catalog.js` incluye imágenes reducidas y datos de las cinco plantillas reales. `.gdignore` evita que Godot importe las fuentes del editor web.

Para regenerar el catálogo con Node y `sharp` disponible: `node tools/forja_items/build-catalog.cjs`. No hace falta para utilizar el taller.

Prueba del exportador: `node tools/forja_items/tests/core.test.cjs`. Genera doce fichas de prueba y un ZIP en `.godot/forja_export_test`, sin modificar los assets jugables. El ZIP se puede verificar con `python -m zipfile -t .godot/forja_export_test/paquete.zip`.

Prueba nativa, después de la anterior:

```text
Godot --headless --path . --script res://tests/ejecutar_con_autoloads.gd -- res://tests/interacciones/prueba_exportador_items_web.gd
```

Comprueba carga de recursos, PNG, texto Unicode y escapes, pila/peso, variantes de sprite, llaves, luz, curación y configuración de las tres superficies. Las texturas de prueba se precargan porque `.godot` no pasa por el importador del editor.


## Efectos de equipo

En **Información**, marca una etiqueta compatible (Arma, Anillo, Pecho, etc.). En **Comportamiento → Efectos de equipo**, pulsa **Añadir efecto de equipo** tantas veces como efectos quieras combinar, hasta 16:

Para un arma, escribe su tirada en **Daño del arma al acertar**: `1d3` para espada o `1d2` para daga y bastón. La etiqueta **Arma** es obligatoria. Dos dagas, una en cada mano, tiran `2d2` en un único ataque; el bono de Fuerza se suma una vez: `max(0, floor((FUE efectiva - 1) / 2))`. El valor `0` deja el objeto sin dado propio.

Ejemplo para importar: [Anillo del pulso](ejemplos/anillo_del_pulso.forja.json), con +1 FUE, +2 daño directo, ventaja de ataque y reducción de FUE al objetivo si falla su salvación.

- **Bono de atributo:** FUE, DES o VOL, de −5 a +5 (sin cero). Solo mientras esté equipado. Puedes combinar un beneficio y una contrapartida.
- **Daño adicional:** cantidad fija añadida a un golpe que causa daño. El alcance **Arma de mano principal** solo activa el efecto de la pieza colocada en esa ranura; **Ataques y Bola de fuego** también permite que un anillo, armadura o amuleto aporte daño global a esas acciones. No aumenta daño de superficies ni de veneno/quemado por turno.
- **Protección física:** reduce el daño de cada ataque físico acertado. Las piezas equipadas se suman y un golpe acertado siempre causa al menos 1 punto. No reduce hechizos ni daño periódico.
- **Ventaja / desventaja:** ataque cuerpo a cuerpo, esquiva o pruebas de un atributo. Las fuentes opuestas se compensan conforme a las reglas del motor. Varias filas coincidentes de una misma pieza cuentan como una sola fuente de ventaja.
- **Estado al acertar:** veneno o quemado, con daño fijo por turno y duración en turnos del objetivo.
- **Reducir atributo al acertar:** resta temporalmente FUE, DES o VOL al objetivo, con intensidad y duración. No causa daño por sí solo.

Los dos efectos al acertar permiten elegir **sin salvación** o una salvación de FUE/DES/VOL para evitarlos. No se activan si se falla, el golpe se esquiva o el objetivo ha muerto. Un mismo estado se renueva conservando la intensidad y duración mayores; no suma repetidamente su magnitud. Cada penalización expira al terminar sus turnos.

Los efectos se guardan en `efectos_equipo` del recurso `.tres`; el juego los interpreta automáticamente al equipar mediante el inventario. Guardar/cargar conserva ranuras y objetos sin duplicar los bonos. La cantidad de una pila no multiplica sus efectos. El peso del equipo cuenta para la carga.

Los atributos base se conservan y la ficha muestra valor efectivo y aporte. FUE modifica la carga y DES el presupuesto de movimiento; equipar o retirar efectos no repone pasos del turno actual. Los PV máximos siguen calculándose con los atributos base. Las pruebas mantienen el 1 crítico y el 6 pifia, aunque los bonos eleven el objetivo por encima de 5.

Prueba adicional de integración: tras generar los recursos de prueba con Node, ejecuta `Godot --headless --path . --script res://tests/ejecutar_con_autoloads.gd -- res://tests/interacciones/prueba_equipo_forja.gd`.
