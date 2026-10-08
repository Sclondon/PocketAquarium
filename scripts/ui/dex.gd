extends "res://scripts/ui/sheet.gd"
## The fish-dex: every kind of animal there is, with the ones kept so far (in any tank) filled
## in and a hint for each of the rest.

const Species := preload("res://scripts/tank/species.gd")
const FishIcon := preload("res://scripts/ui/fish_icon.gd")
const Notes := preload("res://scripts/ui/notes.gd")

## The kinds kept so far (main.gd's, which every tank shares).
var kept := {}
## Which half of the book is open: the animals, or the last keeper's notes.
var _notes := false


func _init() -> void:
	super("The book")


## Opens the book at the notes.
func open_notes() -> void:
	_notes = true
	open()


func refresh() -> void:
	_clear(body)
	_clear(strip)
	for half: Array in [["ANIMALS", false], ["NOTES", true]]:
		var tab := UiKit.button(half[0], func() -> void:
			_notes = half[1]
			refresh(), Vector2(110, 42))
		UiKit.hold(tab, _notes == half[1])
		strip.add_child(tab)
	if _notes:
		_show_notes()
		return
	strip.add_child(UiKit.label("  %d of %d kinds kept" % [kept.size(), Species.ORDER.size()], 18, UiKit.TEAL))
	var grid := GridContainer.new()
	grid.columns = maxi(int((plate_width() - 40.0) / 200.0), 2)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for id: String in Species.ORDER:
		var known: bool = kept.has(id)
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", UiKit.flat(Color(UiKit.INK, 0.6), Color(UiKit.PAPER, 0.3), 1, 8, 8))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		cell.add_child(col)
		var icon := FishIcon.new(id, known, Vector2(120, 70))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(icon)
		var title := UiKit.label(Species.LIST[id].name if known else "? ? ?", 19, UiKit.GOLD if known else UiKit.PAPER)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(title)
		var line := UiKit.label(Species.LIST[id].blurb if known else Species.hint(id), 14, Color(UiKit.PAPER, 0.8), 0)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.custom_minimum_size = Vector2(150, 66)
		col.add_child(line)
		grid.add_child(cell)


## The last keeper's notebook: the pages that have turned up, in the order they are in the book,
## and a line for each that has not.
func _show_notes() -> void:
	strip.add_child(UiKit.label("  %d of %d pages" % [Notes.count(), Notes.PAGES.size()], 18, UiKit.TEAL))
	for id: String in Notes.PAGES:
		if not Notes.has(id):
			var gap := UiKit.label("A page is missing here.", 15, Color(UiKit.PAPER, 0.35), 0)
			body.add_child(gap)
			continue
		var page: Array = Notes.PAGES[id]
		body.add_child(UiKit.label(page[0], 21, UiKit.GOLD))
		var words := Label.new()
		words.text = page[1]
		words.add_theme_font_override("font", load("res://fonts/LibreBaskerville-Italic.ttf"))
		words.add_theme_font_size_override("font_size", 17)
		words.add_theme_color_override("font_color", Color(UiKit.PAPER, 0.92))
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(words)
