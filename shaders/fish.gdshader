// A fish: its tail wags, glowing faces glow (vertex colour alpha < 1), the lamp's net of light
// plays over its back, and a rim light picks it out from the water. A sick fish loses its colour.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

uniform float wag_phase = 0.0;
uniform float wag_amp = 0.12;
// How washed out it is (0 is healthy, 1 is grey).
uniform float pale = 0.0;

varying vec3 v_world;
varying float v_up;

void vertex() {
	float t = clamp((VERTEX.z + 0.5) / 1.8, 0.0, 1.0);
	VERTEX.x += sin(wag_phase - VERTEX.z * 2.5) * wag_amp * t * t * 1.6;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_up = normalize(mat3(MODEL_MATRIX) * NORMAL).y;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	col = mix(col, vec3(dot(col, vec3(0.3, 0.5, 0.2))) * 0.8 + 0.05, pale);
	ALBEDO = col;
	ROUGHNESS = 0.7;
	float glow = COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float net = caustic(v_world.xz * 0.8 + v_world.y * 0.2, TIME * 0.6);
	EMISSION = col * (rim * 0.6 + glow * 1.8 * (1.0 - pale)
			+ (0.35 + min(net, 1.5) * 0.9 * max(v_up, 0.0)) * tank_lamp);
}
