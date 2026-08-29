# Tiles de superficies

Cada superficie guarda aquí sus PNG exportados, dentro de `sources/`. Los archivos
editables de Aseprite viven en la ruta equivalente bajo
`assets/art_source/aseprite/tiles/surface_effects/`.

Carpetas preparadas: `fire`, `poison`, `smoke`, `spikes`, `web`, `mud` e `ice`.

Convenciones iniciales:

- celda isométrica base: `64x32`;
- nombres en inglés y `snake_case`;
- pinchos: altura mecánica/visual `1`, con máscaras de fog `explored` y `hidden`;
- telaraña, lodo e hielo: superficie de suelo, sin sombra propia mientras no
  sobresalgan del plano;
- el atlas puede crecer horizontalmente si una superficie necesita variantes o
  cuadros de animación.

Para pinchos se esperan, como mínimo:

- `spikes_isometric.png`;
- `spikes_fog_explored.png`;
- `spikes_fog_hidden.png`.

Las máscaras deben conservar el mismo tamaño y alineación del atlas principal para
que las capas usen las mismas regiones. El fuego no usa máscaras propias: mientras
existe ilumina su celda; al desaparecer vuelve a verse el fog del terreno inferior.
