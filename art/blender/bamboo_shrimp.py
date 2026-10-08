"""Bamboo shrimp (Atyopsis moluccensis), the fan shrimp.

What makes it one: a big, stout, wood-brown shrimp with a pale stripe down its back; and in
place of claws, four fans, like little feather dusters, which it holds up into the current to
catch what drifts by, and wipes across its mouth one at a time.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import shrimp

kit = Kit("bamboo_shrimp")
WOOD, DARK, STRIPE, LEG, FAN = srgb(0.6, 0.36, 0.2), srgb(0.42, 0.24, 0.14), srgb(0.95, 0.86, 0.66), srgb(0.66, 0.42, 0.26), srgb(0.9, 0.78, 0.6)
shrimp(kit, lambda t, k: STRIPE if k in (2, 3) else (DARK if int(t * 14.0) % 2 == 0 else WOOD), LEG, FAN, srgb(0.05, 0.04, 0.04), size=1.3, fans=True)
kit.finish(sys.argv[sys.argv.index("--") + 1])
