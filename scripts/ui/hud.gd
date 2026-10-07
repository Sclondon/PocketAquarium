extends CanvasLayer
## Everything drawn over the tank: the tickets, the three water gauges, the row of tools along
## the bottom, the card for the fish in hand, messages, and the shop and fish-dex sheets.

## A tap or drag on the tank itself (anywhere no button is).
signal pad_input(event: InputEvent)
signal tool_picked(tool: String)
signal give_away(fish: Node)
signal card_closed
## Step to the next fish (1) or the one before (-1).
signal next_fish(step: int)

const UiKit := preload("res://scripts/ui/ui_kit.gd")
const Shop := preload("res://scripts/ui/shop.gd")
const Dex := preload("res://scripts/ui/dex.gd")
const FishIcon := preload("res://scripts/ui/fish_icon.gd")

var tank
var shop: Shop
var dex: Dex

var _tickets: Label
var _wallet_note: Label
var _day: Label
var _gauges := {}
var _tools := {}
var _lamp: Button
var _water: Button
var _toast: Label
var _toast_plate: PanelContainer
var _toast_tween: Tween
var _card: PanelContainer
var _card_icon: FishIcon
var _card_name: Label
var _card_stage: Label
var _card_fed: ProgressBar
var _card_health: ProgressBar
var _fish: Node


func setup(in_tank) -> void:
	tank = in_tank
	layer = 2
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var pad := Control.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.gui_input.connect(func(event: InputEvent) -> void: pad_input.emit(event))
	root.add_child(pad)

	# tickets, top left
	var purse := PanelContainer.new()
	purse.position = Vector2(12, 12)
	purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(purse)
	var purse_col := VBoxContainer.new()
	purse_col.add_theme_constant_override("separation", -4)
	purse.add_child(purse_col)
	_wallet_note = UiKit.label("TICKETS", 14, UiKit.TEAL, 0)
	purse_col.add_child(_wallet_note)
	_tickets = UiKit.label("0", 30, UiKit.GOLD)
	purse_col.add_child(_tickets)
	_day = UiKit.label("DAY 1", 14, UiKit.PAPER, 0)
	purse_col.add_child(_day)
	Tickets.changed.connect(_show_tickets)
	_show_tickets()

	# the water, top right
	var water := PanelContainer.new()
	water.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	water.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	water.position.y = 12
	water.offset_right = -12
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(water)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 0)
	water.add_child(grid)
	for gauge: Array in [["oxygen", "OXYGEN", UiKit.TEAL], ["clean", "WATER", UiKit.GOLD], ["glass", "GLASS", UiKit.GREEN], ["room", "ROOM", UiKit.CORAL]]:
		grid.add_child(UiKit.label(gauge[1], 14, UiKit.PAPER, 0))
		var b := UiKit.bar(gauge[2])
		grid.add_child(b)
		_gauges[gauge[0]] = b

	# messages, on a plate of their own under the gauges
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	middle.offset_top = 118
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(middle)
	_toast_plate = PanelContainer.new()
	_toast_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_plate.modulate.a = 0.0
	middle.add_child(_toast_plate)
	_toast = UiKit.label("", 19, UiKit.PAPER, 0)
	_toast_plate.add_child(_toast)

	# the tools, along the bottom
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -64
	bar.offset_bottom = -12
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	for tool: String in ["feed", "scrub"]:
		var b := UiKit.button(tool.to_upper(), pick_tool.bind(tool))
		bar.add_child(b)
		_tools[tool] = b
	_lamp = UiKit.button("LAMP", func() -> void: tank.set_lamp(not tank.lamp_on))
	bar.add_child(_lamp)
	_water = UiKit.button("WATER", _change_water)
	bar.add_child(_water)
	shop = Shop.new()
	dex = Dex.new()
	bar.add_child(UiKit.button("SHOP", shop.open))
	bar.add_child(UiKit.button("DEX", dex.open))

	_build_card(root)
	for sheet: Control in [shop, dex]:
		sheet.tank = tank
		root.add_child(sheet)
	pick_tool("feed")


