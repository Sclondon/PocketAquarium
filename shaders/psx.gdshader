// Flat-shaded, vertex-coloured low-poly material used by almost everything.
// Vertex colour alpha < 1 marks a glowing face (glow = 1 - alpha).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

// Plants: how far they sway in the water, more the higher up the plant (0 stands still).
uniform float sway = 0.0;
// Things in the tank (1): lit through the water by the tank's lamp, with the moving net of
// light it throws, brightest on what faces up.
uniform float wet = 0.0;

varying vec3 v_world;
varying float v_up;

void vertex() {
	if (sway > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float h = max(VERTEX.y, 0.0);
		VERTEX.x += sin(TIME * 1.3 + wp.x * 3.0 + wp.z * 2.0) * sway * h * 0.12;
		VERTEX.z += cos(TIME * 1.1 + wp.x * 2.0) * sway * h * 0.08;
	}
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_up = normalize(mat3(MODEL_MATRIX) * NORMAL).y;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	float glow = COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0;
	EMISSION = col * glow * 1.6;
	if (wet > 0.0) {
		float net = caustic(v_world.xz * 0.8 + v_world.y * 0.2, TIME * 0.6);
		EMISSION += col * (0.3 + min(net, 1.5) * 1.3 * (0.2 + 0.8 * max(v_up, 0.0))) * tank_lamp * wet;
	}
}
