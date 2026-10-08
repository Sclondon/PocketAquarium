extends Node
## Pocket Aquarium: a shelf of small tanks to keep. This is the frame round them: the
## picture, the three slots of the shelf and which is being looked at, the camera that
## turns about a tank or follows a fish, what a tap or a drag does, and saving.
##
## Run with `-- --no-save` for a new shelf that is never saved, `--tickets=N` for a wallet of
## that size, `--speed=N` to run the tanks' clocks N times too fast (1440 is a day a minute),
## `--seed=N` to make everything that is left to chance fall out the same way every run, and
## `--shots=FOLDER` or `--smoke` for the automated tour (tools/autotest.gd).

const Tank := preload("res://scripts/tank/tank.gd")
const Room := preload("res://scripts/tank/room.gd")
const Species := preload("res://scripts/tank/species.gd")
const Kinds := preload("res://scripts/tank/kinds.gd")
const Notes := preload("res://scripts/ui/notes.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const Autotest := preload("res://scripts/tools/autotest.gd")

## The longest side the 3D picture is ever drawn at, in pixels: a bigger screen than this
## shares each pixel of it between two or more of its own (see `_fit_picture`).
const LONGEST := 1600
const FOV := 40.0
const SAVE_EVERY := 8.0
## The camera's range: shares of the fitting distance for the whole tank; and, for a fish that
## is being followed, metres from it at the nearest and to start with (more for a big one:
## see _closest).
const ZOOM_IN := 0.6
const ZOOM_OUT := 1.7
const CLOSEST := 0.3
const FOLLOW_FROM := 1.0
## What a new keeper is told, a line at a time and half a minute apart, once each for good.
const TIPS := [
	"FEED, then tap the water. Hold your finger still on the glass to offer it by hand.",
	"Tap a fish to follow it. Each one has a page of its own.",
	"HAND: rest a finger on the glass. The ones that know you will come.",
	"Turn the LAMP off and take the TORCH. Some of them only come out in the dark.",
	"UP and DOWN: there are empty shelves to fill, and something on top.",
]

## The slot every shelf starts with a tank in: the middle one.
const FIRST_SLOT := 2
## Past the top shelf is the top of the unit, where the covered tank stands: it is looked at
## like a slot, though no tank can be put there.
const COVERED := 5

## The tank in each slot of the shelf, bottom to top (null where there is none yet).
var tanks: Array[Tank] = [null, null, null, null, null]
## The slot being looked at, and the tank in it (null for an empty slot).
var slot := FIRST_SLOT
var tank: Tank:
	get:
		return tanks[slot] if slot < tanks.size() else null
## Every kind of animal ever kept, shared by all the tanks.
var dex := {}
var room: Room
var hud: Hud
var camera: Camera3D
var tool := "feed"
## Whether the torch is the red one (which the animals cannot see) or the white.
var torch_red := true
var selected: Node

## The 3D picture, stretched over the whole window. It is drawn in the window's own pixels
## (see `_fit_picture`), not the HUD's, which are fewer on a big screen.
var _container: TextureRect
var _view: SubViewport
## Screen pixels to one pixel of the 3D picture (1 unless the screen is bigger than LONGEST).
var _shrink := 1
var _yaw := 0.25
var _pitch := 0.14
## How far off the camera is: a share of the distance that just fits the whole tank in. With a
## fish selected it may come in far closer (CLOSEST metres from the fish).
var _zoom := 1.0
var _zoom_before := 1.0
var _focus := Vector3.ZERO
var _away := 0.0
var _pressed := false
var _dragging := false
var _press_at := Vector2.ZERO
var _touches := {}
var _pinch := 0.0
## Whether the finger now down went down on the glass with the hand tool, and when it last
## moved (seconds).
var _on_glass := false
## How long the covered tank has been uncovered this time (seconds), and how long till the
## notebook is next looked over for pages that have turned up.
var _uncovered_for := 0.0
var _notes_in := 1.0
## Seconds till the next of the hints a new keeper is given (see TIPS).
var _tip_in := 6.0
## With the food in hand, a finger held still on the glass holds a pinch out there (see
## `Tank.offer`): when the finger went down, and whether it is holding food out now.
var _pressed_when := 0.0
var _offering := false
var _pointed_at := 0.0
var _save_in := SAVE_EVERY
var _scrub_sound := 0.0
var _speed := 1.0


func _ready() -> void:
	_container = TextureRect.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_container.stretch_mode = TextureRect.STRETCH_SCALE
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var post := ShaderMaterial.new()
	post.shader = preload("res://shaders/post.gdshader")
	_container.material = post
	add_child(_container)
	_view = SubViewport.new()
	_view.msaa_3d = Viewport.MSAA_2X
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	_container.texture = _view.get_texture()
	_fit_picture()
	get_window().size_changed.connect(_fit_picture)
	room = Room.new()
	_view.add_child(room)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.03
	_view.add_child(camera)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--speed="):
			_speed = maxf(float(arg.get_slice("=", 1)), 0.0)
		elif arg.begins_with("--seed="):
			seed(int(arg.get_slice("=", 1)))

	hud = Hud.new()
	add_child(hud)
	hud.setup()
	hud.dex.kept = dex
	hud.pad_input.connect(_on_pad)
	hud.tool_picked.connect(_pick_tool)
	hud.give_away.connect(_give_away)
	hud.move_fish.connect(_move)
	hud.page.other_homes = _other_homes
	hud.card_closed.connect(_select.bind(null))
	hud.next_fish.connect(_select_next)
	hud.shelf_stepped.connect(func(step: int) -> void: look_at_slot(slot + step))
	hud.tank_wanted.connect(_buy_tank)

	# the save: a tank for each slot (Save has already brought an older file up to date)
	for id in Save.data.get("dex", []):
		if Species.LIST.has(str(id)):
			dex[str(id)] = true
	var saved: Array = Save.data.get("tanks", [])
	for i in tanks.size():
		var data: Variant = saved[i] if i < saved.size() else null
		if data is Dictionary or i == FIRST_SLOT:
			add_tank(i, data if data is Dictionary else {})
	look_at_slot(FIRST_SLOT)
	if saved.is_empty():
		hud.say("Somebody kept this tank before you. The fish have names already.")
	for t in tanks:
		if t != null:
			t.greet()
	_focus = _slot_centre()
	_place_camera(1.0)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots=") or arg.begins_with("--homes=") or arg == "--smoke":
			var test := Autotest.new()
			test.main = self
			test.folder = arg.get_slice("=", 1) if "=" in arg else ""
			test.homes = arg.begins_with("--homes=")
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
	# the hints, for as long as there are any left to give
	var told := int(Save.data.get("tips", 0))
	if told < TIPS.size() and not hud.is_sheet_open():
		_tip_in -= delta
		if _tip_in <= 0.0:
			_tip_in = 28.0
			hud.say(TIPS[told])
			Save.data["tips"] = told + 1
	_notes_in -= delta
	if _notes_in <= 0.0:
		_notes_in = 1.0
		_look_for_pages()
	# what is under the cloth comes out when it has been left in the dark a little, once the
	# keeper has come back to it often enough
	if room.is_uncovered():
		_uncovered_for += delta
		var lifted := int(Save.data.get("cave", {}).get("lifted", 0))
		if lifted >= 3 and _uncovered_for > 4.0 and not room.olm_out:
			room.show_olm(true)
			if lifted >= 5:
				note("olm")
				if not dex.has("olm"):
					dex["olm"] = true
					_on_discovered("olm")
			else:
				note("pale")
				hud.say("Something pale, behind the rock. Then it is not behind the rock.")
	else:
		_uncovered_for = 0.0
		room.show_olm(false)
	# nobody puts the cloth back when a lamp comes on. It is back all the same
	if room.is_uncovered() and _any_lamp():
		room.uncover(false)
		if slot == COVERED:
			hud.say("The cloth is back over it. You did not put it there.")
	# a finger held still on the glass, with the food in hand, holds a pinch out there
	var held_for := Time.get_ticks_msec() * 0.001 - _pressed_when
	if _pressed and not _dragging and not _offering and tool == "feed" and tank != null and held_for > 0.35:
		var held := _through_tank(_press_at)
		if not held.is_empty():
			_offering = true
			tank.offer(held[0])
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
	Save.write()


# ------------------------------------------------------------------ the picture

## Sizes the 3D picture to the window: pixel for pixel, unless that would make its longest
## side more than LONGEST.
func _fit_picture() -> void:
	var size := get_window().size
	_shrink = maxi(ceili(maxf(size.x, size.y) / float(LONGEST)), 1)
	_view.size = Vector2i((Vector2(size) / _shrink).ceil()).max(Vector2i(2, 2))


## A point on the screen (in the HUD's coordinates) as a point in the 3D picture.
func _in_view(at: Vector2) -> Vector2:
	return at * Vector2(_view.size) / _container.size


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
	slot = clampi(to, 0, COVERED)
	hud.show_slot(tank, slot, COVERED + 1, slot != COVERED)
	if slot == COVERED and not Save.data.get("cave", {}).has("found"):
		Save.data["cave"] = {"found": true, "lifted": 0}
		hud.say("It was here when you came. There is a note pinned to the cloth.")
	if tank != null:
		tank.greet()


func _buy_tank(kind: String) -> void:
	if tank != null:
		return
	if not Tickets.spend(int(Kinds.of(kind).price), "tank:" + kind):
		Sfx.play("no")
		return
	Sfx.play("buy")
	add_tank(slot, {"kind": kind})
	note("home")
	look_at_slot(slot)
	hud.say("%s. %s" % [Kinds.of(kind).name, "Two guppies came with it." if kind == "fresh" else "See the shop for who can live in it."])
	save()


## The middle of the slot being looked at: of its tank, or of where one would stand.
func _slot_centre() -> Vector3:
	if tank != null:
		return tank.position + tank.centre()
	if slot == COVERED:
		return Vector3(0.0, Room.TOP + 0.55, -0.2)
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
	if following:
		# the card sits over the bottom of the screen, so the fish in hand is held above the middle
		want_focus.y -= want_away * 0.1
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
	var need_h := (size.x * 0.5 + 0.16) / (half * screen.x / maxf(screen.y, 1.0))
	var need_v := (size.y * 0.5 + 0.34) / half
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
				_pressed_when = Time.get_ticks_msec() * 0.001
				# (with the hand, a finger put on the glass stays there for the animals to come to)
				_on_glass = tool in ["hand", "torch", "mirror"] and tank != null and not _through_tank(event.position).is_empty()
				if _on_glass:
					_point(event.position)
			elif _pressed:
				_pressed = false
				if _on_glass:
					_on_glass = false
					tank.point_at(null)
					tank.shine(null)
					tank.hold_mirror(null)
				if _offering:
					_offering = false
					if tank != null:
						tank.offer(null)
				elif not _dragging:
					_tap(event.position)
	elif event is InputEventMouseMotion and _pressed:
		if not _dragging and event.position.distance_to(_press_at) > 10.0:
			_dragging = true
		if not _dragging or _touches.size() >= 2:
			return
		if _offering:
			var held := _through_tank(event.position)
			if not held.is_empty():
				tank.offer(held[0])
		elif _on_glass:
			_point(event.position)
		elif tool == "net" and tank != null and not _through_tank(event.position).is_empty():
			_net(event.position)
		elif tool == "scrub" and tank != null and not _through_tank(event.position).is_empty():
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
	var from := camera.project_ray_origin(_in_view(at)) - tank.position
	var dir := camera.project_ray_normal(_in_view(at))
	var box: AABB = tank.inside()
	var enter: Variant = box.intersects_ray(from, dir)
	var leave: Variant = box.intersects_ray(from + dir * 60.0, -dir)
	if enter == null or leave == null:
		return []
	return [enter, leave]


func _tap(at: Vector2) -> void:
	if slot == COVERED:
		_touch_cover()
		return
	if tank == null:
		return
	var from := camera.project_ray_origin(_in_view(at)) - tank.position
	var dir := camera.project_ray_normal(_in_view(at))
	var fish: Node = tank.pick_fish(from, dir)
	if fish != null and tool == "net" and not fish.dead and Species.habit(fish.species, "pest"):
		tank.remove_fish(fish)
		hud.say("One snail the fewer. There are never none.")
		Sfx.play("plop", 1.5)
		return
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
		if tank.swarm != null:
			hud.say(tank.swarm.mood() if tank.swarm.food < 1.0 else "That is plenty. More will foul the water.")
		elif not tank.anyone_hungry():
			hud.say("Nobody is hungry. Food left on the bottom rots.")
		tank.drop_food(mid.x, mid.z)
		Sfx.play("plop", randf_range(0.9, 1.3))
	elif tool == "scrub":
		tank.tap(through[0])
		Sfx.play("tap")
	elif tool == "net":
		_net(at)


## Draws the net through the water under a point on the screen: leftover food comes out, and
## whoever is near gets out of its way. Returns how many pieces it took.
func _net(at: Vector2) -> int:
	var from := camera.project_ray_origin(_in_view(at)) - tank.position
	var dir := camera.project_ray_normal(_in_view(at))
	var took: int = tank.scoop(from, dir)
	if took > 0:
		Sfx.play("plop", randf_range(1.3, 1.6), -6.0)
		tank.notice("netted leftovers", null)
	return took


## Takes up a tool. Taking up the torch when it is already in hand changes it from red to
## white and back.
func _pick_tool(picked: String) -> void:
	if picked == "torch" and tool == "torch":
		torch_red = not torch_red
	tool = picked
	if picked == "mirror":
		hud.say("Hold it to the glass, with the lamp on. You see the back of it: they see a stranger.")
	elif picked == "net":
		hud.say("Draw it through food left on the bottom, or tap a snail you did not ask for.")
	hud.show_torch(torch_red, tool == "torch")


## Puts the keeper's finger on the glass where the screen was touched, and tells the tank how
## fast it is moving (metres a second): slow draws the animals, fast startles them.
func _point(at: Vector2) -> void:
	var through := _through_tank(at)
	if through.is_empty() or tank == null:
		return
	var now := Time.get_ticks_msec() * 0.001
	var speed := 0.0
	if tank.finger != null and now > _pointed_at:
		speed = (through[0] - (tank.finger as Vector3)).length() / maxf(now - _pointed_at, 0.01)
	_pointed_at = now
	if tool == "torch":
		tank.shine(through[0], torch_red)
	elif tool == "mirror":
		tank.hold_mirror(through[0])
	else:
		tank.point_at(through[0], speed)


## A page of the last keeper's notebook turns up (if it has not already).
func note(id: String) -> void:
	if Notes.find(id):
		hud.say("A page of the notebook: %s. It is in the BOOK." % Notes.PAGES[id][0])
		Sfx.play("egg", 0.7)
		save.call_deferred()


## Turns up the pages that go with what has happened on the shelf lately.
func _look_for_pages() -> void:
	note("first")
	if not _any_lamp():
		note("dark")
	for t in tanks:
		if t == null:
			continue
		if t.seen.has("ate from the hand"):
			note("hand")
		if t.seen.has("made friends"):
			note("friends")
		if t.seen.has("flared at the mirror") or t.seen.has("looked in the mirror"):
			note("mirror")
		if t.seen.has("watched at night"):
			note("night")
		if t.torch != null and t.torch_red:
			note("red")
		if t.swarm != null and t.swarm.count() >= 1.0:
			note("dust")
		if t.fish.any(func(f: Node) -> bool: return f.species == "pest_snail"):
			note("pests")
		if t.about().get("humid", false) and t.humidity < 0.45:
			note("damp")


## Whether any tank on the shelf has its lamp on.
func _any_lamp() -> bool:
	for t in tanks:
		if t != null and t.lamp_on:
			return true
	return false


## The covered tank has been touched. The cloth only comes off with every lamp out.
func _touch_cover() -> void:
	if room.is_uncovered():
		room.uncover(false)
		return
	if _any_lamp():
		note("cloth")
		hud.say("The note says: NOT IN THE LIGHT. It is not your writing.")
		Sfx.play("no")
		return
	room.uncover(true)
	note("lifted")
	var cave: Dictionary = Save.data.get("cave", {})
	cave["lifted"] = int(cave.get("lifted", 0)) + 1
	Save.data["cave"] = cave
	hud.say("Cold water, and one rock." if int(cave.lifted) < 3 else "Cold water, and one rock. The rock is not where it was.")


## Takes a fish in hand (null lets go). The camera follows the fish in hand, and comes in
## close to it the first time; letting go takes it back to where it was.
func _select(fish: Node) -> void:
	if fish != null:
		if selected == null:
			_zoom_before = _zoom
		_zoom = minf(maxf(FOLLOW_FROM, fish.reach() * 4.5) / _fit(), 1.0)
	elif fish == null and selected != null:
		_zoom = _zoom_before
		_pitch = maxf(_pitch, 0.0)
	if selected != null and is_instance_valid(selected):
		selected.mark(false)
	selected = fish
	if fish != null:
		fish.mark(true)
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


## The homes on the other shelves that an animal could be moved to: ones its kind can live in,
## with room for it. Each as [slot, name].
func _other_homes(fish: Node) -> Array:
	var places: Array = []
	for i in tanks.size():
		var t := tanks[i]
		if t != null and t != tank and Species.lives_in(fish.species, t.kind) and t.has_room_for(fish.species):
			places.append([i, "%s, shelf %d" % [t.about().name, i + 1]])
	return places


## Nets an animal out of the home being looked at and puts it in the one on another shelf. It
## keeps its name, its temper and its bond with the keeper, and loses its ties: the ones it
## knew are not there.
func _move(fish: Node, to_slot: int) -> void:
	if not is_instance_valid(fish) or tank == null or tanks[to_slot] == null:
		return
	var data: Dictionary = fish.to_data()
	data.buddy["ties"] = {}
	data.buddy["id"] = 0
	var moments: Array = data.buddy.get("moments", [])
	moments.append("Moved to the %s" % tanks[to_slot].about().name)
	data.buddy["moments"] = moments
	tank.remove_fish(fish)
	tanks[to_slot].adopt(data)
	_select(null)
	hud.say("%s is in the %s now." % [data.name, tanks[to_slot].about().name])
	Sfx.play("plop")
	save()


func _give_away(fish: Node) -> void:
	if is_instance_valid(fish) and tank != null:
		hud.say("%s has gone to a good home." % fish.fish_name)
		tank.remove_fish(fish)
	_select(null)


func _on_discovered(species: String) -> void:
	hud.say("New in the book: %s." % Species.LIST[species].name)
	Sfx.play("new")
	# the arcade's leaderboard counts kinds of animal kept
	Tickets.post({"type": "PLAYER_DIED", "score": dex.size()})
	save.call_deferred()
