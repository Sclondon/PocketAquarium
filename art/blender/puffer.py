"""Green spotted puffer (Dichotomyctere nigroviridis).

What makes it one: a round body like a ball with a tail; yellow-green on top, covered in round
black spots, and a plain white belly, with a sharp line between the two; big eyes that roll;
a beak for a mouth; small fins set far back that it hovers on.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("puffer")
GREEN, SPOT, WHITE = srgb(0.78, 0.8, 0.22), srgb(0.08, 0.1, 0.06), srgb(0.98, 0.97, 0.9)
FIN = (0.9, 0.85, 0.5, 0.7)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.15:
        return WHITE
    return SPOT if chance(int(t * 11.0), int(up * 4.0) + side) < 0.34 else GREEN


STATIONS = [(-0.85, 0.1, 0.11, 0.0), (-0.72, 0.26, 0.26, 0.0), (-0.4, 0.4, 0.4, 0.0), (0.05, 0.4, 0.4, 0.0),
            (0.42, 0.22, 0.23, 0.01), (0.65, 0.09, 0.1, 0.02), (0.78, 0.06, 0.08, 0.02)]
plain_fish(kit, STATIONS, skin, FIN, FIN, srgb(0.95, 0.75, 0.3), eye=0.14, eye_at=-0.58, tail=(0.32, 0.0),
           dorsal=(0.25, 0.5, 0.16), anal=(0.3, 0.52, 0.13), pectoral=0.2)
kit.finish(sys.argv[sys.argv.index("--") + 1])
