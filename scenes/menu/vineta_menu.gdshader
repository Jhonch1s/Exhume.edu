shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 color_sombra : source_color = vec4(0.018, 0.008, 0.035, 0.76);
uniform vec2 centro_visual = vec2(0.36, 0.47);
uniform float inicio_bordes : hint_range(0.0, 1.5, 0.01) = 0.42;
uniform float fin_bordes : hint_range(0.0, 1.5, 0.01) = 0.70;
uniform float inicio_derecha : hint_range(0.0, 1.0, 0.01) = 0.56;
uniform float fuerza_derecha : hint_range(0.0, 1.0, 0.01) = 0.82;

void fragment() {
	vec2 distancia = UV - centro_visual;
	distancia.x *= 1.78;
	float borde = smoothstep(inicio_bordes, fin_bordes, length(distancia));
	float derecha = smoothstep(inicio_derecha, 1.0, UV.x) * fuerza_derecha;
	float alpha = color_sombra.a * clamp(max(borde, derecha), 0.0, 1.0);
	COLOR = vec4(color_sombra.rgb, alpha);
}
