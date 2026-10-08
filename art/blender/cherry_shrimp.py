"""Cherry shrimp (Neocaridina davidi), a red one.

What makes it one: a small shrimp, red all over, the red solid along the back and thinner on
the sides where you can nearly see into it, with a pale stripe down the back on some; dark
eyes; legs and feelers red too. (How deep the red is varies from one to the next: the game
turns it up and down. See the grade in fish.gdshader.)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import shrimp

kit = Kit("cherry_shrimp")
RED, THIN, LEG = srgb(0.86, 0.1, 0.08), srgb(0.95, 0.4, 0.3), srgb(0.9, 0.3, 0.22)
# (round the tube: 2 and 3 are the top of its back)
shrimp(kit, lambda t, k: RED if k in (1, 2, 3, 4) or int(t * 14.0) % 2 == 0 else THIN, LEG, LEG, srgb(0.05, 0.03, 0.03))
kit.finish(sys.argv[sys.argv.index("--") + 1])
