# Pocket Aquarium

A small low-poly fish tank to keep, for the Scareathon arcade. Feed the fish, keep the water
alive, breed new kinds and fill the fish-dex. The shop takes the arcade's tickets.

Godot **4.7**, GL Compatibility. Open `project.godot` and press F5. It lays itself out for a
wide screen or a tall one.

## Playing

| | Mouse | Touch |
|---|---|---|
| Feed (FEED tool) | Click in the water | Tap in the water |
| Scrub algae (SCRUB tool) | Drag across the glass | Drag across the glass |
| Tap the glass (SCRUB tool) | Click the glass: nearby fish bolt | Tap the glass |
| Follow a fish | Click it: the camera goes with it, and can come right up to it | Tap it |
| Next fish, or the one before | The < and > buttons on its card | The same |
| Let it go | CLOSE on its card, or click outside the tank | The same |
| Net out a dead fish | Click it | Tap it |
| Turn the tank, or turn about the fish being followed | Drag (anywhere, with FEED) | Drag |
| Zoom | Wheel | Pinch |

Along the bottom: FEED and SCRUB pick the tool, LAMP turns the light on and off, WATER changes
the water (once every six hours), SHOP and DEX open their sheets.

The tank keeps real time, like a real one. It goes on while the game is shut: the save holds
the time it was written, and the next visit catches up on the time away (up to 30 days) and
says what happened. A visit is a minute or two: feed them, look at the water, see who is new.

There are four ways to play it, and they all run at once:

- **A pet.** Fish want feeding about once a day. A fish is full for half a day after a meal
  and will not eat; a day after, it is hungry; after nearly three days unfed it is starving,
  and three days of that kills it. Fry take a week to grow up. An unwell fish loses its colour.
- **A toy.** Turn the tank, tap the glass, turn the lamp off, dress the gravel.
- **A collection.** Seven kinds of fish are sold. Eleven more can only be bred, and breeding
  is uncommon: a tank with two well-fed, healthy adults, good water and room to spare (no more
  than seven tenths full, counting fry as grown) lays an egg about every three days, the egg
  takes a day to hatch, and both parents then wait four days. Two of the same kind have another; the right two different kinds have something new
  (`CROSSES` in `species.gd`), and very rarely any egg hatches a Moonfish. The fish-dex gives a
  hint for each kind not yet seen.
- **An ecosystem.** The four gauges are oxygen, how clean the water is, how clear the glass is
  and how much room is left. Fish use oxygen and make waste, a little every day; food nobody
  eats rots into more after ten minutes, so do not overfeed. Plants make oxygen in the light
  and take waste up, the air pump adds oxygen, the filter removes waste, snails graze the
  algae and shrimps eat fallen food. Algae only grows with the lamp on, but so do the plants.
  Two guppies and a plant look after themselves; a fully stocked tank without a filter needs
  its water changed every few days. Water past the red line harms the fish slowly at first
  and quickly at its worst.

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
`filter`, `bigger`, `column`, `castle`, `chest`, `skull`.

**The arcade page does not send these yet.** Until a `TICKETS` message arrives the game runs
on a practice wallet of 300 tickets kept in its own save, and the plate in the corner reads
PRACTICE TICKETS. Add `?tickets=500` to the address (or run with `-- --tickets=500`) to set it.

## Project layout

| Path | What |
|---|---|
| `scripts/main.gd` | the frame: low-res render target, camera, what a tap or drag does, saving |
| `scripts/tank/tank.gd` | the tank: its meshes, the water, food, eggs, breeding, snails and shrimps |
| `scripts/tank/room.gd` | the room: a shelf unit with a slot for each of three tanks (only the middle one is used yet), the wall, the room's own dim light |
| `scripts/tank/fish.gd` | one fish: swimming, hunger, health, growing |
| `scripts/tank/species.gd` | every kind of fish, what each looks like and which pairs make which |
| `scripts/tank/fish_mesh.gd` | builds a fish's model from its `look` |
| `scripts/tank/props.gd` | plants, rocks, ornaments, gear and the small things |
| `scripts/ui/` | the HUD, the shop and fish-dex sheets, the flat fish pictures, the UI kit |
| `scripts/autoload/` | the save (`user://aquarium.json`), tickets, and sound effects (synthesized at start) |
| `shaders/` | PS1 vertex snap, fish wag, the water (the glass with its algae, the far end with its shafts of light, the surface, and the net of light on everything under it), dither post-process |

Adding a fish is one entry in `Species.LIST` (and its id in `ORDER`); give it a `price` to
sell it or a line in `CROSSES` to breed it. The numbers that set how hard the tank is to keep
are the constants at the top of `fish.gd` and `tank.gd` (all in seconds of real time), and the
arithmetic in `Tank._step_water`.

## Tests and builds

```
godot --headless --path . -- --no-save --smoke          # months of tank time for three tanks (fed daily, fully stocked, left alone); prints how each went
godot --path . -- --no-save --speed=1440                # play with the tank's clock run fast: a day a minute
godot --path . -- --no-save --shots=C:/some/folder      # screenshots of the tank and each sheet, wide and tall
godot --headless --path . --export-release "Web" build/index.html
```

`--no-save` starts from a new tank and writes nothing, so tests leave the real one alone.

The web build in `build/` is served by GitHub Pages at
<https://sclondon.github.io/PocketAquarium/build/>. In the arcade it is a secret cart, on the
shelf once AQUA has been typed into WaysideOS (`src/pages/Arcade/unlocks.ts` in
scareathon-v3). After pushing a new build, bump the `?v=` cache-buster on
`POCKET_AQUARIUM_URL` in that repo's `src/pages/Arcade/games.tsx` to the new commit and push
that too.
