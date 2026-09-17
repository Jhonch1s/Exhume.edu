# Dado de basalto y brasas

Editable: `dadico_trabajo.blend`. Copias previas al cambio: `originales/dadico_trabajo.blend` y `originales/dadico.glb`.

Se conservaron los 848 vértices, 536 polígonos, tres superficies, origen y transformaciones. La superficie anteriormente llamada grey sigue siendo el cuerpo. Solo se renovaron UV y materiales: Basalto_tallado, Brasas_ranuras y Basalto_cuerpo. Rugosidad 0.9, metalicidad 0, emisión 0.95 en las ranuras. Color y normales tangentes se hornean a 1024 px y se empaquetan tanto en el blend como en el GLB; no dependen de nodos procedurales en Godot. Los PNG dadico_dadico_* son extracciones del importador de GLB.

La vista conserva cámara, tamaño y calibración 1→270°, 2→30°, 3→150°, 4→90°, 5→330°, 6→210°. Se eliminaron los reemplazos planos de materiales por código y se añadió ambiente tenue y MSAA 4x. Cada SubViewport conserva su mundo independiente. MotorDados y la lógica del modal no se modificaron.

## Comprobación

Abrir `tests/tiradas/demo_modal_dados.tscn` en Godot y ejecutar con F6; pulsar «Lanzar prueba». En ventaja aparecen dos dados; al terminar, el no seleccionado se atenúa según el comportamiento existente del modal.

Prueba automatizada con render real (no usar --headless):

```powershell
& C:/godot/Godot_v4.7-stable_win64_console.exe --path C:/godot/Exhume.edu --rendering-method gl_compatibility --windowed --resolution 1920x1080 --script res://tests/tiradas/verificar_acabado_dado.gd
```

Genera `tests/tiradas/capturas_dadico/seis_caras.png`, `dos_dados_giro.png` y `dos_dados_resultado.png`. Comprueba mundos distintos y usa una tirada de MotorDados en la demostración real. Validado con OpenGL 3.3 / Compatibility en NVIDIA RTX 3060. La emisión es visible sin bloom y conserva el color rojo y el contorno de los símbolos.

Para regenerar desde la copia original:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' -b assets/art_source/blender/dados/originales/dadico_trabajo.blend --python tools/acabar_dadico.py
```

## Ajuste de paleta

Piedra inspirada en walls_cave_tall.png: sombras #293038, medios #505768 y luces #7a7e91. Runas entre #c52632 y #ff6036 con emisión 0.95. Los colores sRGB se convierten a lineal antes del horneado. La vista aplica además el filtro semipixelado descrito debajo.


## Filtro semipixelado

VistaDado3D expone tamano_pixel (1 a 6) en el Inspector. Valor inicial: 3. Usa stretch_shrink del SubViewportContainer y filtrado nearest; renderiza a un tercio de resolución por eje conservando el tamaño visual, la cámara y la transparencia. No requiere un shader adicional ni altera los materiales del GLB. MSAA 4x conserva cobertura parcial en líneas finas.

1 desactiva el efecto; 2 es sutil; 3 es el ajuste actual; 4 a 6 producen píxeles más grandes. Ajustar la propiedad del nodo VistaDado3D y ejecutar la escena. La prueba verificar_acabado_dado.gd genera seis_caras_sin_filtro.png y seis_caras_pixelado.png para comparar las mismas rotaciones, además de capturas del giro y resultado con dos dados.


## Contorno exterior

contorno_dado.gdshader procesa únicamente el alfa del SubViewport. Solo añade color donde el píxel original es totalmente transparente: no cambia la piedra, las runas ni las aristas internas. El material es local a cada instancia y respeta la modulación del modal. En VistaDado3D, Grosor Contorno (0 desactiva, 1 por defecto, hasta 3) se mide en píxeles del render reducido; Color Contorno permite elegir el tono. Se conserva el Tamano Pixel 5 elegido en la escena por el usuario. Verificado en GL Compatibility con seis caras y tirada doble; capturas seis_caras_contorno.png y seis_caras_sin_contorno.png.

