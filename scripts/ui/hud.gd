extends CanvasLayer
## Everything drawn over the shelf: the tickets, the water gauges of the tank being looked at,
## the row of tools along the bottom, the buttons that step up and down the shelf, the card for
## the fish in hand, the offer of a tank for an empty slot, messages, and the shop and fish-dex
## sheets.

## A tap or drag on the tank itself (anywhere no button is).
signal pad_input(event: InputEvent)
signal tool_picked(tool: String)
signal give_away(fish: Node)
## A page of the notebook wants reading (the keeper asked for it).
signal notebook_opened
## Net an animal out and put it in the home on another shelf.
signal move_fish(fish: Node, to_slot: int)
signal card_closed
## Step to the next fish (1) or the one before (-1).
signal next_fish(step: int)
## Look at the shelf above (1) or below (-1).
signal shelf_stepped(step: int)
## Buy a tank of this kind for the empty slot being looked at.
signal tank_wanted(kind: String)

const UiKit := preload("res://scripts/ui/ui_kit.gd")
const Shop := preload("res://scripts/ui/shop.gd")
const Dex := preload("res://scripts/ui/dex.gd")
const Page := preload("res://scripts/ui/page.gd")
const Homes := preload("res://scripts/ui/homes.gd")
const FishIcon := preload("res://scripts/ui/fish_icon.gd")
const Tank := preload("res://scripts/tank/tank.gd")

## The size of a button in the row along the bottom: eight of them fit a screen 540 across.
const KEY := Vector2(62, 50)

var tank
var shop: Shop
var dex: Dex
var page: Page
var homes: Homes

var _tickets: Label
var _wallet_note: Label
var _day: Label
var _gauges := {}
var _gauge_names := {}
var _tools := {}
var _lamp: Button
var _lamp_lit := false
var _water: Button
var _toast: Label
var _toast_plate: PanelContainer
var _toast_tween: Tween
var _card: PanelContainer
var _card_icon: FishIcon
var _card_name: Label
var _card_stage: Label
var _card_mood: Label
var _card_bond: Label
var _card_fed: ProgressBar
var _card_health: ProgressBar
var _fish: Node
var _water_plate: PanelContainer
var _tank_only: Array[Control] = []
var _up: Button
var _down: Button
var _offer: PanelContainer



func setup() -> void:
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
	_water_plate = water
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 0)
	water.add_child(grid)
	for gauge: Array in [["oxygen", "OXYGEN", UiKit.TEAL], ["clean", "WATER", UiKit.GOLD], ["settled", "FILTER", UiKit.OCHRE],
			["glass", "GLASS", UiKit.GREEN], ["salt", "SALT", UiKit.TEAL], ["damp", "DAMP", UiKit.TEAL], ["swarm", "COLONY", UiKit.CORAL], ["fed", "FOOD", UiKit.OCHRE], ["room", "ROOM", UiKit.CORAL]]:
		var name := UiKit.label(gauge[1], 14, UiKit.PAPER, 0)
		grid.add_child(name)
		var b := UiKit.bar(gauge[2])
		grid.add_child(b)
		_gauges[gauge[0]] = b
		_gauge_names[gauge[0]] = name

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
	var bar := HFlowContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_left = 8
	bar.offset_right = -8
	bar.offset_top = -64
	bar.offset_bottom = -12
	bar.alignment = FlowContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("h_separation", 5)
	bar.add_theme_constant_override("v_separation", 5)
	# (on a narrow screen the keys run to a second row, and the card moves up out of their way)
	# (on one too narrow for a single row, the tools take the first row and the rest the second)
	var row_break := Control.new()
	row_break.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_break.visible = false
	var fit_bar := func() -> void:
		var one_row := -5.0
		for key in bar.get_children():
			if key is Button and key.visible:
				one_row += key.get_combined_minimum_size().x + 5.0
		var narrow := bar.size.x < one_row
		if row_break.visible != narrow:
			row_break.custom_minimum_size.x = bar.size.x - 2.0 if narrow else 0.0
			row_break.visible = narrow
		if _card != null:
			_card.offset_bottom = -(bar.size.y + 22.0)
	bar.resized.connect(func() -> void: fit_bar.call_deferred())
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	for tool: String in ["feed", "hand", "net", "scrub", "mirror", "torch"]:
		var b := UiKit.button(tool.to_upper(), pick_tool.bind(tool), KEY)
		bar.add_child(b)
		_tools[tool] = b
		_tank_only.append(b)
	bar.add_child(row_break)
	_lamp = UiKit.button("LAMP", func() -> void: tank.set_lamp(not tank.lamp_on), KEY)
	bar.add_child(_lamp)
	_water = UiKit.button("WATER", _change_water, KEY)
	bar.add_child(_water)
	shop = Shop.new()
	dex = Dex.new()
	page = Page.new()
	homes = Homes.new()
	homes.wanted.connect(func(kind: String) -> void: tank_wanted.emit(kind))
	page.give_away.connect(func(fish: Node) -> void: give_away.emit(fish))
	page.moved.connect(func(fish: Node, to_slot: int) -> void: move_fish.emit(fish, to_slot))
	var shop_button := UiKit.button("SHOP", shop.open, KEY)
	bar.add_child(shop_button)
	bar.add_child(UiKit.button("BOOK", dex.open, KEY))
	for b in bar.get_children():
		if b is Button:
			b.add_theme_font_size_override("font_size", 17)
	_tank_only.append_array([_lamp, _water, shop_button])

	# up and down the shelf, at the right-hand edge
	var steps := VBoxContainer.new()
	steps.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	steps.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	steps.grow_vertical = Control.GROW_DIRECTION_BOTH
	steps.offset_right = -12
	steps.add_theme_constant_override("separation", 6)
	root.add_child(steps)
	_up = UiKit.button("UP", func() -> void: shelf_stepped.emit(1), Vector2(74, 50))
	_down = UiKit.button("DOWN", func() -> void: shelf_stepped.emit(-1), Vector2(74, 50))
	steps.add_child(_up)
	steps.add_child(_down)

	_build_card(root)
	_build_offer(root)
	for sheet: Control in [shop, dex, page, homes]:
		root.add_child(sheet)
	pick_tool("feed")


