extends RefCounted
## A colony of animals too small and too many to know one by one: sea monkeys. It is kept as
## numbers (how many eggs, young and grown) and looked after as a whole. It knows nothing of
## nodes or pictures: tank.gd draws as many specks as this says there are.
##
## The eggs are dust until they are in salt water; then they hatch within a day or two. The
## young grow up in a few days if there is food in the water, and the grown ones lay eggs of
## their own, so a colony that is fed goes on for good. It is fed by the pinch: a little clouds
## the water and is eaten over a day or so; none and they starve; a lot fouls the water. Salt
## that has crept too far from where it should be kills them, slowly and then quickly.

const DAY := 86400.0
## The most the kit will hold.
const MOST := 240.0
## Days for a packet of eggs to hatch, for the young to grow up, and that a grown one lives.
const HATCHES := 1.2
const GROWS := 3.0
const LIVES := 30.0
## How much of a full feed a full colony eats in a day, and the eggs each grown one lays a day.
const APPETITE := 0.7
const LAYS := 0.25

var eggs := 120.0
var young := 0.0
var grown := 0.0
## How much food is in the water: 0 none, 1 as much as they could want, more than that fouling it.
var food := 0.0


func count() -> float:
	return young + grown


## Moves the colony on by `dt` seconds (which may be many). `salt_off` is how far the salt is
## from where it should be (0 right, 0.3 badly wrong). Returns the waste they made.
func step(dt: float, salt_off: float) -> float:
	var left := dt
	var waste := 0.0
	while left > 0.0:
		var d := minf(left, 1800.0) / DAY
		left -= 1800.0
		var hatching := eggs * minf(d / HATCHES, 1.0)
		eggs -= hatching
		young += hatching
		var fed := clampf(food * 4.0, 0.0, 1.0)
		var growing := young * minf(d / GROWS, 1.0) * fed
		young -= growing
		grown += growing
		# they eat, and what they do not eat sours
		food = maxf(food - count() / MOST * APPETITE * d - 0.12 * d, 0.0)
		if food > 1.0:
			waste += (food - 1.0) * 0.4 * d
		# hunger, salt and age
		var dying := d / LIVES + (1.0 - fed) * d * 0.12 + maxf(salt_off - 0.22, 0.0) * d * 3.0
		young -= young * minf(dying * 1.5, 1.0)
		grown -= grown * minf(dying, 1.0)
		# a grown one that is fed lays, till the kit is full
		eggs += grown * LAYS * d * fed * clampf(1.0 - (count() + eggs) / MOST, 0.0, 1.0)
	return waste


## A pinch of food.
func feed() -> void:
	food = minf(food + 0.4, 2.0)


## How they are, in a few words.
func mood() -> String:
	if count() < 1.0:
		return "Only dust yet. It wants a day or two." if eggs > 1.0 else "Nothing is left alive in it."
	if food < 0.05:
		return "They are hungry."
	return "A cloud of them, and growing." if young > grown else "Dancing toward the light."


func to_data() -> Dictionary:
	return {"eggs": eggs, "young": young, "grown": grown, "food": food}


func load_data(data: Dictionary) -> void:
	eggs = maxf(data.get("eggs", 120.0), 0.0)
	young = maxf(data.get("young", 0.0), 0.0)
	grown = maxf(data.get("grown", 0.0), 0.0)
	food = clampf(data.get("food", 0.0), 0.0, 2.0)
