extends Control
## A sheet that opens over the tank (the shop, the fish-dex): a navy plate in the middle of the
## screen with a title, a close button and a scrolling body. Tapping outside it closes it.

const UiKit := preload("res://scripts/ui/ui_kit.gd")

var tank
var body: VBoxContainer
## A row under the title for tabs or a count (empty unless a sheet fills it).
var strip: HBoxContainer

var _plate: PanelContainer
var _title: Label


func _init(title: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	add_child(dim)
	_plate = PanelContainer.new()
	add_child(_plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_plate.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	_title = UiKit.label(title, 30, UiKit.GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	head.add_child(UiKit.button("CLOSE", close, Vector2(90, 42)))
	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	col.add_child(strip)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# (always there, so the page does not get narrower, and its lines longer, after it is laid out)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	col.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)
	resized.connect(_fit)


func open() -> void:
	visible = true
	_fit()
	refresh()


func close() -> void:
	visible = false


## Fills the body in again (each sheet's own).
func refresh() -> void:
	pass


## How wide the plate is, for sheets that lay their body out to fit.
func plate_width() -> float:
	return minf(680.0, size.x - 24.0)


func _fit() -> void:
	var want := Vector2(plate_width(), minf(maxf(600.0, size.y * 0.7), size.y - 150.0))
	_plate.size = want
	_plate.position = ((size - want) * 0.5).floor()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
