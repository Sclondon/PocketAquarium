extends MeshInstance3D
## One fish: where it swims, how hungry and how well it is, and how grown.
##
## It wanders about the tank, heads for food when it is hungry, and bolts when the glass is
## tapped. It lives in real time: it wants feeding about once a day, can go a few days without,
## and takes a week to grow up. A fish that is starving, short of oxygen or in foul water loses
## health, and one that runs out dies and floats to the top.

const Species := preload("res://scripts/tank/species.gd")
const FishMesh := preload("res://scripts/tank/fish_mesh.gd")
const Models := preload("res://scripts/tank/models.gd")
const Life := preload("res://scripts/sim/life.gd")
const Buddy := preload("res://scripts/sim/buddy.gd")

const DAY := Life.DAY
const PECKISH := Life.PECKISH
## Model units to metres, for a full-grown fish of size 1.
const SCALE := 0.15

var species := "guppy"
var fish_name := ""
## Its life in numbers (sim/life.gd): hunger, health, growth, and whether it is still alive.
## The ones the rest of the game asks after can be had by name.
var life := Life.new()
var growth: float:
	get:
		return life.growth
	set(value):
		life.growth = value
var hunger: float:
	get:
		return life.hunger
	set(value):
		life.hunger = value
var health: float:
	get:
		return life.health
	set(value):
		life.health = value
var dead: bool:
	get:
		return life.dead
var breed_wait: float:
	get:
		return life.breed_wait
	set(value):
		life.breed_wait = value

## What makes it itself: its temper, how well it knows the keeper, and how it stands with the
## others (sim/buddy.gd).
var buddy := Buddy.new()
## What it is about just now, in a word (see `_decide`): wandering, feeding, following (the
## keeper's finger), hiding, greeting, sleeping, begging, chasing, fleeing, keeping company,
## shoaling or sulking.
var doing := "wandering"

## The tank it lives in (tank.gd)
var tank

var _mat: ShaderMaterial
## The ink line round it (outline.gdshader), which has to bend exactly as the skin does.
var _line: ShaderMaterial
var _vel := Vector3.ZERO
var _burst := Vector3.ZERO
var _target := Vector3.ZERO
var _retarget := 0.0
var _heading := Vector3.FORWARD
var _facing := Vector2.RIGHT
var _wag := 0.0
var _roll := 0.0
## Its build: "fish", "squid" or "jelly" (a jellyfish stays upright and only drifts)
var _plan := "fish"
var _rng := RandomNumberGenerator.new()
var _think := 0.0
## The animal it is chasing, fleeing or keeping company with, how long a chase has left to run,
## and how long it has been at its friend's side.
var _with: Node
var _busy := 0.0
var _company := 0.0
## How fast it is going about what it is doing, beside its ordinary speed.
var _pace := 1.0
## How it gets about: "swim", or on foot: "walk", "hop", "climb" (the ground and the back wall)
## or "glide" (a snail: the same, slowly). For one on foot: seconds left of standing still, and
## how far through a hop it is (0 to 1).
var _gait := "swim"
var _rest := 0.0
var _hop := 0.0
var _seen_by_torch := false
## A push away from whoever is too close, so they gather round a thing and do not pile into it.
var _apart := Vector3.ZERO
## Whether it is the one the keeper has in hand (its outline says so).
var _marked := false


