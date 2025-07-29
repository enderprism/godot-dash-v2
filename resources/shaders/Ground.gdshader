shader_type canvas_item;

void fragment() {
	float shadow = SCREEN_UV.x;
	float shadow_left = shadow * 3.0;
	float shadow_right = (1.0 - shadow) * 3.0;
	shadow = mix(0.1, 1.0, shadow_left * shadow_right);
	shadow = clamp(shadow, 0.0, 1.0);
	COLOR.rgb *= shadow;
}