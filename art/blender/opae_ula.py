"""Opae ula (Halocaridina rubra), the red shrimp of Hawaiian lava pools.

What makes it one: tiny, and red all over, from pale pink to deep blood red by the animal and
its mood, the colour even and a little see-through with no banding; dark eyes set close; short
feelers; a slim body with hardly any hump to its back. It swims as much as it walks.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import shrimp

kit = Kit("opae_ula")
RED, PALE, LEG = srgb(0.9, 0.16, 0.1), srgb(1.0, 0.5, 0.4), srgb(0.95, 0.35, 0.25)
# (round the tube: 2 and 3 are the top of its back; underneath it is paler, and you can see in)
shrimp(kit, lambda t, k: RED if k in (1, 2, 3, 4) else PALE, LEG, LEG, srgb(0.05, 0.03, 0.03))
kit.finish(sys.argv[sys.argv.index("--") + 1])
