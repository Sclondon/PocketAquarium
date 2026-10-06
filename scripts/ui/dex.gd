extends "res://scripts/ui/sheet.gd"
## The fish-dex: every kind of fish there is, with the ones kept so far filled in and a hint
## for each of the rest.

const Species := preload("res://scripts/tank/species.gd")
const FishIcon := preload("res://scripts/ui/fish_icon.gd")


func _init() -> void:
	super("Fish-dex")


func refresh() -> void:
	_clear(body)
	_clear(strip)
	strip.add_child(UiKit.label("%d of %d kinds kept" % [tank.dex.size(), Species.ORDER.size()], 18, UiKit.TEAL))
	var grid := GridContainer.new()
	grid.columns = maxi(int((plate_width() - 40.0) / 200.0), 2)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for id: String in Species.ORDER:
		var known: bool = tank.dex.has(id)
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
		line.custom_minimum_size = Vector2(150, 44)
		col.add_child(line)
		grid.add_child(cell)
