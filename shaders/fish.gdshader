// An animal in the tank, shaded like a painted model: light falls on it in a few flat bands
// with a bright glint, a rim of light picks it out from the water, its fins show their rays
// and its skin a hint of scales. It swims by bending (see `swim`). Glowing parts glow (vertex
// colour alpha < 1), the lamp's net of light plays over its back, and a sick one loses colour.
// What each vertex is part of comes in its UV (see fish_mesh.gd).
shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

uniform float wag_phase = 0.0;
uniform float wag_amp = 0.12;
// How it swims: 0 wags its tail from side to side, 1 beats it up and down (whales), 2 pulses
// its bell and trails its tentacles (jellyfish).
uniform int swim = 0;
// How washed out it is (0 is healthy, 1 is grey).
uniform float pale = 0.0;
// Speckles on its back: how many (0 to 1) and what colour.
uniform float spots = 0.0;
uniform vec4 spot_color : source_color = vec4(0.05, 0.08, 0.1, 1.0);

varying vec3 v_world;
varying vec3 v_local;
varying float v_up;

void vertex() {
	v_local = VERTEX;
	if (swim == 2) {
		float under = max(-VERTEX.y, 0.0);
		float beat = sin(wag_phase);
		VERTEX.xz *= 1.0 + beat * 0.1 * (1.0 - under);
		VERTEX.y *= 1.0 - beat * 0.08;
		VERTEX.x += sin(wag_phase * 0.7 + VERTEX.y * 4.0) * under * 0.1;
		VERTEX.z += cos(wag_phase * 0.6 + VERTEX.y * 3.3) * under * 0.1;
	} else {
		float t = clamp((VERTEX.z + 0.5) / 1.8, 0.0, 1.0);
		float bend = sin(wag_phase - VERTEX.z * 2.5) * wag_amp * t * t * 1.6;
		if (swim == 1) {
			VERTEX.y += bend;
		} else {
			VERTEX.x += bend;
		}
	}
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_up = normalize(mat3(MODEL_MATRIX) * NORMAL).y;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	if (UV.y < 1.5) {
		// skin: speckles over the back, and rows of scales along the flank
		float back = smoothstep(0.55, 0.2, UV.y);
		float dots = smoothstep(0.62, 0.72, noise(v_local.zy * vec2(11.0, 14.0) + v_local.x * 9.0));
		col = mix(col, spot_color.rgb, dots * back * spots);
		vec2 cell = vec2(UV.x * 26.0, UV.y * 9.0);
		cell.x += floor(cell.y) * 0.5;
		float scale = smoothstep(0.5, 0.2, length(fract(cell) - vec2(0.5, 0.35)));
		col *= 1.0 + (scale - 0.5) * 0.1 * smoothstep(0.08, 0.2, UV.x) * smoothstep(0.95, 0.8, UV.x);
	} else if (UV.y < 2.5) {
		// fins: fine rays from root to edge
		float ray = sin((v_local.y * 1.3 + v_local.z + v_local.x) * 55.0);
		col *= 1.0 + ray * 0.07 * UV.x;
	}
	col = mix(col, vec3(dot(col, vec3(0.3, 0.5, 0.2))) * 0.8 + 0.05, pale);
	ALBEDO = col;
	ROUGHNESS = 0.5;
	float glow = COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0;
	float rim = smoothstep(0.55, 0.8, 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0));
	float net = caustic(v_world.xz * 0.8 + v_world.y * 0.2, TIME * 0.6);
	float eye = step(2.5, UV.y);
	EMISSION = col * (rim * 0.35 * (1.0 - eye) + glow * 1.8 * (1.0 - pale) + eye * 0.5
			+ (0.42 + min(net, 1.5) * 0.7 * max(v_up, 0.0)) * lamp);
}

void light() {
	// two steps of light and a small hard glint
	float lit = dot(NORMAL, LIGHT);
	float bands = smoothstep(-0.05, 0.05, lit) * 0.55 + smoothstep(0.42, 0.5, lit) * 0.45;
	DIFFUSE_LIGHT += bands * ATTENUATION * LIGHT_COLOR / PI;
	float glint = smoothstep(0.985, 0.995, dot(NORMAL, normalize(LIGHT + VIEW)));
	SPECULAR_LIGHT += glint * 0.15 * ATTENUATION * LIGHT_COLOR / PI;
}