func setup(in_tank, data: Dictionary) -> void:
	tank = in_tank
	_rng.seed = randi()
	species = data.get("species", "guppy")
	if not Species.LIST.has(species):
		species = "guppy"
	fish_name = data.get("name", "")
	if fish_name == "":
		fish_name = Species.NAMES[_rng.randi() % Species.NAMES.size()]
	growth = clampf(data.get("growth", 1.0), 0.0, 1.0)
	hunger = clampf(data.get("hunger", 0.3), 0.0, 1.0)
	health = clampf(data.get("health", 1.0), 0.01, 1.0)
	breed_wait = data.get("breed_wait", 2.0 * DAY)
	buddy.load_data(data.get("buddy", {}), _rng)
	var modelled := Models.of(species) != null
	mesh = Models.of(species) if modelled else FishMesh.of(species)
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/fish.gdshader")
	_line = ShaderMaterial.new()
	_line.shader = preload("res://shaders/outline.gdshader")
	_mat.next_pass = _line
	_mat.set_shader_parameter("modelled", modelled)
	_mat.set_shader_parameter("grade", buddy.grade if Species.habit(species, "graded") else -1.0)
	_line.set_shader_parameter("modelled", modelled)
	_wag = _rng.randf() * TAU
	_bend("wag_phase", _wag)
	var look: Dictionary = info().look
	_plan = look.get("plan", "fish")
	_gait = Species.habit(species, "gait", "swim")
	_bend("swim", 2 if _plan == "jelly" else (1 if look.get("flukes", false) else 0))
	if Species.habit(species, "still"):
		_bend("swim", 4)
	if _gait != "swim":
		# (one on foot sways as it walks, and one that hops or glides holds itself still)
		_bend("swim", 3 if _gait in ["walk", "climb"] else 4)
		# (what counts as leg, for the stepping: see swim.gdshaderinc)
		var legs: Array = Species.habit(species, "legs", [0.26, 0.0])
		_bend("leg_from", legs[0])
		_bend("leg_low", legs[1])
	_bend("wag_amp", Species.habit(species, "wag", 0.07 if _plan == "squid" else 0.12))
	_mat.set_shader_parameter("spots", look.get("spots", 0.0))
	_mat.set_shader_parameter("spot_color", look.get("spot", Color(0.05, 0.08, 0.1)))
	material_override = _mat
	var box: AABB = tank.swim_box(minf(reach(), 0.3)) if _gait == "swim" else tank.walk_box(_gait)
	position = box.position + box.size * Vector3(_rng.randf(), _rng.randf(), _rng.randf())
	if _gait != "swim":
		position.y = tank.floor_y(position.x, position.z) + _stand()
	else:
		position = _at_its_level(position, box)
	_heading = Vector3(1.0 if _rng.randf() < 0.5 else -1.0, 0.0, 0.0)
	_apply_pose()


func to_data() -> Dictionary:
	return {"species": species, "name": fish_name, "growth": growth, "hunger": hunger, "health": health,
			"breed_wait": breed_wait, "buddy": buddy.to_data()}


func info() -> Dictionary:
	return Species.LIST[species]


func is_adult() -> bool:
	return growth >= 1.0


## How much of the tank's room it takes up.
func room() -> float:
	return float(info().load) * lerpf(0.35, 1.0, growth)


## How far from its middle a tap still counts as on it (metres).
func reach() -> float:
	return _size() * 1.15


## How bright the lamp of the tank it is in is, and the tones of that tank's light (tank.gd
## tells it: see `Tank.LOOKS`).
func set_light(amount: float, look: Dictionary, depth: float, water_top: float) -> void:
	_mat.set_shader_parameter("water_top", water_top)
	_mat.set_shader_parameter("lamp", amount)
	_mat.set_shader_parameter("key", look.key)
	_mat.set_shader_parameter("shadow", look.shadow)
	_mat.set_shader_parameter("haze", look.haze)
	_mat.set_shader_parameter("tank_depth", depth)
	_line.set_shader_parameter("ink", Color(1.0, 0.82, 0.4) if _marked else look.ink)
	_line.set_shader_parameter("lamp", amount)


## Where the keeper's torch is shining (in the world) and what colour (black for off).
func set_torch(at: Vector3, light: Color) -> void:
	_mat.set_shader_parameter("torch_at", at)
	_mat.set_shader_parameter("torch_light", light)


## Sets one of the numbers it swims by, on its skin and on its outline alike.
func _bend(what: String, value: Variant) -> void:
	_mat.set_shader_parameter(what, value)
	_line.set_shader_parameter(what, value)


func _size() -> float:
	return SCALE * float(info().size) * lerpf(0.4, 1.0, growth)


func stage() -> String:
	return "Fry" if growth < 0.4 else ("Young" if growth < 1.0 else "Adult")


