extends "res://scripts/ui/sheet.gd"
## One animal's own page: its name (which can be changed here), what it is and what it is
## like, how long it has been kept and how it regards the keeper, who its friends and rivals
## are, and the last few things that happened to it.

signal give_away(fish: Node)

const Species := preload("res://scripts/tank/species.gd")
const FishIcon := preload("res://scripts/ui/fish_icon.gd")

## What each temper is like, in a line.
const TEMPERS := {
	"bold": "Bold: comes forward, and takes a lot of scaring.",
	"shy": "Shy: hides from what it does not know, and is slow to know anyone.",
	"greedy": "Greedy: thinks well of whoever feeds it.",
	"curious": "Curious: has to go and look, at your finger most of all.",
	"grumpy": "Grumpy: keeps a corner to itself and sees the others off.",
	"dozy": "Dozy: first asleep, and last up.",
}

var fish: Node


func _init() -> void:
	super("")


## Opens the page of this animal.
func show_page(of: Node) -> void:
	fish = of
	open()


func refresh() -> void:
	_clear(body)
	_clear(strip)
	if not is_instance_valid(fish):
		close()
		return
	_title.text = fish.fish_name
	var info: Dictionary = fish.info()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	body.add_child(top)
	top.add_child(FishIcon.new(fish.species, true, Vector2(120, 70)))
	var about := VBoxContainer.new()
	about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	about.add_theme_constant_override("separation", 2)
	top.add_child(about)
	about.add_child(UiKit.label("%s %s" % [fish.stage(), info.name], 20, UiKit.PAPER, 0))
	about.add_child(_line(info.blurb))

	# its name, to change
	var naming := HBoxContainer.new()
	naming.add_theme_constant_override("separation", 8)
	body.add_child(naming)
	naming.add_child(UiKit.label("NAME", 14, UiKit.TEAL, 0))
	var box := LineEdit.new()
	box.text = fish.fish_name
	box.max_length = 14
	box.custom_minimum_size = Vector2(200, 40)
	box.add_theme_font_size_override("font_size", 20)
	box.text_changed.connect(func(text: String) -> void:
		if is_instance_valid(fish) and text.strip_edges() != "":
			fish.fish_name = text.strip_edges()
			_title.text = fish.fish_name)
	naming.add_child(box)

	body.add_child(_head("WHAT IT IS LIKE"))
	body.add_child(_line(TEMPERS[fish.buddy.temper]))
	body.add_child(_line("Just now: %s." % fish.mood()))

	body.add_child(_head("YOU AND IT"))
	var days := 0
	if fish.buddy.met > 0:
		days = int((Time.get_unix_time_from_system() - fish.buddy.met) / 86400.0)
	body.add_child(_line("%s. %s." % [fish.buddy.regard(),
			"It came today" if days < 1 else ("With you %d day%s" % [days, "" if days == 1 else "s"])]))

	var company: String = fish.company()
	body.add_child(_head("COMPANY"))
	body.add_child(_line(company + "." if company != "" else "It has not taken to anyone yet, nor against."))

	body.add_child(_head("LATELY"))
	if fish.buddy.moments.is_empty():
		body.add_child(_line("Nothing to speak of yet."))
	for i in range(fish.buddy.moments.size() - 1, -1, -1):
		body.add_child(_line(fish.buddy.moments[i] + "."))

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(foot)
	foot.add_child(UiKit.button("GIVE AWAY", func() -> void:
		give_away.emit(fish)
		close(), Vector2(130, 40)))


func _head(text: String) -> Label:
	return UiKit.label(text, 14, UiKit.TEAL, 0)


func _line(text: String) -> Label:
	var l := UiKit.label(text, 17, Color(UiKit.PAPER, 0.9), 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
