"""Zebra nerite snail (Neritina natalensis).

What makes it one: a shell like half a marble, low and smooth with almost no point to it; gold,
with black stripes that run from the point to the lip and waver as they go; a small dark foot
that it hardly ever shows more than the edge of.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import snail

kit = Kit("nerite")
GOLD, BLACK, FLESH = srgb(0.9, 0.66, 0.16), srgb(0.08, 0.07, 0.06), srgb(0.3, 0.26, 0.22)
snail(kit, lambda t, k: BLACK if math.sin(t * 60.0 + k * 0.5) > 0.2 else GOLD, FLESH, FLESH, srgb(0.05, 0.05, 0.05), round_shell=True, turns=1.6)
kit.finish(sys.argv[sys.argv.index("--") + 1])
