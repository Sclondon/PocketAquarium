"""Blue poison dart frog (Dendrobates tinctorius "azureus").

What makes it one: small and upright, sitting high on its front legs; the brightest blue there
is, darker on the legs and paler on the sides, with black spots on the back and head, round and
of all sizes; a blunt snout, dark eyes, and toes that end in little pads.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import frog

kit = Kit("dart_frog")
BLUE, PALE, NAVY, BLACK = srgb(0.1, 0.4, 0.95), srgb(0.45, 0.72, 1.0), srgb(0.06, 0.12, 0.5), srgb(0.03, 0.03, 0.06)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.3:
        return PALE
    if up > 0.3 and chance(int(t * 16.0), int(up * 5.0) + side) < 0.28:
        return BLACK
    return BLUE


STATIONS = [(-0.85, 0.12, 0.07, 0.42), (-0.7, 0.26, 0.15, 0.44), (-0.4, 0.3, 0.2, 0.42), (0.0, 0.3, 0.21, 0.36),
            (0.35, 0.22, 0.17, 0.28), (0.55, 0.1, 0.09, 0.24)]
frog(kit, STATIONS, skin, NAVY, PALE, srgb(0.06, 0.05, 0.08), eye=0.09)
kit.finish(sys.argv[sys.argv.index("--") + 1])
