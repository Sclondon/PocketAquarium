// A fish: its tail wags, glowing faces glow (vertex colour alpha < 1), and a rim light picks
// it out from the water. A sick fish loses its colour.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"

uniform float wag_phase = 0.0;
uniform float wag_amp = 0.12;
// How washed out it is (0 is healthy, 1 is grey).
uniform float pale = 0.0;

void vertex() {
	float t = clamp((VERTEX.z + 0.5) / 1.8, 0.0, 1.0);
	VERTEX.x += sin(wag_phase - VERTEX.z * 2.5) * wag_amp * t * t * 1.6;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	col = mix(col, vec3(dot(col, vec3(0.3, 0.5, 0.2))) * 0.8 + 0.05, pale);
	ALBEDO = col;
	ROUGHNESS = 0.7;
	float glow = COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = col * (rim * 0.6 + glow * 1.8 * (1.0 - pale));
}
