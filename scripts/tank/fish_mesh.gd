extends RefCounted
## Builds each animal's model from its species' `look` (see species.gd): smooth-skinned, with
## colours that run into each other from back to belly, fins that pale towards their tips and
## round bright eyes, for fish.gdshader to shade in flat bands of light. Every one is built nose
## at -Z (Godot's forward) and about 2.3 long before `len`.
##
## A look's `plan` is "fish" (the default; whales and sharks are fish as far as this goes),
## "squid" or "jelly". For a fish: `back`, `side`, `belly`, `fin` and `tip` (the fin's edge)
## colours; `bar` and `bars`, a colour and the sevenths of the body (0 at the nose) banded with
## it; `glow`, how brightly its sides glow; `len`, `tall` and `wide`, the body's proportions;
## `tail_len`, `spread` (radians either side), `fork` (0 a fan, 1 a crescent), `droop` and
## `tilt` (a longer top lobe, as a shark's) for the tail, and `flukes` for one that lies flat,
## as a whale's; `dorsal` and `anal`, how tall those fins are, and `sweep`, how far they trail
## back; `pec`, how long its pectoral fins are; `finlets`, a tuna's row of little ones; `eye`,
## how big its eyes are, with `iris` and `eye_patch` colours; `gills`, a shark's slits.
##
## UVs tell the shader what a vertex is part of: y below 1.5 is skin (x runs nose to tail, y
## round the body from the back, 0, to the belly, 1); y of 2 is a fin (x runs root to tip);
## y of 3 is an eye.

const Species := preload("res://scripts/tank/species.gd")

## z, half-width, half-height, y-centre
const RINGS := [
	[-1.20, 0.035, 0.04, -0.02],
	[-1.08, 0.11, 0.14, -0.01],
	[-0.90, 0.19, 0.25, 0.01],
	[-0.60, 0.26, 0.37, 0.04],
	[-0.20, 0.28, 0.42, 0.06],
	[0.20, 0.25, 0.36, 0.04],
	[0.55, 0.16, 0.22, 0.01],
	[0.80, 0.08, 0.12, 0.00],
	[0.95, 0.04, 0.07, 0.00],
]
const STATIONS := 22
const ROUND := 14

static var _cache := {}


## The mesh for a species (built once).
static func of(id: String) -> ArrayMesh:
	if not _cache.has(id):
		_cache[id] = build(Species.LIST[id].look)
	return _cache[id]


static func build(look: Dictionary) -> ArrayMesh:
	var skin := Hide.new()
	match look.get("plan", "fish"):
		"squid":
			_squid(skin, look)
		"jelly":
			_jelly(skin, look)
		_:
			_fish(skin, look)
	return skin.build()


