extends RefCounted
## What makes one animal itself and not just one of its kind: its temper, how well it knows
## the keeper (its bond), and how it stands with each of the others it lives with (its ties).
## It knows nothing of nodes or pictures: fish.gd is the animal you see, and acts on what this
## says.
##
## The bond is never shown as a number. It shows in what the animal does when the keeper is
## there (see `stage`): one that is new keeps its distance, one that is close comes to the
## glass. It grows with visits, with being fed and with time spent at the keeper's finger, and
## cools when the keeper stays away.

## Bold comes forward and is hard to scare. Shy hides, and warms slowly. Greedy is won over by
## food. Curious goes to look at anything new, the keeper's finger most of all. Grumpy keeps a
## patch of the tank to itself. Dozy sleeps early and wakes late.
const TEMPERS := ["bold", "shy", "greedy", "curious", "grumpy", "dozy"]
## How fast each temper's bond grows, beside a plain animal's.
const WARMTH := {"bold": 1.3, "shy": 0.6, "greedy": 1.0, "curious": 1.2, "grumpy": 0.7, "dozy": 0.9}
## The bond at which it is settled, friendly and close.
const SETTLED := 0.15
const FRIENDLY := 0.4
const CLOSE := 0.75
## What the bond gains from a visit (once a day), a meal with the keeper there, and each second
## at the keeper's finger; what it loses for each day the keeper is away past the first two;
## and the most a single visit's attention can add.
const VISIT := 0.04
const MEAL := 0.03
const FINGER := 0.006
const AWAY := 0.02
const MOST_A_VISIT := 0.12
## A tie past this either way makes two animals friends, or rivals.
const TIE := 0.5
const MOMENTS := 8

## Which animal of its tank it is (the others' ties are kept by this).
var id := 0
var temper := "bold"
## 0 (does not know the keeper) to 1
var bond := 0.0
## The day (counted from 1970) the keeper last visited it.
var visited := 0
## When it came to the keeper (seconds from 1970; 0 if nobody knows).
var met := 0.0
## Whether it was hatched on the shelf (and so can be traded in), and, for a kind that is bred
## for its colour, how deep its colour is: 0 washed out to 1 as deep as they come.
var born_here := false
var grade := 0.35
## How it stands with each of the others, by their id: -1 (rivals) to 1 (friends).
var ties := {}
## Where in the tank it likes to be: each number 0 to 1, across, up and back.
var spot := Vector3(0.5, 0.5, 0.5)
## The last few things that happened to it, newest last, for its page.
var moments: Array[String] = []

var _this_visit := 0.0


## A new animal's temper and favourite place, by chance.
func roll(rng: RandomNumberGenerator) -> void:
	temper = TEMPERS[rng.randi() % TEMPERS.size()]
	spot = Vector3(rng.randf(), rng.randf_range(0.1, 0.8), rng.randf())


## What a colour of this depth is called in the trade.
func grade_name() -> String:
	var names := ["Wild brown", "Cherry", "Sakura", "Fire red", "Painted fire red"]
	return names[clampi(int(grade * names.size()), 0, names.size() - 1)]


## How well it knows the keeper, in a word: "new", "settled", "friendly" or "close".
func stage() -> String:
	if bond >= CLOSE:
		return "close"
	return "friendly" if bond >= FRIENDLY else ("settled" if bond >= SETTLED else "new")


## The same, as its page puts it.
func regard() -> String:
	return {"new": "Does not know you yet", "settled": "Used to you", "friendly": "Pleased to see you",
			"close": "Knows you well"}[stage()]


## The keeper has come to look at the tank, on this `day` (counted from 1970). The first visit
## of a day warms the bond; days missed before it cool it.
func visit(day: int) -> void:
	_this_visit = 0.0
	if visited > 0 and day - visited > 2:
		bond = maxf(bond - AWAY * (day - visited - 2), 0.0)
	if day != visited:
		bond = minf(bond + VISIT * WARMTH[temper], 1.0)
	visited = day


## It ate with the keeper there.
func fed() -> void:
	_attend(MEAL * (2.0 if temper == "greedy" else 1.0))


## It spent `seconds` at the keeper's finger.
func kept_company(seconds: float) -> void:
	_attend(FINGER * seconds)


func _attend(amount: float) -> void:
	amount = minf(amount * WARMTH[temper], MOST_A_VISIT - _this_visit)
	if amount > 0.0:
		_this_visit += amount
		bond = minf(bond + amount, 1.0)


## How it stands with another, -1 to 1.
func tie(other: int) -> float:
	return ties.get(other, 0.0)


## Something passed between it and another, for better (above 0) or worse.
func nudge(other: int, by: float) -> void:
	ties[other] = clampf(tie(other) + by, -1.0, 1.0)


func is_friend(other: int) -> bool:
	return tie(other) >= TIE


func is_rival(other: int) -> bool:
	return tie(other) <= -TIE


## Another animal has gone from the tank.
func forget(other: int) -> void:
	ties.erase(other)


## Puts something on its page (the same thing twice running is put there once).
func note(what: String) -> void:
	if not moments.is_empty() and moments[-1] == what:
		return
	moments.append(what)
	while moments.size() > MOMENTS:
		moments.remove_at(0)


func to_data() -> Dictionary:
	var kept := {}
	for other: int in ties:
		if absf(ties[other]) > 0.05:
			kept[str(other)] = snappedf(ties[other], 0.01)
	return {"id": id, "temper": temper, "bond": bond, "visited": visited, "met": met, "born": born_here, "grade": grade, "ties": kept,
			"spot": [spot.x, spot.y, spot.z], "moments": moments}


## Takes up what `to_data` gave. An animal from before there were buddies has none of it: it
## gets a temper by chance, and is taken to be settled, having been kept a while.
func load_data(data: Dictionary, rng: RandomNumberGenerator) -> void:
	roll(rng)
	if data.is_empty():
		bond = SETTLED + 0.05
		return
	id = int(data.get("id", 0))
	if data.get("temper", "") in TEMPERS:
		temper = data.temper
	bond = clampf(data.get("bond", 0.0), 0.0, 1.0)
	visited = int(data.get("visited", 0))
	met = float(data.get("met", 0.0))
	born_here = bool(data.get("born", false))
	grade = clampf(data.get("grade", 0.35), 0.0, 1.0)
	ties.clear()
	var saved: Dictionary = data.get("ties", {})
	for other: String in saved:
		ties[int(other)] = clampf(float(saved[other]), -1.0, 1.0)
	var at: Array = data.get("spot", [])
	if at.size() == 3:
		spot = Vector3(at[0], at[1], at[2]).clamp(Vector3.ZERO, Vector3.ONE)
	moments.clear()
	for line: Variant in data.get("moments", []):
		moments.append(str(line))
