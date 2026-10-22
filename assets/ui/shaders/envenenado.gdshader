shader_type canvas_item;

uniform vec4 green_tint : source_color = vec4(0.2, 0.8, 0.2, 1.0);
uniform float mix_amount : hint_range(0.0, 1.0) = 0.3;



void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//obtener color actual de textura viewport
    vec4 tex_color = texture(TEXTURE, UV);

    //Mezclar el color con el verde
    vec3 green_mix = mix(tex_color.rgb, green_tint.rgb, mix_amount);

    // disfruta
    COLOR = vec4(green_mix, COLOR.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
