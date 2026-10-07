// Flat-shaded, vertex-coloured low-poly material used by almost everything that is not an
// animal. Things in the tank are drawn in the lamp's two flat tones; things in the room are
// lit by whatever spills out of the tanks, in hard-edged pools.
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
varying vec3 v_normal;

void vertex() {
	if (sway > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float h = max(VERTEX.y, 0.0);
		VERTEX.x += sin(TIME * 1.3 + wp.x * 3.0 + wp.z * 2.0) * sway * h * 0.12;
		VERTEX.z += cos(TIME * 1.1 + wp.x * 2.0) * sway * h * 0.08;
	}
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	float glow = COLOR.a < 0.995 ? 1.0 - COLOR.a : 0.0;
	// (things are quieter in colour than animals, and the room quieter than the tank: the
	// animals are what the eye should go to)
	if (sway <= 0.0 && glow <= 0.0) {
		col = mix(vec3(dot(col, vec3(0.3, 0.5, 0.2))), col, wet > 0.0 ? 0.65 : 0.4);
	}
	ROUGHNESS = 1.0;
	if (wet > 0.0) {
		vec3 n = normalize(v_normal);
		if (!FRONT_FACING) {
			n = -n;
		}
		float net = step(0.5, caustic(v_world.xz * 0.8 + v_world.y * 0.2, TIME * 0.6)) * smoothstep(0.2, 0.5, n.y);
		// (plants are thin: the light comes through them)
		float lit = sway > 0.0 ? mix(0.55, 1.0, lit_side(n, 0.3)) : lit_side(n, 0.1);
		vec3 shaded = col * (mix(shadow, key * (1.0 + net * 0.35), lit) * lamp + torch_on(v_world));
		ALBEDO = vec3(0.0);
		EMISSION = into_haze(shaded + col * glow * 1.2 * lamp, v_world.z);
	} else {
		ALBEDO = col;
		EMISSION = col * glow * 1.6;
	}
}

void light() {
	// two tones, and the light stops at an edge rather than fading out
	float facing = smoothstep(0.0, 0.03, dot(NORMAL, LIGHT));
	float reach = smoothstep(0.1, 0.11, ATTENUATION) * 0.25 + smoothstep(0.38, 0.4, ATTENUATION) * 0.75;
	DIFFUSE_LIGHT += facing * reach * LIGHT_COLOR / PI;
}
