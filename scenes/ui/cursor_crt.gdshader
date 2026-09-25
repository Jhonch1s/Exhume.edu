shader_type canvas_item;
render_mode unshaded;

uniform float separacion_color_px : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float fuerza_mascara : hint_range(0.0, 1.0, 0.01) = 0.58;
uniform float brillo_mascara : hint_range(0.0, 1.0, 0.01) = 0.95;

float luminancia(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 mascara_fosforo(float x) {
	int columna = int(mod(x, 4.0));
	if (columna == 0) return vec3(1.0, 0.125, 0.02);
	if (columna == 1) return vec3(0.125, 1.0, 0.125);
	if (columna == 2) return vec3(0.02, 0.125, 1.0);
	return vec3(0.125, 0.02, 0.125);
}

void fragment() {
	vec4 centro = texture(TEXTURE, UV);
	vec2 desplazamiento = vec2(
		separacion_color_px / float(textureSize(TEXTURE, 0).x),
		0.0
	);
	vec3 color = vec3(
		texture(TEXTURE, UV + desplazamiento).r,
		centro.g,
		texture(TEXTURE, UV - desplazamiento).b
	);
	vec3 enmascarado = color * mix(vec3(1.0), mascara_fosforo(FRAGCOORD.x), fuerza_mascara);
	float luz_original = luminancia(color);
	float luz_mascara = max(luminancia(enmascarado), 0.001);
	enmascarado *= mix(1.0, luz_original / luz_mascara, brillo_mascara);
	float preservar_altas = smoothstep(0.68, 1.0, luz_original);
	enmascarado = mix(enmascarado, color, preservar_altas);
	COLOR = vec4(clamp(enmascarado, vec3(0.0), vec3(1.0)), centro.a * COLOR.a);
}
