extends Node
## The automated tour, started by main.gd when the game is run with one of:
##   godot --path . -- --no-save --shots=C:/some/folder    screenshots of the tank and each sheet
##   godot --headless --path . -- --no-save --smoke        months of tank time, then a report
## Both quit when they are done. Use --no-save so they leave the real tank alone.

const Species := preload("res://scripts/tank/species.gd")
const Kinds := preload("res://scripts/tank/kinds.gd")

var main: Node
var folder := ""
## The tour of every kind of home, in place of the usual one.
var homes := false


func _ready() -> void:
	if folder == "":
		_smoke.call_deferred()
	else:
		(_homes if homes else _shots).call_deferred()


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
	print("smoke: left alone, the last of the fish died on day %d; waste %.2f, algae %.2f" % [day, tank.waste, tank.algae])

	var sea = main.add_tank(3, {"kind": "sea"})
	sea.grow()
	sea.grow()
	for id in ["pump", "filter"]:
		sea.fit(id)
	for i in 5:
		sea.add_plant()
	for id: String in ["jellyfish", "salmon", "salmon", "tuna", "shark", "giant_squid", "blue_whale"]:
		sea.add_fish(id)
	print("smoke: a magic salt water tank, fed daily")
	_keep(sea, 60)
	main.save()
	print("smoke: saved %d tanks, dex %d" % [Save.data.tanks.filter(func(t: Variant) -> bool: return t != null).size(), main.dex.size()])

	# the other kinds of home. A brine kit, fed a pinch every other day and topped up weekly
	var kit = main.add_tank(0, {"kind": "brine"})
	var most := 0.0
	for d in 40:
		if d % 2 == 0:
			kit.drop_food(0.0, 0.0)
		if d % 7 == 6:
			kit.change_water()
		kit.elapse(86400.0)
		most = maxf(most, kit.swarm.count())
	print("smoke: a brine kit after 40 days: %d sea monkeys (most %d), %d eggs, salt %.2f" % [kit.swarm.count(), most, kit.swarm.eggs, kit.salt])
	kit.load_state({"kind": "brine"})
	kit.elapse(20.0 * 86400.0)
	print("smoke: a brine kit never fed, after 20 days: %d sea monkeys" % kit.swarm.count())
	# a vivarium, misted every day, and one never misted; and a desert with its lamp left off
	for care: String in ["misted daily", "never misted"]:
		var viv = main.tanks[1] if main.tanks[1] != null else main.add_tank(1, {})
		viv.load_state({"kind": "vivarium"})
		for id: String in ["dart_frog", "horned_frog", "crested_gecko"]:
			viv.add_fish(id)
		var first_death := 0
		for n in 30:
			viv.drop_food(0.0, 0.0)
			for i in 600:
				viv.step(0.1)
			if care == "misted daily":
				viv.change_water()
			viv.elapse(86400.0 - 60.0)
			if first_death == 0 and _living(viv) < 3:
				first_death = n + 1
		print("smoke: a vivarium %s for 30 days: %d of 3 living, damp %.2f, first death on day %d" % [care, _living(viv), viv.humidity, first_death])
	# a sealed jar: left quite alone in the light, left in the dark, and fussed over
	for care: String in ["let alone", "kept in the dark", "fed daily and opened weekly"]:
		var sealed = main.tanks[1]
		sealed.load_state({"kind": "sealed", "fish": [{"species": "opae_ula"}, {"species": "opae_ula"}, {"species": "opae_ula"}, {"species": "opae_ula"}]})
		sealed.set_lamp(care != "kept in the dark")
		for n in 60:
			if care == "fed daily and opened weekly":
				sealed.drop_food(0.0, 0.0)
				for i in 600:
					sealed.step(0.1)
				if n % 7 == 6:
					sealed.change_water()
			sealed.elapse(86400.0)
			if OS.has_environment("DBG") and n % 6 == 0:
				print("dbg %s day %d: fish %d living %d algae %.2f waste %.2f o2 %.2f colony %.2f hunger %.2f" % [care, n, sealed.fish.size(), _living(sealed), sealed.algae, sealed.waste, sealed.o2, sealed.water.colony, sealed.fish[0].hunger])
		print("smoke: a sealed jar %s for 60 days: %d of 4 living (and %d born), glass %.2f, water %.2f" % [care, mini(_living(sealed), 4),
				maxi(_living(sealed) - 4, 0), sealed.algae, sealed.waste])

	# an animal netted out of one home and into another keeps its name and what it thinks of the keeper
	var from = main.tanks[2]
	main.look_at_slot(2)
	var jar = main.tanks[1]
	jar.load_state({"kind": "fresh"})
	var mover = from.fish[0]
	mover.buddy.bond = 0.6
	var was_called: String = mover.fish_name
	var before: int = from.fish.size()
	main.call("_move", mover, 1)
	var arrived = jar.fish[jar.fish.size() - 1]
	print("smoke: moved %s: %d fish left behind (of %d), arrived as %s with bond %.1f" % [was_called, from.fish.size(), before, arrived.fish_name, arrived.buddy.bond])

	# saves from the first game, in both the shapes it wrote, come up to date and load with
	# every fish they had
	for was: Dictionary in [
			{"tank": {"fish": [{"species": "guppy"}, {"species": "betta"}, {"species": "aurora_koi"}]}, "dex": ["guppy"], "wallet": 40},
			{"tanks": [null, {"fish": [{"species": "tetra"}, {"species": "puffer"}], "snails": 2},
					{"kind": "sea", "fish": [{"species": "orca"}, {"species": "blue_whale"}]}], "dex": ["tetra", "orca"]}]:
		var had := 0
		for t: Variant in was.get("tanks", [was.get("tank")]):
			had += (t.fish as Array).size() if t is Dictionary else 0
		var now: Dictionary = Save.upgrade(was.duplicate(true))
		var have := 0
		for i in now.tanks.size():
			if now.tanks[i] is Dictionary:
				var t = main.tanks[i] if main.tanks[i] != null else main.add_tank(i, {})
				t.load_state(now.tanks[i])
				have += t.fish.size()
		print("smoke: an old save came up to version %d: %d of %d fish loaded, wallet %s" % [now.version, have, had,
				str(now.get("wallet", "none"))])
	get_tree().quit()