## How hungry it is, in a word.
func appetite() -> String:
	return life.appetite()


## Bolts away from a point.
func startle(from: Vector3) -> void:
	if dead:
		return
	var away := position - from
	away.y *= 0.4
	if away.length() < 0.01:
		away = Vector3.RIGHT
	_burst = away.normalized() * 1.6
	_retarget = 0.0


## Moves it on: `delta` seconds of swimming, in which `lived` seconds of its life go by (the
## two differ only when the tank's clock is run fast).
func tick(delta: float, lived: float) -> void:
	if dead:
		_float_up(delta)
		return
	live(lived)
	if dead:
		return
	if _gait == "swim":
		_swim(delta)
	else:
		_roam(delta)


## Its hunger, growth and health over `delta` seconds (which may be many, when catching up
## on time away).
func live(delta: float) -> void:
	# (a snail on glass with algae on it is a snail that is eating)
	if _gait == "glide" and tank.algae > 0.03:
		life.hunger = minf(life.hunger, 0.3)
	# (an animal of dry land takes no harm from the water it does not live in)
	var in_water: bool = tank.is_wet() and Species.habit(species, "gait", "swim") in ["swim", "glide", "amphibious"]
	var died := life.live(delta, tank.o2 if in_water else 1.0, tank.waste if in_water else 0.0, tank.discomfort(species))
	_mat.set_shader_parameter("pale", 1.0 if dead else clampf(1.0 - health * 1.6, 0.0, 0.8))
	if died:
		tank.fish_died(self)


func _swim(delta: float) -> void:
	var box: AABB = tank.swim_box(minf(reach(), 0.3))
	_busy = maxf(_busy - delta, 0.0)
	var feeding := false
	if hunger > PECKISH and doing != "fleeing":
		# (only one that is used to the keeper will take food from the keeper's fingers)
		var food: Dictionary = tank.nearest_food(position, buddy.stage() == "new")
		if not food.is_empty():
			feeding = true
			doing = "feeding"
			_pace = 1.9
			_target = food.node.position
			if position.distance_to(_target) < reach() + 0.04:
				if food.get("held", false):
					buddy.fed()
					buddy.note("Ate from your fingers")
					tank.notice("ate from the hand", self)
				tank.eat(food)
				life.eat()
				buddy.fed()
	if not feeding:
		_think -= delta
		if _think <= 0.0:
			_think = _rng.randf_range(0.3, 0.6)
			_decide()
		_steer(delta, box)
	var speed := 0.32 * float(info().speed) * _pace * lerpf(0.4, 1.0, health)
	var to := _target - position
	var want := to.normalized() * speed if to.length() > 0.02 else Vector3.ZERO
	_vel = _vel.lerp(want, 1.0 - exp(-2.5 * delta))
	_burst = _burst.lerp(Vector3.ZERO, 1.0 - exp(-2.0 * delta))
	var v := _vel + _burst + _apart
	# (after food, and to sleep, it will nose right down to the gravel, which it otherwise
	# keeps clear of)
	var low := box.position
	if feeding or doing in ["sleeping", "buried"]:
		low.y = 0.12 + _size() * (0.05 if doing == "buried" else 0.3)
	position = (position + v * delta).clamp(low, box.end)
	if v.length() > 0.02:
		# it swims level: nose up or down only a little, and never rolls
		var dir := Vector3(v.x, v.y * 0.4, v.z).normalized()
		var turned := _heading.lerp(dir, 1.0 - exp(-4.0 * delta))
		if turned.length() < 0.05:
			turned = Vector3(dir.z, 0.0, -dir.x)
		_heading = turned.normalized()
	# one that knows the keeper well wriggles when it says hello
	if doing == "greeting" and buddy.stage() == "close":
		_roll = sin(_wag * 1.5) * 0.3
	else:
		_roll = move_toward(_roll, 0.0, delta * 2.0)
	# (the big ones beat slowly)
	_wag += delta * (4.0 + v.length() * 18.0) / maxf(float(info().size), 0.6)
	_bend("wag_phase", _wag)
	_apply_pose()


