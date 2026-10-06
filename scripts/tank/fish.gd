extends MeshInstance3D
## One fish: where it swims, how hungry and how well it is, and how grown.
##
## It wanders about the tank, heads for food when it is hungry, and bolts when the glass is
## tapped. It gets hungrier all the time; a fish that is starving, short of oxygen or in foul
## water loses health, and one that runs out dies and floats to the top.

const Species := preload("res://scripts/tank/species.gd")
const FishMesh := preload("res://scripts/tank/fish_mesh.gd")

## Seconds from a full stomach to starving, and from hatching to full-grown (when fed).
const HUNGER_TIME := 600.0
const GROW_TIME := 150.0
## How hungry it has to be to go looking for food, and how much one flake fills it.
const PECKISH := 0.25
const FLAKE := 0.35
## Above this hunger, below this oxygen or above this waste, it is being harmed.
const STARVING := 0.92
const LOW_OXYGEN := 0.3
const FOUL := 0.75
## Health lost a second for each of those, and won back a second when none apply.
const HARM := 0.006
const HEAL := 0.02
## Model units to metres, for a full-grown fish of size 1.
const SCALE := 0.15

var species := "guppy"
var fish_name := ""
## 0 newly hatched to 1 full-grown
var growth := 1.0
var hunger := 0.3
var health := 1.0
var dead := false
## Seconds until it can breed again
var breed_wait := 30.0

## The tank it lives in (tank.gd)
var tank

var _mat: ShaderMaterial
var _vel := Vector3.ZERO
var _burst := Vector3.ZERO
var _target := Vector3.ZERO
var _retarget := 0.0
var _heading := Vector3.FORWARD
var _wag := 0.0
var _roll := 0.0
var _rng := RandomNumberGenerator.new()


func setup(in_tank, data: Dictionary) -> void:
	tank = in_tank
	species = data.get("species", "guppy")
	if not Species.LIST.has(species):
		species = "guppy"
	fish_name = data.get("name", "")
	if fish_name == "":
		fish_name = Species.NAMES[_rng.randi() % Species.NAMES.size()]
	growth = clampf(data.get("growth", 1.0), 0.0, 1.0)
	hunger = clampf(data.get("hunger", 0.3), 0.0, 1.0)
	health = clampf(data.get("health", 1.0), 0.01, 1.0)
	breed_wait = data.get("breed_wait", 30.0)
	mesh = FishMesh.of(species)
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/fish.gdshader")
	_mat.set_shader_parameter("wag_phase", _rng.randf() * TAU)
	material_override = _mat
	var box: AABB = tank.swim_box(reach())
	position = box.position + box.size * Vector3(_rng.randf(), _rng.randf(), _rng.randf())
	_heading = Vector3(1.0 if _rng.randf() < 0.5 else -1.0, 0.0, 0.0)
	_apply_pose()


func to_data() -> Dictionary:
	return {"species": species, "name": fish_name, "growth": growth, "hunger": hunger, "health": health,
			"breed_wait": breed_wait}


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


func _size() -> float:
	return SCALE * float(info().size) * lerpf(0.4, 1.0, growth)


func stage() -> String:
	return "Fry" if growth < 0.4 else ("Young" if growth < 1.0 else "Adult")


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


func tick(delta: float) -> void:
	if dead:
		_float_up(delta)
		return
	_live(delta)
	if dead:
		return
	_swim(delta)


func _live(delta: float) -> void:
	hunger = minf(hunger + delta / HUNGER_TIME, 1.0)
	breed_wait = maxf(breed_wait - delta, 0.0)
	if growth < 1.0 and hunger < 0.7:
		growth = minf(growth + delta / GROW_TIME, 1.0)
	var harms := int(hunger > STARVING) + int(tank.o2 < LOW_OXYGEN) + int(tank.waste > FOUL)
	if harms > 0:
		health -= HARM * harms * delta
	else:
		health = minf(health + HEAL * delta, 1.0)
	_mat.set_shader_parameter("pale", clampf(1.0 - health * 1.6, 0.0, 0.8))
	if health <= 0.0:
		dead = true
		health = 0.0
		_mat.set_shader_parameter("pale", 1.0)
		tank.fish_died(self)


func _swim(delta: float) -> void:
	var box: AABB = tank.swim_box(reach())
	var chasing := false
	if hunger > PECKISH:
		var food: Dictionary = tank.nearest_food(position)
		if not food.is_empty():
			chasing = true
			_target = food.node.position
			if position.distance_to(_target) < reach() + 0.04:
				tank.eat(food)
				hunger = maxf(hunger - FLAKE, 0.0)
	if not chasing:
		_retarget -= delta
		if _retarget <= 0.0 or position.distance_to(_target) < 0.12:
			_retarget = _rng.randf_range(2.0, 6.0)
			_target = box.position + box.size * Vector3(_rng.randf(), _rng.randf(), _rng.randf())
	var speed := 0.32 * float(info().speed) * (1.9 if chasing else 1.0) * lerpf(0.4, 1.0, health)
	var to := _target - position
	var want := to.normalized() * speed if to.length() > 0.02 else Vector3.ZERO
	_vel = _vel.lerp(want, 1.0 - exp(-2.5 * delta))
	_burst = _burst.lerp(Vector3.ZERO, 1.0 - exp(-2.0 * delta))
	var v := _vel + _burst
	position = (position + v * delta).clamp(box.position, box.end)
	if v.length() > 0.02:
		# it swims level: nose up or down only a little, and never rolls
		var dir := Vector3(v.x, v.y * 0.4, v.z).normalized()
		var turned := _heading.lerp(dir, 1.0 - exp(-4.0 * delta))
		if turned.length() < 0.05:
			turned = Vector3(dir.z, 0.0, -dir.x)
		_heading = turned.normalized()
	_wag += delta * (4.0 + v.length() * 18.0)
	_mat.set_shader_parameter("wag_phase", _wag)
	_apply_pose()


func _float_up(delta: float) -> void:
	_roll = minf(_roll + delta * 1.2, PI)
	position.y = minf(position.y + delta * 0.12, tank.water_level - _size() * 0.3)
	_apply_pose()


func _apply_pose() -> void:
	var flat := Vector3(_heading.x, clampf(_heading.y, -0.5, 0.5), _heading.z).normalized()
	basis = (Basis.looking_at(flat, Vector3.UP) * Basis(Vector3.FORWARD, _roll)).scaled(Vector3.ONE * _size())