## A mesh of shared, smooth-shaded vertices.
class Hide:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	func point(at: Vector3, col: Color, uv := Vector2.ZERO) -> int:
		verts.append(at)
		normals.append(Vector3.ZERO)
		colors.append(col)
		uvs.append(uv)
		return verts.size() - 1

	## A triangle facing `out` (or as wound, if out is zero). Its corners' normals take it in.
	func tri(a: int, b: int, c: int, out := Vector3.ZERO) -> void:
		# (Godot's front faces are wound clockwise)
		var n := (verts[c] - verts[a]).cross(verts[b] - verts[a])
		if n.length_squared() < 1e-12:
			return
		if out != Vector3.ZERO and n.dot(out) < 0.0:
			var swap := b
			b = c
			c = swap
			n = -n
		for i: int in [a, b, c]:
			indices.append(i)
			normals[i] += n.normalized()

	func quad(a: int, b: int, c: int, d: int, out := Vector3.ZERO) -> void:
		tri(a, b, c, out)
		tri(a, c, d, out)

	## A flat fan of triangles (a fin) from `root` round `rim`, in its own vertices.
	func fan(root: Vector3, rim: Array[Vector3], col: Color, tip: Color, out: Vector3) -> void:
		var r := point(root, col, Vector2(0.0, 2.0))
		var before := -1
		for at in rim:
			var now := point(at, tip, Vector2(1.0, 2.0))
			if before >= 0:
				tri(r, before, now, out)
			before = now

	## A tube through `spine`, `sides` round, with a radius and a colour at each point of it.
	func tube(spine: Array[Vector3], radii: Array[float], cols: Array[Color], sides: int, part := 0.5) -> void:
		var rows: Array = []
		for k in spine.size():
			var along := (spine[mini(k + 1, spine.size() - 1)] - spine[maxi(k - 1, 0)]).normalized()
			var ref := Vector3.UP if absf(along.y) < 0.9 else Vector3.RIGHT
			var u := along.cross(ref).normalized()
			var v := along.cross(u)
			var row: Array[int] = []
			for i in sides:
				var a := TAU * i / sides
				row.append(point(spine[k] + (u * cos(a) + v * sin(a)) * radii[k], cols[k],
						Vector2(float(k) / (spine.size() - 1), part)))
			rows.append(row)
		for k in spine.size() - 1:
			for i in sides:
				var j := (i + 1) % sides
				var mid := (spine[k] + spine[k + 1]) * 0.5
				quad(rows[k][i], rows[k][j], rows[k + 1][j], rows[k + 1][i],
						(verts[rows[k][i]] + verts[rows[k][j]]) * 0.5 - mid)

	## A round eye on the side of a head: iris, pupil and a glint, looking out along `out`.
	func eye(at: Vector3, out: Vector3, size: float, iris: Color) -> void:
		var u := out.cross(Vector3.UP).normalized()
		var v := u.cross(out).normalized()
		# (each part stands a little further out than the one under it)
		for part: Array in [[1.0, iris, 0.0], [0.6, Color(0.03, 0.03, 0.05), 0.22], [0.2, Color(1, 1, 1), 0.4]]:
			var centre := at + out * float(part[2]) * size
			if part[0] == 0.2:
				centre += (u * -0.3 + v * 0.35) * size
			var rim: Array[Vector3] = []
			for i in 11:
				var a := TAU * i / 10.0
				rim.append(centre + (u * cos(a) + v * sin(a)) * size * float(part[0]))
			var r := point(centre + out * size * 0.12 * float(part[0]), part[1], Vector2(0.0, 3.0))
			var before := -1
			for p in rim:
				var now := point(p, part[1], Vector2(1.0, 3.0))
				if before >= 0:
					tri(r, before, now, out)
				before = now

	func build() -> ArrayMesh:
		for i in normals.size():
			normals[i] = normals[i].normalized() if normals[i].length_squared() > 1e-10 else Vector3.UP
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


# ------------------------------------------------------------------ fish

