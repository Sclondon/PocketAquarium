extends Node3D
## The tank and everything in it: the glass and gravel, the fish, the plants and other small
## life, the food, the eggs, and the water itself.
##
## It runs in real time, and goes on while the game is shut: the save holds the time it was
## written, and the next visit catches up on the time away (see `elapse`).
##
## The water is three numbers from 0 to 1. Oxygen comes in at the surface (faster with the air
## pump) and from plants in the light, and the fish breathe it. Waste comes from the fish and
## from food left to rot; plants and the filter take it up, and changing the water halves it.
## Algae grows on the glass in the light, faster in dirty water; snails graze it and it can be
## scrubbed off. Fish are harmed by too little oxygen or too much waste (see fish.gd).
##
## A tank is one of two kinds: "fresh", or "sea", a magic salt water tank, which keeps sea life
## of any size (see species.gd) and is dressed with white sand, coral and kelp. They work alike.
##
## It lights itself: a lamp in the hood over the water (see `lamp_glow`), which room.gd dims
## the room by. The origin is the middle of the tank's floor; the tank is `width` (x) by `height` by `depth`.

## A kind of fish was seen for the first time.
signal discovered(species: String)
## Something happened worth telling the player.
signal said(text: String)
## What is in the tank changed.
signal changed

const MB := preload("res://scripts/util/mesh_builder.gd")
const Props := preload("res://scripts/tank/props.gd")
const Species := preload("res://scripts/tank/species.gd")
const Fish := preload("res://scripts/tank/fish.gd")
const Water := preload("res://scripts/sim/water.gd")
const Swarm := preload("res://scripts/sim/swarm.gd")

const Kinds := preload("res://scripts/tank/kinds.gd")

const MAX_PLANTS := 8
const MAX_SNAILS := 3
const MAX_SHRIMPS := 3
const MAX_FOOD := 40
const DAY := 86400.0
## Seconds a flake lies on the gravel before it rots, and the waste it turns into.
const FOOD_KEEPS := 600.0
const FOOD_ROT := 0.02
## Breeding is uncommon: a tank with a pair ready to breed lays an egg about this often. An egg
## takes this long to hatch, and both parents wait this long before breeding again.
const BREED_EVERY := 3.0 * DAY
const HATCH_TIME := DAY
const BREED_WAIT := 4.0 * DAY
## Fish only breed while the tank is no fuller than this share of what it holds, so they never
## crowd themselves out of clean water.
const BREED_ROOM := 0.7
## Seconds between water changes.
const WATER_WAIT := 6.0 * 3600.0
## The longest time away that is caught up on.
const MAX_AWAY := 30.0 * DAY

const FOUL_WATER := Color(0.36, 0.4, 0.12)
## What was in the first tank when the keeper came to it: the last keeper's fish, which do not
## know this one yet.
const LEFT_BEHIND := [
	{"species": "betta", "name": "Admiral", "buddy": {"temper": "grumpy", "bond": 0.1, "spot": [0.7, 0.6, 0.5]}},
	{"species": "kuhli", "name": "Bootlace", "buddy": {"temper": "shy", "bond": 0.05}},
	{"species": "kuhli", "name": "Knot", "buddy": {"temper": "curious", "bond": 0.1}},
	{"species": "kuhli", "name": "Mrs Noodle", "buddy": {"temper": "greedy", "bond": 0.1}},
]
## What its air loses of its damp in a day, what a misting puts back, and what the salt in its
## water gains in a day as the water dries off (for the kinds that have either to mind).
const DRIES := 0.3
const MIST := 0.45
const SALT_CREEP := 0.035
## A new tank's filter is not alive yet: how much of the work it does to start with (it is
## grown in about four days: see sim/water.gd).
const NEW_COLONY := 0.2

## Which kind of home it is (see kinds.gd)
var kind := "fresh"
var size_id := 0
var width := 2.2
var height := 1.5
var depth := 1.2
var water_level := 1.38

var fish: Array[Fish] = []
var plants := 1
var snails := 0
var shrimps := 0
## What is fitted ("pump", "filter") and what is on the gravel ("castle", "chest", ...).
var gear := {}
var decor := {}
## Every kind of animal ever kept, in any tank: main.gd gives every tank the same one.
var dex := {}

## The water itself (sim/water.gd), and its three numbers by name.
var water := Water.new()
var o2: float:
	get:
		return water.o2
	set(value):
		water.o2 = value
var waste: float:
	get:
		return water.waste
	set(value):
		water.waste = value
var algae: float:
	get:
		return water.algae
	set(value):
		water.algae = value
var lamp_on := true
var water_wait := 0.0
## The colony of tiny animals it keeps by the hundred (sim/swarm.gd), for a kind that keeps
## one (null for the rest).
var swarm: Swarm
## How damp its air is and how salty its water (0 to 1), for the kinds that have either to mind.
var humidity := 0.8
var salt := 0.0
## Where the keeper's finger is on the glass, in the tank's own space (null when it is not).
var finger: Variant = null
## Where the keeper's torch shines into the tank, in its own space (null while it is off), and
## whether it is the red one, which the animals take no notice of.
var torch: Variant = null
var torch_red := true
## Seconds left of the animals coming to say hello (see `greet`).
var greeting := 0.0
## How many times each kind of thing has passed between the animals (see `notice`).
var seen := {}

## How long the tank has been kept (seconds), and how fast its clock runs (1 is real time;
## only tests and `--speed=` change it).
var age := 0.0
var time_scale := 1.0

