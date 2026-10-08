extends "res://scripts/ui/sheet.gd"
## The shop: everything that can be bought for the tank being looked at, for tickets. Four
## shelves: fish (the kinds that are sold for its water; the rest are bred), plants and small
## life, gear, and ornaments.

const Species := preload("res://scripts/tank/species.gd")
const Tank := preload("res://scripts/tank/tank.gd")
const FishIcon := preload("res://scripts/ui/fish_icon.gd")

const SHELVES := ["FISH", "LIFE", "GEAR", "DECOR"]

## Everything but the fish: shelf, id, name, a line about it, price.
const GOODS := [
	["LIFE", "plant", "Plant", "Makes oxygen in the light and takes up waste.", 20],
	["LIFE", "snail", "Snail", "Grazes the algae off the glass, slowly.", 30],
	["LIFE", "shrimp", "Shrimp", "Eats the food the fish miss, before it rots.", 30],
	["GEAR", "pump", "Air pump", "A stream of bubbles: far more oxygen.", 100],
	["GEAR", "filter", "Filter", "Hangs on the back and keeps taking waste out.", 150],
	["GEAR", "bigger", "", "Room for more fish. Everything moves across.", 0],
	["DECOR", "column", "Fallen column", "From some very small lost city.", 40],
	["DECOR", "castle", "Castle", "Every tank should have one.", 60],
	["DECOR", "chest", "Treasure chest", "Somebody left the lid open.", 60],
	["DECOR", "skull", "Skull", "It was like that when you got it.", 60],
]

var _shelf := "FISH"


func _init() -> void:
	super("Shop")
	for shelf: String in SHELVES:
		strip.add_child(UiKit.button(shelf, _show_shelf.bind(shelf), Vector2(96, 42)))
	Tickets.changed.connect(func() -> void:
		if visible:
			refresh())


func _show_shelf(shelf: String) -> void:
	_shelf = shelf
	refresh()


func refresh() -> void:
	_clear(body)
	for i in SHELVES.size():
		# the shelf being looked at is the gold one
		var tab: Button = strip.get_child(i)
		UiKit.hold(tab, SHELVES[i] == _shelf)
	if _shelf == "FISH":
		body.add_child(UiKit.label("Room left: %.1f of %d" % [maxf(tank.capacity() - tank.crowd(), 0.0), int(tank.capacity())], 18, UiKit.TEAL))
		for id: String in Species.ORDER:
			var sp: Dictionary = Species.LIST[id]
			if int(sp.price) > 0 and Species.lives_in(id, tank.kind):
				var why := "" if tank.has_room_for(id) else "FULL"
				_row(FishIcon.new(id), sp.name, sp.blurb, sp.price, why, _buy.bind("fish:" + id, sp.price))
		return
	for good: Array in GOODS:
		if good[0] != _shelf:
			continue
		var id: String = good[1]
		var title: String = good[2]
		var blurb: String = good[3]
		var price: int = good[4]
		var why := ""
		# (pumps, filters and the things that live under water are no use on dry land)
		if not tank.is_wet() and id in ["snail", "shrimp", "pump", "filter"]:
			continue
		match id:
			"plant":
				why = "" if tank.plants < Tank.MAX_PLANTS else "MAX"
				if tank.kind == "sea":
					title = "Coral or kelp"
					blurb = "Kelp, coral or a sea fan, in turn. Makes oxygen and takes up waste."
			"snail":
				why = "" if tank.snails < Tank.MAX_SNAILS else "MAX"
			"shrimp":
				why = "" if tank.shrimps < Tank.MAX_SHRIMPS else "MAX"
			"pump", "filter":
				why = "OWNED" if tank.gear.has(id) else ""
			"bigger":
				if tank.size_id >= tank.sizes().size() - 1:
					title = tank.sizes()[tank.size_id].name
					why = "OWNED"
				else:
					title = tank.sizes()[tank.size_id + 1].name
					price = tank.sizes()[tank.size_id + 1].price
			_:
				why = "OWNED" if tank.decor.has(id) else ""
		_row(null, title, blurb, price, why, _buy.bind(id, price))


## One thing for sale: a picture (or none), its name and a line about it, and its price on a
## button, or why it cannot be bought.
func _row(picture: Control, title: String, blurb: String, price: int, why: String, on_buy: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if picture != null:
		row.add_child(picture)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", -2)
	words.add_child(UiKit.label(title, 21))
	var line := UiKit.label(blurb, 16, Color(UiKit.PAPER, 0.8), 0)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(line)
	row.add_child(words)
	var buy := UiKit.button(why if why != "" else str(price), on_buy, Vector2(96, 46))
	buy.disabled = why != "" or not Tickets.can_pay(price)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(buy)
	body.add_child(row)


func _buy(id: String, price: int) -> void:
	if not Tickets.spend(price, id):
		Sfx.play("no")
		return
	Sfx.play("buy")
	if id.begins_with("fish:"):
		tank.add_fish(id.trim_prefix("fish:"))
	else:
		match id:
			"plant":
				tank.add_plant()
			"snail", "shrimp":
				tank.add_critter(id)
			"pump", "filter":
				tank.fit(id)
			"bigger":
				tank.grow()
			_:
				tank.place(id)
	refresh()
