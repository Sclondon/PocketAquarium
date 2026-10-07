extends RefCounted
## Procedural low-poly pieces for the tank. The builders add to a mesh builder at a place, so a
## whole tank's dressing is one mesh; the ones for things that move return a mesh of their own.
## A vertex colour alpha below 1 marks a glowing face (see psx.gdshader).

const MB := preload("res://scripts/util/mesh_builder.gd")

const BOX_FACES := [[0, 2, 6, 4], [1, 3, 7, 5], [0, 1, 5, 4], [2, 3, 7, 6], [0, 1, 3, 2], [4, 5, 7, 6]]


static func glow(c: Color, amount: float) -> Color:
	return Color(c.r, c.g, c.b, 1.0 - amount)


static func vary(c: Color, rng: RandomNumberGenerator, amount := 0.06) -> Color:
	var k := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + k, 0.0, 1.0), clampf(c.g + k * 1.2, 0.0, 1.0), clampf(c.b + k, 0.0, 1.0), c.a)


static func shade(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


# ------------------------------------------------------------------ primitives

## Tapered cylinder from a to b.
static func frustum(mb: MB, a: Vector3, b: Vector3, ra: float, rb: float, sides: int, col: Color,
		cap := true, rng: RandomNumberGenerator = null) -> void:
	var axis := (b - a).normalized()
	var ref := Vector3.UP if absf(axis.y) < 0.95 else Vector3.RIGHT
	var u := axis.cross(ref).normalized()
	var v := axis.cross(u)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := u * cos(a0) + v * sin(a0)
		var d1 := u * cos(a1) + v * sin(a1)
		var c := col if rng == null else vary(col, rng, 0.04)
		mb.quad(a + d0 * ra, a + d1 * ra, b + d1 * rb, b + d0 * rb, c, d0 + d1)
		if cap and rb > 0.001:
			mb.tri(b, b + d0 * rb, b + d1 * rb, c, axis)


## Jittered low-poly ellipsoid.
static func blob(mb: MB, c: Vector3, r: Vector3, rng: RandomNumberGenerator, col: Color,
		lon := 6, lat := 4, jitter := 0.18, cvar := 0.06) -> void:
	var rows: Array = []
	for j in lat + 1:
		var th := PI * j / lat
		var row: Array[Vector3] = []
		if j == 0 or j == lat:
			var pole := c + Vector3(0.0, cos(th), 0.0) * r * (1.0 + rng.randf_range(-jitter, jitter))
			for i in lon:
				row.append(pole)
		else:
			for i in lon:
				var ph := TAU * (i + (0.5 if j % 2 == 1 else 0.0)) / lon
				var dir := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
				row.append(c + dir * r * (1.0 + rng.randf_range(-jitter, jitter)))
		rows.append(row)
	for j in lat:
		var r0: Array[Vector3] = rows[j]
		var r1: Array[Vector3] = rows[j + 1]
		for i in lon:
			var i2 := (i + 1) % lon
			var cc := shade(vary(col, rng, cvar), 1.0 - 0.3 * float(j) / lat)
			mb.tri_out(r0[i], r0[i2], r1[i2], cc, c)
			mb.tri_out(r0[i], r1[i2], r1[i], cc, c)


static func box(mb: MB, c: Vector3, size: Vector3, col: Color, rng: RandomNumberGenerator = null,
		jitter := 0.0, basis := Basis.IDENTITY) -> void:
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for k in 8:
		var p := Vector3(h.x * (1.0 if (k & 1) != 0 else -1.0), h.y * (1.0 if (k & 2) != 0 else -1.0),
				h.z * (1.0 if (k & 4) != 0 else -1.0))
		if rng != null and jitter > 0.0:
			p += Vector3(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter))
		corners.append(c + basis * p)
	for f: Array in BOX_FACES:
		var a: Vector3 = corners[f[0]]
		var b: Vector3 = corners[f[1]]
		var cc: Vector3 = corners[f[2]]
		var d: Vector3 = corners[f[3]]
		var out := (a + b + cc + d) * 0.25 - c
		var k := 1.1 if out.y > 0.3 * out.length() else (0.7 if out.y < -0.3 * out.length() else 0.9)
		var col2 := shade(col if rng == null else vary(col, rng, 0.04), k)
		mb.quad(a, b, cc, d, col2, out)


