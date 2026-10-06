// The panes of the tank, seen from outside. Below the water line the glass takes the colour of
// the water (murkier as it gets dirty) and grows blotches of algae; above it, it is nearly clear.
// UV is in metres: x along the pane, y up from the floor of the tank.
shader_type spatial;
render_mode cull_back, unshaded, depth_draw_never;

uniform vec4 water : source_color = vec4(0.35, 0.75, 0.9, 1.0);
// How dirty the water is, and how much of the glass is under algae (both 0 to 1).
uniform float murk = 0.0;
uniform float algae = 0.0;
// How high the water stands (metres), and how bright the lamp is.
uniform float level = 1.5;
uniform float light = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float under = step(UV.y, level);
	vec3 col = water.rgb;
	float a = mix(0.04, mix(0.1, 0.62, murk), under);
	// a brighter line where the water meets the glass
	float line = under * step(level - 0.025, UV.y);
	col = mix(col, vec3(1.0), line * 0.5);
	a = mix(a, 0.5, line);
	// algae grows in blocky blotches, big ones first
	float n = hash(floor(UV * 5.0)) * 0.55 + hash(floor(UV * 16.0)) * 0.45;
	float green = under * step(n, 0.12 + algae * 0.6) * step(0.004, algae);
	col = mix(col, vec3(0.03, 0.16, 0.02) * (0.7 + 0.6 * hash(floor(UV * 16.0) + 3.0)), green);
	a = mix(a, 0.45 + 0.35 * algae, green);
	ALBEDO = col * light;
	ALPHA = a;
}
