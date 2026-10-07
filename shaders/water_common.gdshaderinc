// Shared by everything that is under, or is, the water.

// How bright the lamp of the tank this is in is (0 off to 1 on); set by tank.gd.
uniform float lamp = 1.0;

// The look: light falls in two flat tones. `key` is the colour of this tank's lamp, `shadow`
// the tone of what it does not reach (a colour, never a grey), and `haze` what things fade
// into toward the back pane, which is `tank_depth` metres behind the front one.
uniform vec3 key : source_color = vec3(1.0, 0.9, 0.72);
uniform vec3 shadow : source_color = vec3(0.24, 0.18, 0.36);
uniform vec3 haze : source_color = vec3(0.12, 0.07, 0.05);
uniform float tank_depth = 1.2;

// The keeper's torch: where its beam goes into the tank (in the world; it shines straight back
// from the glass) and its colour, which is black while it is off.
uniform vec3 torch_at = vec3(0.0);
uniform vec3 torch_light : source_color = vec3(0.0);

// The torch's light on something at a place in the world: a hard-edged pool, with a dimmer
// ring round it.
vec3 torch_on(vec3 world) {
	float off = length(world.xy - torch_at.xy);
	return torch_light * (step(off, 0.3) * 0.65 + step(off, 0.46) * 0.35);
}

// 1 where a surface facing `n` (in the world) is in the lamp's light and 0 where it is not,
// with a hard edge between. `bias` moves the edge: more of it is lit as it goes up.
float lit_side(vec3 n, float bias) {
	return smoothstep(-0.012, 0.012, dot(n, normalize(vec3(0.12, 1.0, 0.3))) + bias);
}

// A colour faded toward the back of the tank (`world_z` is where it is, front to back).
vec3 into_haze(vec3 col, float world_z) {
	float far = clamp(0.5 - world_z / tank_depth, 0.0, 1.0);
	return mix(col, haze, far * far * 0.75);
}

// True for the pixels of something to leave out because it is right up against the eye: it
// thins to a stipple and then to nothing, so an animal swimming past the camera does not fill
// the screen. `at` is where the pixel is from the eye, `pixel` where it is on the screen.
bool too_near(vec3 at, vec2 pixel) {
	float stipple = fract(dot(floor(pixel), vec2(0.5, 0.75)));
	return length(at) / 0.22 < stipple + 0.125;
}

// The net of light that moving water throws on whatever is under it: 0 between the lines,
// 1 and more on them. `uv` repeats every 1.
float caustic(vec2 uv, float time) {
	vec2 p = mod(uv * 6.2831853, 6.2831853) - 250.0;
	vec2 i = p;
	float c = 1.0;
	const float inten = 0.005;
	for (int n = 0; n < 4; n++) {
		float t = time * (1.0 - (3.5 / float(n + 1)));
		i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
	}
	c /= 4.0;
	c = 1.17 - pow(c, 1.4);
	return pow(abs(c), 8.0);
}

// Smooth noise, 0 to 1, and a few layers of it.
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.5 + noise(p * 2.03 + 7.1) * 0.3 + noise(p * 4.1 + 3.7) * 0.2;
}