var _shell: Node3D
var _life: Node3D
var _mat: ShaderMaterial
var _plant_mat: ShaderMaterial
var _dry: ShaderMaterial
var _sand: ShaderMaterial
var _glass: ShaderMaterial
var _back: ShaderMaterial
var _top: ShaderMaterial
var _hood: StandardMaterial3D
var _light: OmniLight3D
var _bubbles: MultiMeshInstance3D
var _bubble_from := Vector3.ZERO
var _foods: Array[Dictionary] = []
var _eggs: Array[Dictionary] = []
var _critters: Array[Dictionary] = []
var _flake: ArrayMesh
var _egg: ArrayMesh
var _rng := RandomNumberGenerator.new()
## While catching up on time away nothing is announced; what happened is counted instead.
var _quiet := false
var _hatched := 0
var _died := 0
var _clock := 0.0
var _lamp := 1.0
## Where each shoaling kind is heading, and until when (see `shoal_goal`).
var _shoals := {}
var _next_id := 1
var _specks: MultiMeshInstance3D


func _ready() -> void:
	# (drawn from the one run-wide source, so `--seed=` makes a whole run repeat itself)
	_rng.seed = randi()
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/psx.gdshader")
	_mat.set_shader_parameter("wet", 1.0)
	_plant_mat = ShaderMaterial.new()
	_plant_mat.shader = preload("res://shaders/psx.gdshader")
	_plant_mat.set_shader_parameter("wet", 1.0)
	_plant_mat.set_shader_parameter("sway", 1.0)
	_dry = ShaderMaterial.new()
	_dry.shader = preload("res://shaders/psx.gdshader")
	_sand = ShaderMaterial.new()
	_sand.shader = preload("res://shaders/sand.gdshader")
	_glass = ShaderMaterial.new()
	_glass.shader = preload("res://shaders/glass.gdshader")
	_back = ShaderMaterial.new()
	_back.shader = preload("res://shaders/backdrop.gdshader")
	_top = ShaderMaterial.new()
	_top.shader = preload("res://shaders/surface.gdshader")
	_hood = StandardMaterial3D.new()
	_hood.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flake = Props.flake()
	_egg = Props.egg()

	# the lamp in the hood: it lights the shelf round the tank as well as what is in it
	_light = OmniLight3D.new()
	_light.light_color = Color(0.8, 0.95, 1.0)
	_light.omni_attenuation = 0.4
	add_child(_light)

	_life = Node3D.new()
	add_child(_life)
	_bubbles = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	ball.radial_segments = 6
	ball.rings = 3
	var bubble_mat := StandardMaterial3D.new()
	bubble_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_mat.albedo_color = Color(0.85, 0.96, 1.0, 0.55)
	ball.material = bubble_mat
	mm.mesh = ball
	mm.instance_count = 18
	_bubbles.multimesh = mm
	add_child(_bubbles)
	# the colony, for a kind that keeps one: each animal a speck with a tail, all one mesh
	_specks = MultiMeshInstance3D.new()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	var speck := MB.new()
	var pink := Color(1.0, 0.72, 0.6)
	for side: Array in [[Vector3(0.3, 0.0, 0.0), Vector3(0.0, 0.3, 0.0)], [Vector3(0.0, 0.3, 0.0), Vector3(-0.3, 0.0, 0.0)],
			[Vector3(-0.3, 0.0, 0.0), Vector3(0.0, -0.3, 0.0)], [Vector3(0.0, -0.3, 0.0), Vector3(0.3, 0.0, 0.0)]]:
		speck.tri(Vector3(0.0, 0.0, -0.5), side[0], side[1], pink, side[0] + side[1])
		speck.tri(Vector3(0.0, 0.0, 1.0), side[1], side[0], Props.shade(pink, 0.8), side[0] + side[1])
	many.mesh = speck.build()
	many.instance_count = int(Swarm.MOST)
	_specks.multimesh = many
	_specks.material_override = _mat
	_specks.visible = false
	add_child(_specks)


func _process(delta: float) -> void:
	step(delta)


## The middle of the water, which is what the camera looks at.
func centre() -> Vector3:
	return Vector3(0.0, height * 0.5, 0.0)


## The inside of the tank, floor to brim.
func inside() -> AABB:
	return AABB(Vector3(-width * 0.5, 0.0, -depth * 0.5), Vector3(width, height, depth))


## Where a fish may be: the water, kept `margin` clear of the glass, gravel and surface.
func swim_box(margin: float) -> AABB:
	var low := Vector3(-width * 0.5 + margin, 0.22 + margin * 0.5, -depth * 0.5 + margin)
	if about().get("bank", false):
		# (the water is the half that is not the bank)
		low.x = width * 0.08
	var high := Vector3(width * 0.5 - margin, water_level - margin, depth * 0.5 - margin)
	return AABB(low, (high - low).max(Vector3.ONE * 0.01))


## Where an animal on foot may be: the floor, kept clear of the glass, and (for a climber) the
## back wall up to most of its height. In a home with a bank, one that only walks keeps to it.
func walk_box(gait: String) -> AABB:
	var low := Vector3(-width * 0.5 + 0.12, 0.0, -depth * 0.5 + 0.1)
	var high := Vector3(width * 0.5 - 0.12, height * 0.8 if gait in ["climb", "glide"] else 0.6, depth * 0.5 - 0.12)
	if about().get("bank", false) and gait != "glide":
		high.x = -width * 0.06
	return AABB(low, high - low)


## How high the gravel is at a place. A home with a bank has one along its left side, rising
## out of the water.
func floor_y(x: float, z: float) -> float:
	var ground := 0.1 + 0.035 * sin(x * 3.1 + 1.0) * cos(z * 4.3) + 0.02 * sin(x * 7.7 + z * 5.1)
	if about().get("bank", false):
		ground += smoothstep(width * 0.08, -width * 0.12, x) * (water_level + 0.05)
	return ground


## How much room the fish take up (and the eggs will), out of capacity().
func crowd() -> float:
	var total := 0.0
	for f in fish:
		if not f.dead:
			total += f.room()
	return total


func capacity() -> float:
	return sizes()[size_id].room


