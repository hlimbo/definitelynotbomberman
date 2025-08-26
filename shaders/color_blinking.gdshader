shader_type canvas_item;

// https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html#per-instance-uniforms
// this allows us to have different nodes that rely on this shader to have different variable values
// saves memory as you don't need to instantiate a new shader material per node that needs it
instance uniform float blink_frequency_instance: hint_range(-1.0, 8.0) = -1.0;
instance uniform vec4 color_fill_instance: source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float blink_frequency: hint_range(1.0, 8.0) = 6.0;
uniform vec4 color_fill: source_color = vec4(1.0, 1.0, 1.0, 1.0);


void fragment() {
	// use blink_frequency_instance if bigger than 0, otherwise use blink_frequency to apply to ALL nodes that rely on this shader
	float frequency = step(0.0, blink_frequency_instance) * blink_frequency_instance + step(blink_frequency_instance, 0.0) * blink_frequency;
	float color_sum = color_fill_instance.r + color_fill_instance.g + color_fill_instance.b + color_fill_instance.a;
	vec4 fill = step(0.0, color_sum) * color_fill_instance + step(color_sum, 0.0) * color_fill;

	float switch_value = abs(sin(frequency * PI * TIME));
	vec4 main_color = (switch_value > 0.5) ? fill : COLOR.rgba;
	COLOR = vec4(main_color.rgb, COLOR.a * main_color.a);
}
