extends RefCounted
## Every kind of home there is to put on the shelf: tanks of water, jars, and terrariums with
## no water in them at all. tank.gd is all of them; this says how each differs.
##
## For each: its `name`, a `blurb` for the catalogue and its `price` in tickets; how far up it
## the `water` comes (0.92 for a full tank, 0 for dry land, between for a paludarium, which
## also has a `bank` of land along one side); the `sizes` it comes in (the tanks' three, or a
## jar's one); the colour of its water and of what covers its floor (`sand`, and how `coarse`);
## its `look`, the tones of its light (see water_common.gdshaderinc) with the colour it spills
## into the room and the colour of the ink line; the `air` behind what is above the water; and
## what comes in it (`starter`, by species, and how many `plants`).
##
## What has to be kept right in it: `salt`, how salty its water should be (0 fresh, 0.5 the
## sea; it creeps up as water dries off, till the water is changed); `humid`, for one whose air
## dries out and has to be misted; `warm`, how warm it runs (0.5 is the room), and `heat_lamp`,
## how much warmer with its lamp on. `swarm` is the kind of tiny animal it keeps by the
## hundred, if it keeps one.

const TANKS := [
	{"name": "Pocket tank", "w": 2.2, "h": 1.5, "d": 1.2, "room": 5.0, "price": 0},
	{"name": "Desk tank", "w": 3.0, "h": 1.8, "d": 1.4, "room": 9.0, "price": 150},
	{"name": "Showpiece tank", "w": 4.0, "h": 2.1, "d": 1.7, "room": 15.0, "price": 400},
]
const JARS := [
	{"name": "Jar", "w": 1.3, "h": 1.35, "d": 1.1, "room": 4.0, "price": 0},
	{"name": "Big jar", "w": 1.9, "h": 1.5, "d": 1.3, "room": 7.0, "price": 80},
]

## The order they are offered in.
const ORDER := ["brine", "snail", "fresh", "shrimp", "hard", "stream", "vivarium", "arid", "cold", "palu", "sea"]

