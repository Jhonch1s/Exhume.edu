shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 color_niebla : source_color = vec4(0.78, 0.82, 0.86, 0.82);
uniform float escala_ruido : hint_range(1.0, 12.0, 0.1) = 4.2;
uniform float velocidad : hint_range(-0.2, 0.2, 0.001) = 0.018;
uniform float densidad : hint_range(0.0, 1.0, 0.01) = 0.26;
uniform float borde_superior : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float borde_inferior : hint_range(0.0, 1.0, 0.01) = 0.94;
uniform float inicio_desvanecido_menu : hint_range(0.0, 1.0, 0.01) = 0.64;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float ruido(vec2 p) {
	vec2 celda = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash(celda);
	float b = hash(celda + vec2(1.0, 0.0));
	float c = hash(celda + vec2(0.0, 1.0));
	float d = hash(celda + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 p) {
	float valor = 0.0;
	float amplitud = 0.5;
	for (int i = 0; i < 5; i++) {
		valor += ruido(p) * amplitud;
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitud *= 0.5;
	}
	return valor;
}

void fragment() {
	vec2 uv = UV;
	vec2 movimiento = vec2(TIME * velocidad, sin(TIME * 0.07) * 0.08);
	vec2 coordenada = vec2(uv.x, uv.y * 0.65) * escala_ruido + movimiento;
	float nube_grande = fbm(coordenada);
	float detalle = fbm(coordenada * 1.7 - vec2(TIME * velocidad * 0.35, 0.0));
	float forma = smoothstep(densidad, 1.0, mix(nube_grande, detalle, 0.35));
	float entrada = smoothstep(borde_superior, borde_superior + 0.16, uv.y);
	float salida = 1.0 - smoothstep(borde_inferior - 0.10, borde_inferior, uv.y);
	float mascara_menu = 1.0 - smoothstep(inicio_desvanecido_menu, 0.94, uv.x);
	float alpha = color_niebla.a * forma * entrada * salida * mascara_menu;
	COLOR = vec4(color_niebla.rgb, alpha);
}
