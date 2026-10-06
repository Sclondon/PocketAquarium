// Flat-shaded, vertex-coloured low-poly material used by almost everything.
// Vertex colour alpha < 1 marks a glowing face (glow = 1 - alpha).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"

// Plants: how far they sway in the water, more the higher up the plant (0 stands still).
uniform float sway = 0.0;

void vertex() {
	if (sway > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float h = max(VERTEX.y, 0.0);
		VERTEX.x += sin(TIME * 1.3 + wp.x * 3.0 + wp.z * 2.0) * sway * h * 0.12;
		VERTEX.z += cos(TIME * 1.1 + wp.x * 2.0) * sway * h * 0.08;
	}
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	float glow = COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0;
	EMISSION = col * glow * 1.6;
}
