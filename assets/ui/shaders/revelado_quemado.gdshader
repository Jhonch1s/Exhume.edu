shader_type canvas_item;

uniform sampler2D retrato_nuevo : source_color;
uniform float avance : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 anterior = texture(TEXTURE, UV);
	vec4 nuevo = texture(retrato_nuevo, UV);
	float ruido = (sin(UV.x * 61.0) + sin(UV.x * 137.0) * 0.5) * 0.012;
	float borde = avance + ruido;
	float revelado = smoothstep(borde + 0.008, borde - 0.008, UV.y);
	float carbon = 1.0 - smoothstep(0.006, 0.035, abs(UV.y - borde));
	vec4 color = mix(anterior, nuevo, revelado);
	color.rgb = mix(color.rgb, vec3(0.01), carbon * 0.9);
	COLOR = color;
}