static func _fish(skin: Hide, look: Dictionary) -> void:
	var length: float = look.get("len", 1.0)
	var tall: float = look.get("tall", 1.0)
	var wide: float = look.get("wide", 1.0)
	var back: Color = look.back
	var belly: Color = look.belly
	var fin: Color = look.fin
	var tip: Color = look.get("tip", fin.lightened(0.35))
	var glow: float = look.get("glow", 0.0)
	var side := Color(look.side.r, look.side.g, look.side.b, 1.0 - glow)
	var bar: Color = look.get("bar", back)
	var bars: Array = look.get("bars", [])
	var head: Color = look.get("head", back.lerp(look.side, 0.35))
	var rings: Array = []
	for r: Array in RINGS:
		rings.append([r[0] * length, r[1] * wide, r[2] * tall, r[3]])

	# the body: rings of vertices from nose to tail, coloured from the back round to the belly
	var z_from: float = rings[0][0]
	var z_to: float = rings[rings.size() - 1][0]
	var rows: Array = []
	for s in STATIONS:
		var t := float(s) / (STATIONS - 1)
		var z := lerpf(z_from, z_to, t)
		var hw := _at(rings, z, 1)
		var hh := _at(rings, z, 2)
		var yc := _at(rings, z, 3)
		var banded := int(t * 7.0) in bars
		var row: Array[int] = []
		for i in ROUND:
			# (from the top, down one side, and back up the other)
			var a := TAU * i / ROUND
			var up := cos(a)
			var col := side
			if banded:
				col = bar
			elif up > 0.0:
				col = side.lerp(back, smoothstep(0.1, 0.7, up))
				col = col.lerp(head, smoothstep(0.22, 0.05, t) * 0.8)
			else:
				col = side.lerp(belly, smoothstep(-0.1, -0.7, up))
			row.append(skin.point(Vector3(sin(a) * hw, yc + up * hh, z), col, Vector2(t, (1.0 - up) * 0.5)))
		rows.append(row)
	for s in STATIONS - 1:
		for i in ROUND:
			var j := (i + 1) % ROUND
			var a := TAU * (i + 0.5) / ROUND
			skin.quad(rows[s][i], rows[s][j], rows[s + 1][j], rows[s + 1][i], Vector3(sin(a), cos(a), 0.0))
	var nose: int = skin.point(Vector3(0.0, rings[0][3], z_from - 0.05 * length), head, Vector2(0.0, 0.5))
	var stump: int = skin.point(Vector3(0.0, 0.0, z_to + 0.02), back, Vector2(1.0, 0.5))
	for i in ROUND:
		var j := (i + 1) % ROUND
		skin.tri(nose, rows[0][i], rows[0][j], Vector3.FORWARD)
		skin.tri(stump, rows[STATIONS - 1][i], rows[STATIONS - 1][j], Vector3.BACK)

	# tail: a fan from the end of the body, upright (or lying flat, for a whale's flukes)
	var root := Vector3(0.0, 0.0, 0.9 * length)
	var tail_len: float = look.get("tail_len", 0.6)
	var spread: float = look.get("spread", 0.85)
	var fork: float = look.get("fork", 0.5)
	var droop: float = look.get("droop", 0.0)
	var tilt: float = look.get("tilt", 0.0)
	var flat: bool = look.get("flukes", false)
	var rim: Array[Vector3] = []
	for i in 13:
		var u := i / 6.0 - 1.0
		var reach := tail_len * (1.0 - fork * pow(1.0 - absf(u), 1.5) * 0.8) * (1.0 + tilt * u)
		var ang := u * spread
		var across := sin(ang) * reach
		var along := cos(ang) * reach
		rim.append(root + (Vector3(across, 0.0, along) if flat else Vector3(0.0, across - droop * along, along)))
	skin.fan(root, rim, fin, tip, Vector3.UP if flat else Vector3.RIGHT)

	# dorsal and anal fins, rooted inside the body so neither floats clear of it
	var sweep: float = look.get("sweep", 0.1)
	var dorsal: float = look.get("dorsal", 0.3)
	if dorsal > 0.0:
		var a := Vector3(0.0, _top(rings, -0.4 * length) - 0.05, -0.4 * length)
		var b := Vector3(0.0, _top(rings, 0.3 * length) - 0.04, 0.3 * length)
		var peak := Vector3(0.0, _top(rings, 0.0) + dorsal, (0.02 + sweep) * length)
		var edge: Array[Vector3] = [a, a.lerp(peak, 0.55) + Vector3(0.0, dorsal * 0.12, 0.0), peak,
				peak.lerp(b, 0.45) + Vector3(0.0, dorsal * 0.1, sweep * 0.2), b]
		skin.fan((a + b) * 0.5 - Vector3(0.0, 0.05, 0.0), edge, fin, tip, Vector3.RIGHT)
	var anal: float = look.get("anal", 0.18)
	if anal > 0.0:
		var a := Vector3(0.0, _bottom(rings, 0.05 * length) + 0.05, 0.05 * length)
		var b := Vector3(0.0, _bottom(rings, 0.55 * length) + 0.03, 0.55 * length)
		var peak := Vector3(0.0, _bottom(rings, 0.3 * length) - anal, (0.32 + sweep) * length)
		var edge: Array[Vector3] = [a, a.lerp(peak, 0.6) - Vector3(0.0, anal * 0.1, 0.0), peak, b]
		skin.fan((a + b) * 0.5 + Vector3(0.0, 0.04, 0.0), edge, fin, tip, Vector3.RIGHT)
	# a tuna's finlets: a row of little fins down to the tail, above and below
	for k: int in look.get("finlets", 0):
		var z := lerpf(0.42, 0.82, float(k) / maxf(look.finlets - 1.0, 1.0)) * length
		for sy: float in [1.0, -1.0]:
			var y := (_top(rings, z) if sy > 0.0 else _bottom(rings, z)) - sy * 0.015
			var edge: Array[Vector3] = [Vector3(0.0, y, z - 0.04), Vector3(0.0, y + sy * 0.09, z + 0.05), Vector3(0.0, y, z + 0.05)]
			skin.fan(Vector3(0.0, y - sy * 0.01, z), edge, tip, tip, Vector3.RIGHT)

	var eye: float = look.get("eye", 1.2)
	var pec: float = look.get("pec", 0.34)
	for sx: float in [-1.0, 1.0]:
		# pectoral fin: out, down and back from behind the head
		var pz := -0.55 * length
		var at := Vector3(sx * _at(rings, pz, 1) * 0.9, _at(rings, pz, 3) - _at(rings, pz, 2) * 0.4, pz)
		var out := Vector3(sx * 0.75, -0.45, 0.5).normalized()
		var back_edge := Vector3(0.0, -0.1, 1.0)
		var edge: Array[Vector3] = [at + Vector3(0.0, 0.03, -0.07), at + out * pec * 0.7 + Vector3(0.0, 0.04, -0.02),
				at + out * pec + back_edge * pec * 0.15, at + out * pec * 0.55 + back_edge * pec * 0.45, at + back_edge * 0.16]
		skin.fan(at, edge, fin, tip, Vector3(sx * 0.3, 1.0, 0.0))
		# pelvic fin, small, under the belly
		var vz := 0.12 * length
		var vat := Vector3(sx * _at(rings, vz, 1) * 0.45, _bottom(rings, vz) + 0.05, vz)
		var vedge: Array[Vector3] = [vat + Vector3(0.0, 0.0, -0.05), vat + Vector3(sx * 0.1, -0.16, 0.14), vat + Vector3(0.0, 0.0, 0.14)]
		if anal > 0.0:
			skin.fan(vat, vedge, fin, tip, Vector3(sx, 0.2, 0.0))
		# eye, with a patch behind it for those that wear one
		var ez := -0.9 * length
		var e := Vector3(sx * (_at(rings, ez, 1) * 0.96 + 0.006), _at(rings, ez, 3) + _at(rings, ez, 2) * 0.28, ez)
		var look_out := Vector3(sx, 0.1, -0.22).normalized()
		if look.has("eye_patch"):
			var pz2 := ez + 0.2 * length
			var patch: Array[Vector3] = []
			var centre := Vector3(sx * (_at(rings, pz2, 1) * 0.97 + 0.004), e.y + 0.07, pz2)
			for i in 9:
				var a := TAU * i / 8.0
				patch.append(centre + Vector3(0.0, sin(a) * 0.07, cos(a) * 0.16))
			skin.fan(centre + Vector3(sx * 0.004, 0.0, 0.0), patch, look.eye_patch, look.eye_patch, Vector3(sx, 0.0, 0.0))
		skin.eye(e, look_out, 0.075 * eye, look.get("iris", Color(0.98, 0.93, 0.72)))
		# a shark's gill slits
		if look.get("gills", false):
			for g in 4:
				var gz := (-0.72 + g * 0.045) * length
				var gx := sx * (_at(rings, gz, 1) * 0.985 + 0.004)
				var gy := _at(rings, gz, 3)
				var slit: Array[Vector3] = [Vector3(gx, gy + 0.11, gz), Vector3(gx, gy + 0.11, gz + 0.012), Vector3(gx, gy - 0.1, gz + 0.012)]
				skin.fan(Vector3(gx, gy - 0.1, gz), slit, back.darkened(0.5), back.darkened(0.5), Vector3(sx, 0.0, 0.0))


