extends Node3D
## The room the tank is kept in: a tall wooden shelf unit against a wall at night, with a slot
## for each of three tanks, one above the other. The tank in the middle slot stands at the
## origin; the other two slots are empty for now. Most of the light is the tank's own lamp.
##
## The unit is built to take the biggest tank, so it never changes; only the odds and ends on
## its shelves do, to keep clear of whatever tanks there are (see `dress`).

const MB := preload("res://scripts/util/mesh_builder.gd")
const Props := preload("res://scripts/tank/props.gd")

## Metres from one shelf to the next, and how thick a shelf is.
const SLOT_GAP := 2.9
const BOARD := 0.14
## Half the width of the unit (to the inside of its sides), and how far it comes forward and
## goes back from the middle of a tank.
const HALF := 2.3
const FRONT := 1.15
const BACK := 1.25
## The y of the floor of each slot: where a tank's base stands.
const SLOTS := [-SLOT_GAP, 0.0, SLOT_GAP]

const WOOD := Color(0.42, 0.26, 0.15)
const WALL := Color(0.2, 0.33, 0.36)
const NIGHT := Color(0.035, 0.045, 0.08)

var _mat: ShaderMaterial
var _env: Environment
var _key: DirectionalLight3D
var _odds: MeshInstance3D
var _dressed_for := ""


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/psx.gdshader")
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = NIGHT
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.5, 0.58, 0.85)
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	# a little warm light from the room, low and from one side
	_key = DirectionalLight3D.new()
	_key.rotation = Vector3(-0.5, 0.7, 0.0)
	_key.light_color = Color(1.0, 0.82, 0.6)
	add_child(_key)
	set_lamp(1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var mb := MB.new()
	var low: float = SLOTS[0] - 0.1 - BOARD
	var high: float = SLOTS[2] + SLOT_GAP
	var mid_z := (FRONT - BACK) * 0.5
	# shelves: one under each slot and one over the top
	for y: float in [SLOTS[0], SLOTS[1], SLOTS[2], high]:
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
	_picture(mb, Vector3(4.3, 1.5, wall_z + 0.02))
	var built := MeshInstance3D.new()
	built.mesh = mb.build()
	built.material_override = _mat
	add_child(built)
	_odds = MeshInstance3D.new()
	_odds.material_override = _mat
	add_child(_odds)


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
			if i == 0:
				Props.box(mb, Vector3(HALF - 0.6, y + 0.25, -0.4), Vector3(0.8, 0.5, 0.6), Color(0.6, 0.48, 0.32), rng, 0.01)
			else:
				Props.pot_plant(mb, Vector3(HALF - 0.5, y, -0.3), rng)
			continue
		if spare > 0.5:
			if i == 1:
				Props.tin(mb, Vector3(-HALF + spare * 0.45, y, 0.35), rng)
			Props.pot_plant(mb, Vector3(HALF - spare * 0.5, y, 0.1), rng)
		if spare > 0.9:
			Props.books(mb, Vector3(-HALF + 0.35, y, -0.55), rng)
	_odds.mesh = mb.build()


## How bright the tank's lamp is (0 to 1): with it off the room is all but dark.
func set_lamp(amount: float) -> void:
	_env.ambient_light_energy = lerpf(0.3, 0.8, amount)
	_key.light_energy = lerpf(0.15, 0.9, amount)


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
