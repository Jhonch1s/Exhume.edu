shader_type canvas_item;

uniform vec4 orange_tint : source_color = vec4(0.811, 0.545, 0.18, 0.8);
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    vec3 orange_mix = mix(tex_color.rgb, orange_tint.rgb, mix_amount);

    COLOR = vec4(orange_mix, COLOR.a);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