# ------------------------------------------------------------------ what it is about

## Works out the push away from the others that are too close.
func _keep_apart() -> void:
	_apart = Vector3.ZERO
	for other in tank.fish:
		if other == self or other.dead:
			continue
		var gap: Vector3 = position - other.position
		var room: float = (reach() + other.reach()) * 0.85
		if gap.length() < room and gap.length() > 0.001:
			_apart += gap.normalized() * (1.0 - gap.length() / room) * 0.35
	_apart = _apart.limit_length(0.3)


## Shows that it is the one the keeper has in hand, or that it no longer is.
func mark(on: bool) -> void:
	_marked = on


## Makes up its mind what to be about (`doing`), a couple of times a second. In order: it sees
## out a chase; it minds the keeper's finger; it says hello; it sleeps when the lamp is off;
## it begs when it is hungry and knows who feeds it; and otherwise it minds the others, by its
## kind and its temper: guards its patch, keeps a friend company, shoals, or just wanders.
func _decide() -> void:
	_keep_apart()
	if _plan == "jelly":
		doing = "wandering"
		return
	if _busy > 0.0 and is_instance_valid(_with) and not _with.dead and doing in ["chasing", "fleeing", "courting"]:
		return
	_with = null
	var stage := buddy.stage()
	var temper := buddy.temper
	if tank.lamp_on:
		_seen_by_torch = false
	if tank.torch != null:
		var off := Vector2(position.x - tank.torch.x, position.y - tank.torch.y).length()
		if off < 0.5 and not tank.torch_red:
			# a white light in the dark: it bolts, and keeps out of the way
			if doing != "hiding":
				startle(Vector3(tank.torch.x, tank.torch.y, position.z))
				tank.notice("fled the torch", self)
			doing = "hiding"
			return
		if off < 0.4 and tank.torch_red and not tank.lamp_on and not _seen_by_torch:
			# watched by red light, which it cannot see: the keeper learns what it does at night
			_seen_by_torch = true
			buddy.note("Watched by red torch: %s" % ("up and about" if Species.habit(species, "night") else "fast asleep"))
			tank.notice("watched at night", self)
	if tank.finger != null:
		var near: bool = position.distance_to(tank.finger) < 1.0
		if stage in ["friendly", "close"] or temper == "curious" or (temper == "bold" and stage != "new"):
			if doing != "following":
				tank.notice("came to the finger", self)
			doing = "following"
			return
		if near and (stage == "new" or temper == "shy"):
			doing = "hiding"
			return
	# one that keeps the night lies buried while the lamp is on, and is up and about when it is off
	var nocturnal: bool = Species.habit(species, "night")
	if nocturnal and tank.lamp_on:
		doing = "buried"
		return
	if tank.greeting > 0.0 and stage in ["friendly", "close"]:
		doing = "greeting"
		return
	if not tank.lamp_on and not nocturnal:
		doing = "sleeping"
		return
	if hunger > Life.HUNGRY and stage in ["friendly", "close"] and not nocturnal:
		doing = "begging"
		return
	_mind_the_others()


