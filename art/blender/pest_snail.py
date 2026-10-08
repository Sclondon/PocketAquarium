"""Bladder snail (Physella acuta), the one nobody buys.

What makes it one: tiny; a thin, pointed, see-through shell, brown with gold flecks, that coils
the other way from most snails'; a grey foot; feelers like two threads. It arrives as eggs on a
plant, and there is never only one.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import snail

kit = Kit("pest_snail")
c = srgb(0.5, 0.36, 0.2)
SHELL, FLECK, FLESH = (c[0], c[1], c[2], 0.75), srgb(0.9, 0.72, 0.3), srgb(0.5, 0.5, 0.48)
snail(kit, lambda t, k: FLECK if (int(t * 40.0) + k) % 5 == 0 else SHELL, FLESH, FLESH, srgb(0.05, 0.05, 0.05), round_shell=False, turns=3)
kit.finish(sys.argv[sys.argv.index("--") + 1])
