// An animal in the tank, drawn like a cel: the lamp's light falls on it in two flat tones with
// a hard edge between them, its shadow side is a colour and not a grey, and outline.gdshader
// draws the ink line round it. Its fins show their rays and its skin a hint of scales. It
// swims by bending (swim.gdshaderinc). Glowing parts glow whatever the lamp is doing (vertex
// colour alpha < 1), the lamp's net of light falls on its back in flat patches, it fades into
// the water toward the back of the tank, and a sick one loses its colour.
// What each vertex is part of comes in its UV (see fish_mesh.gd).
shader_type spatial;
render_mode cull_disabled, unshaded;

#include "res://shaders/psx_common.gdshaderinc"
#include "res://shaders/water_common.gdshaderinc"
#include "res://shaders/swim.gdshaderinc"

// How washed out it is (0 is healthy, 1 is grey).
uniform float pale = 0.0;
// Speckles on its back: how many (0 to 1) and what colour.
uniform float spots = 0.0;
uniform vec4 spot_color : source_color = vec4(0.05, 0.08, 0.1, 1.0);
// A model made in Blender (see scripts/tank/models.gd): its colours are already linear, and
// how much each part glows comes in its second UV.
uniform bool modelled = false;
// For a kind that is bred for its colour: how deep this one's is, 0 washed out to 1 as deep as
// they come (below 0 for any other kind).
uniform float grade = -1.0;

varying vec3 v_world;
varying vec3 v_local;
varying vec3 v_normal;

void vertex() {
	v_local = VERTEX;
	VERTEX = swim_bend(VERTEX);
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	if (too_near(VERTEX, FRAGCOORD.xy)) {
		discard;
	}
	// (skin that can be seen through is drawn as every other dot: no sorting, and it suits ink)
	if (modelled && COLOR.a < 0.99 && fract(dot(floor(FRAGCOORD.xy), vec2(0.5, 0.5))) + 0.25 > COLOR.a * 1.5) {
		discard;
	}
	vec3 col = modelled ? COLOR.rgb : srgb_to_linear(COLOR.rgb);
	if (grade >= 0.0) {
		vec3 washed = mix(vec3(dot(col, vec3(0.3, 0.5, 0.2))), col, 0.2) * vec3(1.0, 0.9, 0.75);
		col = mix(washed, col * vec3(1.0, 0.8, 0.8), grade);
	}
	vec3 n = normalize(v_normal);
	float lit = 1.0;
	if (UV.y < 1.5) {
		// skin: speckles over the back
		float back = smoothstep(0.55, 0.2, UV.y);
		float dots = step(0.67, noise(v_local.zy * vec2(11.0, 14.0) + v_local.x * 9.0));
		col = mix(col, spot_color.rgb, dots * back * spots);
		lit = lit_side(n, 0.12);
	} else if (UV.y < 2.5) {
		// fins: the light comes through them, and their rays show from root to edge
		float ray = step(0.55, sin((v_local.y * 1.3 + v_local.z + v_local.x) * 16.0));
		col *= 1.0 - ray * 0.14 * UV.x;
		lit = 0.8;
	}
	col = mix(col, vec3(dot(col, vec3(0.3, 0.5, 0.2))) * 0.8 + 0.05, pale);
	float glow = modelled ? UV2.y : (COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0);
	// the net of light, in flat patches, on what faces the lamp
	float net = step(0.5, caustic(v_world.xz * 0.8 + v_world.y * 0.2, TIME * 0.6)) * smoothstep(0.2, 0.5, n.y) * step(v_world.y, water_top);
	// (the darkest animal still has a shadow side that is a colour, not black)
	vec3 shaded = (col + 0.035) * (mix(shadow, key * (1.0 + net * 0.35), lit) * lamp + torch_on(v_world));
	if (UV.y > 2.5) {
		// eyes keep their shine
		shaded = col * mix(0.45, 1.0, lamp);
	}
	shaded = into_haze(shaded, v_world.z);
	ALBEDO = shaded + col * glow * 1.6 * (1.0 - pale);
}