## A leaf that stands up from `base` and leans over to one side as it rises.
static func ribbon(mb: MB, base: Vector3, height: float, width: float, lean: Vector3, col: Color,
		rng: RandomNumberGenerator, segs := 4) -> void:
	var across := lean.cross(Vector3.UP)
	across = Vector3.RIGHT if across.length() < 0.01 else across.normalized()
	var prev_l := base - across * width
	var prev_r := base + across * width
	for k in segs:
		var t := float(k + 1) / segs
		var p := base + Vector3.UP * height * t + lean * t * t
		var w := width * (1.0 - t * 0.85)
		var l := p - across * w
		var r := p + across * w
		mb.quad(prev_l, prev_r, r, l, shade(vary(col, rng, 0.05), 0.75 + 0.35 * t))
		prev_l = l
		prev_r = r


# ------------------------------------------------------------------ dressing

## A plant, one of three kinds: tall grass, broad leaves, or a red stem.
static func plant(mb: MB, at: Vector3, kind: int, rng: RandomNumberGenerator) -> void:
	match kind % 3:
		0:
			for i in 6:
				var a := rng.randf() * TAU
				ribbon(mb, at + Vector3(cos(a), 0.0, sin(a)) * 0.04, rng.randf_range(0.55, 1.0), 0.035,
						Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.05, 0.2), Color(0.25, 0.7, 0.3), rng)
		1:
			for i in 7:
				var a := TAU * i / 7.0 + rng.randf_range(-0.2, 0.2)
				ribbon(mb, at, rng.randf_range(0.3, 0.55), 0.08,
						Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.15, 0.3), Color(0.15, 0.55, 0.25), rng, 3)
		2:
			var top := at + Vector3(rng.randf_range(-0.06, 0.06), rng.randf_range(0.6, 0.85), 0.0)
			frustum(mb, at, top, 0.018, 0.01, 4, Color(0.5, 0.2, 0.2))
			for i in 7:
				var p := at.lerp(top, (i + 1) / 7.5)
				var a := i * 2.4
				for s: float in [-1.0, 1.0]:
					ribbon(mb, p, 0.05, 0.05, Vector3(cos(a), 0.0, sin(a)) * 0.16 * s, Color(0.8, 0.25, 0.3), rng, 2)


static func rock(mb: MB, at: Vector3, r: float, rng: RandomNumberGenerator) -> void:
	blob(mb, at + Vector3(0.0, r * 0.45, 0.0), Vector3(r, r * 0.7, r * 0.8), rng, Color(0.45, 0.45, 0.48), 6, 3, 0.25)


