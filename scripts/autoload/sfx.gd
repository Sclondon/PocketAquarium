extends Node
## Sound-effect bank. The sounds are short enough to synthesize when the game starts, so the
## game has no audio files at all.

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	_streams = {
		"ui": _wav(_tones([1200.0], 0.0, 0.06, 40.0, 0.2)),
		"plop": _wav(_plop(320.0, 0.09)),
		"eat": _wav(_tones([1568.0, 2093.0], 0.035, 0.14, 25.0, 0.14)),
		"tap": _wav(_tones([2400.0, 3100.0], 0.0, 0.09, 45.0, 0.2)),
		"scrub": _wav(_noise(0.13, 0.5, 12.0, 0.35)),
		"water": _wav(_noise(0.9, 0.12, 3.0, 0.6)),
		"buy": _wav(_tones([784.0, 987.8, 1174.7, 1568.0], 0.06, 0.55, 7.0, 0.16)),
		"new": _wav(_tones([659.3, 830.6, 987.8, 1318.5, 1661.2], 0.09, 1.0, 4.0, 0.16)),
		"egg": _wav(_tones([1046.5, 1318.5], 0.1, 0.4, 8.0, 0.16)),
		"sad": _wav(_tones([440.0, 349.2, 261.6], 0.17, 0.9, 4.0, 0.2)),
		"no": _wav(_tones([196.0, 185.0], 0.0, 0.16, 14.0, 0.22)),
		"croak": _wav(_tones([210.0, 190.0, 210.0, 190.0, 210.0, 190.0, 210.0], 0.04, 0.4, 70.0, 0.3)),
	}
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var stream: AudioStreamWAV = _streams.get(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(RATE * seconds))
	return b


## Bell-like notes, each starting `gap` seconds after the one before.
func _tones(freqs: Array, gap: float, seconds: float, decay: float, vol: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	for k in freqs.size():
		var from := int(k * gap * RATE)
		var w := TAU * float(freqs[k]) / RATE
		for i in range(from, b.size()):
			var t := float(i - from) / RATE
			b[i] += sin(w * (i - from)) * exp(-t * decay) * minf(t * 400.0, 1.0) * vol
	return b


## A bubble: a short note that slides up.
func _plop(freq: float, seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * freq * (1.0 + t / seconds * 2.2) / RATE
		b[i] = sin(ph) * sin(PI * t / seconds) * 0.35
	return b


func _noise(seconds: float, lp_amount: float, decay: float, vol: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += lp_amount * (_rng.randf_range(-1.0, 1.0) - lp)
		b[i] = lp * exp(-t * decay) * minf(t * 200.0, 1.0) * vol
	return b


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