## The part of making up its mind that is about the other animals. Being near one, over and
## over, is what makes two of them friends or rivals: see `_meet`.
func _mind_the_others() -> void:
	var here := _spot()
	var nest: Variant = tank.nest_of(buddy.id)
	if nest != null:
		here = nest
	var own_kind := 0
	var intruder: Node = null
	var friend: Node = null
	for other in tank.fish:
		if other == self or other.dead:
			continue
		var gap: float = position.distance_to(other.position)
		if other.species == species:
			own_kind += 1
		if gap < 0.25 + reach():
			_meet(other)
			# one with a mouth for it eats what is small enough to fit, when it is hungry
			var prey: Array = Species.habit(species, "prey", [])
			if hunger > Life.PECKISH and other.reach() < reach() * float(Species.habit(species, "eats", 0.0)) \
					and (prey.is_empty() or other.species in prey) and _rng.randf() < 0.25:
				life.hunger = 0.0
				buddy.note("Ate %s" % other.fish_name)
				tank.eaten(other, self)
				return
		if buddy.is_friend(other.buddy.id) and (friend == null or gap < position.distance_to(friend.position)):
			friend = other
		if other.position.distance_to(here) < 0.3 + reach() and not buddy.is_friend(other.buddy.id) and other.reach() <= reach() * 1.5:
			intruder = other
	if intruder != null and is_adult() and (buddy.temper == "grumpy" or Species.guards(species) or nest != null) \
			and _rng.randf() < (0.4 if nest != null else 0.15):
		doing = "chasing"
		_with = intruder
		_busy = 2.5
		intruder.chased_by(self)
		return
	if nest != null:
		if doing != "guarding":
			tank.notice("guarded its eggs", self)
			buddy.note("Stood guard over its eggs")
		doing = "guarding"
		return
	if Species.shoals(species):
		doing = "shoaling" if own_kind >= 2 else "sulking"
		return
	if Species.habit(species, "dives") and _rng.randf() < 0.12:
		doing = "dived" if doing != "dived" else "wandering"
		if doing == "dived":
			tank.notice("dived into the sand", self)
		return
	if doing == "dived":
		return
	if friend != null and _rng.randf() < 0.7:
		doing = "keeping company"
		_with = friend
		return
	doing = "wandering"


## Two animals close by each other. Mostly nothing comes of it. Whether anything ever does is
## settled between the two of them for good (their `chemistry`, which comes of who they are):
## some pairs take to each other a little more each time, a few take against, and most stay
## strangers. Their own kind are easier to like, and a grumpy one is easier to fall out with.
func _meet(other: Node) -> void:
	if _rng.randf() > 0.12:
		return
	var a := mini(buddy.id, other.buddy.id)
	var b := maxi(buddy.id, other.buddy.id)
	var chemistry := fposmod(sin(a * 73.0 + b * 151.0) * 43758.5, 1.0)
	var sour: bool = buddy.temper == "grumpy" or other.buddy.temper == "grumpy"
	var by := 0.0
	if chemistry < (0.55 if other.species == species else 0.3):
		by = 0.035
	elif chemistry > (0.7 if sour else 0.88):
		by = -0.035
	if by == 0.0:
		return
	var before := buddy.tie(other.buddy.id)
	buddy.nudge(other.buddy.id, by)
	other.buddy.nudge(buddy.id, by)
	if other.species == species and Species.habit(species, "croaks"):
		Sfx.play("croak", _rng.randf_range(0.9, 1.15), -4.0)
		tank.notice("croaked", self, other)
		buddy.note("Croaked at %s" % other.fish_name)
	var now := buddy.tie(other.buddy.id)
	if before < Buddy.TIE and now >= Buddy.TIE:
		buddy.note("Took to %s" % other.fish_name)
		other.buddy.note("Took to %s" % fish_name)
		tank.notice("made friends", self, other)
	elif before > -Buddy.TIE and now <= -Buddy.TIE:
		buddy.note("Fell out with %s" % other.fish_name)
		other.buddy.note("Fell out with %s" % fish_name)
		tank.notice("fell out", self, other)


## It and another are about to lay: they circle each other for a few seconds first.
func court(other: Node) -> void:
	doing = "courting"
	_with = other
	_busy = 7.5
	buddy.note("Courted %s" % other.fish_name)
	buddy.nudge(other.buddy.id, 0.2)


## Another animal is seeing it off.
func chased_by(other: Node) -> void:
	if dead or _plan == "jelly":
		return
	doing = "fleeing"
	_with = other
	_busy = 2.0
	_burst = (position - other.position).normalized() * 0.9
	buddy.nudge(other.buddy.id, -0.06)
	other.buddy.nudge(buddy.id, -0.03)
	tank.notice("chase", other, self)


