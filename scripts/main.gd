extends Node
## Pocket Aquarium: a shelf of small tanks to keep. This is the frame round them: the low-res
## render target, the three slots of the shelf and which is being looked at, the camera that
## turns about a tank or follows a fish, what a tap or a drag does, and saving.
##
## Run with `-- --no-save` for a new shelf that is never saved, `--tickets=N` for a wallet of
## that size, `--speed=N` to run the tanks' clocks N times too fast (1440 is a day a minute), and
## `--shots=FOLDER` or `--smoke` for the automated tour (tools/autotest.gd).

const Tank := preload("res://scripts/tank/tank.gd")
const Room := preload("res://scripts/tank/room.gd")
const Species := preload("res://scripts/tank/species.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const Autotest := preload("res://scripts/tools/autotest.gd")

## Screen pixels to one pixel of the 3D picture.
const PIXEL := 2
const FOV := 40.0
const SAVE_EVERY := 8.0
## The camera's range: shares of the fitting distance for the whole tank; and, for a fish that
## is being followed, metres from it at the nearest and to start with (more for a big one:
## see _closest).
const ZOOM_IN := 0.6
const ZOOM_OUT := 1.7
const CLOSEST := 0.3
const FOLLOW_FROM := 1.0
## The slot every shelf starts with a tank in: the middle one.
const FIRST_SLOT := 1

## The tank in each slot of the shelf, bottom to top (null where there is none yet).
var tanks: Array[Tank] = [null, null, null]
## The slot being looked at, and the tank in it (null for an empty slot).
var slot := FIRST_SLOT
var tank: Tank:
	get:
		return tanks[slot]
## Every kind of animal ever kept, shared by all the tanks.
var dex := {}
var room: Room
var hud: Hud
var camera: Camera3D
var tool := "feed"
var selected: Node

var _container: SubViewportContainer
var _view: SubViewport
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
var _speed := 1.0


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
	_view = SubViewport.new()
	_container.add_child(_view)
	room = Room.new()
	_view.add_child(room)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.03
	_view.add_child(camera)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--speed="):
			_speed = maxf(float(arg.get_slice("=", 1)), 0.0)

	hud = Hud.new()
	add_child(hud)
	hud.setup()
	hud.dex.kept = dex
	hud.pad_input.connect(_on_pad)
	hud.tool_picked.connect(func(picked: String) -> void: tool = picked)
	hud.give_away.connect(_give_away)
	hud.card_closed.connect(_select.bind(null))
	hud.next_fish.connect(_select_next)
	hud.shelf_stepped.connect(func(step: int) -> void: look_at_slot(slot + step))
	hud.tank_wanted.connect(_buy_tank)

	# the save: a tank for each slot (an older save has only the one, for the middle slot)
	for id in Save.data.get("dex", []):
		if Species.LIST.has(str(id)):
			dex[str(id)] = true
	var saved: Array = Save.data.get("tanks", [])
	if saved.is_empty():
		saved = [null, Save.data.get("tank", {}), null]
	for i in tanks.size():
		var data: Variant = saved[i] if i < saved.size() else null
		if data is Dictionary or i == FIRST_SLOT:
			add_tank(i, data if data is Dictionary else {})
	look_at_slot(FIRST_SLOT)
	_focus = _slot_centre()
	_place_camera(1.0)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots=") or arg == "--smoke":
			var test := Autotest.new()
			test.main = self
			test.folder = arg.get_slice("=", 1) if "=" in arg else ""
			add_child(test)


func _process(delta: float) -> void:
	var widths: Array[float] = []
	var glow := 0.0
	for t in tanks:
		widths.append(t.width if t != null else 0.0)
		if t != null:
			glow = maxf(glow, t.lamp_glow())
	room.dress(widths)
	room.set_lamp(glow)
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
	var kept: Array = []
	for t in tanks:
		kept.append(t.to_data() if t != null else null)
	Save.data["tanks"] = kept
	Save.data["dex"] = dex.keys()
	Save.data.erase("tank")
	Save.write()


# ------------------------------------------------------------------ the shelf

## Stands a tank in a slot of the shelf, set up from `data` (its kind alone makes a new one).
func add_tank(at: int, data: Dictionary) -> Tank:
	var t := Tank.new()
	t.dex = dex
	t.position.y = Room.SLOTS[at]
	t.time_scale = _speed
	_view.add_child(t)
	t.said.connect(hud.say)
	t.discovered.connect(_on_discovered)
	tanks[at] = t
	t.load_state(data)
	return t


## Turns to another slot of the shelf (one with a tank in it or not).
func look_at_slot(to: int) -> void:
	_select(null)
	slot = clampi(to, 0, tanks.size() - 1)
	hud.show_slot(tank, slot, tanks.size())


func _buy_tank(kind: String) -> void:
	if tank != null:
		return
	if not Tickets.spend(Tank.PRICES[kind], "tank:" + kind):
		Sfx.play("no")
		return
	Sfx.play("buy")
	add_tank(slot, {"kind": kind})
	look_at_slot(slot)
	hud.say("%s. %s" % [Tank.KIND_NAMES[kind], "It wants filling: see the shop." if kind == "sea" else "Two guppies came with it."])
	save()


## The middle of the slot being looked at: of its tank, or of where one would stand.
func _slot_centre() -> Vector3:
	if tank != null:
		return tank.position + tank.centre()
	return Vector3(0.0, Room.SLOTS[slot] + 0.75, 0.0)


# ------------------------------------------------------------------ the camera

## The camera turns about the middle of the tank, far enough off that the whole tank fits
## whichever way up the screen is; or, with a fish selected, about the fish, as close as you
## like. It glides between the two, and from one shelf to the next.
func _place_camera(delta: float) -> void:
	var screen := _container.size
	if screen.y < 1.0:
		return
	var following := selected != null and is_instance_valid(selected) and tank != null
	var want_focus: Vector3 = tank.position + selected.position if following else _slot_centre()
	var want_away := maxf(_fit() * _zoom, _closest()) if following else _fit() * _zoom
	var ease := 1.0 - exp(-6.0 * delta)
	_focus = _focus.lerp(want_focus, ease)
	_away = want_away if _away <= 0.0 else lerpf(_away, want_away, ease)
	var dir := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	camera.position = _focus + dir * _away
	camera.look_at(_focus)


## How far off the camera has to be for the whole tank (or the empty slot) to fit on the screen.
func _fit() -> float:
	var screen := _container.size
	var size := Vector3(tank.width, tank.height, tank.depth) if tank != null else Vector3(2.2, 1.5, 1.2)
	var half := tan(deg_to_rad(FOV) * 0.5)
	var need_h := (size.x * 0.5 + 0.35) / (half * screen.x / maxf(screen.y, 1.0))
	var need_v := (size.y * 0.5 + 0.45) / half
	return maxf(need_h, need_v) + size.z * 0.5


## How near the camera may come to the fish in hand: nearer to a small one than a whale.
func _closest() -> float:
	return maxf(CLOSEST, selected.reach() * 1.6) if selected != null and is_instance_valid(selected) else CLOSEST


## Brings the camera nearer (below 1) or takes it further off, within what is allowed now.
func _zoom_by(factor: float) -> void:
	var nearest := _closest() / _fit() if selected != null else ZOOM_IN
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
		if tool == "scrub" and tank != null and not _through_tank(event.position).is_empty():
			tank.scrub(event.relative.length() * 0.0012)
			if _scrub_sound <= 0.0 and tank.algae > 0.0:
				_scrub_sound = 0.12
				Sfx.play("scrub", randf_range(0.9, 1.2), -6.0)
		else:
			_yaw = clampf(_yaw - event.relative.x * 0.006, -1.25, 1.25)
			_pitch = clampf(_pitch + event.relative.y * 0.004, -0.12 if selected != null else 0.0, 0.65)


## Where a line from the eye through a point on the screen goes into the tank and comes out
## again, in the tank's own space (empty when it misses).
func _through_tank(at: Vector2) -> Array[Vector3]:
	var from := camera.project_ray_origin(at / PIXEL) - tank.position
	var dir := camera.project_ray_normal(at / PIXEL)
	var box: AABB = tank.inside()
	var enter: Variant = box.intersects_ray(from, dir)
	var leave: Variant = box.intersects_ray(from + dir * 60.0, -dir)
	if enter == null or leave == null:
		return []
	return [enter, leave]


func _tap(at: Vector2) -> void:
	if tank == null:
		return
	var from := camera.project_ray_origin(at / PIXEL) - tank.position
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
			hud.say("Nobody is hungry. Food left on the bottom rots.")
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
		_zoom = minf(maxf(FOLLOW_FROM, fish.reach() * 4.5) / _fit(), 1.0)
	elif fish == null and selected != null:
		_zoom = _zoom_before
		_pitch = maxf(_pitch, 0.0)
	selected = fish
	hud.show_fish(fish)


## Steps to the next living fish (or the one before: -1).
func _select_next(step: int) -> void:
	if tank == null:
		return
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
	if is_instance_valid(fish) and tank != null:
		hud.say("%s has gone to a good home." % fish.fish_name)
		tank.remove_fish(fish)
	_select(null)


func _on_discovered(species: String) -> void:
	hud.say("New in the fish-dex: %s!" % Species.LIST[species].name)
	Sfx.play("new")
	# the arcade's leaderboard counts kinds of animal kept
	Tickets.post({"type": "PLAYER_DIED", "score": dex.size()})
	save.call_deferred()
