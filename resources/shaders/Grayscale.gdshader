shader_type canvas_item;

uniform float grayscale_factor;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 bg = texture(screen_texture, SCREEN_UV);
	float avg = (bg.r + bg.g + bg.b) / 3.0f;
	COLOR.rgb = vec3(avg);
	COLOR.a = bg.a;
	COLOR.rgb = mix(bg.rgb, COLOR.rgb, grayscale_factor);
}