## Heads for wherever what it is doing takes it, at the pace that goes with it.
func _steer(delta: float, box: AABB) -> void:
	var front: float = box.end.z
	_pace = 1.0
	if doing in ["chasing", "fleeing", "keeping company", "courting"] and (not is_instance_valid(_with) or _with.dead):
		doing = "wandering"
	match doing:
		"following":
			var at: Vector3 = tank.finger if tank.finger != null else position
			# (each has its own place about the finger, so they gather round it and do not pile up)
			var about := Vector3(sin(buddy.id * 2.4), cos(buddy.id * 1.7), 0.0) * (0.1 + reach() * 1.2)
			_target = (Vector3(at.x, at.y, minf(at.z, front)) + about).clamp(box.position, box.end)
			_pace = 1.5
			if position.distance_to(_target) < 0.4:
				buddy.kept_company(delta)
		"hiding", "sulking":
			_target = tank.hide_for(position)
			_pace = 1.4 if doing == "hiding" else 0.5
		"buried":
			var den: Vector3 = tank.hide_for(_spot())
			_target = Vector3(den.x + (buddy.spot.z - 0.5) * 0.5, box.position.y, den.z)
			_pace = 1.8 if position.distance_to(_target) > 0.3 else 0.3
		"greeting":
			_target = Vector3(lerpf(box.position.x, box.end.x, 0.2 + 0.6 * buddy.spot.x),
					lerpf(box.position.y, box.end.y, 0.3 + 0.5 * buddy.spot.y), front)
			_pace = 1.4
		"sleeping":
			var bed := _spot()
			_target = Vector3(bed.x, box.position.y + 0.05 + 0.2 * buddy.spot.y, bed.z)
			_pace = 0.25
		"begging":
			_target = Vector3(lerpf(box.position.x, box.end.x, 0.15 + 0.7 * buddy.spot.x), box.end.y, front)
			_pace = 1.1
		"chasing":
			_target = _with.position
			_pace = 1.7
			if position.distance_to(_target) < reach() + _with.reach():
				_busy = 0.0
				doing = "wandering"
		"courting":
			# round and round each other, close
			var turn := _wag * 0.35 + buddy.id * PI
			_target = (_with.position + Vector3(cos(turn), 0.25 * sin(turn * 2.0), sin(turn)) * (0.12 + reach())).clamp(box.position, box.end)
			_pace = 1.5
		"guarding":
			var nest: Variant = tank.nest_of(buddy.id)
			_target = ((nest as Vector3) + Vector3(0.0, 0.12 + reach() * 0.5, 0.0)).clamp(box.position, box.end) if nest != null else position
			_pace = 0.6
		"fleeing":
			_target = (position + (position - _with.position).normalized() * 0.6).clamp(box.position, box.end)
			_pace = 1.8
		"keeping company":
			# (a little to one side of its friend, and always the same side)
			var side := 1.0 if buddy.id % 2 == 0 else -1.0
			_target = (_with.position + Vector3(side * (0.1 + reach()), 0.03 * side, 0.05)).clamp(box.position, box.end)
			if position.distance_to(_with.position) < 0.35 + reach():
				_pace = 0.8
				if _company <= 0.0:
					tank.notice("kept company", self, _with)
				_company += delta
			else:
				_company = 0.0
		"shoaling":
			# its own place in the shoal, which goes where the shoal goes
			var place := Vector3(sin(buddy.id * 2.4), cos(buddy.id * 1.7) * 0.6, cos(buddy.id * 3.1)) * (0.12 + reach())
			_target = (tank.shoal_goal(species) + place).clamp(box.position, box.end)
			_pace = 1.15
		_:
			_retarget -= delta
			if _retarget <= 0.0 or position.distance_to(_target) < 0.12:
				_retarget = _rng.randf_range(2.0, 6.0)
				_target = box.position + box.size * Vector3(_rng.randf(), _rng.randf(), _rng.randf())
				# (half the time it stays about the part of the tank it likes)
				if _rng.randf() < 0.5:
					_target = (_spot() + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.15, 0.15),
							_rng.randf_range(-0.2, 0.2))).clamp(box.position, box.end)
	if doing in ["wandering", "shoaling", "keeping company", "greeting", "begging", "sleeping", "sulking"]:
		_target = _at_its_level(_target, box)


