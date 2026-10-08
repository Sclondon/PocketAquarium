extends RefCounted
## The notebook that was on the shelf when the keeper came: the last keeper's, in their words.
## Its pages are not read in order. Each turns up when the keeper does, or sees, the thing the
## page is about (main.gd says when), and they are kept in the save.

## Each page: what it is headed, and what it says. The order here is the order in the book.
const PAGES := {
	"first": ["To whoever has the shelf now",
			"The betta is Admiral and he will not thank you for anything. The loaches you will not see by day. Feed them all the same: they come up for it after dark.\n\nI have left you the notebook. I had not finished it."],
	"hand": ["Feeding by hand",
			"Hold the food still at the glass and wait. The first time, nobody comes. That is not the fish being stupid. That is the fish being right about strangers."],
	"friends": ["They choose",
			"I never could tell beforehand which two would take to each other. Same water, same food, and one pair is never apart and the next pair cannot share a tank's length. Do not move one of a pair if you can help it. The other looks for it."],
	"dark": ["Lamps out",
			"Half of what lives on this shelf you have not seen, because you have only looked with the lamp on. Turn it off and sit a while."],
	"red": ["The red torch",
			"They cannot see red. I do not know why that should feel like cheating, but it does. The white one is for finding what has got out, and for nothing else."],
	"night": ["What the loaches do",
			"Counted nine last night in a knot under the wood, all going round each other like something being stirred. By morning: sand, and nothing."],
	"home": ["A second tank",
			"New water is not safe water. It looks the same. Give it four days with a pinch of food in it before you put anyone in you would mind losing, and watch the filter gauge come up."],
	"dust": ["The kit",
			"A child's toy, and I kept it running three years. Salt creeps: top it up before the gauge falls. A pinch of food, not a spoon."],
	"damp": ["Glass that fogs",
			"The frogs do not drink. They sit in the wet. If the glass is dry when you come in, you are a day late already. Mist it, and they will tell you so: they sing."],
	"pests": ["Uninvited",
			"There are snails in the tank that I did not buy. They came in on a plant, as eggs. One is nothing. Forty is the week after. They do no harm, and they clean the glass; but if you want them gone, a pea puffer would thank you."],
	"cloth": ["The one on top",
			"Not in the light. I mean it. I put the cloth on for a reason and the reason has not changed."],
	"lifted": ["Under the cloth",
			"Cold water and a rock. I know. That is what I saw too, for a month. Keep the lamps out and keep coming back. It does not hurry. It has never had to."],
	"pale": ["Something pale",
			"Tonight. Behind the rock, and then not behind the rock. The length of my hand. No eyes that I could find. It knew I was there and it did not mind."],
	"olm": ["Its name",
			"Proteus. An olm. They live in caves under the mountains, in water that has never been lit, and they can go ten years without a meal and a hundred without dying. I did not buy it. It was on the shelf when I came, under the cloth, with a note.\n\nI have written you the same note."],
}


## Whether a page has turned up yet.
static func has(id: String) -> bool:
	return (Save.data.get("notes", {}) as Dictionary).has(id)


## A page turns up. True if it had not before (false if it had, or there is no such page).
static func find(id: String) -> bool:
	if not PAGES.has(id) or has(id):
		return false
	var found: Dictionary = Save.data.get("notes", {})
	found[id] = true
	Save.data["notes"] = found
	return true


static func count() -> int:
	return (Save.data.get("notes", {}) as Dictionary).size()
