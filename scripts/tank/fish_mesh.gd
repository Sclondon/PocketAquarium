extends RefCounted
## Builds a low-poly fish from a species' `look` (see species.gd). Every fish is the same body
## pulled into a different shape: nose at -Z (Godot's forward), about 2.3 long before `len`.
##
## The look: `back`, `side`, `belly` and `fin` colours; `bar` and `bars`, a colour and the body
## segments (0 at the nose to 6 at the tail) painted with it; `glow`, how brightly its sides
## glow; `len`, `tall` and `wide`, the body's proportions; `tail_len`, `spread` (radians either
## side), `fork` (0 a fan, 1 a deep fork) and `droop` for the tail; `dorsal` and `anal`, how
## tall those fins are, and `sweep`, how far they trail back; `eye`, how big its eyes are.

const MB := preload("res://scripts/util/mesh_builder.gd")
const Species := preload("res://scripts/tank/species.gd")

## z, half-width, half-height, y-centre
const RINGS := [
	[-1.20, 0.03, 0.03, -0.02],
	[-0.95, 0.17, 0.21, 0.00],
	[-0.60, 0.25, 0.36, 0.04],
	[-0.20, 0.28, 0.42, 0.06],
	[0.20, 0.25, 0.36, 0.04],
	[0.55, 0.16, 0.22, 0.01],
	[0.80, 0.08, 0.12, 0.00],
	[0.95, 0.04, 0.07, 0.00],
]
const SIDES := 8

static var _cache := {}


## The mesh for a species (built once).
static func of(id: String) -> ArrayMesh:
	if not _cache.has(id):
		_cache[id] = build(Species.LIST[id].look)
	return _cache[id]


