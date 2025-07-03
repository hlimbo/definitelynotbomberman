shader_type canvas_item;

uniform float alpha: hint_range(0.0, 1.0) = 1.0;
uniform vec3 color_tint: source_color = vec3(1.0, 0.0, 0.0);

uniform float wave_frequency: hint_range(1.0, 512.0) = 64.0;
uniform float wave_threshold: hint_range(0.0, 1.0) = 0.5;

// used to sample neighboring fragments using sine wave pattern
vec2 wave_field_uv(vec2 uv, vec2 texture_pixel_size) {
	// doing time * time creates a parabolic like motion inside of the sine wave
	float period = 50.0 * TAU * texture_pixel_size.y * TIME * uv.y;
	float offset = 50.0 * TAU * texture_pixel_size.x * TIME * TIME;
	float x = wave_frequency * texture_pixel_size.y * sin(period + offset);
	float can_wave = mod(uv.y + TIME, 1.0);
	vec2 uv_offset = vec2(x, 0.0);
	
	return can_wave < wave_threshold ? uv + uv_offset : uv;
}

void fragment() {
	
	vec2 uv = wave_field_uv(UV, TEXTURE_PIXEL_SIZE);
	vec4 color = texture(TEXTURE, uv);
	
	float alpha_lines = smoothstep(0.0, 1.0, sin(fract(UV.x * 16.0)));
	COLOR = vec4(color.rgb + color_tint, color.a * alpha * alpha_lines);
}