func _build_card(root: Control) -> void:
	_card = PanelContainer.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card.offset_bottom = -74
	_card.visible = false
	root.add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_card.add_child(row)
	_card_icon = FishIcon.new()
	row.add_child(_card_icon)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	_card_name = UiKit.label("", 21, UiKit.GOLD)
	col.add_child(_card_name)
	_card_stage = UiKit.label("", 15, Color(UiKit.PAPER, 0.8), 0)
	col.add_child(_card_stage)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	col.add_child(grid)
	grid.add_child(UiKit.label("FED", 14, UiKit.PAPER, 0))
	_card_fed = UiKit.bar(UiKit.OCHRE, Vector2(130, 12))
	grid.add_child(_card_fed)
	grid.add_child(UiKit.label("HEALTH", 14, UiKit.PAPER, 0))
	_card_health = UiKit.bar(UiKit.GREEN, Vector2(130, 12))
	grid.add_child(_card_health)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	row.add_child(buttons)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 4)
	buttons.add_child(steps)
	steps.add_child(UiKit.button("<", func() -> void: next_fish.emit(-1), Vector2(58, 34)))
	steps.add_child(UiKit.button(">", func() -> void: next_fish.emit(1), Vector2(58, 34)))
	buttons.add_child(UiKit.button("GIVE AWAY", func() -> void: give_away.emit(_fish), Vector2(120, 34)))
	buttons.add_child(UiKit.button("CLOSE", func() -> void: card_closed.emit(), Vector2(120, 34)))


func _process(_delta: float) -> void:
	if tank == null:
		return
	_set_gauge("oxygen", tank.o2)
	_set_gauge("clean", 1.0 - tank.waste)
	_set_gauge("glass", 1.0 - tank.algae)
	_set_gauge("room", 1.0 - tank.crowd() / tank.capacity())
	_lamp.text = "LAMP ON" if tank.lamp_on else "LAMP OFF"
	_water.disabled = not tank.can_change_water()
	if tank.can_change_water():
		_water.text = "WATER"
	elif tank.water_wait > 3600.0:
		_water.text = "%d h" % ceili(tank.water_wait / 3600.0)
	else:
		_water.text = "%d min" % ceili(tank.water_wait / 60.0)
	_day.text = "DAY %d" % (int(tank.age / 86400.0) + 1)
	if _card.visible and is_instance_valid(_fish):
		_card_fed.value = 1.0 - _fish.hunger
		_card_health.value = _fish.health
		_card_stage.text = "%s %s, %s" % [_fish.stage(), _fish.info().name, _fish.appetite()]


## A gauge turns red when it is low enough to be doing harm.
func _set_gauge(id: String, value: float) -> void:
	var b: ProgressBar = _gauges[id]
	b.value = value
	b.modulate = Color(1.0, 0.45, 0.4) if value < 0.3 and id != "room" else Color.WHITE


func pick_tool(tool: String) -> void:
	for id: String in _tools:
		var b: Button = _tools[id]
		if id == tool:
			b.add_theme_stylebox_override("normal", UiKit.card(UiKit.GOLD, UiKit.INK, 3, 8))
		else:
			b.remove_theme_stylebox_override("normal")
	tool_picked.emit(tool)


## Shows the card for a fish (null puts it away).
func show_fish(fish: Node) -> void:
	_fish = fish
	_card.visible = fish != null
	if fish != null:
		_card_icon.species = fish.species
		_card_icon.queue_redraw()
		_card_name.text = fish.fish_name


## A message that fades after a few seconds.
func say(text: String) -> void:
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_plate.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.5)
	_toast_tween.tween_property(_toast_plate, "modulate:a", 0.0, 0.8)


func is_sheet_open() -> bool:
	return shop.visible or dex.visible


func _show_tickets() -> void:
	_tickets.text = str(Tickets.balance)
	_wallet_note.text = "TICKETS" if Tickets.hosted else "PRACTICE TICKETS"


func _change_water() -> void:
	if tank.can_change_water():
		tank.change_water()
		Sfx.play("water")
		say("Fresh water.")
