// The panes of the tank, seen from outside. Below the water line the glass takes the colour of
// the water (deeper towards the bottom, murkier as it gets dirty) and grows a film of algae in
// soft patches, thickest low down; above it, it is nearly clear.
// UV is in metres: x along the pane, y up from the floor of the tank.
shader_type spatial;
render_mode cull_back, unshaded, depth_draw_never;

#include "res://shaders/water_common.gdshaderinc"

uniform vec4 water : source_color = vec4(0.35, 0.75, 0.9, 1.0);
// How dirty the water is, and how much of the glass is under algae (both 0 to 1).
uniform float murk = 0.0;
uniform float algae = 0.0;
// How high the water stands (metres), and how bright the lamp is.
uniform float level = 1.5;
uniform float light = 1.0;

void fragment() {
	// the water line rocks a little
	float top = level + sin(UV.x * 9.0 + TIME * 1.7) * 0.006 + sin(UV.x * 23.0 - TIME * 2.3) * 0.003;
	float under = smoothstep(top + 0.006, top - 0.006, UV.y);
	float depth = clamp(1.0 - UV.y / level, 0.0, 1.0);
	vec3 col = water.rgb * mix(1.0, 0.55, depth);
	float a = mix(0.03, mix(0.07, 0.6, murk) + depth * 0.1, under);
	// dirt hangs in the water in slow clouds
	a += under * murk * 0.25 * fbm(UV * 1.6 + vec2(TIME * 0.03, 0.0));
	// a bright line where the water meets the glass
	float line = smoothstep(0.03, 0.0, abs(UV.y - top + 0.012));
	col = mix(col, vec3(1.0), line * 0.6);
	a = mix(a, 0.55, line);
	// a soft streak of the room in the glass
	float sheen = smoothstep(0.25, 0.0, abs(fract((UV.x + UV.y * 0.6) * 0.45) - 0.5));
	col += vec3(0.5, 0.6, 0.7) * sheen * 0.06;
	a += sheen * 0.03;
	// algae: a film that spreads in soft-edged patches, up from the bottom
	float patches = fbm(UV * 2.3) * 0.75 + fbm(UV * 9.0 + 5.0) * 0.25 + depth * 0.22;
	float film = under * smoothstep(1.0 - algae * 1.05, 1.18 - algae * 1.05, patches) * step(0.004, algae);
	vec3 green = mix(vec3(0.02, 0.12, 0.02), vec3(0.08, 0.26, 0.04), noise(UV * 31.0));
	col = mix(col, green, film);
	a = mix(a, 0.35 + 0.5 * algae, film * (0.75 + 0.25 * noise(UV * 55.0)));
	ALBEDO = col * light;
	ALPHA = clamp(a, 0.0, 1.0);
}
