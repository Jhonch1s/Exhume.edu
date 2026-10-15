# Comprobación de campos de visión de NPC

Abrir `tests/interacciones/escena_facciones_npc.tscn` en Godot y ejecutar F6.
El cartel de la escena recuerda V para alternar la superposición, clic derecho
ar y C para cargar en reposo. Usar
`inicio_hostil = false` en el nodo raíz para empezar con Guardia neutral.

1. Pulsar V. Los campos de Guardia y Compañero fijo se ven grises; el de Amistoso,
   verde. Si Trompo está visible, su campo es gris aunque no pueda combatir.
   Compañero lejano no debe revelar su ubicación mientras esté oculto. Las
   casillas fuera de la visibilidad actual del jugador tampoco se colorean.
2. Moverse con clic derecho. Los campos siguen a los NPC visibles y desaparecen
   cuando dejan de estar a la vista. Una pared o humo opaco recortan el campo de
   cada NPC; no se pinta a través del obstáculo.
3. Atacar a Guardia. Mientras él y su compañero defienden el bando oponente,
   sus campos son rojos aunque su relación siga neutral. Huir hasta cerrar el
   encuentro: si siguen neutrales, vuelven a gris. La penalización de actitud
   corresponde sólo al NPC atacado.
4. Pulsar V de nuevo para ocultar la capa. Derrotar a un NPC y volver a activar
   V: el cadáver no aporta campo. Guardar con K, cargar con C y comprobar que
   los campos reflejan las posiciones, relaciones y bandos restaurados. La capa
   es sólo visual y su estado encendido/apagado no se guarda.
5. Opcional: reiniciar F6 con `inicio_hostil = true`. Guardia empieza rojo; si
   Amistoso se incorpora al bando del jugador, permanece verde. V funciona
   también durante los turnos NPC, siempre que no haya una ventana modal abierta.

La prueba automática `tests/interacciones/prueba_facciones_npc.tscn` protege los
datos dibujados; el recorrido manual comprueba el aspecto real en pantalla.
El estado `VISIBLE` todavía depende de la iluminación actual del juego; separar
luz, percepción del jugador y niebla de guerra es trabajo posterior.

El 15-10-2026 el usuario la vio en juego y confirmó que funciona y que por
ahora es suficiente. No detalló qué pasos de este recorrido completó.