## What this kind of home is like (its entry in kinds.gd), and the sizes it comes in.
func about() -> Dictionary:
	return Kinds.of(kind)


func sizes() -> Array:
	return about().sizes


## Whether it has water in it at all.
func is_wet() -> bool:
	return Kinds.is_wet(kind)


## How warm it runs: 0 cold, 0.5 the room, 1 hot.
func warmth() -> float:
	return float(about().get("warm", 0.5)) + (float(about().get("heat_lamp", 0.0)) if lamp_on else 0.0)


## How far what an animal of this kind wants is from what it has here, 0 (content) to 1, and
## what it would say was wrong (empty when nothing is).
func discomfort(species: String) -> float:
	return float(_wrong(species)[0])


func complaint(species: String) -> String:
	return str(_wrong(species)[1])


func _wrong(species: String) -> Array:
	var wants: Dictionary = Species.LIST[species].get("wants", {})
	var worst := 0.0
	var what := ""
	var have := {"warmth": warmth(), "humidity": humidity, "salt": salt}
	var words := {"warmth": ["too cold", "too warm"], "humidity": ["too dry", "too wet"], "salt": ["not salty enough", "too salty"]}
	for need: String in wants:
		var band: Array = wants[need]
		var value: float = have[need]
		var off := clampf(maxf(float(band[0]) - value, value - float(band[1])) / 0.3, 0.0, 1.0)
		if off > worst:
			worst = off
			what = words[need][0 if value < float(band[0]) else 1]
	return [worst, what]


func has_room_for(species: String) -> bool:
	return crowd() + float(Species.LIST[species].load) <= capacity() + 0.001


# ------------------------------------------------------------------ saving

func to_data() -> Dictionary:
	var kept: Array = []
	for f in fish:
		if not f.dead:
			kept.append(f.to_data())
	var laid: Array = []
	for egg in _eggs:
		laid.append({"species": egg.species, "age": egg.age, "x": egg.node.position.x, "z": egg.node.position.z, "grade": egg.get("grade", 0.35)})
	return {"kind": kind, "size": size_id, "plants": plants, "snails": snails, "shrimps": shrimps, "gear": gear.keys(),
			"decor": decor.keys(), "dex": dex.keys(), "o2": o2, "waste": waste, "algae": algae, "lamp": lamp_on,
			"colony": water.colony, "humidity": humidity, "salt": salt,
			"swarm": swarm.to_data() if swarm != null else {},
			"fish": kept, "eggs": laid, "age": age, "water_wait": water_wait,
			"at": Time.get_unix_time_from_system()}


## Sets the tank up from a save. One with no fish listed is a new tank: two guppies and a plant
## in fresh water, and only a frond of kelp in a salt water one.
func load_state(data: Dictionary) -> void:
	for f in fish:
		f.queue_free()
	fish.clear()
	for list: Array in [_foods, _eggs, _critters]:
		for item: Dictionary in list:
			item.node.queue_free()
		list.clear()
	kind = str(data.get("kind", "fresh"))
	if not Kinds.LIST.has(kind):
		kind = "fresh"
	size_id = clampi(int(data.get("size", 0)), 0, sizes().size() - 1)
	plants = clampi(int(data.get("plants", about().get("plants", 1))), 0, MAX_PLANTS)
	snails = clampi(int(data.get("snails", 0)), 0, MAX_SNAILS)
	shrimps = clampi(int(data.get("shrimps", 0)), 0, MAX_SHRIMPS)
	gear = {}
	for id in data.get("gear", about().get("gear", [])):
		gear[str(id)] = true
	decor = {}
	for id in data.get("decor", []):
		decor[str(id)] = true
	for id in data.get("dex", []):
		if Species.LIST.has(str(id)):
			dex[str(id)] = true
	o2 = clampf(data.get("o2", 0.9), 0.0, 1.0)
	waste = clampf(data.get("waste", 0.05), 0.0, 1.0)
	algae = clampf(data.get("algae", 0.0), 0.0, 1.0)
	lamp_on = data.get("lamp", true)
	# (a tank from a save has been running: its filter is alive. One just bought is not)
	water.colony = clampf(data.get("colony", NEW_COLONY if data.has("kind") and not data.has("fish") else 1.0), 0.0, 1.0)
	swarm = null
	if about().has("swarm"):
		swarm = Swarm.new()
		swarm.load_data(data.get("swarm", {}))
	_specks.visible = swarm != null
	humidity = clampf(data.get("humidity", 0.8), 0.0, 1.0)
	salt = clampf(data.get("salt", about().get("salt", 0.0)), 0.0, 1.0)
	age = maxf(data.get("age", 0.0), 0.0)
	water_wait = clampf(data.get("water_wait", 0.0), 0.0, WATER_WAIT)
	_lamp = 1.0 if lamp_on else 0.0
	rebuild()
	var saved: Array = data.get("fish", [])
	if not data.has("fish"):
		# a tank that is bought comes with two guppies. The first tank of all was somebody else's
		# before it was the keeper's, and what is in it has names already
		saved = LEFT_BEHIND
		if data.has("kind"):
			saved = []
			for id: String in about().get("starter", []):
				saved.append({"species": id})
	for entry in saved:
		if entry is Dictionary and Species.LIST.has(str(entry.get("species", ""))):
			# (whatever a save holds is let in, whether or not it belongs in this kind of home)
			_spawn(entry)
	for i in snails:
		_add_critter_node("snail")
	for i in shrimps:
		_add_critter_node("shrimp")
	for entry in data.get("eggs", []):
		if entry is Dictionary and Species.LIST.has(str(entry.get("species", ""))):
			_lay(str(entry.species), float(entry.get("x", 0.0)), float(entry.get("z", 0.0)), float(entry.get("age", 0.0)), float(entry.get("grade", 0.35)))
	if data.has("at"):
		var away := clampf(Time.get_unix_time_from_system() - float(data["at"]), 0.0, MAX_AWAY)
		elapse(away)
		if away > 3600.0:
			var news := "You were away %s." % _span(away)
			if _died > 0:
				news += " %d fish died." % _died
			if _hatched > 0:
				news += " %d hatched." % _hatched
			said.emit(news)
	changed.emit()


