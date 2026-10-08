// How an animal moves its body as it goes. Its skin and its outline both use this, with the
// same numbers, so the line never moves out of step with the animal.
uniform float wag_phase = 0.0;
uniform float wag_amp = 0.12;
// 0 wags its tail from side to side, 1 beats it up and down (whales), 2 pulses its bell and
// trails its tentacles (jellyfish), 3 walks: its body sways and its legs step, 4 holds its
// body still (and kicks its hind legs out when it leaps).
uniform int swim = 0;
// For one that walks: what counts as leg. Anything further out to the side than `leg_from`, or
// (if `leg_low` is above 0) lower than `leg_low`, steps; the rest is body.
uniform float leg_from = 0.26;
uniform float leg_low = 0.0;
// For one that hops: how far through a leap it is, 0 on the ground to 1 at the top.
uniform float leap = 0.0;

// How much of a leg a point of the model is, 0 (body) to 1.
float limb(vec3 v) {
	float out_side = smoothstep(leg_from, leg_from + 0.14, abs(v.x));
	float low = leg_low > 0.0 ? smoothstep(leg_low, leg_low * 0.4, v.y) : 0.0;
	return max(out_side, low);
}

vec3 swim_bend(vec3 v) {
	if (swim == 4) {
		// a leap: the hind legs go out straight behind, and the front ones tuck
		float kick = limb(v) * leap;
		v.z += kick * (v.z > 0.0 ? 0.4 : -0.08);
		v.y += kick * 0.06;
		return v;
	}
	if (swim == 3) {
		// the legs step in pairs, corner to corner, and the body sways to them
		float leg = limb(v);
		float pair = (v.x > 0.0 ? 0.0 : 3.14159) + (v.z > 0.0 ? 3.14159 : 0.0);
		v.x += sin(wag_phase - v.z * 3.0) * wag_amp * 0.3 * (1.0 - leg);
		v.z += sin(wag_phase + pair) * 0.15 * leg;
		v.y += max(cos(wag_phase + pair), 0.0) * 0.07 * leg * step(0.01, v.y);
		return v;
	}
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
