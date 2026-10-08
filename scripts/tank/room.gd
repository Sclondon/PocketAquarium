extends Node3D
## The room the tank is kept in: a tall wooden shelf unit against a wall at night, with a slot
## for each of three tanks, one above the other. The tank in the middle slot stands at the
## origin; the other two slots are empty for now. Most of the light is the tank's own lamp.
##
## The unit is built to take the biggest tank, so it never changes; only the odds and ends on
## its shelves do, to keep clear of whatever tanks there are (see `dress`).

const MB := preload("res://scripts/util/mesh_builder.gd")
const Props := preload("res://scripts/tank/props.gd")
const Models := preload("res://scripts/tank/models.gd")

## Metres from one shelf to the next, and how thick a shelf is.
const SLOT_GAP := 2.9
const BOARD := 0.14
## Half the width of the unit (to the inside of its sides), and how far it comes forward and
## goes back from the middle of a tank.
const HALF := 2.3
const FRONT := 1.15
const BACK := 1.25
## The y of the floor of each slot: where a tank's base stands.
const SLOTS := [-2.0 * SLOT_GAP, -SLOT_GAP, 0.0, SLOT_GAP, 2.0 * SLOT_GAP]
## The y of the top of the unit, where the covered tank stands.
const TOP := 3.0 * SLOT_GAP - 0.1

const WOOD := Color(0.26, 0.2, 0.2)
const WALL := Color(0.13, 0.17, 0.26)
const NIGHT := Color(0.012, 0.014, 0.035)

