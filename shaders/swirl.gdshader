// adapted from https://godotshaders.com/shader/swirl-sink/
shader_type canvas_item;
 
uniform float ratio : hint_range(0.0, 1.0) = 1.0;

// controls the velocity and acceleration of the swirl
uniform float power = 3.0;
uniform float min_speed = 10.0;
uniform float max_speed = 90.0;

// in pixel coordinates
uniform vec2 rect_offset = vec2(38.0, 9.0);
uniform vec2 size = vec2(20, 22.0);
 
// frame 2 of 2d_animation_player-run.webp file
instance uniform vec2 rect_offset_instance = vec2(38.0, 9.0);
instance uniform vec2 size_instance = vec2(20, 22.0);

bool is_in_bounds(vec2 uv, vec2 uv_offset, vec2 uv_size_region) {
	return uv.x > uv_offset.x && uv.x < uv_offset.x + uv_size_region.x && uv.y > uv_offset.y && uv.y < uv_offset.y + uv_size_region.y;
}

void fragment() {
	// normalize pixel coordinates to be UV
	vec2 uv_offset = vec2(rect_offset.x * TEXTURE_PIXEL_SIZE.x, rect_offset.y * TEXTURE_PIXEL_SIZE.y);
	vec2 uv_size_region = vec2(size.x * TEXTURE_PIXEL_SIZE.x, size.y * TEXTURE_PIXEL_SIZE.y);
    vec2 uv = UV;
    
	// apply swirl effect to specific texture region only
	if (is_in_bounds(uv, uv_offset, uv_size_region)) {
		vec2 local_uv = (UV - uv_offset) / uv_size_region;
		vec4 pixel_color = texture(TEXTURE, UV);
		
		local_uv *= 2.0; // scales up uv by 2 for both x and y
		local_uv -= vec2(1.0);

		float len = length(local_uv);

		float rspeed = mix(max_speed, min_speed, len);

		float sinx = sin((1. - ratio) * rspeed);
		float cosx = cos((1. - ratio) * rspeed);

		// 2d rotation matrix
		vec2 trs = local_uv * mat2(vec2(cosx, sinx), vec2(-sinx, cosx));
		trs /= pow(ratio, power);

		// centers the texture back onto the UV
		trs += vec2(1.0);
		trs /= 2.;
		if(trs.x > 1. || trs.x < 0. || trs.y > 1. || trs.y < 0.) {
		    // Prevent sprite leaking.
		    COLOR = vec4(0.);
		} else {
			// convert back from local_uv to uv to ensure it is picking the correct pixels to paint
			trs = trs * uv_size_region + uv_offset;
		    vec4 col = texture(TEXTURE, trs);   
		   	COLOR = col;
		}
		
	} else {
		// outside the region
       COLOR = texture(TEXTURE, UV);
	}
}
