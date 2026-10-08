# Pocket Aquarium

A shelf of small worlds to keep, at night, for the Scareathon arcade: tanks, jars and
terrariums, each a pool of its own light in a dark room, and in them fish, shrimps, snails,
frogs, lizards, a crab and a colony of sea monkeys. Every one of them is somebody: it has a
name, a temper and its own opinion of you. Somebody kept the shelf before you. They left a
notebook, and a tank under a cloth.

The shop takes the arcade's tickets.

Godot **4.7**, GL Compatibility. Open `project.godot` and press F5. It lays itself out for a
wide screen or a tall one.

## Playing

| | Mouse | Touch |
|---|---|---|
| Feed (FEED tool) | Click in the water | Tap in the water |
| Say hello (HAND tool) | Hold on the glass: fish that know you, and curious ones, come to your finger; shy and new ones hide. Move it fast and they bolt | The same |
| Hand feed (FEED tool) | Hold still on the glass: a pinch is held out there, and fish that are used to you take it from your fingers | The same |
| Look in the dark (TORCH tool) | Hold on the glass to shine it in. Pick TORCH again to change it: RED, which the fish cannot see, or WHITE, which sends them into hiding | The same |
| Clear up (NET tool) | Drag through food left on the bottom to take it out before it rots; click a snail you did not ask for to take it out | The same |
| Show them a stranger (MIRROR tool) | Hold on the glass with the lamp on. Bold and grumpy animals square up to it, curious ones and ones that know you come and look, shy ones hide; they lose interest after a quarter of a minute | The same |
| Scrub algae (SCRUB tool) | Drag across the glass | Drag across the glass |
| Tap the glass (SCRUB tool) | Click the glass: nearby fish bolt | Tap the glass |
| Follow a fish | Click it: the camera goes with it, and can come right up to it | Tap it |
| Next fish, or the one before | The < and > buttons on its card | The same |
| Let it go | CLOSE on its card, or click outside the tank | The same |
| Net out a dead fish | Click it | Tap it |
| Turn the tank, or turn about the fish being followed | Drag (anywhere, with FEED) | Drag |
| Zoom | Wheel | Pinch |
| Look at the shelf above or below | UP and DOWN, at the right. Above the top shelf is the covered tank | The same |
| The covered tank | Click it. The cloth comes off only with every lamp out | Tap it |
| Put a tank on an empty shelf | The price buttons on the plate over it | The same |

Along the bottom: FEED, HAND, NET, SCRUB, MIRROR and TORCH pick the tool, LAMP turns the light on and off, WATER changes
the water (once every six hours), SHOP and DEX open their sheets.

The tank keeps real time, like a real one. It goes on while the game is shut: the save holds
the time it was written, and the next visit catches up on the time away (up to 30 days) and
says what happened. A visit is a minute or two: feed them, look at the water, see who is new.

There are five ways to play it, and they all run at once:

- **Company.** Every fish is itself: it has a name (yours to change, on its page), a temper
  (bold, shy, greedy, curious, grumpy or dozy), a part of the tank it likes, and a bond with
  you that grows with visits, meals and time at your finger, and cools if you stay away. The
  bond is never shown as a number: a fish that does not know you keeps its distance, and one
  that does comes to the glass when you arrive, follows your finger and eats from your hand.
  The fish have each other too. Some pairs take to each other and swim together, a few fall
  out, shoaling kinds keep together and sulk alone, and a grumpy one sees the rest off its
  patch. Some kinds have ways of their own: kuhli loaches lie buried till the lamp is off,
  hatchetfish keep to the surface, sparkling gouramis croak. A new game starts with the
  last keeper's fish, which have names already and do not know you.

- **A pet.** Fish want feeding about once a day. A fish is full for half a day after a meal
  and will not eat; a day after, it is hungry; after nearly three days unfed it is starving,
  and three days of that kills it. Fry take a week to grow up. An unwell fish loses its colour.
- **A toy.** Turn the tank, tap the glass, turn the lamp off, dress the gravel.
- **A shelf.** It starts with one blackwater tank on the middle shelf, which was the last
  keeper's. The two shelves above and the two below are empty, and each will take any kind of
  home (see Homes). The homes are kept apart: each has its own water or air, gear and
  ornaments, and the shop sells for the one being looked at. The old sea animals of the first
  game (a blue whale about a metre long, an orca, a shark) are still sold for the night sea.
- **A collection.** Fifty-five kinds of animal: forty-three are sold, each for the homes it can
  live in, eleven old ones can only be bred, and one is not for sale. Breeding is uncommon: a
  home with two well-fed, healthy adults of a kind, good water and room to spare (no more than
  seven tenths full, counting young as grown) lays an egg about every three days, the egg
  takes a day to hatch, and both parents then wait four days. The old pet-shop fish also
  cross with each other (`CROSSES` in `species.gd`), and very rarely one of their eggs hatches
  a Moonfish. The book gives a hint for each kind not yet seen.
