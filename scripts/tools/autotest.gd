extends Node
## The automated tour, started by main.gd when the game is run with one of:
##   godot --path . -- --no-save --shots=C:/some/folder    screenshots of the tank and each sheet
##   godot --headless --path . -- --no-save --smoke        an hour of tank time, then a report
## Both quit when they are done. Use --no-save so they leave the real tank alone.

const Species := preload("res://scripts/tank/species.gd")

var main: Node
var folder := ""


func _ready() -> void:
	if folder == "":
		_smoke.call_deferred()
	else:
		_shots.call_deferred()


## Fills a tank with everything, then runs it for an hour (fed and cleaned every so often) and
## prints what became of it.
func _smoke() -> void:
	var tank = main.tank
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
	var bought: int = tank.fish.size()
	var died := 0
	var given := 0
	for i in 36000:
		if i % 600 == 0:
			for k in 4:
				tank.drop_food(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4))
		if i % 6000 == 0:
			tank.change_water()
			for f in tank.fish.duplicate():
				if f.dead:
					died += 1
					tank.remove_fish(f)
			# room for eggs: give away any fish over a dozen
			while tank.fish.size() > 12:
				tank.remove_fish(tank.fish[0])
				given += 1
		tank.step(0.1)
		if i % 3000 == 2999:
			var hungry := 0.0
			var living := 0
			for f in tank.fish:
				if not f.dead:
					living += 1
					hungry += f.hunger
			print("smoke: minute %d: %d living, hunger %.2f, o2 %.2f, waste %.2f, algae %.2f, %d flakes lying" % [(i + 1) / 600,
					living, hungry / maxf(living, 1.0), tank.o2, tank.waste, tank.algae, tank._foods.size()])
	var alive := 0
	for f in tank.fish:
		alive += int(not f.dead)
	print("smoke: %d alive; %d hatched, %d died, %d given away; dex %d/%d %s" % [alive,
			tank.fish.size() + died + given - bought, died + tank.fish.size() - alive, given,
			tank.dex.size(), Species.ORDER.size(), str(tank.dex.keys())])
	print("smoke: o2 %.2f waste %.2f algae %.2f crowd %.1f/%.0f" % [tank.o2, tank.waste, tank.algae, tank.crowd(), tank.capacity()])
	var again: Dictionary = JSON.parse_string(JSON.stringify(tank.to_data()))
	tank.load_state(again)
	print("smoke: reloaded %d fish, ok" % tank.fish.size())
	# a neglected tank: nothing fed, nothing cleaned
	tank.load_state({})
	for i in 9000:
		tank.step(0.1)
	var left := 0
	for f in tank.fish:
		left += int(not f.dead)
	print("smoke: 15 minutes of neglect leaves %d of 2 guppies, waste %.2f algae %.2f" % [left, tank.waste, tank.algae])
	get_tree().quit()


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
