extends RefCounted
## Every kind of animal there is to keep. Of the fresh water fish, the first seven are sold in
## the shop; the rest can only be bred, by keeping the right two kinds together (CROSSES), and
## one turns up by luck. The sea life (`water` of "sea") is all sold, and lives only in a magic
## salt water tank, which holds a whale as easily as a guppy: each is as big as its `size`
## says beside the others, not as big as it would be in the sea.
##
## For each: its name, a line about it, its price in tickets (0: not for sale), how big it is
## beside the others, how much room it takes in the tank (`load`), how fast it swims, and its
## `look`, which is what fish_mesh.gd builds it from.

## The order they are listed in, in the shop and the fish-dex.
const ORDER := ["guppy", "tetra", "goldfish", "angelfish", "betta", "clownfish", "puffer",
		"glow_guppy", "sunset_fantail", "electric_angel", "royal_veiltail", "midnight_betta",
		"harlequin", "tangerine", "bumblepuff", "aurora_koi", "ghost_angel", "moonfish",
		"jellyfish", "salmon", "tuna", "shark", "orca", "giant_squid", "blue_whale"]

const LIST := {
	"guppy": {
		"name": "Guppy", "blurb": "Small, cheerful and hard to upset. A good first fish.",
		"price": 10, "size": 0.7, "load": 0.5, "speed": 1.1,
		"look": {"back": Color(0.45, 0.55, 0.5), "side": Color(0.75, 0.8, 0.7), "belly": Color(0.92, 0.92, 0.85),
			"fin": Color(0.95, 0.5, 0.2), "tip": Color(1.0, 0.85, 0.3), "tall": 0.8, "tail_len": 0.75, "spread": 1.0, "fork": 0.0,
			"dorsal": 0.22, "spots": 0.3},
	},
	"tetra": {
		"name": "Neon Tetra", "blurb": "A sliver of a fish with a stripe that glows.",
		"price": 25, "size": 0.55, "load": 0.4, "speed": 1.4,
		"look": {"back": Color(0.25, 0.3, 0.3), "side": Color(0.2, 0.75, 1.0), "belly": Color(0.9, 0.25, 0.2),
			"fin": Color(0.8, 0.85, 0.85), "tall": 0.7, "wide": 0.8, "glow": 0.6, "tail_len": 0.45, "fork": 0.5, "dorsal": 0.18},
	},
	"goldfish": {
		"name": "Goldfish", "blurb": "Round, greedy and always pleased to see you.",
		"price": 40, "size": 1.0, "load": 1.0, "speed": 0.8,
		"look": {"back": Color(0.95, 0.45, 0.1), "side": Color(1.0, 0.6, 0.15), "belly": Color(1.0, 0.82, 0.5),
			"fin": Color(1.0, 0.55, 0.15), "tip": Color(1.0, 0.9, 0.6), "tall": 1.15, "wide": 1.25, "len": 0.85, "tail_len": 0.7, "spread": 0.95, "fork": 0.45, "dorsal": 0.3},
	},
	"angelfish": {
		"name": "Angelfish", "blurb": "Tall and stately, and it knows it.",
		"price": 80, "size": 1.05, "load": 1.2, "speed": 0.7,
		"look": {"back": Color(0.75, 0.75, 0.7), "side": Color(0.92, 0.92, 0.86), "belly": Color(0.98, 0.98, 0.94),
			"fin": Color(0.85, 0.85, 0.75), "bar": Color(0.12, 0.12, 0.14), "bars": [1, 3, 5],
			"tall": 1.5, "wide": 0.6, "len": 0.75, "tail_len": 0.55, "fork": 0.3, "dorsal": 0.9, "anal": 0.9, "sweep": 0.45},
	},
	"betta": {
		"name": "Betta", "blurb": "All fins and attitude.",
		"price": 120, "size": 0.9, "load": 0.8, "speed": 0.75,
		"look": {"back": Color(0.45, 0.05, 0.12), "side": Color(0.8, 0.1, 0.2), "belly": Color(0.9, 0.3, 0.35),
			"fin": Color(0.35, 0.15, 0.7), "tip": Color(0.3, 0.75, 0.95), "tall": 0.85, "tail_len": 1.15, "spread": 1.25, "fork": 0.0,
			"droop": 0.3, "dorsal": 0.5, "anal": 0.55, "sweep": 0.3},
	},
	"clownfish": {
		"name": "Clownfish", "blurb": "Bold bars on bright orange. Likes to stay near home.",
		"price": 150, "size": 0.8, "load": 0.8, "speed": 1.0,
		"look": {"back": Color(0.95, 0.4, 0.05), "side": Color(1.0, 0.5, 0.1), "belly": Color(1.0, 0.6, 0.2),
			"fin": Color(0.95, 0.45, 0.1), "tip": Color(0.08, 0.07, 0.07), "bar": Color(0.97, 0.97, 0.95), "bars": [2, 4, 6],
			"tall": 0.95, "tail_len": 0.5, "spread": 0.9, "fork": 0.1, "dorsal": 0.25},
	},
	"puffer": {
		"name": "Pufferfish", "blurb": "A ball with a face. Takes up a lot of room.",
		"price": 200, "size": 0.95, "load": 1.3, "speed": 0.55,
		"look": {"back": Color(0.6, 0.55, 0.2), "side": Color(0.85, 0.8, 0.35), "belly": Color(0.98, 0.96, 0.85),
			"fin": Color(0.9, 0.8, 0.4), "tall": 1.2, "wide": 1.7, "len": 0.7, "tail_len": 0.35, "spread": 0.7, "fork": 0.0,
			"dorsal": 0.12, "eye": 1.7, "spots": 0.8, "spot": Color(0.3, 0.25, 0.08)},
	},
	"glow_guppy": {
		"name": "Glow Guppy", "blurb": "A guppy that took the tetra's stripe and ran with it.",
		"price": 0, "size": 0.7, "load": 0.5, "speed": 1.2,
		"look": {"back": Color(0.2, 0.4, 0.45), "side": Color(0.3, 1.0, 0.85), "belly": Color(0.85, 0.95, 0.9),
			"fin": Color(1.0, 0.35, 0.6), "tall": 0.8, "glow": 0.6, "tail_len": 0.85, "spread": 1.05, "fork": 0.0, "dorsal": 0.25},
	},
	"sunset_fantail": {
		"name": "Sunset Fantail", "blurb": "Goldfish gold fading into a guppy's evening colours.",
		"price": 0, "size": 0.9, "load": 0.8, "speed": 0.9,
		"look": {"back": Color(0.85, 0.3, 0.35), "side": Color(1.0, 0.6, 0.3), "belly": Color(1.0, 0.85, 0.55),
			"fin": Color(0.75, 0.3, 0.75), "tall": 1.05, "wide": 1.15, "len": 0.9, "tail_len": 1.0, "spread": 1.2, "fork": 0.35, "dorsal": 0.35},
	},
	"electric_angel": {
		"name": "Electric Angel", "blurb": "An angelfish lit from the inside.",
		"price": 0, "size": 1.05, "load": 1.2, "speed": 0.8,
		"look": {"back": Color(0.1, 0.2, 0.45), "side": Color(0.2, 0.8, 1.0), "belly": Color(0.8, 0.95, 1.0),
			"fin": Color(0.4, 0.6, 1.0), "bar": Color(0.05, 0.08, 0.25), "bars": [1, 3, 5], "glow": 0.55,
			"tall": 1.5, "wide": 0.6, "len": 0.75, "tail_len": 0.55, "fork": 0.3, "dorsal": 0.9, "anal": 0.9, "sweep": 0.45},
	},
	"royal_veiltail": {
		"name": "Royal Veiltail", "blurb": "A goldfish in a betta's robes.",
		"price": 0, "size": 1.0, "load": 1.0, "speed": 0.7,
		"look": {"back": Color(0.5, 0.2, 0.6), "side": Color(1.0, 0.75, 0.2), "belly": Color(1.0, 0.9, 0.6),
			"fin": Color(0.55, 0.2, 0.75), "tall": 1.1, "wide": 1.2, "len": 0.85, "tail_len": 1.3, "spread": 1.3, "fork": 0.2,
			"droop": 0.3, "dorsal": 0.55, "anal": 0.5, "sweep": 0.3},
	},
	"midnight_betta": {
		"name": "Midnight Betta", "blurb": "Dark as the deep end, with one bright line.",
		"price": 0, "size": 0.9, "load": 0.8, "speed": 0.85,
		"look": {"back": Color(0.05, 0.05, 0.15), "side": Color(0.3, 0.5, 1.0), "belly": Color(0.1, 0.1, 0.3),
			"fin": Color(0.12, 0.1, 0.4), "glow": 0.6, "tall": 0.85, "tail_len": 1.15, "spread": 1.25, "fork": 0.0, "droop": 0.3,
			"dorsal": 0.5, "anal": 0.55, "sweep": 0.3},
	},
	"harlequin": {
		"name": "Harlequin", "blurb": "Angelfish height, clownfish costume.",
		"price": 0, "size": 1.0, "load": 1.1, "speed": 0.85,
		"look": {"back": Color(0.9, 0.3, 0.1), "side": Color(1.0, 0.5, 0.15), "belly": Color(1.0, 0.7, 0.3),
			"fin": Color(0.1, 0.1, 0.12), "bar": Color(0.97, 0.97, 0.95), "bars": [1, 3, 5],
			"tall": 1.4, "wide": 0.7, "len": 0.8, "tail_len": 0.55, "fork": 0.2, "dorsal": 0.75, "anal": 0.7, "sweep": 0.35},
	},
	"tangerine": {
		"name": "Tangerine", "blurb": "Round, orange and very nearly glowing.",
		"price": 0, "size": 0.9, "load": 0.9, "speed": 0.9,
		"look": {"back": Color(1.0, 0.45, 0.0), "side": Color(1.0, 0.65, 0.05), "belly": Color(1.0, 0.85, 0.3),
			"fin": Color(0.98, 0.95, 0.9), "glow": 0.25, "tall": 1.1, "wide": 1.3, "len": 0.8, "tail_len": 0.6, "spread": 1.0, "fork": 0.3, "dorsal": 0.3},
	},
	"bumblepuff": {
		"name": "Bumblepuff", "blurb": "A pufferfish dressed as a bee.",
		"price": 0, "size": 0.95, "load": 1.3, "speed": 0.6,
		"look": {"back": Color(0.95, 0.75, 0.05), "side": Color(1.0, 0.85, 0.1), "belly": Color(1.0, 0.95, 0.7),
			"fin": Color(0.15, 0.12, 0.1), "bar": Color(0.1, 0.09, 0.08), "bars": [2, 4],
			"tall": 1.2, "wide": 1.7, "len": 0.7, "tail_len": 0.35, "spread": 0.7, "fork": 0.0, "dorsal": 0.12, "eye": 1.7},
	},
	"aurora_koi": {
		"name": "Aurora Koi", "blurb": "The northern lights, with fins.",
		"price": 0, "size": 1.15, "load": 1.2, "speed": 0.8,
		"look": {"back": Color(0.3, 0.9, 0.6), "side": Color(0.6, 0.4, 1.0), "belly": Color(0.95, 0.9, 1.0),
			"fin": Color(0.3, 1.0, 0.8), "bar": Color(1.0, 0.45, 0.75), "bars": [2, 5], "glow": 0.6,
			"tall": 1.0, "wide": 1.1, "tail_len": 1.2, "spread": 1.25, "fork": 0.3, "droop": 0.2, "dorsal": 0.5, "anal": 0.35, "sweep": 0.3},
	},
	"ghost_angel": {
		"name": "Ghost Angel", "blurb": "You can very nearly see through it.",
		"price": 0, "size": 1.1, "load": 1.2, "speed": 0.65,
		"look": {"back": Color(0.8, 0.9, 0.95), "side": Color(0.92, 0.98, 1.0), "belly": Color(1.0, 1.0, 1.0),
			"fin": Color(0.75, 0.9, 1.0), "bar": Color(0.6, 0.75, 0.9), "bars": [1, 3, 5], "glow": 0.5,
			"tall": 1.55, "wide": 0.55, "len": 0.75, "tail_len": 0.9, "spread": 1.0, "fork": 0.3, "droop": 0.25,
			"dorsal": 1.0, "anal": 1.0, "sweep": 0.55},
	},
	"moonfish": {
		"name": "Moonfish", "blurb": "Nobody breeds a moonfish. Now and then one just hatches.",
		"price": 0, "size": 1.0, "load": 1.0, "speed": 0.7,
		"look": {"back": Color(0.7, 0.75, 0.9), "side": Color(0.95, 0.95, 0.8), "belly": Color(1.0, 1.0, 0.9),
			"fin": Color(1.0, 0.9, 0.5), "glow": 0.7, "tall": 1.4, "wide": 0.9, "len": 0.7, "tail_len": 0.6, "spread": 1.1, "fork": 0.8,
			"dorsal": 0.4, "anal": 0.4, "eye": 1.4},
	},
	"jellyfish": {
		"name": "Moon Jelly", "water": "sea", "blurb": "Goes where the water goes, and seems content with that.",
		"price": 60, "size": 0.9, "load": 0.5, "speed": 0.25,
		"look": {"plan": "jelly", "back": Color(0.95, 0.6, 0.85), "side": Color(0.95, 0.6, 0.85), "belly": Color(1.0, 0.85, 0.95),
			"fin": Color(0.95, 0.7, 0.9), "tip": Color(0.75, 0.85, 1.0), "glow": 0.45},
	},
	"salmon": {
		"name": "Sockeye Salmon", "water": "sea", "blurb": "Silver at sea, and always thinking about a river.",
		"price": 120, "size": 1.3, "load": 1.0, "speed": 1.25,
		"look": {"back": Color(0.12, 0.3, 0.42), "side": Color(0.78, 0.84, 0.9), "belly": Color(0.97, 0.98, 0.99),
			"fin": Color(0.35, 0.45, 0.55), "tip": Color(0.6, 0.7, 0.78), "tall": 0.82, "wide": 0.9, "len": 1.1,
			"tail_len": 0.55, "spread": 0.9, "fork": 0.55, "dorsal": 0.28, "anal": 0.2, "spots": 0.6},
	},
	"tuna": {
		"name": "Bluefin Tuna", "water": "sea", "blurb": "A torpedo with somewhere to be.",
		"price": 200, "size": 1.7, "load": 1.5, "speed": 1.6,
		"look": {"back": Color(0.06, 0.13, 0.35), "side": Color(0.62, 0.72, 0.82), "belly": Color(0.95, 0.96, 0.98),
			"fin": Color(0.12, 0.18, 0.4), "tip": Color(1.0, 0.85, 0.2), "tall": 1.0, "wide": 1.15,
			"tail_len": 0.75, "spread": 1.25, "fork": 1.0, "dorsal": 0.4, "anal": 0.3, "sweep": 0.3, "pec": 0.45, "finlets": 5},
	},
	"shark": {
		"name": "Reef Shark", "water": "sea", "blurb": "Never stops swimming. Never blinks, either.",
		"price": 350, "size": 2.2, "load": 2.5, "speed": 1.1,
		"look": {"back": Color(0.36, 0.42, 0.48), "side": Color(0.55, 0.6, 0.66), "belly": Color(0.96, 0.96, 0.95),
			"fin": Color(0.33, 0.38, 0.44), "tip": Color(0.08, 0.09, 0.11), "head": Color(0.4, 0.46, 0.52),
			"tall": 0.72, "wide": 1.0, "len": 1.15, "tail_len": 0.85, "spread": 1.05, "fork": 0.9, "tilt": 0.4,
			"dorsal": 0.62, "anal": 0.14, "sweep": 0.4, "pec": 0.72, "eye": 0.6, "iris": Color(0.05, 0.05, 0.06), "gills": true},
	},
	"orca": {
		"name": "Orca", "water": "sea", "blurb": "Black, white and cleverer than the rest of the shelf.",
		"price": 500, "size": 2.6, "load": 3.0, "speed": 0.9,
		"look": {"back": Color(0.05, 0.05, 0.07), "side": Color(0.06, 0.06, 0.08), "belly": Color(0.97, 0.97, 0.96),
			"fin": Color(0.05, 0.05, 0.07), "tip": Color(0.12, 0.12, 0.15), "eye_patch": Color(0.97, 0.97, 0.96),
			"flukes": true, "tall": 0.95, "wide": 1.15, "len": 1.05, "tail_len": 0.6, "spread": 1.2, "fork": 0.55,
			"dorsal": 0.8, "anal": 0.0, "sweep": 0.12, "pec": 0.6, "eye": 0.5, "iris": Color(0.1, 0.1, 0.12)},
	},
	"giant_squid": {
		"name": "Giant Squid", "water": "sea", "blurb": "From very far down. It has not said why it came up.",
		"price": 600, "size": 2.6, "load": 3.0, "speed": 0.7,
		"look": {"plan": "squid", "back": Color(0.72, 0.16, 0.14), "side": Color(0.8, 0.25, 0.2), "belly": Color(0.95, 0.7, 0.6),
			"fin": Color(0.72, 0.16, 0.14), "tip": Color(0.98, 0.6, 0.5), "eye": 1.2, "iris": Color(0.98, 0.9, 0.6), "spots": 0.5,
			"spot": Color(0.4, 0.05, 0.08)},
	},
	"blue_whale": {
		"name": "Blue Whale", "water": "sea", "blurb": "The biggest animal there has ever been, give or take a shelf.",
		"price": 800, "size": 3.2, "load": 4.0, "speed": 0.5,
		"look": {"back": Color(0.22, 0.38, 0.55), "side": Color(0.34, 0.5, 0.66), "belly": Color(0.78, 0.85, 0.9),
			"fin": Color(0.22, 0.36, 0.52), "tip": Color(0.3, 0.46, 0.62), "flukes": true, "tall": 0.72, "wide": 0.95, "len": 1.35,
			"tail_len": 0.6, "spread": 1.2, "fork": 0.5, "dorsal": 0.07, "anal": 0.0, "sweep": 0.5, "pec": 0.5, "eye": 0.35,
			"iris": Color(0.1, 0.12, 0.15), "spots": 0.45, "spot": Color(0.55, 0.68, 0.8)},
	},
}

