// How an animal bends as it swims. Its skin and its outline both use this, with the same
// numbers, so the line never swims out of step with the fish.
uniform float wag_phase = 0.0;
uniform float wag_amp = 0.12;
// 0 wags its tail from side to side, 1 beats it up and down (whales), 2 pulses its bell and
// trails its tentacles (jellyfish).
uniform int swim = 0;

vec3 swim_bend(vec3 v) {
	if (swim == 2) {
		float under = max(-v.y, 0.0);
		float beat = sin(wag_phase);
		v.xz *= 1.0 + beat * 0.1 * (1.0 - under);
		v.x += sin(wag_phase * 0.7 + v.y * 4.0) * under * 0.1;
		v.z += cos(wag_phase * 0.6 + v.y * 3.3) * under * 0.1;
		v.y *= 1.0 - beat * 0.08;
		return v;
	}
	float t = clamp((v.z + 0.5) / 1.8, 0.0, 1.0);
	float bend = sin(wag_phase - v.z * 2.5) * wag_amp * t * t * 1.6;
	if (swim == 1) {
		v.y += bend;
	} else {
		v.x += bend;
	}
	return v;
}
