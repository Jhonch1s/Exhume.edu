# Pantallas de menú

Esta carpeta contiene las pantallas de navegación externas a la partida.

Pantallas actuales:

- `menu_principal.tscn`: entrada general al juego.
- `nueva_partida.tscn`: inicio futuro del flujo de creación de una expedición.
- `personajes.tscn`: selección de personajes existentes.
- `opciones.tscn`: configuración del juego.

Cuando aparezcan elementos reutilizables (botón con icono, diálogo, selector de atributos,
tarjeta de personaje), se recomienda guardarlos como escenas independientes en
`scenes/menu/componentes/`. Actualmente contiene el menú colgante y la tabla reutilizable
para cada opción del menú principal.

Los recursos gráficos, tipografías, temas y sonidos no deben guardarse junto a estas escenas;
su ubicación común es `res://assets/ui/`.
