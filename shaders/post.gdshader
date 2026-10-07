// Over the finished 3D picture: the corners darken, and a grain too fine to see breaks up the
// bands that a dark, smooth fade would otherwise show.
shader_type canvas_item;

uniform float vignette = 0.55;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 d = UV - 0.5;
	c.rgb *= 1.0 - dot(d, d) * vignette * 2.0;
	float grain = fract(sin(dot(floor(UV / TEXTURE_PIXEL_SIZE), vec2(12.9898, 78.233))) * 43758.5453);
	c.rgb += (grain - 0.5) / 255.0;
	COLOR = vec4(c.rgb, 1.0);
}
