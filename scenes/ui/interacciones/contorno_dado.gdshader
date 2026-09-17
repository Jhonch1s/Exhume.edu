shader_type canvas_item;
render_mode unshaded;

uniform vec4 color_contorno : source_color = vec4(0.035, 0.055, 0.085, 1.0);
// Un píxel del render reducido: acompaña la cuadrícula del filtro pixelado.
uniform float grosor_contorno : hint_range(0.0, 3.0, 1.0) = 1.0;
varying vec4 modulacion;

void vertex() {
	modulacion = COLOR;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec4 resultado = original;
	// No modificar ningún píxel que ya pertenezca al modelo, ni siquiera
	// la cobertura parcial del antialiasing. Solo extender su silueta afuera.
	if (original.a == 0.0 && grosor_contorno > 0.0) {
		float vecino = 0.0;
		for (int y = -3; y <= 3; y++) {
			for (int x = -3; x <= 3; x++) {
				if (float(max(abs(x), abs(y))) <= grosor_contorno) {
					vec2 muestra = UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
					if (all(greaterThanEqual(muestra, vec2(0.0))) && all(lessThanEqual(muestra, vec2(1.0)))) {
						vecino = max(vecino, texture(TEXTURE, muestra).a);
					}
				}
			}
		}
		resultado = vec4(color_contorno.rgb, color_contorno.a * step(0.01, vecino));
	}
	// Preserva la atenuación del dado descartado que aplica el modal.
	COLOR = resultado * modulacion;
}

