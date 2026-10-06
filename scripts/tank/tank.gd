extends Node3D
## The tank and everything in it: the glass and gravel, the fish, the plants and other small
## life, the food, the eggs, and the water itself.
##
## The water is three numbers from 0 to 1. Oxygen comes in at the surface (faster with the air
## pump) and from plants in the light, and the fish breathe it. Waste comes from the fish and
## from food left to rot; plants and the filter take it up, and changing the water halves it.
## Algae grows on the glass in the light, faster in dirty water; snails graze it and it can be
## scrubbed off. Fish are harmed by too little oxygen or too much waste (see fish.gd).
##
## The origin is the middle of the tank's floor; the tank is `width` (x) by `height` by `depth`.

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

## The tanks, smallest first: metres, how much fish it holds (the sum of their `load`), price.
const SIZES := [
	{"name": "Pocket tank", "w": 2.2, "h": 1.5, "d": 1.2, "room": 5.0, "price": 0},
	{"name": "Desk tank", "w": 3.0, "h": 1.8, "d": 1.4, "room": 9.0, "price": 150},
	{"name": "Showpiece tank", "w": 4.0, "h": 2.1, "d": 1.7, "room": 15.0, "price": 400},
]
const MAX_PLANTS := 8
const MAX_SNAILS := 3
const MAX_SHRIMPS := 3
const MAX_FOOD := 40
## Seconds a flake lies on the gravel before it rots, and the waste it turns into.
const FOOD_KEEPS := 25.0
const FOOD_ROT := 0.03
## Seconds an egg takes to hatch, and both parents wait before breeding again.
const HATCH_TIME := 18.0
const BREED_WAIT := 120.0
## Seconds between water changes.
const WATER_WAIT := 45.0

const CLEAN_WATER := Color(0.35, 0.8, 0.95)
const FOUL_WATER := Color(0.42, 0.46, 0.16)

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
## Every kind of fish ever kept here.
var dex := {}

var o2 := 0.9
var waste := 0.05
var algae := 0.0
var lamp_on := true
var water_wait := 0.0

var _shell: Node3D
var _life: Node3D
var _mat: ShaderMaterial
var _plant_mat: ShaderMaterial
var _glass: ShaderMaterial
var _light: DirectionalLight3D
var _env: Environment
var _bubbles: MultiMeshInstance3D
var _bubble_from := Vector3.ZERO
var _foods: Array[Dictionary] = []
var _eggs: Array[Dictionary] = []
var _critters: Array[Dictionary] = []
var _flake: ArrayMesh
var _egg: ArrayMesh
var _rng := RandomNumberGenerator.new()
var _breed_in := 4.0
var _clock := 0.0
var _lamp := 1.0


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/psx.gdshader")
	_plant_mat = ShaderMaterial.new()
	_plant_mat.shader = preload("res://shaders/psx.gdshader")
	_plant_mat.set_shader_parameter("sway", 1.0)
	_glass = ShaderMaterial.new()
	_glass.shader = preload("res://shaders/glass.gdshader")
	_flake = Props.flake()
	_egg = Props.egg()

	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.93, 0.86, 0.7)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.85, 0.9, 1.0)
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_light = DirectionalLight3D.new()
	_light.rotation = Vector3(-1.05, 0.5, 0.0)
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
	var low := Vector3(-width * 0.5 + margin, 0.2 + margin, -depth * 0.5 + margin)
	var high := Vector3(width * 0.5 - margin, water_level - margin, depth * 0.5 - margin)
	return AABB(low, (high - low).max(Vector3.ONE * 0.01))


## How high the gravel is at a place.
func floor_y(x: float, z: float) -> float:
	return 0.1 + 0.035 * sin(x * 3.1 + 1.0) * cos(z * 4.3) + 0.02 * sin(x * 7.7 + z * 5.1)


## How much room the fish take up (and the eggs will), out of capacity().
func crowd() -> float:
	var total := 0.0
	for f in fish:
		if not f.dead:
			total += f.room()
	return total


func capacity() -> float:
	return SIZES[size_id].room


func has_room_for(species: String) -> bool:
	return crowd() + float(Species.LIST[species].load) <= capacity() + 0.001


# ------------------------------------------------------------------ saving