## Catches the tank up on `seconds` in which nobody was looking: the fish get hungrier, the
## water changes, eggs hatch. Nothing is fed and nothing is announced.
func elapse(seconds: float) -> void:
	_quiet = true
	_hatched = 0
	_died = 0
	var left := seconds
	while left > 0.0:
		var dt := minf(left, 300.0)
		left -= dt
		for f in fish:
			if not f.dead:
				f.live(dt)
		_step_water(dt)
		_step_eggs(dt)
		_try_breeding(dt)
	_quiet = false


## A length of time in words, to the nearest hour: "3 hours", "2 days".
func _span(seconds: float) -> String:
	if seconds < 1.5 * DAY:
		var hours := maxi(roundi(seconds / 3600.0), 1)
		return "%d hour%s" % [hours, "" if hours == 1 else "s"]
	return "%d days" % roundi(seconds / DAY)


# ------------------------------------------------------------------ building

## Builds the tank and its dressing again (after it grows, or something is bought).
func rebuild() -> void:
	var s: Dictionary = sizes()[size_id]
	width = s.w
	height = s.h
	depth = s.d
	water_level = height * float(about().water)
	if _shell != null:
		_shell.queue_free()
	_shell = Node3D.new()
	add_child(_shell)
	move_child(_shell, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var hw := width * 0.5
	var hd := depth * 0.5

	# the frame: a base, a rim round the top, a post at each corner, and the hood with its lamp
	var frame := MB.new()
	var trim := Color(0.3, 0.2, 0.42) if kind == "sea" else Color(0.24, 0.26, 0.33)
	Props.box(frame, Vector3(0.0, -0.05, 0.0), Vector3(width + 0.1, 0.1, depth + 0.1), trim)
	for sz: float in [-1.0, 1.0]:
		Props.box(frame, Vector3(0.0, height, sz * hd), Vector3(width + 0.08, 0.05, 0.05), trim)
	for sx: float in [-1.0, 1.0]:
		Props.box(frame, Vector3(sx * hw, height, 0.0), Vector3(0.05, 0.05, depth + 0.08), trim)
		for sz: float in [-1.0, 1.0]:
			Props.box(frame, Vector3(sx * hw, height * 0.5, sz * hd), Vector3(0.035, height, 0.035), trim)
	Props.box(frame, Vector3(0.0, height + 0.08, -hd * 0.25), Vector3(width * 0.94, 0.09, depth * 0.4), Color(0.13, 0.14, 0.18))
	if kind == "sea":
		# the magic shows: a line of gold runs round the base, and a gem glows at each corner
		for sz: float in [-1.0, 1.0]:
			Props.box(frame, Vector3(0.0, -0.05, sz * (hd + 0.05)), Vector3(width + 0.12, 0.025, 0.012), Props.glow(Color(1.0, 0.8, 0.3), 0.5))
			for sx: float in [-1.0, 1.0]:
				Props.box(frame, Vector3(sx * hw, height + 0.02, sz * hd), Vector3(0.08, 0.08, 0.08), Props.glow(Color(0.7, 0.45, 1.0), 0.7),
						null, 0.0, Basis(Vector3.UP, 0.785))
	if gear.has("filter"):
		Props.filter_box(frame, Vector3(-hw + 0.35, height - 0.08, -hd - 0.09), 0.5)
	_shell.add_child(_instance(frame.build(), _dry))
	var strip := MeshInstance3D.new()
	var strip_mesh := PlaneMesh.new()
	strip_mesh.size = Vector2(width * 0.88, depth * 0.3)
	strip_mesh.flip_faces = true
	strip.mesh = strip_mesh
	strip.material_override = _hood
	strip.position = Vector3(0.0, height + 0.03, -hd * 0.25)
	_shell.add_child(strip)
	_light.position = Vector3(0.0, height + 0.3, hd * 0.3)
	_light.omni_range = width * 1.5 + 3.5
	# the far end of the water, on the back pane (see backdrop.gdshader)
	var far := MB.new()
	far.quad(Vector3(-hw, 0.0, -hd + 0.004), Vector3(hw, 0.0, -hd + 0.004), Vector3(hw, height, -hd + 0.004),
			Vector3(-hw, height, -hd + 0.004), Color.WHITE, Vector3.BACK, Vector2(0, 0), Vector2(width, 0),
			Vector2(width, height), Vector2(0, height))
	_shell.add_child(_instance(far.build(), _back))
	_back.set_shader_parameter("level", water_level)
	_back.set_shader_parameter("air", about().air)

	var mb := MB.new()
	# the sand, or gravel, in gentle humps (see sand.gdshader for its grain)
	var bed := MB.new()
	var nx := int(width * 12.0)
	var nz := int(depth * 12.0)
	for i in nx:
		for j in nz:
			var x0 := lerpf(-hw, hw, float(i) / nx)
			var x1 := lerpf(-hw, hw, float(i + 1) / nx)
			var z0 := lerpf(-hd, hd, float(j) / nz)
			var z1 := lerpf(-hd, hd, float(j + 1) / nz)
			bed.quad(Vector3(x0, floor_y(x0, z0), z0), Vector3(x1, floor_y(x1, z0), z0), Vector3(x1, floor_y(x1, z1), z1),
					Vector3(x0, floor_y(x0, z1), z1), Color.WHITE, Vector3.UP)
	_shell.add_child(_instance(bed.build(), _sand))
	_sand.set_shader_parameter("sand", about().sand)
	_sand.set_shader_parameter("coarse", about().coarse)
	# what stands on it
	Props.rock(mb, _on_floor(-hw * 0.62, hd * 0.35), 0.16, rng)
	Props.rock(mb, _on_floor(hw * 0.55, -hd * 0.5), 0.2, rng)
	if decor.has("castle"):
		Props.castle(mb, _on_floor(-hw * 0.38, -hd * 0.35), rng)
	if decor.has("chest"):
		Props.chest(mb, _on_floor(hw * 0.42, hd * 0.2), rng)
	if decor.has("skull"):
		Props.skull(mb, _on_floor(hw * 0.02, hd * 0.3), rng)
	if decor.has("column"):
		Props.column(mb, _on_floor(hw * 0.12, -hd * 0.55), rng)
	_bubble_from = _on_floor(hw - 0.2, -hd + 0.18)
	if gear.has("pump"):
		Props.air_stone(mb, _bubble_from, height)
	_shell.add_child(_instance(mb.build(), _mat))

	var greens := MB.new()
	for i in plants:
		var prng := RandomNumberGenerator.new()
		prng.seed = 100 + i
		var x := lerpf(-hw + 0.25, hw - 0.25, fmod(0.13 + i * 0.381, 1.0))
		if kind == "sea":
			Props.sea_plant(greens, _on_floor(x, lerpf(-hd + 0.14, -0.05, prng.randf())), i, prng)
		else:
			Props.plant(greens, _on_floor(x, lerpf(-hd + 0.14, -0.05, prng.randf())), i, prng)
	if not greens.is_empty():
		_shell.add_child(_instance(greens.build(), _plant_mat))

	# the glass: four panes facing out, with UVs in metres (see glass.gdshader)
	var panes := MB.new()
	var corners := [Vector3(-hw, 0, hd), Vector3(hw, 0, hd), Vector3(hw, 0, -hd), Vector3(-hw, 0, -hd)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var up := Vector3(0.0, height, 0.0)
		var run := a.distance_to(b)
		panes.quad(a, b, b + up, a + up, Color.WHITE, (a + b) * 0.5, Vector2(0, 0), Vector2(run, 0),
				Vector2(run, height), Vector2(0, height))
	_shell.add_child(_instance(panes.build(), _glass))
	_glass.set_shader_parameter("level", water_level)

	var top := MeshInstance3D.new()
	var sheet := PlaneMesh.new()
	sheet.size = Vector2(width - 0.02, depth - 0.02)
	sheet.subdivide_width = 16
	sheet.subdivide_depth = 8
	top.mesh = sheet
	top.material_override = _top
	top.position.y = water_level
	top.visible = is_wet()
	_shell.add_child(top)
	_bubbles.visible = gear.has("pump")


func _instance(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	return m


func _on_floor(x: float, z: float) -> Vector3:
	return Vector3(x, floor_y(x, z) - 0.01, z)


# ------------------------------------------------------------------ what the player does

## Sprinkles a pinch of food on the water above a place.
func drop_food(x: float, z: float) -> void:
	if swarm != null:
		# (a colony is fed by clouding the water, not by the flake)
		swarm.feed()
		return
	for i in 3:
		if _foods.size() >= MAX_FOOD:
			return
		var node := _instance(_flake, _mat)
		node.position = Vector3(clampf(x + _rng.randf_range(-0.08, 0.08), -width * 0.5 + 0.06, width * 0.5 - 0.06),
				water_level - 0.02, clampf(z + _rng.randf_range(-0.08, 0.08), -depth * 0.5 + 0.06, depth * 0.5 - 0.06))
		_life.add_child(node)
		_foods.append({"node": node, "age": 0.0, "landed": false, "spin": _rng.randf() * TAU})


## Holds a pinch of food out at a place on the glass (in the tank's own space) for whoever
## will come and take it from the keeper's fingers, or lets go of it (null) to sink.
func offer(at: Variant) -> void:
	for food in _foods:
		if food.get("held", false):
			if at == null:
				food.held = false
			else:
				food.node.position = _hold_at(at)
			return
	if at == null or _foods.size() >= MAX_FOOD:
		return
	var node := _instance(_flake, _mat)
	node.position = _hold_at(at)
	node.scale = Vector3.ONE * 1.6
	_life.add_child(node)
	_foods.append({"node": node, "age": 0.0, "landed": false, "spin": 0.0, "held": true})


## Where food held at a place on the glass is: just inside it, and under the water.
func _hold_at(at: Vector3) -> Vector3:
	return Vector3(clampf(at.x, -width * 0.5 + 0.1, width * 0.5 - 0.1), clampf(at.y, 0.3, water_level - 0.06),
			clampf(at.z, -depth * 0.5 + 0.1, depth * 0.5 - 0.1))


## Wipes algae off the glass (`amount` is how much of it, 0 to 1).
func scrub(amount: float) -> void:
	algae = maxf(algae - amount, 0.0)


func can_change_water() -> bool:
	return water_wait <= 0.0


## Swaps out most of the water for clean.
func change_water() -> void:
	if about().get("humid", false):
		# (frogs sing when it rains)
		for f in fish:
			if not f.dead and Species.habit(f.species, "gait") == "hop":
				Sfx.play("croak", _rng.randf_range(1.3, 1.9), -6.0)
				notice("sang after the mist", f)
				f.buddy.note("Sang when it was misted")
	if not is_wet():
		# no water to change: the air is misted instead
		humidity = minf(humidity + MIST, 1.0)
		water_wait = 60.0
		return
	waste *= 0.35
	o2 = lerpf(o2, 1.0, 0.5)
	# (fresh water in puts the salt back where it should be, and damps the air of a paludarium)
	salt = float(about().get("salt", 0.0))
	humidity = minf(humidity + MIST, 1.0)
	water_wait = WATER_WAIT


func set_lamp(on: bool) -> void:
	lamp_on = on


## Taps the glass: every fish near the place bolts.
func tap(at: Vector3) -> void:
	for f in fish:
		if f.position.distance_to(at) < 1.2:
			f.startle(at)


## The nearest fish to a ray, living or dead (null when it passes them all by).
func pick_fish(from: Vector3, dir: Vector3) -> Fish:
	var best: Fish = null
	var best_along := INF
	for f in fish:
		var along := (f.position - from).dot(dir)
		if along > 0.0 and along < best_along and (from + dir * along).distance_to(f.position) < f.reach():
			best = f
			best_along = along
	return best


## Puts a new fish in the tank (the caller has checked there is room).
func add_fish(species: String, growth := 1.0) -> Fish:
	var f := _spawn({"species": species, "growth": growth})
	# (it has only just met the keeper)
	f.buddy.bond = 0.0
	f.buddy.met = Time.get_unix_time_from_system()
	changed.emit()
	return f


## Takes a fish out for good: given away, or netted once it has died.
func remove_fish(f: Fish) -> void:
	fish.erase(f)
	for other in fish:
		other.buddy.forget(f.buddy.id)
	f.queue_free()
	changed.emit()


func add_plant() -> void:
	plants = mini(plants + 1, MAX_PLANTS)
	rebuild()
	changed.emit()


func add_critter(kind: String) -> void:
	if kind == "snail":
		snails += 1
	else:
		shrimps += 1
	_add_critter_node(kind)
	changed.emit()


func fit(id: String) -> void:
	gear[id] = true
	rebuild()
	changed.emit()


func place(id: String) -> void:
	decor[id] = true
	rebuild()
	changed.emit()


## Moves everything into the next tank up.
func grow() -> void:
	size_id = mini(size_id + 1, sizes().size() - 1)
	rebuild()
	for item: Dictionary in _eggs + _critters:
		var p: Vector3 = item.node.position
		item.node.position = _on_floor(p.x, p.z)
	changed.emit()


# ------------------------------------------------------------------ what fish.gd asks for

## The nearest flake of food to a place ({} when there is none).
## The food nearest a place (empty if there is none). An animal that will not come to the
## keeper's hand (`wary`) does not count what the keeper is holding out.
func nearest_food(at: Vector3, wary := false) -> Dictionary:
	var best := {}
	var best_d := INF
	for food in _foods:
		if wary and food.get("held", false):
			continue
		var d := at.distance_squared_to(food.node.position)
		if d < best_d:
			best = food
			best_d = d
	return best


func eat(food: Dictionary) -> void:
	if food in _foods:
		_foods.erase(food)
		food.node.queue_free()
		Sfx.play("eat", randf_range(0.9, 1.2), -8.0)


## One animal has eaten another: nothing is left of it.
func eaten(prey: Fish, by: Fish) -> void:
	_say("%s the %s has eaten %s." % [by.fish_name, by.info().name, prey.fish_name], "sad")
	notice("ate a tankmate", by, prey)
	remove_fish(prey)


func fish_died(f: Fish) -> void:
	_died += 1
	_say("%s the %s has died. Tap to net it out." % [f.fish_name, f.info().name], "sad")
	if not _quiet:
		changed.emit()


## Whether any fish would eat if it were fed now.
func anyone_hungry() -> bool:
	for f in fish:
		if not f.dead and f.hunger > Fish.PECKISH:
			return true
	return false


func _say(text: String, sound: String, pitch := 1.0) -> void:
	if not _quiet:
		said.emit(text)
		Sfx.play(sound, pitch)


# ------------------------------------------------------------------ the keeper, and company

## The keeper has come to look. Every animal's bond takes note of the visit (the first of a day
## warms it, and days missed cool it), and the ones that know the keeper come to the front.
func greet() -> void:
	greeting = 8.0
	var day := int(Time.get_unix_time_from_system() / DAY)
	for f in fish:
		if not f.dead:
			f.buddy.visit(day)


## The keeper's finger is on the glass at `at` (in the tank's own space), or has been lifted
## (null). One that is moved fast startles whatever is near it.
func point_at(at: Variant, speed := 0.0) -> void:
	finger = at
	if at != null and speed > 2.0:
		tap(at)


## Shines the keeper's torch into the tank at a place on the glass (null puts it out). A white
## one sends whatever it falls on into hiding; a red one they do not see, which is how to
## watch the ones that only come out in the dark.
func shine(at: Variant, red := true) -> void:
	torch = at
	torch_red = red


## Something passed between two animals, or between one and the keeper, that a watcher would
## have seen: a chase, a friendship made, one coming to the finger. Counted by kind in `seen`.
func notice(kind: String, _a: Fish, _b: Fish = null) -> void:
	seen[kind] = int(seen.get(kind, 0)) + 1


## Somewhere out of the way for an animal at `at` to go: low down at the back, on its own side.
func hide_for(at: Vector3) -> Vector3:
	return Vector3((1.0 if at.x >= 0.0 else -1.0) * width * 0.36, 0.32, -depth * 0.36)


## Where the shoal of a kind is heading: somewhere in open water, a new place every few seconds.
func shoal_goal(species: String) -> Vector3:
	var goal: Dictionary = _shoals.get(species, {})
	if goal.is_empty() or _clock > float(goal.until):
		var box := swim_box(0.3)
		goal = {"at": box.position + box.size * Vector3(_rng.randf(), _rng.randf_range(0.2, 0.9), _rng.randf()),
				"until": _clock + _rng.randf_range(4.0, 9.0)}
		_shoals[species] = goal
	return goal.at


# ------------------------------------------------------------------ the simulation

## Moves the whole tank on by `delta` seconds.
func step(delta: float) -> void:
	_clock += delta
	greeting = maxf(greeting - delta, 0.0)
	_lamp = move_toward(_lamp, 1.0 if lamp_on else 0.0, delta * 2.0)
	var lived := delta * time_scale
	for f in fish:
		f.tick(delta, lived)
	_step_water(lived)
	_step_food(delta)
	_step_critters(delta)
	_step_eggs(lived)
	_try_breeding(lived)
	_step_looks(lerpf(0.15, 1.0, _lamp))


## The water over `dt` seconds, which may be many. Oxygen settles within minutes to wherever
## the fish and the surface leave it; waste and algae build up over days.
func _step_water(dt: float) -> void:
	age += dt
	water_wait = maxf(water_wait - dt, 0.0)
	var bodies := 0
	for f in fish:
		bodies += int(f.dead)
	if is_wet():
		water.step(dt, crowd(), bodies, plants, snails, lamp_on, gear.has("pump"), gear.has("filter"))
	if swarm != null:
		waste = minf(waste + swarm.step(dt, absf(salt - float(about().get("salt", 0.0)))), 1.0)
	# the air dries, and the salt creeps up as the water dries off
	if about().get("humid", false):
		humidity = maxf(humidity - DRIES * dt / DAY, 0.0)
	if float(about().get("salt", 0.0)) > 0.0:
		salt = minf(salt + SALT_CREEP * dt / DAY, 1.0)


func _step_food(delta: float) -> void:
	for food in _foods.duplicate():
		var node: MeshInstance3D = food.node
		if food.get("held", false):
			# (in the keeper's fingers: it turns a little, and stays where it is held)
			node.rotation.y = _clock * 2.0
		elif not food.landed:
			node.scale = Vector3.ONE
			var p := node.position
			p.y -= 0.16 * delta
			p.x += sin(_clock * 2.0 + food.spin) * 0.03 * delta
			node.rotation = Vector3(sin(_clock * 3.0 + food.spin) * 0.6, _clock + food.spin, 0.0)
			var ground := floor_y(p.x, p.z) + 0.012
			if p.y <= ground:
				p.y = ground
				food.landed = true
				node.rotation = Vector3.ZERO
			node.position = p
		else:
			food.age += delta
			if food.age > FOOD_KEEPS:
				_foods.erase(food)
				node.queue_free()
				waste = minf(waste + FOOD_ROT, 1.0)


func _add_critter_node(kind: String) -> void:
	var node := _instance(Props.snail() if kind == "snail" else Props.shrimp(), _mat)
	var x := _rng.randf_range(-width * 0.4, width * 0.4)
	var z := _rng.randf_range(-depth * 0.35, depth * 0.35)
	node.position = _on_floor(x, z)
	_life.add_child(node)
	_critters.append({"node": node, "kind": kind, "to": node.position, "wait": 0.0})


## Snails wander the gravel; shrimps wander too, but make for any food lying on it and eat it.
func _step_critters(delta: float) -> void:
	for c in _critters:
		var node: MeshInstance3D = c.node
		var speed := 0.03
		if c.kind == "shrimp":
			speed = 0.12
			var meal := {}
			var meal_d := INF
			for food in _foods:
				if food.landed and node.position.distance_to(food.node.position) < meal_d:
					meal = food
					meal_d = node.position.distance_to(food.node.position)
			if not meal.is_empty():
				c.to = meal.node.position
				c.wait = 0.0
				speed = 0.3
				if meal_d < 0.06:
					_foods.erase(meal)
					meal.node.queue_free()
		var to: Vector3 = c.to
		var gap := Vector3(to.x - node.position.x, 0.0, to.z - node.position.z)
		if gap.length() < 0.03:
			c.wait -= delta
			if c.wait <= 0.0:
				c.wait = _rng.randf_range(1.0, 5.0)
				c.to = Vector3(_rng.randf_range(-width * 0.44, width * 0.44), 0.0, _rng.randf_range(-depth * 0.4, depth * 0.4))
			continue
		var p := node.position + gap.normalized() * minf(speed * delta, gap.length())
		node.position = _on_floor(p.x, p.z)
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-gap.x, -gap.z), 1.0 - exp(-4.0 * delta))


func _step_eggs(delta: float) -> void:
	for egg in _eggs.duplicate():
		egg.age += delta
		if egg.age < HATCH_TIME:
			continue
		_eggs.erase(egg)
		var at: Vector3 = egg.node.position
		egg.node.queue_free()
		var f := _spawn({"species": egg.species, "growth": 0.0, "buddy": {"grade": egg.get("grade", 0.35), "born": true, "bond": 0.1}})
		# (it was born here, and has seen the keeper about since it was an egg)
		f.buddy.met = Time.get_unix_time_from_system()
		f.buddy.bond = 0.1
		f.position = at + Vector3(0.0, 0.25, 0.0)
		_hatched += 1
		_say("An egg has hatched: %s the %s." % [f.fish_name, f.info().name], "egg", 1.3)
		if not _quiet:
			changed.emit()


## Two well-fed, healthy adults in good water, with room to spare, may lay an egg: now and
## then, about once every BREED_EVERY while all of that holds.
func _try_breeding(dt: float) -> void:
	if o2 < 0.5 or waste > 0.5 or _eggs.size() >= 2:
		return
	# (room is counted as if every fry and egg were already full-grown)
	var grown := 0.0
	for f in fish:
		if not f.dead:
			grown += float(f.info().load)
	for egg in _eggs:
		grown += float(Species.LIST[egg.species].load)
	var ready: Array[Fish] = []
	for f in fish:
		if not f.dead and f.is_adult() and f.hunger < 0.45 and f.health > 0.8 and f.breed_wait <= 0.0:
			ready.append(f)
	if ready.size() < 2 or _rng.randf() > 1.0 - exp(-dt / BREED_EVERY):
		return
	var a: Fish = ready[_rng.randi() % ready.size()]
	ready.erase(a)
	# (its mate is one of its own kind; only the old pet-shop fish will cross)
	var mates: Array[Fish] = []
	for f in ready:
		if f.species == a.species or not (a.info().has("home") or f.info().has("home")):
			mates.append(f)
	if mates.is_empty():
		return
	var b: Fish = mates[_rng.randi() % mates.size()]
	var child := Species.child_of(a.species, b.species, _rng)
	if grown + float(Species.LIST[child].load) > capacity() * BREED_ROOM:
		return
	a.breed_wait = BREED_WAIT
	b.breed_wait = BREED_WAIT
	var mid := (a.position + b.position) * 0.5
	# (a kind bred for colour takes after its parents, a little deeper or paler by chance)
	_lay(child, mid.x, mid.z, 0.0, clampf((a.buddy.grade + b.buddy.grade) * 0.5 + _rng.randf_range(-0.12, 0.16), 0.0, 1.0))
	_say("%s and %s have laid an egg." % [a.fish_name, b.fish_name], "egg")


func _lay(species: String, x: float, z: float, egg_age: float, grade := 0.35) -> void:
	var node := _instance(_egg, _mat)
	node.position = _on_floor(clampf(x, -width * 0.45, width * 0.45), clampf(z, -depth * 0.45, depth * 0.45))
	_life.add_child(node)
	_eggs.append({"node": node, "age": egg_age, "species": species, "grade": grade})


## How brightly the lamp is lit, 0 to 1 (it fades on and off).
func lamp_glow() -> float:
	return _lamp


## The lamp, the colour of the water, the algae and the bubbles.
func _step_looks(light: float) -> void:
	_light.light_energy = 3.6 * _lamp
	_hood.albedo_color = (about().look.key as Color) * lerpf(0.06, 1.0, _lamp)
	var glow := lerpf(0.24, 1.0, _lamp)
	var look: Dictionary = about().look
	# (the net of light is only on what is under the water)
	var water_top := position.y + water_level if is_wet() else -1000.0
	for mat: ShaderMaterial in [_mat, _plant_mat, _sand]:
		mat.set_shader_parameter("lamp", glow)
		mat.set_shader_parameter("key", look.key)
		mat.set_shader_parameter("shadow", look.shadow)
		mat.set_shader_parameter("haze", look.haze)
		mat.set_shader_parameter("tank_depth", depth)
		mat.set_shader_parameter("water_top", water_top)
	var beam := Color(0.9, 0.12, 0.08) if torch_red else Color(1.0, 0.97, 0.88)
	if torch == null:
		beam = Color.BLACK
	var beam_at: Vector3 = position + (torch if torch != null else Vector3.ZERO)
	for mat: ShaderMaterial in [_mat, _plant_mat, _sand]:
		mat.set_shader_parameter("torch_at", beam_at)
		mat.set_shader_parameter("torch_light", beam)
	for f in fish:
		f.set_light(glow, look, depth, water_top)
		f.set_torch(beam_at, beam)
	_light.light_color = look.spill
	var colour := (about().water_colour as Color).lerp(FOUL_WATER, waste)
	for mat: ShaderMaterial in [_glass, _back, _top]:
		mat.set_shader_parameter("water", colour)
		mat.set_shader_parameter("light", lerpf(0.3, 1.0, light))
	_back.set_shader_parameter("murk", waste)
	_glass.set_shader_parameter("murk", waste)
	_glass.set_shader_parameter("algae", algae)
	_draw_swarm()
	if not _bubbles.visible:
		return
	var mm := _bubbles.multimesh
	var rise := water_level - _bubble_from.y
	for i in mm.instance_count:
		var t := fmod(_clock * 0.45 + i * 0.618, 1.0)
		var at := _bubble_from + Vector3(sin(_clock * 3.0 + i * 1.7) * 0.04 * t, 0.06 + t * rise, cos(_clock * 2.3 + i) * 0.04 * t)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (0.025 + 0.02 * fmod(i * 0.37, 1.0))), at))


