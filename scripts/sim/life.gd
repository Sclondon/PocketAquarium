extends RefCounted
## One animal's life, as numbers: how hungry and how well it is, how grown, and whether it is
## still alive. It knows nothing of nodes or pictures (fish.gd is the animal you see, and keeps
## one of these), so the tests can run years of it in a moment.
##
## It lives in real time: it wants feeding about once a day, can go a few days without, and
## takes a week to grow up. An animal that is starving, short of oxygen or in foul water loses
## health, and one that runs out dies.

const DAY := 86400.0
## Seconds from a full stomach to starving, and from hatching to full-grown (when fed).
const HUNGER_TIME := 3.0 * DAY
const GROW_TIME := 7.0 * DAY
## How hungry it has to be to eat (it gets there about half a day after a full meal), how
## hungry it is a day after one, and how much one flake fills it.
const PECKISH := 0.2
const HUNGRY := 0.33
const FLAKE := 0.34
## Above this hunger, below this oxygen or above this waste, it is being harmed.
const STARVING := 0.92
const LOW_OXYGEN := 0.3
const FOUL := 0.75
## How long each of those takes to kill a healthy animal (for oxygen and waste, at their very
## worst: just past the line they do far less harm), and how long a sick one takes to mend.
const STARVE_TIME := 3.0 * DAY
const CHOKE_TIME := 4.0 * 3600.0
const FOUL_TIME := 2.0 * DAY
const HEAL_TIME := DAY
## How long a home that is quite wrong for it (too dry, too cold, the wrong salt) takes to kill
## it: far longer than foul water, so there are days of warning.
const WRONG_HOME_TIME := 8.0 * DAY

## 0 newly hatched to 1 full-grown
var growth := 1.0
var hunger := 0.3
var health := 1.0
var dead := false
## Seconds until it can breed again
var breed_wait := 2.0 * DAY


## Its hunger, growth and health over `dt` seconds (which may be many) in water with this much
## oxygen and waste, in a home that is this far (0 to 1) from what it wants. Returns true if it
## died in that time.
func live(dt: float, o2: float, waste: float, discomfort := 0.0) -> bool:
	if dead:
		return false
	hunger = minf(hunger + dt / HUNGER_TIME, 1.0)
	breed_wait = maxf(breed_wait - dt, 0.0)
	if growth < 1.0 and hunger < 0.7:
		growth = minf(growth + dt / GROW_TIME, 1.0)
	var harm := 0.0
	if hunger > STARVING:
		harm += dt / STARVE_TIME
	if o2 < LOW_OXYGEN:
		harm += dt / CHOKE_TIME * maxf(1.0 - o2 / LOW_OXYGEN, 0.1)
	if waste > FOUL:
		harm += dt / FOUL_TIME * maxf((waste - FOUL) / (1.0 - FOUL), 0.1)
	if discomfort > 0.2:
		harm += dt / WRONG_HOME_TIME * discomfort
	if harm > 0.0:
		health -= harm
	else:
		health = minf(health + dt / HEAL_TIME, 1.0)
	if health <= 0.0:
		dead = true
		health = 0.0
	return dead


## Eats one flake.
func eat() -> void:
	hunger = maxf(hunger - FLAKE, 0.0)


## How hungry it is, in a word.
func appetite() -> String:
	if hunger > STARVING:
		return "starving"
	return "hungry" if hunger > HUNGRY else ("peckish" if hunger > PECKISH else "full")
