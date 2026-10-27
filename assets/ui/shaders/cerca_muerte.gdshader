shader_type canvas_item;

uniform vec4 color_sangre : source_color = vec4(0.6, 0.02, 0.02, 1.0);
uniform float intensidad : hint_range(0.0, 1.0) = 0.0;
uniform float frecuencia_pulso = 4.2;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Muy leve vibración de pantalla proporcional a la intensidad
	float pulso = sin(TIME * frecuencia_pulso);
	float vibracion = pulso * 0.0015 * intensidad;
	uv += vec2(vibracion * 0.7, vibracion);
	
	// Viñeta circular desde el centro hacia los bordes
	vec2 centro = uv - vec2(0.5);
	float dist = length(centro);
	
	// Factor de borde: oscuro y rojo en los extremos
	float borde = smoothstep(0.28, 0.75, dist);
	
	// Modulación de latido
	float modulacion_latido = 0.75 + 0.25 * max(0.0, pulso);
	
	float alfa_efecto = borde * intensidad * modulacion_latido * 0.85;
	
	COLOR = vec4(color_sangre.rgb, alfa_efecto);
}
