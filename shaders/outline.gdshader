// The ink line round an animal: a second copy of it, pushed out a few pixels on the screen and
// drawn black behind the first. Skin is pushed out along its normals and only its far side is
// drawn; a fin is a single sheet, so it is pushed out in its own plane (the way CUSTOM0 says)
// and drawn just behind itself. The line is the same width however near the camera is.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://shaders/swim.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"

// Pixels wide on a screen 720 high.
uniform float width = 3.0;
uniform vec3 ink : source_color = vec3(0.03, 0.02, 0.07);
// A model made in Blender: its fins have thickness, so they are pushed out along their normals
// like the rest of it, and how wide the line is at each point comes in its second UV.
uniform bool modelled = false;

varying float v_part;

void vertex() {
	vec3 v = swim_bend(VERTEX);
	bool fin = !modelled && UV.y > 1.5 && UV.y < 2.5;
	vec4 view = MODELVIEW_MATRIX * vec4(v, 1.0);
	if (fin) {
		// (straight away from the eye, so it does not slide across the screen as it goes back)
		view.xyz *= 1.004;
	}
	vec4 clip = PROJECTION_MATRIX * view;
	vec2 dir = (mat3(MODELVIEW_MATRIX) * (fin ? CUSTOM0.xyz : NORMAL)).xy;
	float len = length(dir);
	if (len > 1e-5) {
		// (thinner on a fin, and on anything far enough off to be small)
		float px = width * (modelled ? UV2.x : (fin ? 0.7 : 1.0)) * clamp(1.8 / clip.w, 0.4, 1.0);
		clip.xy += dir / len * px * 2.0 / 720.0 * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0) * clip.w;
	}
	POSITION = clip;
	v_part = modelled && UV.y < 2.5 ? 0.0 : UV.y;
}

void fragment() {
	bool fin = v_part > 1.5 && v_part < 2.5;
	if (v_part > 2.5 || (!fin && FRONT_FACING) || too_near(VERTEX, FRAGCOORD.xy)) {
		discard;
	}
	ALBEDO = ink * mix(0.5, 1.0, lamp);
}