## The place in the tank it likes to be.
func _spot() -> Vector3:
	var box: AABB = tank.swim_box(minf(reach(), 0.3)) if _gait == "swim" else tank.walk_box(_gait)
	return _at_its_level(box.position + box.size * buddy.spot, box)


## A place, moved up or down into the part of the water its kind keeps to (if it keeps to one).
func _at_its_level(at: Vector3, box: AABB) -> Vector3:
	var share := (at.y - box.position.y) / box.size.y
	match Species.habit(species, "level", ""):
		"top":
			at.y = box.position.y + box.size.y * lerpf(0.86, 1.0, share)
		"middle":
			at.y = box.position.y + box.size.y * lerpf(0.35, 0.7, share)
		"bottom":
			at.y = box.position.y + box.size.y * lerpf(0.0, 0.14, share)
	return at


## How it is, in a few words, for its card.
func mood() -> String:
	if dead:
		return "dead"
	if tank.complaint(species) != "":
		return "unhappy: it is %s here" % tank.complaint(species)
	if health < 0.6:
		return "poorly"
	var who: String = _with.fish_name if is_instance_valid(_with) else "someone"
	match doing:
		"sleeping":
			return "asleep"
		"hiding":
			return "hiding from you"
		"buried":
			return "buried till dark" if _gait == "swim" else "hidden away till dark"
		"dived":
			return "under the sand"
		"sulking":
			return "sulking for want of its own kind"
		"begging":
			return "begging"
		"greeting":
			return "saying hello"
		"following":
			return "at your finger"
		"feeding":
			return "eating"
		"chasing":
			return "seeing %s off" % who
		"fleeing":
			return "keeping clear of %s" % who
		"keeping company":
			return "with %s" % who
		"shoaling":
			return "with the shoal"
		"courting":
			return "courting %s" % who
		"guarding":
			return "guarding its eggs"
	return "perky" if buddy.stage() != "new" else "wary"


## Who its friends and rivals are, in a line (empty if it has neither).
func company() -> String:
	var friends: Array[String] = []
	var rivals: Array[String] = []
	for other in tank.fish:
		if other == self or other.dead:
			continue
		if buddy.is_friend(other.buddy.id):
			friends.append(other.fish_name)
		elif buddy.is_rival(other.buddy.id):
			rivals.append(other.fish_name)
	var lines: Array[String] = []
	if not friends.is_empty():
		lines.append("Friends with " + ", ".join(friends.slice(0, 3)))
	if not rivals.is_empty():
		lines.append("No friend of " + ", ".join(rivals.slice(0, 2)))
	return ". ".join(lines)


func _float_up(delta: float) -> void:
	if _gait != "swim":
		# (one on foot does not float: it lies where it fell, on its back)
		_roll = minf(_roll + delta * 1.2, PI)
		position.y = tank.floor_y(position.x, position.z) + _stand()
		_apply_pose()
		return
	_roll = minf(_roll + delta * 1.2, PI)
	position.y = minf(position.y + delta * 0.12, tank.water_level - _size() * 0.3)
	_apply_pose()


func _apply_pose() -> void:
	# (a fish heading straight up or down keeps the way it was facing)
	var across := Vector2(_heading.x, _heading.z)
	if across.length() > 0.2:
		_facing = across.normalized()
	var flat := Vector3(_facing.x, clampf(_heading.y, -0.5, 0.5), _facing.y).normalized()
	if _plan == "jelly":
		# upright, tipped a little the way it is drifting
		basis = (Basis(Vector3.UP, atan2(_facing.x, _facing.y)) * Basis(Vector3.RIGHT, 0.25 - _roll)).scaled(Vector3.ONE * _size())
		return
	basis = (Basis.looking_at(flat, Vector3.UP) * Basis(Vector3.FORWARD, _roll)).scaled(Vector3.ONE * _size())


# ------------------------------------------------------------------ on foot

