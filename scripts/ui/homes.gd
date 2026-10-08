extends "res://scripts/ui/sheet.gd"
## The catalogue of homes for an empty shelf: every kind there is (kinds.gd), what it is like,
## who can live in it, and its price.

signal wanted(kind: String)

const Kinds := preload("res://scripts/tank/kinds.gd")
const Species := preload("res://scripts/tank/species.gd")


func _init() -> void:
	super("For an empty shelf")
	Tickets.changed.connect(func() -> void:
		if visible:
			refresh())


func refresh() -> void:
	_clear(body)
	for kind: String in Kinds.ORDER:
		var about: Dictionary = Kinds.of(kind)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", -2)
		words.add_child(UiKit.label(about.name, 21))
		var line := UiKit.label(about.blurb, 16, Color(UiKit.PAPER, 0.8), 0)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(line)
		var who := _who(kind)
		if who != "":
			var living := UiKit.label(who, 14, UiKit.TEAL, 0)
			living.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			words.add_child(living)
		row.add_child(words)
		var buy := UiKit.button(str(about.price), func() -> void:
			wanted.emit(kind)
			close(), Vector2(96, 46))
		buy.disabled = not Tickets.can_pay(int(about.price), "tank:")
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(buy)
		body.add_child(row)


## The animals that are sold for a kind of home, in a line.
func _who(kind: String) -> String:
	var names: Array[String] = []
	for id: String in Species.ORDER:
		if int(Species.LIST[id].price) > 0 and Species.LIST[id].has("home") and Species.lives_in(id, kind):
			names.append(Species.LIST[id].name)
	if Kinds.of(kind).has("swarm"):
		names.append("sea monkeys, by the hundred")
	return "For: " + ", ".join(names) if not names.is_empty() else ""