## The plate shown over an empty slot of the shelf: a tank of either kind, for tickets.
func _build_offer(root: Control) -> void:
	_offer = PanelContainer.new()
	_offer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_offer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_offer.grow_vertical = Control.GROW_DIRECTION_BOTH
	_offer.visible = false
	root.add_child(_offer)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_offer.add_child(col)
	col.add_child(UiKit.label("An empty shelf", 28, UiKit.GOLD))
	var line := UiKit.label("Room for a tank, a jar or a terrarium.", 16, Color(UiKit.PAPER, 0.8), 0)
	col.add_child(line)
	col.add_child(UiKit.button("SEE WHAT WILL FIT", func() -> void: homes.open(), Vector2(220, 46)))


func _show_offer_prices() -> void:
	pass


## Turns the HUD to a slot of the shelf: its tank (null for an empty slot, which gets the
## offer of one instead of the tools).
func show_slot(in_tank, at: int, slots: int, for_sale := true) -> void:
	tank = in_tank
	shop.tank = tank
	dex.tank = tank
	shop.close()
	page.close()
	for c in _tank_only:
		c.visible = tank != null
	_water_plate.visible = tank != null
	_offer.visible = tank == null and for_sale
	_up.disabled = at >= slots - 1
	_down.disabled = at <= 0
	_show_offer_prices()


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
	# who it is: its temper and what it is about, then how it stands with you and the others
	_card_mood = UiKit.label("", 15, UiKit.TEAL, 0)
	col.add_child(_card_mood)
	_card_bond = UiKit.label("", 14, Color(UiKit.PAPER, 0.8), 0)
	_card_bond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_bond.custom_minimum_size.x = 210
	col.add_child(_card_bond)
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
	buttons.add_child(UiKit.button("ITS PAGE", func() -> void: page.show_page(_fish), Vector2(120, 34)))
	buttons.add_child(UiKit.button("CLOSE", func() -> void: card_closed.emit(), Vector2(120, 34)))


