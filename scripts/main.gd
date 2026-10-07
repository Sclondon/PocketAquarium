extends Node
## Pocket Aquarium: a small tank to keep. This is the frame round it: the low-res render
## target, the camera that turns about the tank, what a tap or a drag does, and saving.
##
## Run with `-- --no-save` for a new tank that is never saved, `--tickets=N` for a wallet of
## that size, `--speed=N` to run the tank's clock N times too fast (1440 is a day a minute), and `--shots=FOLDER` or `--smoke` for the automated tour (tools/autotest.gd).

const Tank := preload("res://scripts/tank/tank.gd")
const Room := preload("res://scripts/tank/room.gd")
const Species := preload("res://scripts/tank/species.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const Autotest := preload("res://scripts/tools/autotest.gd")

## Screen pixels to one pixel of the 3D picture.
const PIXEL := 3
const FOV := 40.0
const SAVE_EVERY := 8.0
## The camera's range: shares of the fitting distance for the whole tank, and metres from a
## fish that is being followed.
const ZOOM_IN := 0.6
const ZOOM_OUT := 1.7
const CLOSEST := 0.3
const FOLLOW_FROM := 1.0

var tank: Tank
var room: Room
var hud: Hud
var camera: Camera3D
var tool := "feed"
var selected: Node

var _container: SubViewportContainer
var _yaw := 0.25
var _pitch := 0.14
## How far off the camera is: a share of the distance that just fits the whole tank in. With a
## fish selected it may come in far closer (CLOSEST metres from the fish).
var _zoom := 1.12
var _zoom_before := 1.12
var _focus := Vector3.ZERO
var _away := 0.0
var _pressed := false
var _dragging := false
var _press_at := Vector2.ZERO
var _touches := {}
var _pinch := 0.0
var _save_in := SAVE_EVERY
var _scrub_sound := 0.0


func _ready() -> void:
	_container = SubViewportContainer.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.stretch = true
	_container.stretch_shrink = PIXEL
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var post := ShaderMaterial.new()
	post.shader = preload("res://shaders/post.gdshader")
	_container.material = post
	add_child(_container)
	var view := SubViewport.new()
	_container.add_child(view)
	room = Room.new()
	view.add_child(room)
	tank = Tank.new()
	view.add_child(tank)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.03
	view.add_child(camera)

	hud = Hud.new()
	add_child(hud)
	hud.setup(tank)
	hud.pad_input.connect(_on_pad)
	hud.tool_picked.connect(func(picked: String) -> void: tool = picked)
	hud.give_away.connect(_give_away)
	hud.card_closed.connect(_select.bind(null))
	hud.next_fish.connect(_select_next)
	tank.said.connect(hud.say)
	tank.discovered.connect(_on_discovered)
	var saved: Variant = Save.data.get("tank", {})
	tank.load_state(saved if saved is Dictionary else {})
	_focus = tank.centre()
	_place_camera(1.0)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--speed="):
			tank.time_scale = maxf(float(arg.get_slice("=", 1)), 0.0)
		if arg.begins_with("--shots=") or arg == "--smoke":
			var test := Autotest.new()
			test.main = self
			test.folder = arg.get_slice("=", 1) if "=" in arg else ""
			add_child(test)


func _process(delta: float) -> void:
	room.dress(tank.width)
	room.set_lamp(tank.lamp_glow())
	_place_camera(delta)
	_scrub_sound = maxf(_scrub_sound - delta, 0.0)
	if selected != null and (not is_instance_valid(selected) or selected.dead):
		_select(null)
	_save_in -= delta
	if _save_in <= 0.0:
		save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save()


func save() -> void:
	_save_in = SAVE_EVERY
	if tank != null:
		Save.data["tank"] = tank.to_data()
		Save.write()


## The camera turns about the middle of the tank, far enough off that the whole tank fits
## whichever way up the screen is; or, with a fish selected, about the fish, as close as you
## like. It glides between the two.
func _place_camera(delta: float) -> void:
	var screen := _container.size
	if screen.y < 1.0:
		return
	var following := selected != null and is_instance_valid(selected)
	var want_focus: Vector3 = selected.position if following else tank.centre()
	var want_away := maxf(_fit() * _zoom, CLOSEST) if following else _fit() * _zoom
	var ease := 1.0 - exp(-6.0 * delta)
	_focus = _focus.lerp(want_focus, ease)
	_away = want_away if _away <= 0.0 else lerpf(_away, want_away, ease)
	var dir := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	camera.position = _focus + dir * _away
	camera.look_at(_focus)


## How far off the camera has to be for the whole tank to fit on the screen.
func _fit() -> float:
	var screen := _container.size
	var half := tan(deg_to_rad(FOV) * 0.5)
	var need_h := (tank.width * 0.5 + 0.35) / (half * screen.x / maxf(screen.y, 1.0))
	var need_v := (tank.height * 0.5 + 0.45) / half
	return maxf(need_h, need_v) + tank.depth * 0.5


## Brings the camera nearer (below 1) or takes it further off, within what is allowed now.
func _zoom_by(factor: float) -> void:
	var nearest := CLOSEST / _fit() if selected != null else ZOOM_IN
	_zoom = clampf(_zoom * factor, nearest, ZOOM_OUT)


# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	# two fingers pinch to zoom
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch = 0.0
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 2:
			var at: Array = _touches.values()
			var gap: float = (at[0] as Vector2).distance_to(at[1])
			if _pinch > 0.0 and gap > 1.0:
				_zoom_by(_pinch / gap)
			_pinch = gap
			_dragging = true


func _on_pad(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(1.0 / 0.9)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_dragging = false
				_press_at = event.position
			elif _pressed:
				_pressed = false
				if not _dragging:
					_tap(event.position)
	elif event is InputEventMouseMotion and _pressed:
		if not _dragging and event.position.distance_to(_press_at) > 10.0:
			_dragging = true
		if not _dragging or _touches.size() >= 2:
			return
		if tool == "scrub" and not _through_tank(event.position).is_empty():
			tank.scrub(event.relative.length() * 0.0012)
			if _scrub_sound <= 0.0 and tank.algae > 0.0:
				_scrub_sound = 0.12
				Sfx.play("scrub", randf_range(0.9, 1.2), -6.0)
		else:
			_yaw = clampf(_yaw - event.relative.x * 0.006, -1.25, 1.25)
			_pitch = clampf(_pitch + event.relative.y * 0.004, -0.12 if selected != null else 0.0, 0.65)


## Where a line from the eye through a point on the screen goes into the tank and comes out
## again (empty when it misses).
func _through_tank(at: Vector2) -> Array[Vector3]:
	var from := camera.project_ray_origin(at / PIXEL)
	var dir := camera.project_ray_normal(at / PIXEL)
	var box: AABB = tank.inside()
	var enter: Variant = box.intersects_ray(from, dir)
	var leave: Variant = box.intersects_ray(from + dir * 60.0, -dir)
	if enter == null or leave == null:
		return []
	return [enter, leave]


func _tap(at: Vector2) -> void:
	var from := camera.project_ray_origin(at / PIXEL)
	var dir := camera.project_ray_normal(at / PIXEL)
	var fish: Node = tank.pick_fish(from, dir)
	if fish != null:
		if fish.dead:
			tank.remove_fish(fish)
			hud.say("%s has been netted out." % fish.fish_name)
		else:
			_select(fish)
			Sfx.play("ui", 1.4)
		return
	# (a tap in the water leaves the fish in hand selected, so it can be fed while followed;
	# a tap outside the tank lets it go)
	var through := _through_tank(at)
	if through.is_empty():
		_select(null)
		return
	if tool == "feed":
		var mid := (through[0] + through[1]) * 0.5
		if not tank.anyone_hungry():
			hud.say("Nobody is hungry. Food left on the gravel rots.")
		tank.drop_food(mid.x, mid.z)
		Sfx.play("plop", randf_range(0.9, 1.3))
	else:
		tank.tap(through[0])
		Sfx.play("tap")


## Takes a fish in hand (null lets go). The camera follows the fish in hand, and comes in
## close to it the first time; letting go takes it back to where it was.
func _select(fish: Node) -> void:
	if fish != null and selected == null:
		_zoom_before = _zoom
		_zoom = FOLLOW_FROM / _fit()
	elif fish == null and selected != null:
		_zoom = _zoom_before
		_pitch = maxf(_pitch, 0.0)
	selected = fish
	hud.show_fish(fish)


## Steps to the next living fish (or the one before: -1).
func _select_next(step: int) -> void:
	var living: Array[Node] = []
	for f in tank.fish:
		if not f.dead:
			living.append(f)
	if living.is_empty():
		return
	var at := living.find(selected)
	_select(living[posmod(at + step, living.size())] if at >= 0 else living[0])
	Sfx.play("ui", 1.4)


func _give_away(fish: Node) -> void:
	if is_instance_valid(fish):
		hud.say("%s has gone to a good home." % fish.fish_name)
		tank.remove_fish(fish)
	_select(null)


func _on_discovered(species: String) -> void:
	hud.say("New in the fish-dex: %s!" % Species.LIST[species].name)
	Sfx.play("new")
	# the arcade's leaderboard counts kinds of fish kept
	Tickets.post({"type": "PLAYER_DIED", "score": tank.dex.size()})
	save()
