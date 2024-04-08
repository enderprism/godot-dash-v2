shader_type canvas_item;

uniform vec2 scale;
uniform float alpha = 1.0;
uniform float inner_radius = 0.0;
uniform float outer_radius = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv *= scale;
	float x = abs(uv.r-.5)*2.0;
	float y = abs(uv.g-.5)*2.0;
	float q = 1.0-(1.0-sqrt(x*x+y*y)/outer_radius)/(1.0-inner_radius);
	COLOR = vec4(0, 0, 0, q*alpha);
}