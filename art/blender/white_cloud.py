"""White Cloud Mountain minnow (Tanichthys albonubes).

What makes it one: a small slim minnow; a bright line from eye to tail, pale gold over a dark
one; a red patch at the root of the tail and red in the dorsal and anal fins, which are tipped
white; dorsal and anal fins set far back, opposite each other; a forked tail.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("white_cloud")
BACK, LINE, DARK, BELLY = srgb(0.42, 0.40, 0.24), srgb(0.98, 0.92, 0.62), srgb(0.14, 0.16, 0.2), srgb(0.9, 0.9, 0.86)
RED, WHITE = srgb(0.86, 0.16, 0.12), srgb(0.98, 0.98, 0.95)


def skin(t, up, side):
    if t > 0.88 and abs(up) < 0.6:
        return RED
    if up > 0.6:
        return BACK
    if 0.5 < up <= 0.6:
        return LINE
    if 0.1 < up <= 0.3 and t > 0.1:
        return DARK
    return BELLY


STATIONS = [(-1.0, 0.03, 0.04, 0.02), (-0.9, 0.08, 0.1, 0.01), (-0.6, 0.13, 0.18, 0.0), (-0.2, 0.14, 0.2, 0.0),
            (0.3, 0.1, 0.16, 0.0), (0.65, 0.06, 0.11, 0.0), (0.85, 0.035, 0.09, 0.0)]
plain_fish(kit, STATIONS, skin, RED, WHITE, srgb(0.9, 0.85, 0.6), eye=0.06, eye_at=-0.85, tail=(0.4, 0.65),
           dorsal=(0.15, 0.45, 0.24), anal=(0.2, 0.5, 0.2), pectoral=0.16)
kit.finish(sys.argv[sys.argv.index("--") + 1])
