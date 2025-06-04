shader_type canvas_item;

uniform vec4 flash_colour: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool hit_flash_on = false;
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0;
void fragment(){
	vec4 texture_colour = texture(TEXTURE, UV);
	vec3 final_rgb = hit_flash_on ? flash_colour.rgb: texture_colour.rgb;
	COLOR = vec4(final_rgb, texture_colour.a * alpha_override);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
