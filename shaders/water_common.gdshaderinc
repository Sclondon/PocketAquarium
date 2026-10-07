// Shared by everything that is under, or is, the water.

// How bright the tank's lamp is (0 off to 1 on); set by tank.gd.
global uniform float tank_lamp;

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