static func build(look: Dictionary) -> ArrayMesh:
	var mb := MB.new()
	var length: float = look.get("len", 1.0)
	var tall: float = look.get("tall", 1.0)
	var wide: float = look.get("wide", 1.0)
	var back: Color = look.back
	var belly: Color = look.belly
	var fin: Color = look.fin
	var glow: float = look.get("glow", 0.0)
	var side := Color(look.side.r, look.side.g, look.side.b, 1.0 - glow)
	var bar: Color = look.get("bar", back)
	var bars: Array = look.get("bars", [])
	var head := back.lerp(look.side, 0.4)

	var rings: Array = []
	for r: Array in RINGS:
		rings.append([r[0] * length, r[1] * wide, r[2] * tall, r[3]])

	for k in rings.size() - 1:
		var ra: Array = rings[k]
		var rb: Array = rings[k + 1]
		var axis := Vector3(0.0, (ra[3] + rb[3]) * 0.5, (ra[0] + rb[0]) * 0.5)
		for i in SIDES:
			var a0 := TAU * i / SIDES + PI / SIDES
			var a1 := TAU * (i + 1) / SIDES + PI / SIDES
			var pa0 := Vector3(cos(a0) * ra[1], ra[3] + sin(a0) * ra[2], ra[0])
			var pa1 := Vector3(cos(a1) * ra[1], ra[3] + sin(a1) * ra[2], ra[0])
			var pb0 := Vector3(cos(a0) * rb[1], rb[3] + sin(a0) * rb[2], rb[0])
			var pb1 := Vector3(cos(a1) * rb[1], rb[3] + sin(a1) * rb[2], rb[0])
			var up := sin((a0 + a1) * 0.5)
			var col := side
			if k in bars:
				col = bar
			elif up > 0.6:
				col = head if k < 2 else back
			elif up < -0.5:
				col = belly
			elif k < 1:
				col = head
			mb.tri_out(pa0, pa1, pb1, col, axis)
			mb.tri_out(pa0, pb1, pb0, col, axis)

	# tail: a fan of triangles from the end of the body
	var root := Vector3(0.0, 0.0, 0.9 * length)
	var tail_len: float = look.get("tail_len", 0.6)
	var spread: float = look.get("spread", 0.85)
	var fork: float = look.get("fork", 0.5)
	var droop: float = look.get("droop", 0.0)
	var rim: Array[Vector3] = []
	for i in 5:
		var u := i / 2.0 - 1.0
		var reach := tail_len * (1.0 - fork * (1.0 - absf(u)) * 0.75)
		var ang := u * spread
		rim.append(root + Vector3(0.0, sin(ang) * reach - droop * reach * cos(ang), cos(ang) * reach))
	for i in 4:
		mb.tri(root, rim[i], rim[i + 1], fin if i % 2 == 0 else fin.darkened(0.12), Vector3.RIGHT)

	# dorsal and anal fins, rooted inside the body so neither floats clear of it
	var sweep: float = look.get("sweep", 0.1)
	var dorsal: float = look.get("dorsal", 0.3)
	if dorsal > 0.0:
		var a := Vector3(0.0, _top(rings, -0.4 * length) - 0.04, -0.4 * length)
		var b := Vector3(0.0, _top(rings, 0.3 * length) - 0.03, 0.3 * length)
		var tip := Vector3(0.0, _top(rings, 0.0) + dorsal, (0.05 + sweep) * length)
		mb.tri(a, tip, b, fin, Vector3.RIGHT)
		mb.tri(tip, b, Vector3(0.0, b.y + dorsal * 0.35, b.z + sweep * 0.4), fin.darkened(0.12), Vector3.RIGHT)
	var anal: float = look.get("anal", 0.18)
	if anal > 0.0:
		var a := Vector3(0.0, _bottom(rings, 0.0) + 0.04, 0.0)
		var b := Vector3(0.0, _bottom(rings, 0.5 * length) + 0.03, 0.5 * length)
		var tip := Vector3(0.0, _bottom(rings, 0.25 * length) - anal, (0.3 + sweep) * length)
		mb.tri(a, tip, b, fin, Vector3.RIGHT)

	var eye: float = look.get("eye", 1.3)
	for sx: float in [-1.0, 1.0]:
		# pectoral fin
		var pz := -0.55 * length
		var px := sx * _half(rings, pz, 1) * 0.9
		var py := _half(rings, pz, 3) - _half(rings, pz, 2) * 0.35
		mb.tri(Vector3(px, py, pz), Vector3(px + sx * 0.32, py - 0.2, pz + 0.3), Vector3(px, py - 0.08, pz + 0.3), fin, Vector3.UP)
		# eye
		var ez := -0.85 * length
		var e := Vector3(sx * (_half(rings, ez, 1) * 0.98 + 0.004), _half(rings, ez, 3) + _half(rings, ez, 2) * 0.3, ez)
		mb.quad(e + Vector3(0, 0.07, -0.07) * eye, e + Vector3(0, 0.07, 0.07) * eye, e + Vector3(0, -0.07, 0.07) * eye,
				e + Vector3(0, -0.07, -0.07) * eye, Color(0.97, 0.95, 0.85), Vector3(sx, 0, 0))
		var p := e + Vector3(sx * 0.006, 0.0, -0.01)
		mb.quad(p + Vector3(0, 0.04, -0.04) * eye, p + Vector3(0, 0.04, 0.04) * eye, p + Vector3(0, -0.04, 0.04) * eye,
				p + Vector3(0, -0.04, -0.04) * eye, Color(0.03, 0.03, 0.05), Vector3(sx, 0, 0))
	return mb.build()


## One of a ring's numbers (1 half-width, 2 half-height, 3 y-centre) at any z along the body.
static func _half(rings: Array, z: float, what: int) -> float:
	for r in rings.size() - 1:
		var z0: float = rings[r][0]
		var z1: float = rings[r + 1][0]
		if z >= z0 and z <= z1:
			return lerpf(rings[r][what], rings[r + 1][what], (z - z0) / (z1 - z0))
	return 0.0


static func _top(rings: Array, z: float) -> float:
	return _half(rings, z, 3) + _half(rings, z, 2)


static func _bottom(rings: Array, z: float) -> float:
	return _half(rings, z, 3) - _half(rings, z, 2)