## Puts a speck where each animal of the colony is: they mill about, drawn up toward the lamp
## when it is on, and the young are smaller than the grown.
func _draw_swarm() -> void:
	if swarm == null:
		return
	var many := _specks.multimesh
	var shown := mini(int(swarm.count()), many.instance_count)
	many.visible_instance_count = shown
	var box := swim_box(0.08)
	var grown := int(swarm.grown)
	for i in shown:
		var a := i * 2.399
		var t := _clock * (0.25 + 0.2 * fmod(i * 0.37, 1.0))
		# (each goes round a path of its own, higher in the water while the lamp is on)
		var at := box.position + box.size * Vector3(0.5 + 0.46 * sin(t + a) * cos(t * 0.37 + a * 1.7),
				lerpf(0.3, 0.72, _lamp) + 0.28 * sin(t * 0.8 + a * 2.3), 0.5 + 0.46 * cos(t * 0.9 + a * 0.6))
		var ahead := Vector3(cos(t + a), 0.4 * cos(t * 0.8 + a * 2.3), -sin(t * 0.9 + a * 0.6)).normalized()
		var size := 0.035 if i < grown else 0.016
		many.set_instance_transform(i, Transform3D(Basis.looking_at(ahead, Vector3.UP).scaled(Vector3.ONE * size), at))


func _spawn(data: Dictionary) -> Fish:
	var f := Fish.new()
	_life.add_child(f)
	f.setup(self, data)
	# (each animal of a tank has a number of its own, which the others' ties are kept by)
	if f.buddy.id <= 0 or fish.any(func(other: Fish) -> bool: return other.buddy.id == f.buddy.id):
		f.buddy.id = _next_id
	_next_id = maxi(_next_id, f.buddy.id + 1)
	fish.append(f)
	if not dex.has(f.species):
		dex[f.species] = true
		discovered.emit(f.species)
	return f