## One of a ring's numbers (1 half-width, 2 half-height, 3 y-centre) at any z along the body,
## eased between the rings so the outline has no corners.
static func _at(rings: Array, z: float, what: int) -> float:
	for r in rings.size() - 1:
		var z0: float = rings[r][0]
		var z1: float = rings[r + 1][0]
		if z >= z0 and z <= z1:
			var t := (z - z0) / (z1 - z0)
			var before: float = rings[maxi(r - 1, 0)][what]
			var after: float = rings[mini(r + 2, rings.size() - 1)][what]
			var a: float = rings[r][what]
			var b: float = rings[r + 1][what]
			# (Catmull-Rom through the four rings about here)
			return 0.5 * ((2.0 * a) + (b - before) * t + (2.0 * before - 5.0 * a + 4.0 * b - after) * t * t
					+ (3.0 * a - before - 3.0 * b + after) * t * t * t)
	return 0.0


static func _top(rings: Array, z: float) -> float:
	return _at(rings, z, 3) + _at(rings, z, 2)


static func _bottom(rings: Array, z: float) -> float:
	return _at(rings, z, 3) - _at(rings, z, 2)


# ------------------------------------------------------------------ squid

## It swims mantle first: the pointed end with its two fins leads (-Z), and the head, eight
## arms and two long tentacles trail behind.
static func _squid(skin: Hide, look: Dictionary) -> void:
	var back: Color = look.back
	var belly: Color = look.belly
	var tip: Color = look.get("tip", back.lightened(0.3))
	var spine: Array[Vector3] = []
	var radii: Array[float] = []
	var cols: Array[Color] = []
	for p: Array in [[-1.45, 0.02], [-1.25, 0.12], [-0.95, 0.21], [-0.55, 0.27], [-0.15, 0.28], [0.1, 0.24], [0.2, 0.17], [0.32, 0.2], [0.5, 0.19], [0.6, 0.12]]:
		spine.append(Vector3(0.0, 0.0, p[0]))
		radii.append(p[1])
		cols.append(back if p[0] < 0.15 else back.lerp(belly, 0.35))
	skin.tube(spine, radii, cols, 12)
	# the two fins at the pointed end
	for sx: float in [-1.0, 1.0]:
		var edge: Array[Vector3] = [Vector3(sx * 0.04, 0.0, -1.42), Vector3(sx * 0.34, 0.0, -1.2), Vector3(sx * 0.4, 0.0, -0.98),
				Vector3(sx * 0.2, 0.0, -0.72)]
		skin.fan(Vector3(sx * 0.12, 0.0, -1.0), edge, back, tip, Vector3.UP)
		skin.eye(Vector3(sx * 0.2, 0.03, 0.38), Vector3(sx, 0.05, 0.0).normalized(), 0.11 * float(look.get("eye", 1.0)),
				look.get("iris", Color(0.98, 0.93, 0.72)))
	# eight arms in a ring, and two tentacles twice as long, each with a club at its end
	for i in 10:
		var long := i >= 8
		var a := TAU * i / 8.0 + (0.4 if long else 0.0)
		var out := Vector3(cos(a), sin(a), 0.0)
		var reach := 1.9 if long else 0.95 + 0.12 * sin(i * 2.4)
		var arm: Array[Vector3] = []
		var thick: Array[float] = []
		var shade: Array[Color] = []
		for k in 7:
			var t := k / 6.0
			arm.append(Vector3(0.0, 0.0, 0.55) + out * (0.07 + 0.1 * sin(t * PI)) + Vector3(0.0, 0.0, reach * t))
			var r := 0.045 * (1.0 - t * 0.8)
			if long:
				r = 0.022 if t < 0.75 else 0.05 * (1.0 - (t - 0.75) * 3.0)
			thick.append(maxf(r, 0.006))
			shade.append(back.lerp(tip, t * 0.6))
		skin.tube(arm, thick, shade, 5)


