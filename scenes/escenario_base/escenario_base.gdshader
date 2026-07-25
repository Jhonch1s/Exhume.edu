shader_type canvas_item;

uniform sampler2D textura_niebla: filter_nearest, repeat_enable;
uniform vec2 posicion_jugador;
uniform float radio_luz = 0.15;
uniform float velocidad_movimiento = 0.02;

void fragment() {
    //mueve la textura de la niebla en el tiempo
    vec2 uv_animada = UV + vec2(TIME * velocidad_movimiento, TIME * (velocidad_movimiento * 0.5));
    vec4 color_niebla = texture(textura_niebla, uv_animada);
    
    // calcula la distancia hacia la ficha/antorcha
    float dist = distance(UV, posicion_jugador);
    float mascara_luz = smoothstep(radio_luz * 0.6, radio_luz, dist);
    
    COLOR = vec4(color_niebla.rgb, color_niebla.a * mascara_luz);
}