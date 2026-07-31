shader_type canvas_item;

uniform sampler2D textura_niebla: filter_nearest, repeat_enable;
uniform float velocidad_movimiento = 0.02;
uniform sampler2D textura_mascara: filter_linear, repeat_disable;

void fragment() {
	vec2 uv_animada = UV + vec2(TIME * velocidad_movimiento, TIME * (velocidad_movimiento * 0.5));
	vec4 color_niebla = texture(textura_niebla, uv_animada);
	float mascara = texture(textura_mascara, UV).r;
	COLOR = vec4(color_niebla.rgb, color_niebla.a * mascara);
}
