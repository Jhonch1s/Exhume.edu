shader_type canvas_item;

uniform sampler2D textura_niebla: filter_nearest, repeat_enable;
uniform float velocidad_movimiento = 0.02;

// Arrays para soportar múltiples luces
uniform vec2 posiciones_luces[30];
uniform float radios_luces[30];
uniform int cantidad_luces = 0;

void fragment() {
	// Mueve la textura de la niebla en el tiempo
	vec2 uv_animada = UV + vec2(TIME * velocidad_movimiento, TIME * (velocidad_movimiento * 0.5));
	vec4 color_niebla = texture(textura_niebla, uv_animada);
	
	// Opacidad inicial (1.0 = totalmente oscuro)
	float mascara_final = 1.0;
	
	//procesa cada luz recibida desde el script
	for (int i = 0; i < 30; i++) {
		if (i >= cantidad_luces) {
			break;
		}
		
		// cambia lo del vac2(1.1, 1.0) si querees cambiar el tamaño de la niebla al rededor de la pantalla
		// primero es en x (1.1) y lo otro es la y (1.0)
		vec2 st = (UV - posiciones_luces[i]) * vec2(1.1, 1.0); 
		float dist = length(st);
		
		float radio = radios_luces[i];
		
		//calcula el agujero de esa luz específica
		float luz_actual = smoothstep(radio * 0.6, radio, dist);
		
		// Combina los agujeros en la máscara general
		mascara_final = min(mascara_final, luz_actual);
	}
	
	COLOR = vec4(color_niebla.rgb, color_niebla.a * mascara_final);
}