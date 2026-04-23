shader_type canvas_item;

uniform float time : hint_range(0, 1);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR = COLOR * (1.0 - time) + vec4(0.52, 1.0, 0.52, COLOR.a) * time;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
