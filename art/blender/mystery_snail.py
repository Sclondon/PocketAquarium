"""Mystery snail (Pomacea bridgesii), the gold one.

What makes it one: a round shell as big as a walnut, with a low point and a few fat whorls,
plain gold; a cream foot freckled with orange; two very long feelers, and a breathing tube it
puts up to the surface.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one, snail

kit = Kit("mystery_snail")
GOLD, DEEP, FLESH, SOLE = srgb(0.96, 0.74, 0.18), srgb(0.82, 0.52, 0.1), srgb(0.98, 0.9, 0.72), srgb(0.9, 0.78, 0.55)
# (the shell darkens into the groove between one whorl and the next)
snail(kit, lambda t, k: DEEP if k in (4, 5) else GOLD, SOLE, FLESH, srgb(0.1, 0.1, 0.1), round_shell=True, turns=2.5)
# the breathing tube, up from the left of the head
kit.tube([(0.14, 0.26, -0.8), (0.24, 0.5, -0.95), (0.26, 0.78, -1.0)], [0.04, 0.035, 0.03], one(FLESH), around=5, line=0.5)
kit.finish(sys.argv[sys.argv.index("--") + 1])
