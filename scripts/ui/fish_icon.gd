extends Control
## A small flat drawing of a kind of fish, from the same `look` its 3D model is built from.
## A kind nobody has seen yet is drawn as a dark shape with a question mark.

const Species := preload("res://scripts/tank/species.gd")
const UiKit := preload("res://scripts/ui/ui_kit.gd")

var species := "guppy"
var known := true


func _init(id := "guppy", is_known := true, min_size := Vector2(84, 54)) -> void:
	species = id
	known = is_known
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var look: Dictionary = Species.LIST[species].look
	var unit := minf(size.x / 3.1, size.y / 2.7)
	var mid := size * 0.5 + Vector2(-0.25 * unit, 0.0)
	var half_len := unit * 0.95 * float(look.get("len", 1.0))
	var half_tall := unit * 0.42 * float(look.get("tall", 1.0))
	var dark := Color(UiKit.INK, 0.85)
	var fin: Color = look.fin if known else dark
	var side: Color = look.side if known else dark
	var back: Color = look.back if known else dark
	var belly: Color = look.belly if known else dark

	# tail, then the fins, then the body over their roots (the fish faces left)
	var root := mid + Vector2(half_len * 0.85, 0.0)
	var reach := unit * float(look.get("tail_len", 0.6)) * 0.9
	var spread: float = look.get("spread", 0.85)
	var fork: float = look.get("fork", 0.5)
	var tail := PackedVector2Array([root])
	for i in 5:
		var u := i / 2.0 - 1.0
		var r := reach * (1.0 - fork * (1.0 - absf(u)) * 0.75)
		tail.append(root + Vector2(cos(u * spread) * r, sin(u * spread) * r + float(look.get("droop", 0.0)) * r))
	draw_colored_polygon(tail, fin)
	var sweep := half_len * float(look.get("sweep", 0.1))
	var dorsal := unit * float(look.get("dorsal", 0.3)) * 0.8
	draw_colored_polygon(PackedVector2Array([mid + Vector2(-half_len * 0.4, -half_tall * 0.8),
			mid + Vector2(sweep, -half_tall - dorsal), mid + Vector2(half_len * 0.4, -half_tall * 0.7)]), fin)
	var anal := unit * float(look.get("anal", 0.18)) * 0.8
	draw_colored_polygon(PackedVector2Array([mid + Vector2(0.0, half_tall * 0.8),
			mid + Vector2(half_len * 0.3 + sweep, half_tall + anal), mid + Vector2(half_len * 0.55, half_tall * 0.5)]), fin)

	var whole := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		whole.append(mid + Vector2(-cos(a) * half_len, -sin(a) * half_tall))
	draw_colored_polygon(whole, side)
	if known:
		# the back, as a cap over the top third, and the belly under
		var cap := PackedVector2Array()
		var under := PackedVector2Array()
		for i in 9:
			var a := lerpf(0.5, PI - 0.5, i / 8.0)
			cap.append(mid + Vector2(-cos(a) * half_len, -sin(a) * half_tall))
			under.append(mid + Vector2(-cos(a) * half_len, sin(a) * half_tall))
		draw_colored_polygon(cap, back)
		draw_colored_polygon(under, belly)
		var bar: Color = look.get("bar", back)
		for seg: int in look.get("bars", []):
			var x := lerpf(-0.75, 0.75, (seg - 0.5) / 6.0) * half_len
			var h := half_tall * sqrt(maxf(1.0 - pow(x / half_len, 2.0), 0.0))
			draw_rect(Rect2(mid + Vector2(x - half_len * 0.07, -h), Vector2(half_len * 0.14, h * 2.0)), bar)
		var eye := mid + Vector2(-half_len * 0.68, -half_tall * 0.15)
		draw_circle(eye, unit * 0.09, Color(0.97, 0.95, 0.85))
		draw_circle(eye, unit * 0.05, UiKit.INK)
	else:
		var f := UiKit.serif()
		draw_string(f, mid + Vector2(-6, 9), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiKit.PAPER)
