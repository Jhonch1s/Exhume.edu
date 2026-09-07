shader_type canvas_item;

uniform vec2 posicion_jugador;
uniform vec2 radio = vec2(90.0, 60.0);
uniform float ancho_borde : hint_range(0.0, 24.0, 1.0) = 12.0;

varying vec2 posicion_mundo;

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float bayer_2x2(vec2 bits) {
	return 2.0 * bits.x + 3.0 * bits.y - 4.0 * bits.x * bits.y;
}

float bayer_4x4(vec2 posicion) {
	vec2 pixel = mod(floor(posicion), 4.0);
	return (4.0 * bayer_2x2(mod(pixel, 2.0)) + bayer_2x2(floor(pixel / 2.0)) + 0.5) / 16.0;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 distancia = (posicion_mundo - posicion_jugador) / radio;
	float distancia_borde = (length(distancia) - 1.0) * min(radio.x, radio.y);
	float semiancho = max(ancho_borde * 0.5, 0.001);
	float cobertura = smoothstep(-semiancho, semiancho, distancia_borde);
	if (cobertura < bayer_4x4(posicion_mundo)) {
		discard;
	}
	COLOR = color;
}
