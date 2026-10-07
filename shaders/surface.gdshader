// The top of the water: it laps, and the lamp glitters on it in a moving net of light.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

uniform vec4 water : source_color = vec4(0.35, 0.75, 0.9, 1.0);
uniform float light = 1.0;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (sin(v_world.x * 5.0 + TIME * 1.6) + sin(v_world.z * 6.5 + v_world.x * 2.0 + TIME * 1.2)) * 0.012;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	float net = min(caustic(v_world.xz * 0.9, TIME * 0.6), 1.0);
	ALBEDO = mix(water.rgb * 0.85 + 0.1, vec3(1.0), net * light) * mix(0.3, 1.0, light);
	ALPHA = 0.3 + net * 0.5 * light;
}
