shader_type canvas_item;

uniform sampler2D textura_niebla : repeat_enable, filter_nearest;
uniform float velocidad_x = 0.015;
uniform float velocidad_y = 0.004;
uniform float brillo : hint_range(0.0, 1.0) = 0.75;
uniform float borde_inicio : hint_range(0.0, 1.0) = 0.25;
uniform float borde_fin : hint_range(0.0, 1.0) = 0.72;

void fragment() {
	vec2 uv_desplazada = UV + vec2(TIME * velocidad_x, sin(TIME * 0.4) * velocidad_y);
	vec4 col = texture(textura_niebla, uv_desplazada);
	
	// Viñeta circular como en daño crítico: centro limpio y oscuro, niebla roja en los bordes
	vec2 centro = UV - vec2(0.5);
	float dist = length(centro);
	float borde = smoothstep(borde_inicio, borde_fin, dist);
	
	// La textura de niebla roja pixelada solo aparece alrededor (en los bordes)
	float alfa = col.a * borde * 0.90;
	
	COLOR = vec4(col.rgb * brillo, alfa);
}
