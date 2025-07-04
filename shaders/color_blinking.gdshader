shader_type canvas_item;

// https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html#per-instance-uniforms
// this allows us to have different nodes that rely on this shader to have different variable values
// saves memory as you don't need to instantiate a new shader material per node that needs it
instance uniform float blink_frequency_instance: hint_range(-1.0, 8.0) = -1.0;

uniform float blink_frequency: hint_range(1.0, 8.0) = 6.0;
uniform vec3 color_fill: source_color = vec3(1.0, 1.0, 1.0);


void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	// use blink_frequency_instance if bigger than 0, otherwise use blink_frequency to apply to ALL nodes that rely on this shader
	float frequency = step(0.0, blink_frequency_instance) * blink_frequency_instance + step(blink_frequency_instance, 0.0) * blink_frequency;
	
	float switch_value = abs(sin(frequency * PI * TIME));
	vec3 main_color = (switch_value > 0.5) ? color_fill : color.rgb;

	COLOR = vec4(main_color, color.a);
}
