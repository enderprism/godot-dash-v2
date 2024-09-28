shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); //Shine color
uniform float alpha_limit : hint_range(0.0, 1.0, 0.1) = 0.0; //Alpha color limit to apply the shine, for example, if you won't to apply the shine to semi-transparent pixels
uniform float cycle_speed : hint_range(0.0, 10.0, 0.1) = 1.0; //Pulse cycle speed
uniform bool full_pulse_cycle = false; //[False = Do the effect and make a pause] [True = Do the effect continuosly]
uniform float factor : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform int mode : hint_range(0, 2, 1) = 2; //[0 = Always off] [1 = Pulse mode] [2 = Always on]

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment()
{
	//Check if the effect is enabled
	if (mode > 0)
	{
		//Check the pixel alpha value
		if (COLOR.a >= alpha_limit)
		{
			//Check the mode
			switch (mode)
			{
				case 1: //Pulse mode
				{
					float cycle = sin(TIME * cycle_speed);
					COLOR.rgb = mix(COLOR.rgb, shine_color.rgb, (((cycle >= 0.0) || (full_pulse_cycle)) ? abs(cycle) : 0.0) * shine_color.a);
					break;
				}
				case 2: //Always on
				{
					COLOR.rgb = mix(COLOR.rgb, shine_color.rgb, factor * rgb2hsv(vec3(COLOR.rgb)).z * 1.5);
					break;
				}
			}
		}
	}
}