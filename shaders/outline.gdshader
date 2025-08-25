shader_type canvas_item;

uniform vec3 outline_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float outline_thickness = 42.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	vec2 top_offset = -1.0 * outline_thickness * vec2(0.0, TEXTURE_PIXEL_SIZE.y);
	vec2 bot_offset = outline_thickness * vec2(0.0, TEXTURE_PIXEL_SIZE.y);
	vec2 left_offset = -1.0 * outline_thickness * vec2(TEXTURE_PIXEL_SIZE.x, 0.0);
	vec2 right_offset = outline_thickness * vec2(TEXTURE_PIXEL_SIZE.x, 0.0);

	// if current fragment is opaque (not transparent), return its original color
	if (color.a == 0.0) {
		// sample neighboring fragments alpha values to see if they are not transparent
		float alpha_sum = 0.0;
		alpha_sum += texture(TEXTURE, vec2(UV.x, max(UV.y + top_offset.y, 0.0))).a;
		alpha_sum += texture(TEXTURE, vec2(UV.x, min(UV.y + bot_offset.y, 1.0))).a;
		alpha_sum += texture(TEXTURE, vec2(max(UV.x + left_offset.x, 0.0), UV.y)).a;
		alpha_sum += texture(TEXTURE, vec2(min(UV.x + right_offset.x, 1.0), UV.y)).a;

		// apply outline
		if (alpha_sum > 0.0) {
			COLOR = vec4(outline_color.rgb + color.rgb, 1.0);
		}
	}
}