- **An ecosystem.** The four gauges are oxygen, how clean the water is, how clear the glass is
  and how much room is left. Fish use oxygen and make waste, a little every day; food nobody
  eats rots into more after ten minutes, so do not overfeed. Plants make oxygen in the light
  and take waste up, the air pump adds oxygen, the filter removes waste, snails graze the
  algae and shrimps eat fallen food. Algae only grows with the lamp on, but so do the plants.
  Two guppies and a plant look after themselves; a fully stocked tank without a filter needs
  its water changed every few days. Water past the red line harms the fish slowly at first
  and quickly at its worst.

## Homes

The shelf has five places, and the top of it a sixth that is taken. An empty place takes any
of twelve kinds of home (`scripts/tank/kinds.gd`), and what is sold for each is listed with it:

| Home | What it is | What has to be kept right |
|---|---|---|
| Blackwater tank | warm, soft, tea-coloured water: most of the odd fish | the water |
| Hard water tank | clear and bright over pale stone | the water |
| Stream tank | cool and fast, with a pump | the water |
| Cold tank | still and chilled: the axolotl | the water |
| Night sea tank | salt water in the dark | the water, and its salt |
| Brine kit | sea monkeys, by the hundred, from a packet | salt, and a pinch of food |
| Snail jar, shrimp jar | small, green and slow | the water |
| Rainforest vivarium | frogs and a gecko, no water | how damp the air is: MIST it |
| Arid terrarium | geckos and a skink under a heat lamp | the lamp left on |
| Paludarium | half water, half mud: a mudskipper and a crab | salt, and damp |

Salt creeps up as water dries off, till the water is changed. Air dries out till it is misted
(the WATER button says MIST over dry land). A new tank's filter takes about four days to come
alive, and until it has, the water fouls three times as fast: the FILTER gauge shows it. An
animal in the wrong home says what is wrong on its card, and sickens slowly, over a week.

Animals get about in their own ways: most swim, snails and the hillstream loach glide over
the floor and up the back wall, shrimps, lizards and the crab walk, frogs and the mudskipper
hop, and the crested gecko climbs. Some keep the night, and are only out with the lamp off.
A horned frog or a mantis shrimp eats what is small enough; a pea puffer eats snails.

Sea monkeys are not kept one by one. A brine kit holds a colony (`scripts/sim/swarm.gd`): the
eggs hatch a day or two after the kit is set up, the young grow up if they are fed, and the
grown ones lay. FEED clouds the water for them.

The snail jar and the shrimp jar are round jars; everything else is a glass box. A plant bought
for fresh water now and then brings bladder snails in with it, which nobody ordered: they
graze the glass, multiply while there is algae, and are what a pea puffer eats.

A pair about to lay courts first, circling, if the keeper is there to see it; and an animal
with eggs waiting stands over them and sees the others off.

## The book

BOOK opens the book: its first half is every kind of animal, filled in as each is kept, and
its second the notebook the last keeper left (`scripts/ui/notes.gd`). The notebook's pages
turn up as the keeper does the thing each is about: feeds by hand, turns the lamps out, uses
the red torch, buys a second tank, touches the cloth.

The covered tank on top of the shelf can be touched at any time and uncovered only with
every lamp out. What is under the cloth comes out from behind its rock for a keeper who has
uncovered it three times, and is named on the fifth.

## Breeding and trading in

Two healthy, well-fed adults of a kind may lay an egg (the old pet-shop fish still cross with
each other; nothing else does). Cherry shrimp are bred for colour: each has a depth of red,
shown on its page (wild brown, cherry, sakura, fire red, painted fire red), and its young take
after their parents, a little deeper or paler by chance. An animal hatched on the shelf can
be traded in from its page for shop credit, more for a deeper red. Credit is spent before
tickets on anything but a new home.

## Tickets

Everything in the shop is priced in the arcade's tickets (`scripts/autoload/tickets.gd`).
Nothing in the game earns them.

The page the cabinet is in owns the balance, and the game talks to it with window messages:

| Direction | Message | When |
|---|---|---|
| game → page | `{ type: 'AQUARIUM_READY' }` | once, when the game has loaded |
| page → game | `{ type: 'TICKETS', balance: 1234 }` | in answer, and whenever the balance changes |
| game → page | `{ type: 'SPEND_TICKETS', amount: 40, item: 'fish:goldfish' }` | on each purchase |
| game → page | `{ type: 'PLAYER_DIED', score: 7 }` | each time a new kind is kept (the score is the number of kinds) |

The game takes the price off its own copy of the balance at once, so the page should answer a
spend with a fresh `TICKETS` message, which always wins. Only messages from the parent window
are listened to. `item` is `fish:<id>`, or one of `plant`, `snail`, `shrimp`, `pump`,
`filter`, `bigger`, `column`, `castle`, `chest`, `skull`, or `tank:fresh` or `tank:sea` for a new tank.

