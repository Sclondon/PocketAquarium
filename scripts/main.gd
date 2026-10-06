extends Node
## Pocket Aquarium: a small tank to keep. This is the frame round it: the low-res render
## target, the camera that turns about the tank, what a tap or a drag does, and saving.
##
## Run with `-- --no-save` for a new tank that is never saved, `--tickets=N` for a wallet of
## that size, `--speed=N` to run the tank's clock N times too fast (1440 is a day a minute), and `--shots=FOLDER` or `--smoke` for the automated tour (tools/autotest.gd).

const Tank := preload("res://scripts/tank/tank.gd")
const Species := preload("res://scripts/tank/species.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const Autotest := preload("res://scripts/tools/autotest.gd")

## Screen pixels to one pixel of the 3D picture.
const PIXEL := 3
const FOV := 40.0
const SAVE_EVERY := 8.0

var tank: Tank
var hud: Hud
var camera: Camera3D
var tool := "feed"
var selected: Node

var _container: SubViewportContainer
var _yaw := 0.25
var _pitch := 0.14
var _zoom := 1.0
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
	tank = Tank.new()
	view.add_child(tank)
	camera = Camera3D.new()
	camera.fov = FOV
	view.add_child(camera)

	hud = Hud.new()
	add_child(hud)
	hud.setup(tank)
	hud.pad_input.connect(_on_pad)
	hud.tool_picked.connect(func(picked: String) -> void: tool = picked)
	hud.give_away.connect(_give_away)
	hud.card_closed.connect(_select.bind(null))
	tank.said.connect(hud.say)
	tank.discovered.connect(_on_discovered)
	var saved: Variant = Save.data.get("tank", {})
	tank.load_state(saved if saved is Dictionary else {})
	_place_camera()

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--speed="):
			tank.time_scale = maxf(float(arg.get_slice("=", 1)), 0.0)
		if arg.begins_with("--shots=") or arg == "--smoke":
			var test := Autotest.new()
			test.main = self
			test.folder = arg.get_slice("=", 1) if "=" in arg else ""
			add_child(test)


func _process(delta: float) -> void:
	_place_camera()
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
## whichever way up the screen is.
func _place_camera() -> void:
	var screen := _container.size
	if screen.y < 1.0:
		return
	var half := tan(deg_to_rad(FOV) * 0.5)
	var need_h := (tank.width * 0.5 + 0.35) / (half * screen.x / screen.y)
	var need_v := (tank.height * 0.5 + 0.45) / half
	var away := (maxf(need_h, need_v) + tank.depth * 0.5) * _zoom
	var dir := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	camera.position = tank.centre() + dir * away
	camera.look_at(tank.centre())


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
				_zoom = clampf(_zoom * _pinch / gap, 0.55, 1.3)
			_pinch = gap
			_dragging = true


func _on_pad(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 0.05, 0.55, 1.3)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 0.05, 0.55, 1.3)
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
			_pitch = clampf(_pitch + event.relative.y * 0.004, 0.0, 0.65)


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
	_select(null)
	var through := _through_tank(at)
	if through.is_empty():
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


func _select(fish: Node) -> void:
	selected = fish
	hud.show_fish(fish)


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