func to_data() -> Dictionary:
	var kept: Array = []
	for f in fish:
		if not f.dead:
			kept.append(f.to_data())
	return {"size": size_id, "plants": plants, "snails": snails, "shrimps": shrimps, "gear": gear.keys(),
			"decor": decor.keys(), "dex": dex.keys(), "o2": o2, "waste": waste, "algae": algae, "lamp": lamp_on,
			"fish": kept}


## Sets the tank up from a save. An empty one is a new tank: two guppies and a plant.
func load_state(data: Dictionary) -> void:
	for f in fish:
		f.queue_free()
	fish.clear()
	for list: Array in [_foods, _eggs, _critters]:
		for item: Dictionary in list:
			item.node.queue_free()
		list.clear()
	size_id = clampi(int(data.get("size", 0)), 0, SIZES.size() - 1)
	plants = clampi(int(data.get("plants", 1)), 0, MAX_PLANTS)
	snails = clampi(int(data.get("snails", 0)), 0, MAX_SNAILS)
	shrimps = clampi(int(data.get("shrimps", 0)), 0, MAX_SHRIMPS)
	gear = {}
	for id in data.get("gear", []):
		gear[str(id)] = true
	decor = {}
	for id in data.get("decor", []):
		decor[str(id)] = true
	dex = {}
	for id in data.get("dex", []):
		if Species.LIST.has(str(id)):
			dex[str(id)] = true
	o2 = clampf(data.get("o2", 0.9), 0.0, 1.0)
	waste = clampf(data.get("waste", 0.05), 0.0, 1.0)
	algae = clampf(data.get("algae", 0.0), 0.0, 1.0)
	lamp_on = data.get("lamp", true)
	_lamp = 1.0 if lamp_on else 0.0
	rebuild()
	var saved: Array = data.get("fish", [])
	if not data.has("fish"):
		saved = [{"species": "guppy"}, {"species": "guppy"}]
	for entry in saved:
		if entry is Dictionary:
			_spawn(entry)
	for i in snails:
		_add_critter_node("snail")
	for i in shrimps:
		_add_critter_node("shrimp")
	changed.emit()


# ------------------------------------------------------------------ building

