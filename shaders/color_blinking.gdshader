shader_type canvas_item;

uniform float blink_frequency: hint_range(1.0, 8.0) = 6.0;
uniform vec3 color_fill: source_color = vec3(1.0, 1.0, 1.0);


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float switch_value = abs(sin(blink_frequency * PI * TIME));
	vec3 main_color = (switch_value > 0.5) ? color_fill : color.rgb;

	COLOR = vec4(main_color, color.a);
}