static func castle(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	var stone := Color(0.6, 0.58, 0.62)
	box(mb, at + Vector3(0.0, 0.17, 0.0), Vector3(0.5, 0.34, 0.3), stone, rng, 0.01)
	for sx: float in [-1.0, 1.0]:
		var foot := at + Vector3(sx * 0.27, 0.0, 0.0)
		frustum(mb, foot, foot + Vector3(0.0, 0.55, 0.0), 0.1, 0.09, 6, stone, true, rng)
		frustum(mb, foot + Vector3(0.0, 0.55, 0.0), foot + Vector3(0.0, 0.8, 0.0), 0.13, 0.0, 6, Color(0.7, 0.2, 0.25), false, rng)
		mb.quad(foot + Vector3(-0.025, 0.36, 0.101), foot + Vector3(0.025, 0.36, 0.101), foot + Vector3(0.025, 0.44, 0.101),
				foot + Vector3(-0.025, 0.44, 0.101), glow(Color(1.0, 0.85, 0.4), 0.6), Vector3.BACK)
	# the gate
	mb.quad(at + Vector3(-0.07, 0.0, 0.152), at + Vector3(0.07, 0.0, 0.152), at + Vector3(0.07, 0.2, 0.152),
			at + Vector3(-0.07, 0.2, 0.152), Color(0.1, 0.08, 0.12), Vector3.BACK)
	for i in 4:
		box(mb, at + Vector3(-0.19 + i * 0.125, 0.37, 0.12), Vector3(0.06, 0.06, 0.06), stone)


static func chest(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	var wood := Color(0.5, 0.3, 0.15)
	box(mb, at + Vector3(0.0, 0.08, 0.0), Vector3(0.32, 0.16, 0.2), wood, rng, 0.005)
	blob(mb, at + Vector3(0.0, 0.17, 0.0), Vector3(0.13, 0.05, 0.08), rng, glow(Color(1.0, 0.8, 0.2), 0.5), 6, 3, 0.2)
	var tilt := Basis(Vector3.RIGHT, -0.9)
	box(mb, at + Vector3(0.0, 0.2, -0.13), Vector3(0.32, 0.06, 0.2), wood.lightened(0.1), rng, 0.005, tilt)
	for sx: float in [-1.0, 1.0]:
		box(mb, at + Vector3(sx * 0.1, 0.08, 0.0), Vector3(0.03, 0.17, 0.21), Color(0.8, 0.65, 0.2))


static func skull(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	var bone := Color(0.9, 0.88, 0.78)
	blob(mb, at + Vector3(0.0, 0.2, 0.0), Vector3(0.17, 0.16, 0.19), rng, bone, 7, 4, 0.06, 0.03)
	box(mb, at + Vector3(0.0, 0.06, 0.07), Vector3(0.17, 0.1, 0.14), shade(bone, 0.9), rng, 0.01)
	for sx: float in [-1.0, 1.0]:
		box(mb, at + Vector3(sx * 0.065, 0.2, 0.16), Vector3(0.07, 0.07, 0.05), Color(0.06, 0.05, 0.08))
	box(mb, at + Vector3(0.0, 0.13, 0.17), Vector3(0.03, 0.04, 0.03), Color(0.06, 0.05, 0.08))


static func column(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	var marble := Color(0.82, 0.8, 0.72)
	box(mb, at + Vector3(0.0, 0.03, 0.0), Vector3(0.26, 0.06, 0.26), marble, rng, 0.01)
	frustum(mb, at + Vector3(0.0, 0.06, 0.0), at + Vector3(0.05, 0.7, 0.0), 0.09, 0.08, 7, marble, true, rng)
	frustum(mb, at + Vector3(0.25, 0.07, 0.12), at + Vector3(0.55, 0.07, 0.2), 0.08, 0.08, 7, shade(marble, 0.9), true, rng)


## The air stone the pump's bubbles come out of, with its hose going up the corner of the tank.
static func air_stone(mb: MB, at: Vector3, top: float) -> void:
	box(mb, at + Vector3(0.0, 0.04, 0.0), Vector3(0.14, 0.07, 0.08), Color(0.3, 0.45, 0.75))
	frustum(mb, at + Vector3(0.06, 0.05, -0.02), Vector3(at.x + 0.08, top, at.z - 0.05), 0.012, 0.012, 4, Color(0.75, 0.85, 0.8), false)


## The filter that hangs on the back of the tank, with its pipe down into the water.
static func filter_box(mb: MB, at: Vector3, reach: float) -> void:
	box(mb, at, Vector3(0.36, 0.3, 0.14), Color(0.16, 0.17, 0.2))
	box(mb, at + Vector3(0.0, 0.1, 0.1), Vector3(0.3, 0.03, 0.1), glow(Color(0.5, 0.85, 1.0), 0.3))
	frustum(mb, at + Vector3(0.1, -0.1, 0.12), at + Vector3(0.1, -reach, 0.12), 0.025, 0.025, 5, Color(0.2, 0.22, 0.26), true)


# ------------------------------------------------------------------ small things

static func snail() -> ArrayMesh:
	var mb := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	box(mb, Vector3(0.0, 0.015, 0.0), Vector3(0.05, 0.03, 0.14), Color(0.75, 0.65, 0.5))
	blob(mb, Vector3(0.0, 0.07, 0.02), Vector3(0.05, 0.06, 0.06), rng, Color(0.75, 0.45, 0.2), 6, 4, 0.1)
	for sx: float in [-1.0, 1.0]:
		frustum(mb, Vector3(sx * 0.015, 0.03, -0.06), Vector3(sx * 0.03, 0.07, -0.08), 0.006, 0.006, 3, Color(0.75, 0.65, 0.5))
	return mb.build()


static func shrimp() -> ArrayMesh:
	var mb := MB.new()
	var pink := Color(0.95, 0.5, 0.45)
	frustum(mb, Vector3(0.0, 0.035, -0.06), Vector3(0.0, 0.045, 0.02), 0.012, 0.022, 5, pink)
	frustum(mb, Vector3(0.0, 0.045, 0.02), Vector3(0.0, 0.025, 0.08), 0.022, 0.008, 5, shade(pink, 0.9))
	mb.tri(Vector3(0.0, 0.025, 0.08), Vector3(-0.03, 0.02, 0.11), Vector3(0.03, 0.02, 0.11), pink, Vector3.UP)
	for sx: float in [-1.0, 1.0]:
		mb.tri(Vector3(sx * 0.008, 0.04, -0.06), Vector3(sx * 0.04, 0.07, -0.13), Vector3(sx * 0.012, 0.04, -0.05), pink, Vector3.UP)
		for i in 3:
			mb.tri(Vector3(sx * 0.012, 0.03, -0.03 + i * 0.03), Vector3(sx * 0.03, 0.0, -0.035 + i * 0.03),
					Vector3(sx * 0.012, 0.03, -0.02 + i * 0.03), shade(pink, 0.8), Vector3(sx, 0.3, 0.0))
	return mb.build()


## A flake of fish food.
static func flake() -> ArrayMesh:
	var mb := MB.new()
	var col := glow(Color(0.95, 0.55, 0.2), 0.3)
	mb.quad(Vector3(-0.02, 0.0, 0.0), Vector3(0.0, 0.006, -0.02), Vector3(0.02, 0.0, 0.0), Vector3(0.0, -0.006, 0.02), col)
	return mb.build()


static func egg() -> ArrayMesh:
	var mb := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	blob(mb, Vector3(0.0, 0.035, 0.0), Vector3(0.035, 0.035, 0.035), rng, glow(Color(1.0, 0.9, 0.7), 0.4), 6, 4, 0.05, 0.02)
	return mb.build()


# ------------------------------------------------------------------ the room

## A row of books standing on a shelf, with one leaning at the end.
static func books(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	var covers := [Color(0.6, 0.2, 0.2), Color(0.2, 0.35, 0.5), Color(0.75, 0.6, 0.3), Color(0.25, 0.4, 0.3), Color(0.45, 0.3, 0.5)]
	var x := 0.0
	for i in 6:
		var thick := rng.randf_range(0.06, 0.12)
		var tall := rng.randf_range(0.5, 0.75)
		var lean := Basis(Vector3.BACK, -0.25) if i == 5 else Basis.IDENTITY
		box(mb, at + Vector3(x + thick * 0.5 + (0.09 if i == 5 else 0.0), tall * 0.5, 0.0), Vector3(thick, tall, 0.45),
				covers[rng.randi() % covers.size()], rng, 0.0, lean)
		x += thick + 0.008


## A plant in a clay pot, with leaves that hang over the side.
static func pot_plant(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	frustum(mb, at, at + Vector3(0.0, 0.3, 0.0), 0.14, 0.2, 7, Color(0.7, 0.38, 0.25), true, rng)
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var out := Vector3(cos(a), 0.0, sin(a))
		blade(mb, at + Vector3(0.0, 0.28, 0.0) + out * 0.05, out, rng.randf_range(0.35, 0.6), 0.07, 0.9, 1.1,
				Color(0.2, 0.5, 0.25), rng, 4)


## A leaf that arches out from `base` along `dir`, rising and then drooping.
static func blade(mb: MB, base: Vector3, dir: Vector3, length: float, width: float, lift: float,
		droop: float, col: Color, rng: RandomNumberGenerator, segs := 3) -> void:
	var across := dir.cross(Vector3.UP).normalized()
	var prev_l := base
	var prev_r := base
	for k in segs:
		var t := float(k + 1) / segs
		var p := base + dir * length * t + Vector3.UP * (lift * t - droop * t * t) * length
		var w := width * sin(PI * minf(t, 0.95))
		mb.quad(prev_l, prev_r, p + across * w, p - across * w, vary(col, rng, 0.05), Vector3.UP)
		prev_l = p - across * w
		prev_r = p + across * w


## A tin of fish food.
static func tin(mb: MB, at: Vector3, rng: RandomNumberGenerator) -> void:
	frustum(mb, at, at + Vector3(0.0, 0.3, 0.0), 0.13, 0.13, 8, Color(0.85, 0.7, 0.2), true, rng)
	frustum(mb, at + Vector3(0.0, 0.3, 0.0), at + Vector3(0.0, 0.34, 0.0), 0.14, 0.14, 8, Color(0.75, 0.2, 0.2), true)
	frustum(mb, at + Vector3(0.0, 0.1, 0.0), at + Vector3(0.0, 0.2, 0.0), 0.134, 0.134, 8, Color(0.2, 0.45, 0.7), false)
