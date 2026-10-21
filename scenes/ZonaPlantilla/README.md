# Plantilla de zona

Duplica `zona_plantilla.tscn` en una carpeta nueva y cambia el nombre del nodo raíz.
La plantilla ya contiene las capas que leen `EscenarioBase`, `TableroGrid`, la cámara,
la niebla y el validador de contenido. Incluye oclusión en `CapaParedes`, contenedores
para fuentes de luz, mecanismos, puertas, trampas, decoraciones, cofres, personajes,
guías, efectos de superficie e ítems de suelo, además de las capas de terreno y
peligros.

Las dos capas de decoración ofrecen tanto los atlas originales de la plantilla
como los del TemploDeLasTrampas: rocas y ruinas no caminables en
`CapaDecoracionNoCaminable`; rocas, ruinas, huesos, cadenas y restos de suelo en
`CapaDecoracion`. `TramperoSinRostro` es una escena aparte en
`scenes/decoraciones/` que se puede instanciar bajo `Interactuables/Decoraciones`.

Antes de ejecutar una zona, pinta al menos una casilla caminable en `CapaSuelo` y
coloca `PuntosSpawn/PuntoSpawnEntrada` sobre ella. El marcador tiene id `entrada` y
se ajusta al centro de la casilla en el editor. El resto de contenedores puede quedar
vacío hasta que el diseño lo necesite. Ejecutar la escena con F6 la envuelve en
`EscenarioBase`, igual que Zona1 y TemploDeLasTrampas.

`../DescansoCuevas/DescansoCuevas.tscn` es el primer escenario creado con esta
estructura: trae un suelo inicial editable, paredes perimetrales, punto de entrada
y una fogata interactuable. Se usa al viajar al campamento.
