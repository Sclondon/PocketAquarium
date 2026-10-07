// The floor of the tank: fine sand or gravel, grain by grain, with ripples, darker and paler
// patches, the odd pebble, and the lamp's net of light moving over it.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

uniform vec4 sand : source_color = vec4(0.85, 0.74, 0.55, 1.0);
// How coarse it is: 0 is fine sand, 1 is gravel with a pebble in every handful.
uniform float coarse = 0.5;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	vec2 p = v_world.xz;
	float grain = noise(p * 230.0) * 0.4 + noise(p * 95.0) * 0.35 + noise(p * 41.0) * 0.25;
	float ripple = sin(p.x * 24.0 + sin(p.y * 5.0) * 1.6 + noise(p * 3.0) * 5.0);
	float patches = fbm(p * 2.2);
	vec3 col = sand.rgb * (0.74 + grain * 0.42) * (0.95 + 0.05 * ripple * (1.0 - coarse)) * mix(0.82, 1.1, patches);
	// pebbles: darker and paler stones scattered through it
	vec2 q = p * mix(90.0, 44.0, coarse);
	vec2 cell = floor(q);
	vec2 centre = vec2(hash21(cell + 3.0), hash21(cell + 11.0)) * 0.5 + 0.25;
	float round_stone = smoothstep(0.3, 0.18, length(fract(q) - centre));
	float there = step(1.0 - 0.06 - 0.3 * coarse, hash21(cell));
	col = mix(col, sand.rgb * mix(0.45, 1.3, hash21(cell + 7.0)), there * round_stone * 0.8);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	float net = caustic(p * 0.8 + v_world.y * 0.2, TIME * 0.6);
	EMISSION = col * (0.1 + min(net, 1.5) * 0.55) * lamp;
}
