// The far end of the water, on the back pane of the tank: dark in the depths and bright under
// the surface, with slanting shafts of light that drift. UV is in metres, y up from the floor.
shader_type spatial;
render_mode unshaded;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

uniform vec4 water : source_color = vec4(0.35, 0.75, 0.9, 1.0);
uniform float murk = 0.0;
uniform float level = 1.5;
uniform float light = 1.0;
// What is behind the part of the tank that is above the water.
uniform vec4 air : source_color = vec4(0.02, 0.025, 0.03, 1.0);

void vertex() {
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	float h = clamp(UV.y / level, 0.0, 1.0);
	vec3 col = mix(water.rgb * 0.1, water.rgb * 0.8 + 0.06, pow(h, 1.5));
	// shafts, leaning, brightest near the top and lost in dirty water
	float x = UV.x + (level - UV.y) * 0.4;
	float ray = sin(x * 4.6 + TIME * 0.3) * sin(x * 2.1 - TIME * 0.17) + 0.45 * sin(x * 10.5 + TIME * 0.55);
	col += (water.rgb + 0.15) * smoothstep(0.15, 1.2, ray) * h * h * 0.5 * (1.0 - murk * 0.8);
	// the surface, seen from below, shimmers
	float shimmer = caustic(vec2(UV.x * 0.9, TIME * 0.05), TIME * 0.6);
	col += vec3(1.0) * min(shimmer, 1.0) * smoothstep(0.86, 1.0, h) * 0.5;
	// above the water it is only the dark back of the tank
	col = mix(air.rgb * mix(0.4, 1.0, light) * (0.6 + 0.8 * clamp(UV.y / 1.5, 0.0, 1.0)), col * light, step(UV.y, level));
	ALBEDO = col;
}
