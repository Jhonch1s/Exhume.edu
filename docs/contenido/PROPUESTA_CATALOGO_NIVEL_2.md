# Catálogo de nivel 2

Estado: catálogo aprobado por el usuario e implementado en el corte de nivel 2.
El nombre de archivo se conserva para mantener los enlaces de la propuesta.
Por clase se ofrecen dos
activas y dos pasivas, y se aprende exactamente una de las cuatro. La habilidad
inicial se conserva. La elección y lo aprendido deben persistir.

El objetivo es dar herramientas para resolver situaciones de distintas formas.
Cada recompensa debe permitir al menos una interacción nueva con posiciones,
percepción, objetos o estados. El balance queda sujeto a pruebas de juego.

## Guerrero: decidir dónde ocurre el combate

| Tipo | Nombre | Efecto | Ejemplo de uso |
|---|---|---|---|
| Activa | Ariete | Empuja visiblemente a un enemigo adyacente hasta dos casillas en línea recta, una a una. Se detiene en cualquier trampa que active, ante obstáculos o peligros que interrumpan. Sin daño directo añadido. | Echar a un guardia sobre una trampa, separarlo de sus compañeros o liberar una puerta. |
| Activa | Agarre | Sujetas a un enemigo adyacente hasta el inicio de tu siguiente turno. Tus siguientes dos pasos pueden arrastrarlo a la casilla que abandonas, consumiendo tu movimiento normal. Ambos sufren las reacciones de sus recorridos. | Sacar a alguien de una cobertura o conducirlo hacia un peligro, asumiendo el riesgo de acercarte tú también. |
| Pasiva | Golpe desplazante | Una vez por turno, un golpe cuerpo a cuerpo que aciertas permite empujar al blanco una casilla, si decides hacerlo. El golpe conserva su daño normal. | Usar Ataque doble para desplazar con el último golpe y preparar el terreno para otra acción. |
| Pasiva | Inercia | Al derrotar a un enemigo puedes avanzar inmediatamente hasta dos casillas sin gastar movimiento. Máximo una vez por turno. Ese avance conserva peligros y reacciones. | Atravesar la brecha que deja una baja, alcanzar cobertura o salir de una nube antes de terminar el turno. |

Detalles: Ariete y Agarre cuestan una acción principal y su propio
uso por descanso. Una casilla bloqueada detiene el desplazamiento, sin daño
por colisión adicional. Agarre se rompe si no puede conservar la adyacencia,
si muere alguno, al terminar el encuentro o al empezar el siguiente turno del
Guerrero; tampoco hace inmune a los ataques del agarrado. No permite arrastrar
a través de paredes ni casillas ocupadas. No se concede ataque gratis con Inercia.

Golpe desplazante ofrece **Empujar / No empujar después de causar daño**, si el
blanco sobrevive y puede desplazarse. Rechazar conserva la oportunidad del turno.
Con Ataque doble puedes rechazar tras el primer golpe y decidir de nuevo si el
segundo causa daño. Empujar tras el primero puede dejar al blanco fuera del
alcance del segundo. No requiere activar un modo antes de atacar.

## Ladrón: manipular la atención y las rutas

| Tipo | Nombre | Efecto | Ejemplo de uso |
|---|---|---|---|
| Activa | Señuelo | Coloca un señuelo sonoro en una casilla visible a cuatro casillas. Los NPC que lo oigan y no vean un oponente investigan esa posición durante su próximo turno. | Hacer que un guardia abandone una puerta o se acerque a una trampa antes de pasar oculto. |
| Activa | Paso de sombra | Mientras estás oculto, te desplazas instantáneamente a una casilla libre y visible a tres casillas, con paso físico despejado entre origen y destino. Conservas el sigilo. Reaccionan los elementos del destino. | Cruzar una franja de fuego o pasar entre dos líneas de vigilancia sin pisar las casillas intermedias. |
| Pasiva | Escapista | Una vez por turno, terminar un desplazamiento en combate fuera de la visión de todos los oponentes te otorga Oculto durante un turno propio, sin gastar el uso de Ocultarse. Atacar o recibir daño lo rompe. | Doblar una esquina o crear cobertura con humo para perder al perseguidor y cambiar de ruta. |
| Pasiva | Trampero | No activas al pisarlas las trampas de presión que ya descubriste. Siguen armadas para otros actores; las trampas sin descubrir y las superficies peligrosas conservan su efecto. | Cruzar una trampa y dejar que el enemigo que te persigue la active. |

Detalles: Señuelo y Paso de sombra cuestan una acción adicional y
su uso individual por descanso. Oír Señuelo requiere estar a cuatro casillas
de él y tener un camino físico; no atraviesa muros cerrados ni obliga a ignorar
un enemigo visible. Investigar puede acabar antes si aparece un oponente real.
Paso de sombra no atraviesa muros, puertas cerradas ni ocupantes; su diferencia
con caminar es que no pisa las casillas intermedias. Una trampa o daño en el
destino sí se aplica y puede romper el sigilo.