func _process(_delta: float) -> void:
	# (messages and the shelf buttons keep out from under an open sheet)
	_toast_plate.visible = not is_sheet_open()
	_up.get_parent().visible = not is_sheet_open()
	if tank == null:
		_day.text = ""
		return
	# each kind of home shows the gauges that mean something in it
	var wet: bool = tank.is_wet()
	var salty: bool = float(tank.about().get("salt", 0.0)) > 0.0
	_set_gauge("oxygen", tank.o2, wet)
	_set_gauge("clean", 1.0 - tank.waste, wet)
	_set_gauge("settled", tank.water.colony, wet and tank.water.colony < 0.995)
	_set_gauge("glass", 1.0 - tank.algae, wet)
	# (salt reads full when it is just right, and falls as it creeps up)
	_set_gauge("salt", 1.0 - absf(tank.salt - float(tank.about().get("salt", 0.0))) * 3.0, salty)
	_set_gauge("damp", tank.humidity, tank.about().get("humid", false))
	_set_gauge("room", 1.0 - tank.crowd() / tank.capacity(), tank.swarm == null)
	_set_gauge("swarm", tank.swarm.count() / 240.0 if tank.swarm != null else 0.0, tank.swarm != null)
	_set_gauge("fed", minf(tank.swarm.food, 1.0) if tank.swarm != null else 0.0, tank.swarm != null)
	# (the lamp's button is lit while the lamp is)
	if _lamp_lit != tank.lamp_on:
		_lamp_lit = tank.lamp_on
		UiKit.hold(_lamp, _lamp_lit)
	_water.disabled = not tank.can_change_water()
	# (a dry terrarium has neither water to change nor air that wants misting)
	_water.visible = wet or tank.about().get("humid", false)
	if tank.can_change_water():
		_water.text = "WATER" if wet else "MIST"
	elif tank.water_wait > 3600.0:
		_water.text = "%d h" % ceili(tank.water_wait / 3600.0)
	else:
		_water.text = "%d min" % ceili(tank.water_wait / 60.0)
	_day.text = "DAY %d" % (int(tank.age / 86400.0) + 1)
	if _card.visible and is_instance_valid(_fish):
		_card_fed.value = 1.0 - _fish.hunger
		_card_health.value = _fish.health
		_card_stage.text = "%s %s, %s" % [_fish.stage(), _fish.info().name, _fish.appetite()]
		_card_mood.text = "%s, %s" % [_fish.buddy.temper.capitalize(), _fish.mood()]
		var company: String = _fish.company()
		_card_bond.text = _fish.buddy.regard() + (". " + company if company != "" else "")


## A gauge turns red when it is low enough to be doing harm.
func _set_gauge(id: String, value: float, shown: bool) -> void:
	var b: ProgressBar = _gauges[id]
	b.visible = shown
	(_gauge_names[id] as Label).visible = shown
	b.value = value
	b.modulate = Color(1.0, 0.45, 0.4) if value < 0.3 and not id in ["room", "swarm", "settled"] else Color.WHITE


## Says on the torch's button which torch it is: taking it up again changes it.
func show_torch(red: bool, in_hand: bool) -> void:
	(_tools["torch"] as Button).text = ("RED" if red else "WHITE") if in_hand else "TORCH"


func pick_tool(tool: String) -> void:
	for id: String in _tools:
		var b: Button = _tools[id]
		UiKit.hold(b, id == tool)
	tool_picked.emit(tool)


## Shows the card for a fish (null puts it away).
func show_fish(fish: Node) -> void:
	_fish = fish
	_card.visible = fish != null
	if fish != null:
		_card_icon.show_kind(fish.species)
		_card_name.text = fish.fish_name


## A message that fades after a few seconds.
func say(text: String) -> void:
	_toast.text = text
	# (a long one is wrapped to fit a phone, and stays up long enough to read)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.custom_minimum_size.x = minf(text.length() * 9.5, minf(get_viewport().get_visible_rect().size.x - 60.0, 900.0))
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_plate.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0 + _toast.text.length() * 0.045)
	_toast_tween.tween_property(_toast_plate, "modulate:a", 0.0, 0.8)


func is_sheet_open() -> bool:
	return shop.visible or dex.visible or page.visible or homes.visible


func _show_tickets() -> void:
	_tickets.text = str(Tickets.balance)
	_wallet_note.text = "TICKETS" if Tickets.hosted else "PRACTICE TICKETS"
	if Tickets.credit > 0:
		_wallet_note.text += "  +%d CREDIT" % Tickets.credit


func _change_water() -> void:
	if tank.can_change_water():
		tank.change_water()
		Sfx.play("water")
		say("Fresh water." if not tank.about().get("sealed", false) else "You have opened it. New water, and most of what kept it alive poured down the sink.")
