shader_type canvas_item;
render_mode unshaded;

uniform vec4 color_contorno : source_color = vec4(0.035, 0.055, 0.085, 1.0);
// 1 rellena el borde de cobertura parcial; 2 y 3 añaden píxeles exteriores.
uniform float grosor_contorno : hint_range(0.0, 3.0, 1.0) = 1.0;
varying vec4 modulacion;

void vertex() {
	modulacion = COLOR;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec4 resultado = original;
	// Rellenar detrás de la cobertura parcial sin tocar el interior opaco.
	// El radio exterior es un píxel menor que en la versión anterior.
	if (original.a < 1.0 && grosor_contorno > 0.0) {
		float vecino = original.a;
		for (int y = -3; y <= 3; y++) {
			for (int x = -3; x <= 3; x++) {
				if (float(max(abs(x), abs(y))) <= grosor_contorno - 1.0) {
					vec2 muestra = UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
					if (all(greaterThanEqual(muestra, vec2(0.0))) && all(lessThanEqual(muestra, vec2(1.0)))) {
						vecino = max(vecino, texture(TEXTURE, muestra).a);
					}
				}
			}
		}
		float relleno = color_contorno.a * step(0.01, vecino) * (1.0 - original.a);
		float alfa = original.a + relleno;
		vec3 rgb = (original.rgb * original.a + color_contorno.rgb * relleno) / max(alfa, 0.00001);
		resultado = vec4(rgb, alfa);
	}
	// Preserva la atenuación del dado descartado que aplica el modal.
	COLOR = resultado * modulacion;
}

