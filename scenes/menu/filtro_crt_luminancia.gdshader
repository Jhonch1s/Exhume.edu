// Adaptacion para postproceso en pantalla del shader CRT de Harrison Allen (CC0).
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear;
uniform int tipo_mascara : hint_enum("Nula:0", "Puntos:1", "Rejilla:2", "Rejilla ancha:3", "Rejilla ancha suave:4") = 4;
uniform float curvatura : hint_range(0.0, 0.25, 0.001) = 0.03;
uniform float separacion_color_px : hint_range(0.0, 3.0, 0.01) = 0.45;
uniform float fuerza_mascara : hint_range(0.0, 1.0, 0.01) = 0.72;
uniform float brillo_mascara : hint_range(0.0, 1.0, 0.01) = 0.95;
uniform float aspecto : hint_range(0.4, 1.0, 0.0001) = 0.5625;

vec2 deformar(vec2 uv) {
	uv -= 0.5;
	uv.x /= aspecto;
	float deformacion = dot(uv, uv) * curvatura - curvatura * 0.25;
	uv /= 1.0 - deformacion;
	uv.x *= aspecto;
	return uv + 0.5;
}

vec3 mascara_fosforo(vec2 pixel) {
	if (tipo_mascara == 0) {
		return vec3(1.0);
	}

	int x = int(mod(pixel.x, 4.0));
	int y = int(mod(pixel.y, 4.0));

	if (tipo_mascara == 1) {
		int indice = int(mod(float(y * 2 + x), 4.0));
		if (indice == 0) return vec3(1.0, 0.08, 0.08);
		if (indice == 1) return vec3(0.08, 1.0, 0.08);
		if (indice == 2) return vec3(0.08, 0.08, 1.0);
		return vec3(0.08);
	}

	if (tipo_mascara == 2) {
		return int(mod(pixel.x, 2.0)) == 0
			? vec3(0.08, 1.0, 0.08)
			: vec3(1.0, 0.08, 1.0);
	}

	if (tipo_mascara == 3) {
		if (x == 0) return vec3(1.0, 0.04, 0.04);
		if (x == 1) return vec3(0.04, 1.0, 0.04);
		if (x == 2) return vec3(0.04, 0.04, 1.0);
		return vec3(0.04);
	}

	if (x == 0) return vec3(1.0, 0.125, 0.02);
	if (x == 1) return vec3(0.125, 1.0, 0.125);
	if (x == 2) return vec3(0.02, 0.125, 1.0);
	return vec3(0.125, 0.02, 0.125);
}

float luminancia(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 uv = deformar(SCREEN_UV);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec2 tamano = vec2(textureSize(pantalla, 0));
		vec2 offset = vec2(separacion_color_px / tamano.x, 0.0);
		vec3 centro = texture(pantalla, uv).rgb;
		vec3 color = vec3(
			texture(pantalla, uv + offset).r,
			centro.g,
			texture(pantalla, uv - offset).b
		);

		vec3 patron = mascara_fosforo(FRAGCOORD.xy);
		vec3 color_enmascarado = color * mix(vec3(1.0), patron, fuerza_mascara);
		float luz_original = luminancia(color);
		float luz_mascara = max(luminancia(color_enmascarado), 0.001);
		color_enmascarado *= mix(1.0, luz_original / luz_mascara, brillo_mascara);

		// En las luces altas se reduce el patron para no quemar ni oscurecer el haz.
		float preservar_altas = smoothstep(0.68, 1.0, luz_original);
		color_enmascarado = mix(color_enmascarado, color, preservar_altas);
		COLOR = vec4(clamp(color_enmascarado, vec3(0.0), vec3(1.0)), 1.0);
	}
}