## Moves an animal that does not swim: one that walks, hops, climbs or glides. It makes up its
## mind the same way a swimmer does (`_decide`), but goes there over the ground (or, if it
## climbs, up the back wall), and in fits and starts: a few steps, then a wait.
func _roam(delta: float) -> void:
	var box: AABB = tank.walk_box(_gait)
	_busy = maxf(_busy - delta, 0.0)
	var feeding := false
	if hunger > PECKISH and doing != "fleeing":
		var food: Dictionary = tank.nearest_food(position, buddy.stage() == "new")
		if not food.is_empty() and food.landed:
			feeding = true
			doing = "feeding"
			_pace = 1.6
			_rest = 0.0
			_target = food.node.position
			if position.distance_to(_target) < reach() + 0.06:
				tank.eat(food)
				life.eat()
				buddy.fed()
	if not feeding:
		_think -= delta
		if _think <= 0.0:
			_think = _rng.randf_range(0.3, 0.6)
			_decide()
		_steer(delta, box)
	# where it is going, brought down to the ground, or (for a climber) put on the back wall
	var goal := _target.clamp(box.position, box.end)
	var wall: bool = _gait in ["climb", "glide"] and goal.y > tank.floor_y(goal.x, goal.z) + 0.3
	if wall:
		goal.z = -tank.depth * 0.5 + 0.05
	else:
		goal.y = tank.floor_y(goal.x, goal.z) + _stand()
	var to := goal - position
	var hurried := doing in ["fleeing", "chasing", "hiding", "feeding", "following"]
	_rest = 0.0 if hurried else maxf(_rest - delta, 0.0)
	var moving: bool = _rest <= 0.0 and to.length() > 0.04 and doing != "dived"
	var v := _burst + Vector3(_apart.x, 0.0, _apart.z)
	_burst = _burst.lerp(Vector3.ZERO, 1.0 - exp(-3.0 * delta))
	if moving:
		v += to.normalized() * 0.2 * float(info().speed) * _pace * lerpf(0.4, 1.0, health)
		# (it stops now and then, as they do, for no reason it gives)
		if not hurried and _hop <= 0.0 and _rng.randf() < delta * 0.45:
			_rest = _rng.randf_range(0.8, 5.0)
	if _gait == "hop":
		# a hop is all or nothing: once off the ground it finishes, and then it sits
		if _hop > 0.0 or moving:
			_hop += delta / 0.38
			if _hop >= 1.0:
				_hop = 0.0
				if not hurried:
					_rest = _rng.randf_range(0.4, 3.0)
		else:
			v = _burst
	position += v * delta
	position = position.clamp(box.position, box.end)
	if wall and absf(position.z - goal.z) < 0.12:
		position.z = goal.z
	else:
		position.y = tank.floor_y(position.x, position.z) + _stand() + sin(PI * _hop) * _size() * 0.9
		wall = false
	if v.length() > 0.02:
		var dir := (Vector3(v.x, v.y, 0.0) if wall else Vector3(v.x, 0.0, v.z)).normalized()
		var turned := _heading.lerp(dir, 1.0 - exp(-5.0 * delta))
		_heading = turned.normalized() if turned.length() > 0.05 else dir
	_wag += delta * v.length() * 55.0 / maxf(float(info().size), 0.5)
	_bend("wag_phase", _wag)
	if _gait == "hop":
		_bend("leap", sin(PI * _hop))
	if wall:
		# flat against the wall, belly to it, head the way it is going
		basis = Basis.looking_at(_heading if _heading.length() > 0.1 else Vector3.UP, Vector3.BACK).scaled(Vector3.ONE * _size())
	else:
		var across := Vector2(_heading.x, _heading.z)
		if across.length() > 0.2:
			_facing = across.normalized()
		basis = Basis.looking_at(Vector3(_facing.x, 0.0, _facing.y), Vector3.UP).scaled(Vector3.ONE * _size())


## How far its middle is above the ground it stands on (metres). One that has dived is most of
## the way under it.
func _stand() -> float:
	return _size() * (float(Species.habit(species, "stand", 0.25)) - (0.22 if doing == "dived" else 0.0))
