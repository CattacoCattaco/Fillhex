shader_type canvas_item;

uniform float time : hint_range(0, 1);
uniform sampler2D noise;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float noise_value = texture(noise, UV).r;
	COLOR.a = COLOR.a * max(1.0 - (time / noise_value), 0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
