// The floor of the tank: sand or gravel in a few flat tones, with ripples, darker and paler
// patches, the odd pebble, and the lamp's net of light lying on it in bright shapes.
shader_type spatial;
render_mode unshaded;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

uniform vec4 sand : source_color = vec4(0.85, 0.74, 0.55, 1.0);
// How coarse it is: 0 is fine sand, 1 is gravel with a pebble in every handful.
uniform float coarse = 0.5;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world.xz;
	// (each of these is cut to a step, so the sand is drawn and not photographed)
	float ripple = step(0.3, sin(p.x * 24.0 + sin(p.y * 5.0) * 1.6 + noise(p * 3.0) * 5.0));
	float patches = step(0.5, fbm(p * 2.2));
	vec3 col = sand.rgb * (0.92 + 0.08 * ripple * (1.0 - coarse)) * mix(0.84, 1.0, patches);
	// pebbles: darker and paler stones scattered through it
	vec2 q = p * mix(60.0, 30.0, coarse);
	vec2 cell = floor(q);
	vec2 centre = vec2(hash21(cell + 3.0), hash21(cell + 11.0)) * 0.5 + 0.25;
	float round_stone = step(length(fract(q) - centre), 0.24);
	float there = step(1.0 - 0.05 - 0.3 * coarse, hash21(cell));
	col = mix(col, sand.rgb * mix(0.5, 1.25, step(0.5, hash21(cell + 7.0))), there * round_stone);
	float net = step(0.45, caustic(p * 0.8 + v_world.y * 0.2, TIME * 0.6));
	ALBEDO = into_haze(col * (mix(shadow * 1.6, key, 0.62 + net * 0.38) * lamp + torch_on(v_world)), v_world.z);
}