var _mat: ShaderMaterial
var _env: Environment
var _key: DirectionalLight3D
var _odds: MeshInstance3D
var _cloth: MeshInstance3D
var _cave: MeshInstance3D
## What lives under the cloth, whether it has come out from behind its rock, and how far out.
var olm_out := false
var _olm: MeshInstance3D
var _olm_mat: ShaderMaterial
var _olm_at := 0.0
var _dressed_for := ""


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/psx.gdshader")
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = NIGHT
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.3, 0.34, 0.75)
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	# the moon through the window, low and from one side: barely there
	_key = DirectionalLight3D.new()
	_key.rotation = Vector3(-0.5, 0.7, 0.0)
	_key.light_color = Color(0.55, 0.65, 1.0)
	add_child(_key)
	set_lamp(1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var mb := MB.new()
	var low: float = SLOTS[0] - 0.1 - BOARD
	var high: float = SLOTS[SLOTS.size() - 1] + SLOT_GAP
	var mid_z := (FRONT - BACK) * 0.5
	# shelves: one under each slot and one over the top
	for y: float in SLOTS + [high]:
		Props.box(mb, Vector3(0.0, y - 0.1 - BOARD * 0.5, mid_z), Vector3(HALF * 2.0 + 0.3, BOARD, FRONT + BACK), WOOD, rng)
	# the sides, the plinth it stands on, and a back of planks
	for sx: float in [-1.0, 1.0]:
		Props.box(mb, Vector3(sx * (HALF + 0.08), (low + high) * 0.5 - 0.1, mid_z), Vector3(0.16, high - low + 0.2, FRONT + BACK),
				Props.shade(WOOD, 0.85), rng)
	Props.box(mb, Vector3(0.0, low - 0.2, mid_z - 0.05), Vector3(HALF * 2.0 + 0.2, 0.4, FRONT + BACK - 0.1), Props.shade(WOOD, 0.6), rng)
	var planks := 10
	for i in planks:
		var x0 := lerpf(-HALF, HALF, float(i) / planks)
		var x1 := lerpf(-HALF, HALF, float(i + 1) / planks)
		mb.quad(Vector3(x0, low, -BACK + 0.02), Vector3(x1, low, -BACK + 0.02), Vector3(x1, high, -BACK + 0.02),
				Vector3(x0, high, -BACK + 0.02), Props.shade(WOOD, rng.randf_range(0.5, 0.72)), Vector3.BACK)

	# the wall, with a rail along it, and the floor
	var wall_z := -BACK - 0.02
	var floor_y := low - 0.4
	mb.quad(Vector3(-16.0, floor_y, wall_z), Vector3(16.0, floor_y, wall_z), Vector3(16.0, high + 4.0, wall_z),
			Vector3(-16.0, high + 4.0, wall_z), WALL, Vector3.BACK)
	mb.quad(Vector3(-16.0, floor_y, wall_z + 0.01), Vector3(16.0, floor_y, wall_z + 0.01), Vector3(16.0, SLOTS[0] + 0.6, wall_z + 0.01),
			Vector3(-16.0, SLOTS[0] + 0.6, wall_z + 0.01), Props.shade(WALL, 0.6), Vector3.BACK)
	Props.box(mb, Vector3(0.0, SLOTS[0] + 0.64, wall_z + 0.03), Vector3(32.0, 0.1, 0.06), Props.shade(WOOD, 1.2))
	for i in 16:
		var x0 := -16.0 + i * 2.0
		mb.quad(Vector3(x0, floor_y, wall_z), Vector3(x0 + 2.0, floor_y, wall_z), Vector3(x0 + 2.0, floor_y, 6.0),
				Vector3(x0, floor_y, 6.0), Props.shade(WOOD, rng.randf_range(0.45, 0.6)), Vector3.UP)

	# a window on one side, with the moon behind it, and a picture on the other
	_window(mb, Vector3(-5.2, 1.3, wall_z + 0.02))
	_window(mb, Vector3(-5.2, 1.3 + 2.0 * SLOT_GAP, wall_z + 0.02))
	_picture(mb, Vector3(4.3, 1.5, wall_z + 0.02))
	var built := MeshInstance3D.new()
	built.mesh = mb.build()
	built.material_override = _mat
	add_child(built)
	_odds = MeshInstance3D.new()
	_odds.material_override = _mat
	add_child(_odds)
	_covered_tank()


## Puts the odds and ends on the shelves where the tanks leave room for them. `widths` is how
## wide the tank in each slot is, bottom to top (0 for an empty slot, which gets the most).
func dress(widths: Array[float]) -> void:
	if str(widths) == _dressed_for:
		return
	_dressed_for = str(widths)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var mb := MB.new()
	for i in SLOTS.size():
		var y: float = SLOTS[i] - 0.1
		var spare := HALF - widths[i] * 0.5
		if widths[i] <= 0.0:
			# nothing here yet: a few things left on the shelf
			Props.books(mb, Vector3(-HALF + 0.45, y, -0.5), rng)
			if i % 2 == 0:
				Props.box(mb, Vector3(HALF - 0.6, y + 0.25, -0.4), Vector3(0.8, 0.5, 0.6), Color(0.6, 0.48, 0.32), rng, 0.01)
			else:
				Props.pot_plant(mb, Vector3(HALF - 0.5, y, -0.3), rng)
			continue
		if spare > 0.5:
			if i == 2:
				Props.tin(mb, Vector3(-HALF + spare * 0.45, y, 0.35), rng)
			Props.pot_plant(mb, Vector3(HALF - spare * 0.5, y, 0.1), rng)
		if spare > 0.9:
			Props.books(mb, Vector3(-HALF + 0.35, y, -0.55), rng)
	_odds.mesh = mb.build()


## How bright the tanks' lamps are (0 to 1). The room has next to no light of its own: what
## shows of it is what the lamps spill onto the shelf.
func set_lamp(amount: float) -> void:
	_env.ambient_light_energy = lerpf(0.05, 0.11, amount)
	_key.light_energy = 0.07


func _window(mb: MB, at: Vector3) -> void:
	var frame := Props.shade(WOOD, 1.3)
	Props.box(mb, at, Vector3(2.4, 3.2, 0.08), frame)
	for ix in 2:
		for iy in 2:
			var c := at + Vector3((ix - 0.5) * 1.1, (iy - 0.5) * 1.5, 0.045)
			var sky := Color(0.1, 0.16, 0.4).lerp(Color(0.22, 0.3, 0.6), iy)
			mb.quad(c + Vector3(-0.5, -0.7, 0.0), c + Vector3(0.5, -0.7, 0.0), c + Vector3(0.5, 0.7, 0.0), c + Vector3(-0.5, 0.7, 0.0),
					Props.glow(sky, 0.45), Vector3.BACK)
	# the moon, in the top pane
	var moon := at + Vector3(0.6, 0.85, 0.05)
	for i in 8:
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		mb.tri(moon, moon + Vector3(cos(a0), sin(a0), 0.0) * 0.22, moon + Vector3(cos(a1), sin(a1), 0.0) * 0.22,
				Props.glow(Color(1.0, 0.97, 0.8), 0.7), Vector3.BACK)


func _picture(mb: MB, at: Vector3) -> void:
	Props.box(mb, at, Vector3(1.5, 1.1, 0.06), Props.shade(WOOD, 0.7))
	var paper := at + Vector3(0.0, 0.0, 0.035)
	mb.quad(paper + Vector3(-0.65, -0.45, 0.0), paper + Vector3(0.65, -0.45, 0.0), paper + Vector3(0.65, 0.45, 0.0),
			paper + Vector3(-0.65, 0.45, 0.0), Color(0.85, 0.8, 0.66), Vector3.BACK)
	# a fish, in a few strokes
	var ink := Color(0.75, 0.3, 0.2)
	var c := paper + Vector3(-0.05, 0.0, 0.005)
	mb.quad(c + Vector3(-0.35, 0.0, 0.0), c + Vector3(0.0, -0.17, 0.0), c + Vector3(0.25, 0.0, 0.0), c + Vector3(0.0, 0.17, 0.0), ink, Vector3.BACK)
	mb.tri(c + Vector3(0.22, 0.0, 0.0), c + Vector3(0.45, 0.16, 0.0), c + Vector3(0.45, -0.16, 0.0), ink, Vector3.BACK)


# ------------------------------------------------------------------ the covered tank

## Builds the tank on top of the unit that was there before the keeper was: under a cloth, with
## a note pinned to it. The cloth and what is under it are separate, so the cloth can come off.
func _covered_tank() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var at := Vector3(0.0, TOP, -0.2)
	var size := Vector3(1.7, 1.0, 0.9)
	# what is under the cloth: a bare tank of dark water, and one rock
	var mb := MB.new()
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			Props.box(mb, at + Vector3(sx * size.x * 0.5, size.y * 0.5, sz * size.z * 0.5), Vector3(0.05, size.y, 0.05), Color(0.3, 0.32, 0.4))
	Props.box(mb, at + Vector3(0.0, 0.03, 0.0), Vector3(size.x + 0.04, 0.06, size.z + 0.04), Color(0.3, 0.32, 0.4))
	# (the dark of the water is a wall at the back, so what is on the floor shows against it)
	Props.box(mb, at + Vector3(0.0, 0.47, -size.z * 0.5 + 0.04), Vector3(size.x - 0.05, 0.82, 0.04), Color(0.05, 0.1, 0.16))
	Props.rock(mb, at + Vector3(0.3, 0.06, 0.05), 0.22, rng)
	_cave = MeshInstance3D.new()
	_cave.mesh = mb.build()
	_cave.material_override = _mat
	add_child(_cave)
	# the cloth: a box a little bigger than the tank, with a hem that hangs unevenly, and the note
	var cloth := MB.new()
	var fabric := Color(0.34, 0.3, 0.42)
	Props.box(cloth, at + Vector3(0.0, size.y * 0.5 + 0.03, 0.0), size + Vector3(0.08, 0.06, 0.08), fabric, rng, 0.012)
	for i in 9:
		var x := lerpf(-size.x * 0.5, size.x * 0.5, i / 8.0)
		var drop := 0.05 + 0.06 * absf(sin(i * 1.9))
		cloth.quad(at + Vector3(x - 0.11, 0.0, size.z * 0.5 + 0.05), at + Vector3(x + 0.11, 0.0, size.z * 0.5 + 0.05),
				at + Vector3(x + 0.1, -drop, size.z * 0.5 + 0.06), at + Vector3(x - 0.1, -drop * 0.7, size.z * 0.5 + 0.06),
				Props.shade(fabric, 0.8 + 0.25 * (i % 2)), Vector3.BACK)
	var pin := at + Vector3(-0.35, 0.62, size.z * 0.5 + 0.05)
	cloth.quad(pin + Vector3(-0.13, -0.09, 0.0), pin + Vector3(0.13, -0.1, 0.0), pin + Vector3(0.14, 0.09, 0.0), pin + Vector3(-0.12, 0.1, 0.0),
			Color(0.8, 0.76, 0.62), Vector3.BACK)
	for line in 3:
		var y := 0.045 - line * 0.04
		cloth.quad(pin + Vector3(-0.09, y - 0.006, 0.002), pin + Vector3(0.09 - line * 0.03, y - 0.008, 0.002),
				pin + Vector3(0.09 - line * 0.03, y + 0.004, 0.002), pin + Vector3(-0.09, y + 0.006, 0.002), Color(0.15, 0.13, 0.2), Vector3.BACK)
	_cloth = MeshInstance3D.new()
	_cloth.mesh = cloth.build()
	_cloth.material_override = _mat
	add_child(_cloth)
	# what lives in it (its model is made in Blender: see art/blender/olm.py), drawn like the
	# animals in the tanks, in what light the moon gives
	var model: Mesh = Models.of("olm")
	if model != null:
		_olm_mat = ShaderMaterial.new()
		_olm_mat.shader = preload("res://shaders/fish.gdshader")
		var line := ShaderMaterial.new()
		line.shader = preload("res://shaders/outline.gdshader")
		_olm_mat.next_pass = line
		for mat: ShaderMaterial in [_olm_mat, line]:
			mat.set_shader_parameter("modelled", true)
			mat.set_shader_parameter("swim", 3)
			mat.set_shader_parameter("wag_amp", 0.2)
			mat.set_shader_parameter("leg_from", 0.11)
			mat.set_shader_parameter("lamp", 0.8)
		_olm_mat.set_shader_parameter("key", Color(0.6, 0.72, 1.0))
		_olm_mat.set_shader_parameter("shadow", Color(0.2, 0.22, 0.45))
		_olm_mat.set_shader_parameter("haze", Color(0.03, 0.05, 0.1))
		_olm_mat.set_shader_parameter("water_top", -1000.0)
		line.set_shader_parameter("ink", Color(0.05, 0.06, 0.14))
		_olm = MeshInstance3D.new()
		_olm.mesh = model
		_olm.material_override = _olm_mat
		_olm.basis = Basis(Vector3.UP, PI * 0.5).scaled(Vector3.ONE * 0.2)
		_olm.visible = false
		add_child(_olm)
	# a little of the moon reaches it, and nothing else does
	var moon := OmniLight3D.new()
	moon.light_color = Color(0.5, 0.62, 1.0)
	moon.light_energy = 2.2
	moon.omni_range = 7.0
	moon.omni_attenuation = 0.5
	moon.position = at + Vector3(-1.1, 1.0, 1.5)
	add_child(moon)


## Brings what lives there out from behind its rock, or sends it back.
func show_olm(out: bool) -> void:
	olm_out = out


func _process(delta: float) -> void:
	if _olm == null:
		return
	_olm_at = move_toward(_olm_at, 1.0 if olm_out else 0.0, delta * (0.12 if olm_out else 1.5))
	_olm.visible = _olm_at > 0.01 and is_uncovered()
	var from := Vector3(0.42, TOP + 0.07, -0.25)
	_olm.position = from.lerp(Vector3(-0.35, TOP + 0.07, 0.0), _olm_at)
	_olm_mat.set_shader_parameter("wag_phase", _olm_at * 26.0)
	(_olm_mat.next_pass as ShaderMaterial).set_shader_parameter("wag_phase", _olm_at * 26.0)


## Takes the cloth off the covered tank, or puts it back.
func uncover(off: bool) -> void:
	_cloth.visible = not off


func is_uncovered() -> bool:
	return not _cloth.visible
