"""Peacock mantis shrimp (Odontodactylus scyllarus).

What makes it one: every colour at once: a green body, banded, with orange legs, blue and red
feelers flattened like paddles, and leopard spots on the front of the shell; eyes on stalks
that turn one at a time, pink-purple; and two clubs folded under the head, which it punches
with, fast enough to break a snail's shell or a thumb.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one, shrimp

kit = Kit("mantis_shrimp")
GREEN, BAND, ORANGE, BLUE, CLUB = srgb(0.15, 0.6, 0.3), srgb(0.08, 0.32, 0.2), srgb(0.95, 0.45, 0.1), srgb(0.2, 0.5, 0.95), srgb(0.9, 0.2, 0.15)


def shell(t, k):
    if t < 0.25 and k % 3 == 0:
        return ORANGE
    return BAND if int(t * 12.0) % 2 == 0 else GREEN


shrimp(kit, shell, ORANGE, BLUE, srgb(0.8, 0.4, 0.8), size=1.35)
# the clubs: folded under the head, the elbows out
for sx in (-1.0, 1.0):
    kit.tube([(sx * 0.1, 0.32, -0.6), (sx * 0.22, 0.18, -0.4), (sx * 0.2, 0.14, -0.72)], [0.06, 0.055, 0.075], one(CLUB), around=6, line=0.7)
kit.finish(sys.argv[sys.argv.index("--") + 1])
