extends Node
## The automated tour, started by main.gd when the game is run with one of:
##   godot --path . -- --no-save --shots=C:/some/folder    screenshots of the tank and each sheet
##   godot --headless --path . -- --no-save --smoke        months of tank time, then a report
## Both quit when they are done. Use --no-save so they leave the real tank alone.

const Species := preload("res://scripts/tank/species.gd")

var main: Node
var folder := ""


func _ready() -> void:
	if folder == "":
		_smoke.call_deferred()
	else:
		_shots.call_deferred()


## Keeps three tanks for weeks of tank time and prints what became of each: a beginner's and a
## full one, both fed once a day with the water changed once a week, and one left alone.
func _smoke() -> void:
	var tank = main.tank
	print("smoke: a new tank, fed daily")
	_keep(tank, 60)

	tank.load_state({})
	for i in 2:
		tank.grow()
	for id in ["pump", "filter"]:
		tank.fit(id)
	for id in ["castle", "chest", "skull", "column"]:
		tank.place(id)
	for i in 5:
		tank.add_plant()
	tank.add_critter("snail")
	tank.add_critter("shrimp")
	for id: String in ["tetra", "goldfish", "angelfish", "betta", "clownfish", "puffer"]:
		tank.add_fish(id)
	print("smoke: a full tank with everything fitted, fed daily")
	_keep(tank, 120)

	# a save from three days ago: the tank catches up on the time away
	var old: Dictionary = JSON.parse_string(JSON.stringify(tank.to_data()))
	old["at"] = Time.get_unix_time_from_system() - 3.0 * 86400.0
	var hungry_before: float = tank.fish[0].hunger
	tank.said.connect(func(text: String) -> void: print("smoke: said: ", text))
	tank.load_state(old)
	print("smoke: reloaded %d fish and %d eggs after 3 days away; first fish's hunger %.2f -> %.2f" % [tank.fish.size(),
			tank._eggs.size(), hungry_before, tank.fish[0].hunger])

	# a neglected tank: nothing fed, nothing cleaned
	tank.load_state({})
	var day := 0
	while day < 30 and _living(tank) > 0:
		tank.elapse(86400.0)
		day += 1
	print("smoke: left alone, the last of 2 guppies died on day %d; waste %.2f, algae %.2f" % [day, tank.waste, tank.algae])
	get_tree().quit()


## A keeper's routine for so many days: every day a pinch of food for each three fish, then two
## minutes of watching while they eat; every week a water change, a scrub, and the dead netted.
func _keep(tank, days: int) -> void:
	var start: int = tank.fish.size()
	var died := 0
	var worst_waste := 0.0
	var worst_o2 := 1.0
	for day in days:
		for k in ceili(_living(tank) / 3.0):
			tank.drop_food(randf_range(-0.8, 0.8), randf_range(-0.4, 0.4))
		for i in 1200:
			tank.step(0.1)
		tank.elapse(86400.0 - 120.0)
		worst_waste = maxf(worst_waste, tank.waste)
		worst_o2 = minf(worst_o2, tank.o2)
		if day % 7 == 6:
			tank.change_water()
			tank.scrub(1.0)
			for f in tank.fish.duplicate():
				if f.dead:
					died += 1
					tank.remove_fish(f)
	var hunger := 0.0
	for f in tank.fish:
		hunger += f.hunger
	print("smoke:   after %d days: %d living; %d hatched, %d died, %d eggs waiting; hunger %.2f" % [days, _living(tank),
			tank.fish.size() + died - start, died + tank.fish.size() - _living(tank), tank._eggs.size(),
			hunger / maxf(tank.fish.size(), 1.0)])
	print("smoke:   worst waste %.2f, lowest oxygen %.2f, algae %.2f, crowd %.1f/%.0f, dex %d/%d %s" % [worst_waste, worst_o2,
			tank.algae, tank.crowd(), tank.capacity(), tank.dex.size(), Species.ORDER.size(), str(tank.dex.keys())])


func _living(tank) -> int:
	var n := 0
	for f in tank.fish:
		n += int(not f.dead)
	return n


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	var tank = main.tank
	await _settle(1.0)
	await _shot("1_new_tank")
	tank.grow()
	tank.fit("pump")
	tank.fit("filter")
	for id in ["castle", "chest", "skull", "column"]:
		tank.place(id)
	for i in 5:
		tank.add_plant()
	tank.add_critter("snail")
	tank.add_critter("shrimp")
	for id: String in ["tetra", "goldfish", "angelfish", "betta", "clownfish", "puffer", "aurora_koi", "moonfish"]:
		tank.add_fish(id)
	for f in tank.fish:
		f.growth = 1.0
	tank.drop_food(0.2, 0.0)
	for i in 100:
		tank.step(0.1)
	await _settle(2.0)
	await _shot("2_full_tank")
	main.call("_select", tank.fish[3])
	tank.algae = 0.6
	tank.waste = 0.8
	await _settle(0.5)
	await _shot("3_dirty_with_card")
	main.call("_select", null)
	tank.algae = 0.0
	tank.waste = 0.05
	tank.set_lamp(false)
	await _settle(1.5)
	await _shot("4_lamp_off")
	tank.set_lamp(true)
	main.hud.shop.open()
	await _settle(0.5)
	await _shot("5_shop")
	main.hud.shop.close()
	main.hud.dex.open()
	await _settle(0.5)
	await _shot("6_dex")
	main.hud.dex.close()
	get_window().size = Vector2i(540, 960)
	await _settle(1.0)
	await _shot("7_portrait")
	main.hud.shop.open()
	await _settle(0.5)
	await _shot("8_portrait_shop")
	main.hud.shop.close()
	main.hud.dex.open()
	await _settle(0.5)
	await _shot("9_portrait_dex")
	get_tree().quit()


func _settle(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [folder, title])
	print("shot ", title)