# ------------------------------------------------------------------ jellyfish

## A bell, crown up (+Y), with a fringe of tentacles and four frilled arms hanging under it.
static func _jelly(skin: Hide, look: Dictionary) -> void:
	var back := Color(look.back.r, look.back.g, look.back.b, 1.0 - float(look.get("glow", 0.4)))
	var tip: Color = look.get("tip", look.back.lightened(0.4))
	var rows: Array = []
	var around := 14
	for j in 6:
		var a := (PI * 0.5) * j / 5.0
		var row: Array[int] = []
		for i in around:
			var b := TAU * i / around
			var flare := 1.0 + (0.08 if j == 5 and i % 2 == 0 else 0.0)
			row.append(skin.point(Vector3(cos(b) * sin(a) * 0.55 * flare, cos(a) * 0.42, sin(b) * sin(a) * 0.55 * flare),
					back.lerp(tip, j / 5.0 * 0.6), Vector2(j / 5.0, 0.2)))
		rows.append(row)
	for j in 5:
		for i in around:
			var k := (i + 1) % around
			var b := TAU * (i + 0.5) / around
			skin.quad(rows[j][i], rows[j][k], rows[j + 1][k], rows[j + 1][i], Vector3(cos(b), 0.6, sin(b)))
	for i in around:
		var b := TAU * i / around
		var from := Vector3(cos(b) * 0.5, 0.0, sin(b) * 0.5)
		var edge: Array[Vector3] = [from + Vector3(cos(b + 0.25), 0.0, sin(b + 0.25)) * 0.03, from + Vector3(0.0, -1.1 - 0.3 * sin(i * 1.9), 0.0)]
		skin.fan(from, edge, tip, tip, Vector3(cos(b), 0.0, sin(b)))
	for i in 4:
		var b := TAU * i / 4.0 + 0.4
		var out := Vector3(cos(b), 0.0, sin(b))
		var edge: Array[Vector3] = []
		for k in 7:
			var t := k / 6.0
			edge.append(out * (0.1 + 0.07 * sin(t * 9.0)) + Vector3(0.0, -0.75 * t, 0.0))
		skin.fan(out * 0.02 + Vector3(0.0, 0.05, 0.0), edge, back, tip, out.cross(Vector3.UP))
