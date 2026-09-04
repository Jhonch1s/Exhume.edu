shader_type canvas_item;

uniform vec2 posicion_jugador;
uniform vec2 radio = vec2(64.0, 52.0);

varying vec2 posicion_mundo;

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 distancia = (posicion_mundo - posicion_jugador) / radio;
	if (length(distancia) < 1.0) {
		discard;
	}
	COLOR = color;
}
