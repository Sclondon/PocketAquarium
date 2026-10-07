extends RefCounted
## The water of one tank, as three numbers from 0 to 1, and how they move. It knows nothing of
## nodes or pictures, so the tests can run years of it in a moment.
##
## Oxygen comes in at the surface (faster with an air pump) and from plants in the light, and
## the fish breathe it. Waste comes from the fish, and from bodies left in; plants and the
## filter take it up. Algae grows on the glass in the light, faster in dirty water, and snails
## graze it. (Food left to rot, a change of water and a scrub of the glass are done to these
## numbers from outside: see tank.gd.)

const DAY := 86400.0

var o2 := 0.9
var waste := 0.05
var algae := 0.0


## Moves the water on by `dt` seconds, which may be many: each number heads for a resting
## level, so one long step is as good as many short ones. `crowd` is the room the living fish
## take up between them, `bodies` how many dead ones are still in the water.
func step(dt: float, crowd: float, bodies: int, plants: int, snails: int, lit: bool, pump: bool, filter: bool) -> void:
	var light := 1.0 if lit else 0.15
	var exchange := 0.05 * (2.5 if pump else 1.0) + plants * 0.012 * light
	var o2_rest := 1.0 - (crowd * 0.0045 + waste * 0.004) / exchange
	o2 = clampf(lerpf(o2_rest, o2, exp(-exchange * dt)), 0.0, 1.0)
	# a day's waste: 0.03 for each fish's worth of room, more for a body left in; a day's
	# cleaning takes this share of what is there
	var making := (crowd * 0.03 + bodies * 0.1) / DAY
	var cleaning := (0.05 + (0.4 if filter else 0.0) + plants * 0.05 * light) / DAY
	waste = clampf(lerpf(making / cleaning, waste, exp(-cleaning * dt)), 0.0, 1.0)
	algae = clampf(algae + dt / DAY * ((0.1 + 0.2 * waste) * light - snails * 0.06), 0.0, 1.0)