Se permite tanto en exploración como en tu turno de combate, con **Oculto y una
acción adicional libre**. Ocultarse también consume esa acción: si la agotaste,
espera al siguiente turno. La ficha Oculta se muestra al 40% de opacidad y el
HUD indica sus turnos restantes; recupera opacidad al romperse o expirar el sigilo.

Escapista no genera bucles de ocultamiento al quedarse quieto: exige terminar
un desplazamiento real durante un encuentro, y solo dispara una vez en ese
turno. Trampero no desactiva mecanismos: cambia únicamente la reacción a la
entrada del Ladrón sobre una placa descubierta.

## Mago: cambiar las relaciones entre peligros y objetivos

| Tipo | Nombre | Efecto | Ejemplo de uso |
|---|---|---|---|
| Activa | Transposición | Intercambias posición con otro actor visible hasta cinco casillas, con línea de efecto física. Ambos activan las reacciones del destino. | Escapar de un fuego dejando allí a un enemigo, o sacar a un aliado de una nube venenosa. |
| Activa | Trasvase | Trasladas una superficie temporal de fuego, humo o veneno desde una casilla visible a otra libre de superficies. Ambas están hasta cinco casillas de ti y con línea de efecto física. Conserva su duración restante. | Llevar una nube hacia un grupo de enemigos o mover el fuego que impide abrir un cofre. |
| Pasiva | Piromancia libre | Bola de fuego también puede apuntar a suelo libre y crear fuego durante tres turnos, en vez de impactar a un enemigo. Mantiene su coste y su único uso por descanso. | Encender un paso para iluminar, cortar una ruta o preparar una zona de peligro. |
| Pasiva | Contagio arcano | Una vez por turno, al causar daño directo con un ataque puedes transferir al blanco uno de tus estados Quemado o Veneno. Se retira de ti y conserva los ticks pendientes. Es opcional. | Arriesgarse a atravesar veneno para llevarlo hasta un enemigo y librarse de él al acertar. |

Detalles: Transposición y Trasvase cuestan una acción principal y
su uso individual por descanso. Transposición exige posiciones legales para
ambos actores; no cambia bandos, turnos ni recursos. Trasvase mueve una sola
superficie temporal completa, no copia, no reinicia duración y no mueve lava,
terreno, antorchas, fogatas ni mecanismos. Una superficie con un actor encima
puede ser origen. El destino puede contener un NPC, que recibe la reacción de
la superficie trasladada al colocarla: fuego aplica Quemado y veneno conserva
su salvación normal. El NPC permanece en su casilla. El destino debe estar libre
de otras superficies; el traslado no vuelve a activar terreno ni trampas. Las combinaciones
entre superficies quedan fuera de esta habilidad para su primer corte.

Piromancia libre requiere que la casilla admita una superficie y esté libre de
actores y de otra superficie; crear fuego no ocasiona un impacto adicional a un
ocupante. Al apuntar a un enemigo, la Bola de fuego inicial siempre enciende su
celda durante tres turnos, salga o no el 50% de Quemado. Si ya hay fuego, renueva
su duración sin duplicarlo. Mantiene el daño directo y el único uso originales;
Piromancia libre permite además elegir suelo vacío.

Contagio arcano solo ocurre si el blanco sobrevive al daño directo,
no desde daño periódico, y no transfiere parálisis, sigilo ni otro tipo de estado.
Si ya tiene el mismo estado, conserva el que tenga más ticks pendientes,
sin sumar duraciones ni duplicar pulsos de daño.

## Criterios para el corte jugable

- La pantalla muestra las cuatro opciones de la clase y confirma una sola.
- Aprender una activa la añade al HUD con su contador individual `1/1`.
  Aprender una pasiva modifica las acciones existentes y se muestra en la ficha.
- Cada activa mantiene el gasto al ejecutar un intento válido; cancelar o
  seleccionar un objetivo inválido no cobra. Se repone solo al descansar.
- Cada paso forzado valida ocupación y aplica las reacciones correspondientes.
  El daño y la muerte interrumpen cadenas que ya no puedan continuar.
- La previsualización explica qué casillas se pisan y quién puede sufrir sus
  efectos. Las opciones voluntarias de pasivas requieren un control accesible.
- Guardar/cargar conserva aprendizaje, usos, límites por turno y cualquier
  estado persistente nuevo. No renueva gratis duraciones ni oportunidades.

La implementación reutiliza casillas, visibilidad, trampas, superficies, estados
y recursos de turno. `scripts/personajes/catalogo_habilidades.gd` define las
opciones; `scripts/interacciones/habilidades_nivel_dos.gd` resuelve sus efectos.
La ficha guarda aprendizaje y estado; el escenario integra entrada, HUD y turnos.
Hay [arenas de las tres clases](../../scenes/pruebas_habilidades/README.md).