## Builds the tank and its dressing again (after it grows, or something is bought).
func rebuild() -> void:
	var s: Dictionary = SIZES[size_id]
	width = s.w
	height = s.h
	depth = s.d
	water_level = height * 0.92
	if _shell != null:
		_shell.queue_free()
	_shell = Node3D.new()
	add_child(_shell)
	move_child(_shell, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var hw := width * 0.5
	var hd := depth * 0.5

	# the room: a desk under the tank and a wall behind it
	var mb := MB.new()
	Props.box(mb, Vector3(0.0, -0.2, 0.0), Vector3(width + 4.0, 0.2, depth + 2.2), Color(0.8, 0.58, 0.38), rng, 0.0)
	mb.quad(Vector3(-9.0, -0.3, -hd - 1.1), Vector3(9.0, -0.3, -hd - 1.1), Vector3(9.0, 7.0, -hd - 1.1),
			Vector3(-9.0, 7.0, -hd - 1.1), Color(0.93, 0.86, 0.7), Vector3.BACK)
	# a skirting of colour along the wall, and the picture stuck on the back of the tank
	mb.quad(Vector3(-9.0, 0.5, -hd - 1.09), Vector3(9.0, 0.5, -hd - 1.09), Vector3(9.0, 0.62, -hd - 1.09),
			Vector3(-9.0, 0.62, -hd - 1.09), Color(0.85, 0.4, 0.3), Vector3.BACK)
	for i in 4:
		var y0 := height * i / 4.0
		var y1 := height * (i + 1) / 4.0
		mb.quad(Vector3(-hw, y0, -hd + 0.004), Vector3(hw, y0, -hd + 0.004), Vector3(hw, y1, -hd + 0.004),
				Vector3(-hw, y1, -hd + 0.004), Color(0.12, 0.42, 0.62).lerp(Color(0.45, 0.85, 0.95), i / 3.0), Vector3.BACK)
	# the frame: a base, a rim round the top and a post at each corner
	var trim := Color(0.24, 0.26, 0.33)
	Props.box(mb, Vector3(0.0, -0.05, 0.0), Vector3(width + 0.1, 0.1, depth + 0.1), trim)
	for sz: float in [-1.0, 1.0]:
		Props.box(mb, Vector3(0.0, height, sz * hd), Vector3(width + 0.08, 0.05, 0.05), trim)
	for sx: float in [-1.0, 1.0]:
		Props.box(mb, Vector3(sx * hw, height, 0.0), Vector3(0.05, 0.05, depth + 0.08), trim)
		for sz: float in [-1.0, 1.0]:
			Props.box(mb, Vector3(sx * hw, height * 0.5, sz * hd), Vector3(0.035, height, 0.035), trim)
	# gravel
	var nx := int(width * 6.0)
	var nz := int(depth * 6.0)
	var pebbles := [Color(0.85, 0.72, 0.5), Color(0.75, 0.62, 0.45), Color(0.9, 0.8, 0.62), Color(0.62, 0.56, 0.5)]
	for i in nx:
		for j in nz:
			var x0 := lerpf(-hw, hw, float(i) / nx)
			var x1 := lerpf(-hw, hw, float(i + 1) / nx)
			var z0 := lerpf(-hd, hd, float(j) / nz)
			var z1 := lerpf(-hd, hd, float(j + 1) / nz)
			var col: Color = pebbles[rng.randi() % pebbles.size()]
			mb.quad(Vector3(x0, floor_y(x0, z0), z0), Vector3(x1, floor_y(x1, z0), z0), Vector3(x1, floor_y(x1, z1), z1),
					Vector3(x0, floor_y(x0, z1), z1), col, Vector3.UP)
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
	if gear.has("filter"):
		Props.filter_box(mb, Vector3(-hw + 0.35, height - 0.08, -hd - 0.09), 0.5)
	_shell.add_child(_instance(mb.build(), _mat))

	var greens := MB.new()
	for i in plants:
		var prng := RandomNumberGenerator.new()
		prng.seed = 100 + i
		var x := lerpf(-hw + 0.25, hw - 0.25, fmod(0.13 + i * 0.381, 1.0))
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
	var top_mat := StandardMaterial3D.new()
	top_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	top_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	top_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	top_mat.albedo_color = Color(0.8, 0.93, 1.0, 0.28)
	sheet.material = top_mat
	top.mesh = sheet
	top.position.y = water_level
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
	for i in 3:
		if _foods.size() >= MAX_FOOD:
			return
		var node := _instance(_flake, _mat)
		node.position = Vector3(clampf(x + _rng.randf_range(-0.08, 0.08), -width * 0.5 + 0.06, width * 0.5 - 0.06),
				water_level - 0.02, clampf(z + _rng.randf_range(-0.08, 0.08), -depth * 0.5 + 0.06, depth * 0.5 - 0.06))
		_life.add_child(node)
		_foods.append({"node": node, "age": 0.0, "landed": false, "spin": _rng.randf() * TAU})


## Wipes algae off the glass (`amount` is how much of it, 0 to 1).
func scrub(amount: float) -> void:
	algae = maxf(algae - amount, 0.0)


func can_change_water() -> bool:
	return water_wait <= 0.0


## Swaps out most of the water for clean.
func change_water() -> void:
	waste *= 0.35
	o2 = lerpf(o2, 1.0, 0.5)
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
	changed.emit()
	return f


## Takes a fish out for good: given away, or netted once it has died.
func remove_fish(f: Fish) -> void:
	fish.erase(f)
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
	size_id = mini(size_id + 1, SIZES.size() - 1)
	rebuild()
	for item: Dictionary in _eggs + _critters:
		var p: Vector3 = item.node.position
		item.node.position = _on_floor(p.x, p.z)
	changed.emit()


# ------------------------------------------------------------------ what fish.gd asks for

## The nearest flake of food to a place ({} when there is none).
func nearest_food(at: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for food in _foods:
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


func fish_died(f: Fish) -> void:
	said.emit("%s the %s has died. Tap to net it out." % [f.fish_name, f.info().name])
	Sfx.play("sad")
	changed.emit()


# ------------------------------------------------------------------ the simulation

## Moves the whole tank on by `delta` seconds.
func step(delta: float) -> void:
	_clock += delta
	water_wait = maxf(water_wait - delta, 0.0)
	_lamp = move_toward(_lamp, 1.0 if lamp_on else 0.0, delta * 2.0)
	var light := lerpf(0.15, 1.0, _lamp)

	var bodies := 0
	for f in fish:
		f.tick(delta)
		if f.dead:
			bodies += 1
	var crowded := crowd()
	var exchange := 0.05 * (2.5 if gear.has("pump") else 1.0) + plants * 0.012 * light
	o2 = clampf(o2 + delta * (exchange * (1.0 - o2) - crowded * 0.0045 - waste * 0.004), 0.0, 1.0)
	var cleaning := 0.002 + (0.012 if gear.has("filter") else 0.0) + plants * 0.0015 * light
	waste = clampf(waste + delta * (crowded * 0.0009 + bodies * 0.002 - waste * cleaning), 0.0, 1.0)
	algae = clampf(algae + delta * ((0.0015 + 0.004 * waste) * light - snails * 0.005), 0.0, 1.0)

	_step_food(delta)
	_step_critters(delta)
	_step_eggs(delta)
	_breed_in -= delta
	if _breed_in <= 0.0:
		_breed_in = 2.0
		_try_breeding()
	_step_looks(light)


func _step_food(delta: float) -> void:
	for food in _foods.duplicate():
		var node: MeshInstance3D = food.node
		if not food.landed:
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
		var f := add_fish(egg.species, 0.0)
		f.position = at + Vector3(0.0, 0.25, 0.0)
		said.emit("An egg has hatched: %s the %s." % [f.fish_name, f.info().name])
		Sfx.play("egg", 1.3)


## Two well-fed, healthy adults in good water, with room to spare, may lay an egg.
func _try_breeding() -> void:
	if o2 < 0.5 or waste > 0.5 or _eggs.size() >= 2:
		return
	if crowd() + _eggs.size() * 0.4 + 0.4 > capacity():
		return
	var ready: Array[Fish] = []
	for f in fish:
		if not f.dead and f.is_adult() and f.hunger < 0.45 and f.health > 0.8 and f.breed_wait <= 0.0:
			ready.append(f)
	if ready.size() < 2 or _rng.randf() > 0.15:
		return
	var a: Fish = ready[_rng.randi() % ready.size()]
	ready.erase(a)
	var b: Fish = ready[_rng.randi() % ready.size()]
	a.breed_wait = BREED_WAIT
	b.breed_wait = BREED_WAIT
	var node := _instance(_egg, _mat)
	var mid := (a.position + b.position) * 0.5
	node.position = _on_floor(mid.x, mid.z)
	_life.add_child(node)
	_eggs.append({"node": node, "age": 0.0, "species": Species.child_of(a.species, b.species, _rng)})
	said.emit("%s and %s have laid an egg." % [a.fish_name, b.fish_name])
	Sfx.play("egg")


## The lamp, the colour of the water, the algae and the bubbles.
func _step_looks(light: float) -> void:
	_light.light_energy = lerpf(0.1, 1.1, _lamp)
	_env.ambient_light_energy = lerpf(0.2, 1.0, _lamp)
	_env.background_color = Color(0.93, 0.86, 0.7) * lerpf(0.06, 0.8, _lamp)
	_glass.set_shader_parameter("water", CLEAN_WATER.lerp(FOUL_WATER, waste))
	_glass.set_shader_parameter("murk", waste)
	_glass.set_shader_parameter("algae", algae)
	_glass.set_shader_parameter("light", lerpf(0.35, 1.0, light))
	if not _bubbles.visible:
		return
	var mm := _bubbles.multimesh
	var rise := water_level - _bubble_from.y
	for i in mm.instance_count:
		var t := fmod(_clock * 0.45 + i * 0.618, 1.0)
		var at := _bubble_from + Vector3(sin(_clock * 3.0 + i * 1.7) * 0.04 * t, 0.06 + t * rise, cos(_clock * 2.3 + i) * 0.04 * t)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (0.025 + 0.02 * fmod(i * 0.37, 1.0))), at))


func _spawn(data: Dictionary) -> Fish:
	var f := Fish.new()
	_life.add_child(f)
	f.setup(self, data)
	fish.append(f)
	if not dex.has(f.species):
		dex[f.species] = true
		discovered.emit(f.species)
	return f
