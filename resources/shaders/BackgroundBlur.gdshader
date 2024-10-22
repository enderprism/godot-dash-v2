shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5) = 0.0;
uniform vec4 gui_color: source_color;
uniform float mix_factor: hint_range(0.0, 1.0, 0.01);

void fragment(){
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	color = mix(color, gui_color, mix_factor);
	COLOR = color;
}