## A keeper's routine for so many days: every day a pinch of food for each three fish, then two
## minutes of watching while they eat; every week a water change, a scrub, and the dead netted.
func _keep(tank, days: int) -> void:
	var start: int = tank.fish.size()
	var died := 0
	var lost := {}
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
					lost[f.species] = int(lost.get(f.species, 0)) + 1
					tank.remove_fish(f)
	var hunger := 0.0
	for f in tank.fish:
		hunger += f.hunger
	print("smoke:   after %d days: %d living; %d hatched, %d died, %d eggs waiting; hunger %.2f" % [days, _living(tank),
			tank.fish.size() + died - start, died + tank.fish.size() - _living(tank), tank._eggs.size(),
			hunger / maxf(tank.fish.size(), 1.0)])
	print("smoke:   worst waste %.2f, lowest oxygen %.2f, algae %.2f, crowd %.1f/%.0f, dex %d/%d %s" % [worst_waste, worst_o2,
			tank.algae, tank.crowd(), tank.capacity(), tank.dex.size(), Species.ORDER.size(), str(tank.dex.keys())])
	if not lost.is_empty():
		print("smoke:   the dead, by kind: %s" % str(lost))
	# (two minutes of each day were watched)
	var passed := 0
	for kind: String in tank.seen:
		passed += int(tank.seen[kind])
	print("smoke:   between the animals, %.1f things a minute watched: %s" % [passed / (days * 2.0), str(tank.seen)])
	tank.seen.clear()


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
	for id: String in ["kuhli", "kuhli", "kuhli", "glass_catfish", "glass_catfish", "glass_catfish", "hatchetfish", "hatchetfish",
			"hatchetfish", "sparkling_gourami", "sparkling_gourami"]:
		tank.add_fish(id)
	for f in tank.fish:
		f.growth = 1.0
	tank.drop_food(0.2, 0.0)
	for i in 100:
		tank.step(0.1)
	await _settle(2.0)
	await _shot("2_full_tank")
	# a finger on the glass, with fish that know the keeper well and one that does not
	for f in tank.fish:
		f.buddy.bond = 0.9
	tank.fish[0].buddy.bond = 0.0
	tank.fish[0].buddy.temper = "shy"
	tank.point_at(Vector3(0.7, 1.0, tank.depth * 0.5))
	await _settle(4.0)
	await _shot("2b_at_the_finger")
	tank.point_at(null)
	# a pinch of food held out at the glass, and then one fish's own page
	for f in tank.fish:
		f.hunger = 0.5
	tank.offer(Vector3(-0.5, 0.9, tank.depth * 0.5))
	await _settle(3.0)
	await _shot("2d_from_the_hand")
	tank.offer(null)
	tank.live_food = true
	for f in tank.fish:
		if Species.habit(f.species, "hunts"):
			f.hunger = 0.9
			tank.drop_food(f.position.x, f.position.z)
	tank.live_food = false
	await _settle(1.2)
	await _shot("2g_live_food")
	await _settle(6.0)
	print("hunted: ", tank.seen.get("hunted", 0))
	main.hud.page.show_page(tank.fish[2])
	await _settle(0.5)
	await _shot("2e_its_page")
	main.hud.page.close()
	tank.greet()
	await _settle(3.5)
	await _shot("2c_saying_hello")
	tank.hold_mirror(Vector3(0.3, 0.6, tank.depth * 0.5))
	await _settle(4.0)
	await _shot("2f_at_the_mirror")
	print("at the mirror: ", tank.fish.filter(func(f: Node) -> bool: return f.doing in ["flaring", "peering"]).size())
	tank.hold_mirror(null)
	await _settle(5.0)
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
	# the shelf above: a magic salt water tank with one of everything, then the empty one below
	var sea = main.add_tank(3, {"kind": "sea"})
	sea.grow()
	sea.grow()
	sea.fit("pump")
	sea.place("chest")
	for i in 5:
		sea.add_plant()
	for id: String in ["jellyfish", "salmon", "tuna", "shark", "orca", "giant_squid", "blue_whale"]:
		sea.add_fish(id)
	for i in 300:
		sea.step(0.1)
	main.look_at_slot(3)
	await _settle(2.0)
	await _shot("6a_sea_tank")
	for i in sea.fish.size():
		main.call("_select", sea.fish[i])
		await _settle(1.5)
		await _shot("6b_sea_%s" % sea.fish[i].species)
	main.call("_select", null)
	main.look_at_slot(1)
	await _settle(1.5)
	await _shot("6c_empty_shelf")
	# the top of the unit: the covered tank, touched in the light, and then with every lamp out
	main.look_at_slot(5)
	await _settle(2.0)
	main.call("_touch_cover")
	await _settle(0.5)
	await _shot("6h_covered_tank")
	tank.set_lamp(false)
	sea.set_lamp(false)
	await _settle(1.5)
	main.call("_touch_cover")
	await _settle(1.0)
	await _shot("6i_uncovered")
	# and as it is to a keeper who has come back to it often enough
	main.call("_touch_cover")
	Save.data["cave"] = {"found": true, "lifted": 5}
	await _settle(0.5)
	main.call("_touch_cover")
	await _settle(11.0)
	await _shot("6j_olm")
	main.hud.dex.open_notes()
	await _settle(0.5)
	await _shot("6k_notebook")
	main.hud.dex.close()
	tank.set_lamp(true)
	sea.set_lamp(true)
	await _settle(1.0)
	main.look_at_slot(2)
	main.call("_select", tank.fish[4])
	await _settle(1.5)
	await _shot("6d_fresh_close")
	for kind: String in ["betta", "glass_catfish", "hatchetfish", "sparkling_gourami", "kuhli"]:
		if kind == "kuhli":
			tank.set_lamp(false)
			await _settle(6.0)
		for f in tank.fish:
			if f.species == kind:
				main.call("_select", f)
				break
		await _settle(2.0)
		await _shot("6e_%s" % kind)
	# the night watch: the whole tank in the dark, by red torch and then by white
	main.call("_select", null)
	await _settle(1.5)
	tank.shine(Vector3(-0.4, 0.5, tank.depth * 0.5), true)
	await _settle(2.5)
	await _shot("6f_red_torch")
	tank.shine(Vector3(-0.4, 0.5, tank.depth * 0.5), false)
	await _settle(2.5)
	await _shot("6g_white_torch")
	tank.shine(null)
	tank.set_lamp(true)
	main.call("_select", null)
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


## A picture of every kind of home, each stocked with the animals that are sold for it.
func _homes() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	await _settle(0.5)
	for kind: String in Kinds.ORDER:
		if main.tanks[4] != null:
			main.tanks[4].queue_free()
			main.tanks[4] = null
		var t = main.add_tank(4, {"kind": kind})
		t.grow()
		for id: String in Species.ORDER:
			if Species.LIST[id].has("home") and Species.lives_in(id, kind) and int(Species.LIST[id].price) > 0:
				for n in (3 if Species.shoals(id) else 1):
					var f = t.add_fish(id)
					f.buddy.bond = 0.5
		main.look_at_slot(4)
		await _settle(3.5)
		if not t.is_wet():
			# (crickets, for the ones on dry land)
			for f in t.fish:
				f.hunger = 0.2
			for i in 4:
				t.drop_food(-0.6 + 0.4 * i, 0.3)
		await _settle(1.5)
		await _shot("home_%s" % kind)
		if not t.fish.is_empty():
			main.call("_select", t.fish[t.fish.size() - 1])
			await _settle(2.5)
			await _shot("home_%s_close" % kind)
			main.call("_select", null)
	get_tree().quit()