**The arcade page does not send these yet.** Until a `TICKETS` message arrives the game runs
on a practice wallet of 300 tickets kept in its own save, and the plate in the corner reads
PRACTICE TICKETS. Add `?tickets=500` to the address (or run with `-- --tickets=500`) to set it.

## Project layout

| Path | What |
|---|---|
| `scripts/main.gd` | the frame: the 3D picture (as sharp as the window, up to 1600 pixels on its longest side), the shelf's three slots, camera, what a tap or drag does, saving |
| `scripts/tank/tank.gd` | the tank: its meshes, the water, food, eggs, breeding, snails and shrimps |
| `scripts/tank/room.gd` | the room: a shelf unit with a slot for each of three tanks (only the middle one is used yet), the wall, the room's own dim light |
| `scripts/tank/fish.gd` | one fish: swimming, hunger, health, growing |
| `scripts/tank/species.gd` | every kind of animal: what it costs, which homes it lives in (`home`), what it wants there (`wants`), its ways (`habits`: how it gets about, whether it keeps the night, what it eats) and, for the old code-built fish, what it looks like and which pairs make which |
| `scripts/tank/kinds.gd` | every kind of home: its size, water, light and what must be kept right in it |
| `scripts/tank/fish_mesh.gd` | builds an animal's model from its `look`: smooth-skinned fish (and sharks and whales), squid and jellyfish |
| `scripts/tank/models.gd`, `models/`, `art/` | the animals that have a model made in Blender: each is a script in `art/blender/` (they share `fishkit.py`, whose top says what every model must keep to), built by `tools/build_models.sh` into `art/generated/` with a turnaround sheet to look over, and copied to `models/` for the game. A model reworked by hand goes in `art/hand/` and is used instead. Thirty-one animals have one; the old pet-shop fish and the big sea animals are still built in code, by `fish_mesh.gd` |
| `scripts/sim/` | the rules with no pictures attached, so tests can run years of them: the water and its filter (`water.gd`), one animal's hunger, health and growth (`life.gd`), what makes it itself (`buddy.gd`: temper, bond, ties, colour) and a colony of sea monkeys (`swarm.gd`) |
| `scripts/tank/props.gd` | plants, rocks, ornaments, gear and the small things |
| `scripts/ui/` | the HUD, the shop and fish-dex sheets, the flat fish pictures, the UI kit |
| `scripts/autoload/` | the save (`user://aquarium.json`, versioned: an older file is backed up to `aquarium.v1.json` and brought up to date), tickets, and sound effects (synthesized at start) |
| `shaders/` | the cel look: two flat tones of light with a coloured shadow (`water_common.gdshaderinc`), the animals and their swimming (`fish.gdshader`, `swim.gdshaderinc`), the ink line round them (`outline.gdshader`), the sand, the water (the glass with its algae, the far end with its shafts of light, the surface, and the net of light on everything under it), and a vignette over the finished picture |

Adding an animal is one entry in `Species.LIST` (and its id in `ORDER`); give it a `price` to
sell it or a line in `CROSSES` to breed it, and a `water` of "sea" if it lives in salt water.
What its `look` can say is listed at the top of `fish_mesh.gd`. The numbers that set how hard the tank is to keep
are the constants at the top of `sim/life.gd` and `tank.gd` (all in seconds of real time), and the
arithmetic in `sim/water.gd`.

## Tests and builds

```
godot --headless --path . -- --no-save --smoke          # months of tank time for four tanks (fed daily, fully stocked, left alone, salt water); prints how each went
godot --path . -- --no-save --speed=1440                # play with the tank's clock run fast: a day a minute
godot --path . -- --no-save --shots=C:/some/folder      # screenshots of the tanks, the tools at work, each sheet, the covered tank, wide and tall
godot --path . -- --no-save --homes=C:/some/folder      # a screenshot of every kind of home with its animals in it
godot --headless --path . --export-release "Web" build/index.html
```

`--no-save` starts from a new tank and writes nothing, so tests leave the real one alone. The three automated tours (`--smoke`, `--shots=`, `--homes=`) never write the save whether or not it is given.
`--seed=7` (any number) makes everything left to chance fall out the same way each run.

`tools/check.sh` is what to run before a release: it keeps the tanks for months with a fixed
seed and compares how they went with `tests/smoke_seed7.txt`, loads saves from the first game
to see that no fish is lost, and builds the Blender models. If the rules were changed on
purpose, read the difference it prints and then run `tools/check.sh --accept`.

The web build in `build/` is served by GitHub Pages at
<https://sclondon.github.io/PocketAquarium/build/>. In the arcade it is a secret cart, on the
shelf once AQUA has been typed into WaysideOS (`src/pages/Arcade/unlocks.ts` in
scareathon-v3). After pushing a new build, bump the `?v=` cache-buster on
`POCKET_AQUARIUM_URL` in that repo's `src/pages/Arcade/games.tsx` to the new commit and push
that too.