## What two different kinds have when kept together (the two names in alphabetical order).
const CROSSES := {
	"guppy+tetra": "glow_guppy",
	"goldfish+guppy": "sunset_fantail",
	"angelfish+tetra": "electric_angel",
	"betta+goldfish": "royal_veiltail",
	"betta+tetra": "midnight_betta",
	"angelfish+clownfish": "harlequin",
	"clownfish+goldfish": "tangerine",
	"clownfish+puffer": "bumblepuff",
	"glow_guppy+royal_veiltail": "aurora_koi",
	"electric_angel+midnight_betta": "ghost_angel",
}

## The fish that hatches by luck from any egg, and how often.
const MUTANT := "moonfish"
const MUTANT_CHANCE := 0.04

const NAMES := ["Biscuit", "Pickle", "Noodle", "Bubbles", "Mango", "Pepper", "Waffle", "Dot", "Gus",
		"Olive", "Pip", "Turnip", "Sushi", "Moss", "Clementine", "Bean", "Figgy", "Juniper", "Tofu",
		"Marble", "Sprout", "Peaches", "Button", "Radish", "Nori", "Opal", "Crumb", "Plum"]


## Which water a kind lives in: "fresh" or "sea".
static func water(id: String) -> String:
	return LIST[id].get("water", "fresh")


## What hatches from an egg laid by these two kinds.
static func child_of(a: String, b: String, rng: RandomNumberGenerator) -> String:
	if rng.randf() < MUTANT_CHANCE:
		return MUTANT
	if a == b:
		return a
	var key := a + "+" + b if a < b else b + "+" + a
	if CROSSES.has(key):
		return CROSSES[key]
	return a if rng.randf() < 0.5 else b


## A line for the fish-dex about a kind nobody has seen yet.
static func hint(id: String) -> String:
	if int(LIST[id].price) > 0:
		return "Sold in the shop, for a salt water tank." if water(id) == "sea" else "Sold in the shop."
	for key: String in CROSSES:
		if CROSSES[key] == id:
			return "A %s might have one, with the right company." % LIST[key.get_slice("+", 0)].name
	return "Now and then an egg hatches into something else."
