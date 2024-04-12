shader_type canvas_item;
uniform vec2 scale;
uniform float alpha = 1.0;
uniform float inner_radius = 0.0;
uniform float outer_radius = 1.0;
void fragment() {
    float q = 1.-(1.-length(UV*scale*2.-1.)/outer_radius)/(1.-inner_radius);
    COLOR = vec4(0, 0, 0, q*alpha);
}