const LIST := {
	"fresh": {
		"name": "Blackwater tank", "price": 200, "water": 0.92, "sizes": TANKS,
		"blurb": "Warm, soft water the colour of tea. Home to most of the odd ones.",
		"water_colour": Color(0.72, 0.5, 0.24), "sand": Color(0.8, 0.62, 0.4), "coarse": 0.8, "air": Color(0.02, 0.025, 0.03),
		"look": {"key": Color(1.0, 0.9, 0.72), "shadow": Color(0.3, 0.2, 0.36), "haze": Color(0.2, 0.11, 0.05),
			"spill": Color(1.0, 0.8, 0.58), "ink": Color(0.05, 0.03, 0.08)},
		"warm": 0.65, "starter": ["guppy", "guppy"], "plants": 1,
	},
	"hard": {
		"name": "Hard water tank", "price": 220, "water": 0.92, "sizes": TANKS,
		"blurb": "Clear, bright water over pale stone, for fish from lakes and caves.",
		"water_colour": Color(0.55, 0.8, 0.85), "sand": Color(0.86, 0.83, 0.74), "coarse": 0.5, "air": Color(0.02, 0.025, 0.03),
		"look": {"key": Color(0.95, 0.97, 1.0), "shadow": Color(0.2, 0.25, 0.42), "haze": Color(0.1, 0.15, 0.2),
			"spill": Color(0.8, 0.9, 1.0), "ink": Color(0.04, 0.05, 0.1)},
		"warm": 0.6, "starter": [], "plants": 1,
	},
	"stream": {
		"name": "Stream tank", "price": 260, "water": 0.92, "sizes": TANKS,
		"blurb": "Cool, fast and full of air. Nothing in it needs a heater.",
		"water_colour": Color(0.3, 0.75, 0.7), "sand": Color(0.6, 0.62, 0.6), "coarse": 1.0, "air": Color(0.02, 0.025, 0.03),
		"look": {"key": Color(0.75, 0.95, 0.9), "shadow": Color(0.1, 0.25, 0.3), "haze": Color(0.03, 0.12, 0.12),
			"spill": Color(0.5, 0.9, 0.8), "ink": Color(0.02, 0.06, 0.08)},
		"warm": 0.4, "starter": [], "plants": 1, "gear": ["pump"],
	},
	"cold": {
		"name": "Cold tank", "price": 300, "water": 0.92, "sizes": TANKS,
		"blurb": "Still and chilled, with a chiller humming behind it.",
		"water_colour": Color(0.5, 0.62, 0.75), "sand": Color(0.5, 0.5, 0.52), "coarse": 0.3, "air": Color(0.02, 0.025, 0.03),
		"look": {"key": Color(0.8, 0.88, 1.0), "shadow": Color(0.18, 0.2, 0.32), "haze": Color(0.06, 0.08, 0.13),
			"spill": Color(0.6, 0.72, 1.0), "ink": Color(0.04, 0.05, 0.1)},
		"warm": 0.2, "starter": [], "plants": 1,
	},
	"sea": {
		"name": "Night sea tank", "price": 500, "water": 0.92, "sizes": TANKS,
		"blurb": "Salt water in the dark, and the things in it that make their own light.",
		"water_colour": Color(0.1, 0.3, 0.9), "sand": Color(0.93, 0.89, 0.78), "coarse": 0.1, "air": Color(0.01, 0.015, 0.03),
		"look": {"key": Color(0.7, 0.86, 1.0), "shadow": Color(0.12, 0.14, 0.42), "haze": Color(0.02, 0.05, 0.2),
			"spill": Color(0.4, 0.55, 1.0), "ink": Color(0.3, 0.42, 0.8)},
		"warm": 0.6, "salt": 0.5, "starter": [], "plants": 4,
	},
	"brine": {
		"name": "Brine kit", "price": 30, "water": 0.9, "sizes": JARS,
		"blurb": "A plastic tank, a packet of dust and a promise. Add salt water and wait.",
		"water_colour": Color(0.55, 0.85, 0.9), "sand": Color(0.95, 0.6, 0.75), "coarse": 0.0, "air": Color(0.03, 0.03, 0.05),
		"look": {"key": Color(0.8, 1.0, 1.0), "shadow": Color(0.25, 0.3, 0.45), "haze": Color(0.12, 0.2, 0.25),
			"spill": Color(0.6, 0.95, 1.0), "ink": Color(0.05, 0.06, 0.12)},
		"warm": 0.55, "salt": 0.5, "starter": [], "plants": 0, "swarm": "sea_monkey",
	},
	"snail": {
		"name": "Snail jar", "price": 60, "water": 0.9, "sizes": JARS,
		"blurb": "A jar of green water and slow company.",
		"water_colour": Color(0.5, 0.7, 0.35), "sand": Color(0.45, 0.42, 0.3), "coarse": 0.6, "air": Color(0.02, 0.03, 0.02),
		"look": {"key": Color(0.9, 1.0, 0.75), "shadow": Color(0.12, 0.25, 0.2), "haze": Color(0.08, 0.14, 0.06),
			"spill": Color(0.7, 0.95, 0.5), "ink": Color(0.03, 0.06, 0.04)},
		"warm": 0.6, "starter": [], "plants": 2,
	},
	"shrimp": {
		"name": "Shrimp jar", "price": 90, "water": 0.9, "sizes": JARS,
		"blurb": "Planted thick, with no pump and no filter: the plants do the work.",
		"water_colour": Color(0.4, 0.75, 0.45), "sand": Color(0.2, 0.18, 0.16), "coarse": 0.3, "air": Color(0.02, 0.03, 0.02),
		"look": {"key": Color(0.85, 1.0, 0.8), "shadow": Color(0.1, 0.26, 0.22), "haze": Color(0.04, 0.14, 0.08),
			"spill": Color(0.55, 0.95, 0.55), "ink": Color(0.03, 0.06, 0.04)},
		"warm": 0.6, "starter": [], "plants": 4,
	},
	"vivarium": {
		"name": "Rainforest vivarium", "price": 300, "water": 0.0, "sizes": TANKS,
		"blurb": "Wet leaves behind glass. Mist it, or it dries out.",
		"water_colour": Color(0.4, 0.7, 0.45), "sand": Color(0.5, 0.38, 0.24), "coarse": 0.4, "air": Color(0.06, 0.2, 0.1),
		"look": {"key": Color(0.75, 1.0, 0.7), "shadow": Color(0.05, 0.2, 0.14), "haze": Color(0.02, 0.09, 0.05),
			"spill": Color(0.5, 1.0, 0.6), "ink": Color(0.02, 0.05, 0.03)},
		"warm": 0.65, "humid": true, "starter": [], "plants": 7,
	},
	"arid": {
		"name": "Arid terrarium", "price": 300, "water": 0.0, "sizes": TANKS,
		"blurb": "Sand, stone and a heat lamp. One end hot, the other cool.",
		"water_colour": Color(0.9, 0.7, 0.5), "sand": Color(0.9, 0.72, 0.5), "coarse": 0.1, "air": Color(0.1, 0.035, 0.03),
		"look": {"key": Color(1.0, 0.66, 0.42), "shadow": Color(0.36, 0.1, 0.16), "haze": Color(0.14, 0.05, 0.04),
			"spill": Color(1.0, 0.45, 0.25), "ink": Color(0.07, 0.02, 0.03)},
		"warm": 0.6, "heat_lamp": 0.25, "starter": [], "plants": 0,
	},
	"palu": {
		"name": "Paludarium", "price": 350, "water": 0.38, "bank": true, "sizes": TANKS,
		"blurb": "Half water, half mud, and a little salt: the edge of a mangrove at dusk.",
		"water_colour": Color(0.55, 0.45, 0.35), "sand": Color(0.42, 0.33, 0.27), "coarse": 0.2, "air": Color(0.09, 0.05, 0.07),
		"look": {"key": Color(1.0, 0.74, 0.7), "shadow": Color(0.25, 0.14, 0.24), "haze": Color(0.1, 0.06, 0.08),
			"spill": Color(1.0, 0.6, 0.6), "ink": Color(0.06, 0.03, 0.05)},
		"warm": 0.7, "salt": 0.25, "humid": true, "starter": [], "plants": 2,
	},
}


static func of(kind: String) -> Dictionary:
	return LIST[kind]


## Whether it has any water in it.
static func is_wet(kind: String) -> bool:
	return float(LIST[kind].water) > 0.0
