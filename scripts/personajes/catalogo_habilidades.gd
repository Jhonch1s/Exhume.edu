class_name CatalogoHabilidades
extends RefCounted

const DATOS := {
	"ariete": ["Guerrero", "Ariete", "Activa", "Desplaza visiblemente a un enemigo adyacente hasta 2 casillas, una a una. Se detiene en la casilla donde activa una trampa o un peligro que interrumpe, y ante obstáculos.", &"accion_principal"],
	"agarre": ["Guerrero", "Agarre", "Activa", "Sujeta a un enemigo adyacente: tus próximos 2 pasos lo arrastran a la casilla que abandonas. Ambos sufren el terreno. Termina al comenzar tu siguiente turno.", &"accion_principal"],
	"golpe_desplazante": ["Guerrero", "Golpe desplazante", "Pasiva", "Después de causar daño cuerpo a cuerpo eliges si empujar 1 casilla. Una vez por turno; rechazar no gasta la oportunidad. En Ataque doble puedes rechazar tras el primero y decidir tras el segundo. Empujar tras el primero puede dejar al enemigo fuera de alcance.", &""],
	"inercia": ["Guerrero", "Inercia", "Pasiva", "Al derrotar a un oponente obtienes 2 pasos sin gastar movimiento, una vez por turno. Conservan coste de energía, trampas y peligros.", &""],
	"senuelo": ["Ladrón", "Señuelo", "Activa", "Señala una casilla visible a 4 casillas. NPC a 4 pasos que no vean una amenaza investigan ese lugar durante su próximo turno. No atraviesa muros.", &"accion_adicional"],
	"paso_sombra": ["Ladrón", "Paso de sombra", "Activa", "Se usa en exploración o en tu turno de combate: exige estar Oculto y tener 1 acción adicional libre. Ocultarse también consume esa acción; si ya la gastaste, espera al siguiente turno o recupera recursos en el laboratorio. Salta hasta 3 casillas libres con línea física despejada, conserva sigilo y activa peligros solo al aterrizar.", &"accion_adicional"],
	"escapista": ["Ladrón", "Escapista", "Pasiva", "Una vez por turno, terminar un movimiento real en combate fuera de la visión de todos los oponentes concede Oculto. Atacar o recibir daño lo rompe.", &""],
	"trampero": ["Ladrón", "Trampero", "Pasiva", "No disparas al pisarlas las trampas de presión descubiertas. Quedan armadas para otros. Las desconocidas y superficies siguen siendo peligrosas.", &""],
	"transposicion": ["Mago", "Transposición", "Activa", "Intercambia posición con otro actor visible hasta 5 casillas, con línea física despejada. Ambos sufren las reacciones de sus destinos.", &"accion_principal"],
	"trasvase": ["Mago", "Trasvase", "Activa", "Selecciona fuego, humo o veneno temporal y después una celda sin otra superficie; puede contener un NPC, que sufre la reacción del efecto al recibirlo. Origen y destino deben ser visibles hasta 5 casillas de ti. Conserva duración; no copia ni mueve lava o fogatas.", &"accion_principal"],
	"piromancia_libre": ["Mago", "Piromancia libre", "Pasiva", "Bola de fuego también apunta al suelo vacío: crea fuego durante 3 turnos con el mismo uso y coste de la habilidad inicial.", &""],
	"contagio_arcano": ["Mago", "Contagio arcano", "Pasiva", "Una vez por turno, al causar daño directo puedes transferir tu Quemado o Veneno al blanco superviviente, conservando ticks. Con 2 eliges el estado o desactivas la transferencia.", &""],
}


static func obtener(id: String) -> Dictionary:
	if not DATOS.has(id):
		return {}
	var datos: Array = DATOS[id]
	return {"id": id, "clase": datos[0], "nombre": datos[1], "tipo": datos[2],
		"descripcion": datos[3], "recurso": datos[4],
		"coste": "Sin usos por descanso" if datos[2] == "Pasiva" else
			"1 acción %s y 1 uso por descanso" % ("adicional" if datos[4] == &"accion_adicional" else "principal")}


static func opciones(clase: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for id: String in DATOS:
		if DATOS[id][0] == clase:
			resultado.append(obtener(id))
	return resultado
