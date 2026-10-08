"""Hillstream loach (Sewellia lineolata).

What makes it one: flat as a leaf underneath, to grip rock in a torrent; seen from above it is
nearly a disc, because its pectoral and pelvic fins are spread flat to the sides and overlap
into one sucker; a small head with the eyes on top; brown, marked all over with fine pale
lines and spots; a short tail.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import fork_tail

kit = Kit("hillstream_loach")
BROWN, PALE, BELLY, FIN = srgb(0.3, 0.22, 0.14), srgb(0.86, 0.76, 0.5), srgb(0.9, 0.86, 0.74), srgb(0.5, 0.4, 0.26)


def skin(t, up, side):
    if up < -0.3:
        return BELLY
    # fine wavy lines along the back, and spots lower down
    return PALE if math.sin(t * 40.0 + up * 9.0) > 0.55 else BROWN


# low and broad: its belly is flat on the ground at y = 0
STATIONS = [(-0.95, 0.06, 0.03, 0.04), (-0.8, 0.2, 0.08, 0.08), (-0.45, 0.3, 0.12, 0.12), (0.0, 0.26, 0.12, 0.12),
            (0.45, 0.14, 0.09, 0.1), (0.75, 0.06, 0.07, 0.09), (0.9, 0.035, 0.06, 0.09)]
kit.body(STATIONS, 14, skin, rows=29, squareness=2.6)
web = lambda u, v: PALE if (int(u * 9.0) % 2 == 0 and v > 0.3) or v > 0.85 else FIN
fork_tail(kit, 0.88, 0.09, 0.05, 0.3, 0.25, web)
for sx in (-1.0, 1.0):
    # the pectoral fin: a wide fan flat on the ground, from under the head back along the side
    root, rim = [], []
    for i in range(7):
        u = i / 6.0
        z = -0.75 + 0.55 * u
        root.append((sx * kit.ring(z)[0] * 0.8, 0.03, z))
        a = (u - 0.25) * 2.0
        rim.append((sx * (kit.ring(z)[0] + 0.34 * math.cos(a * 0.9)), 0.012, z + 0.3 * math.sin(a)))
    kit.fin(root, rim, web, rows=3, thick=0.02)
    # the pelvic fin, the same again behind it, overlapping
    root, rim = [], []
    for i in range(5):
        u = i / 4.0
        z = -0.1 + 0.4 * u
        root.append((sx * kit.ring(z)[0] * 0.8, 0.03, z))
        a = (u - 0.3) * 2.0
        rim.append((sx * (kit.ring(z)[0] + 0.26 * math.cos(a * 0.9)), 0.012, z + 0.22 * math.sin(a)))
    kit.fin(root, rim, web, rows=3, thick=0.02)
    kit.eye((sx * 0.13, 0.17, -0.72), (sx * 0.5, 1.0, -0.1), 0.045, srgb(0.85, 0.7, 0.35))
# the dorsal fin, small, in the middle of the back
kit.fin([(0.0, kit.top(z) - 0.01, z) for z in (0.0, 0.1, 0.2)], [(0.0, kit.top(0.05) + 0.1, 0.1), (0.0, kit.top(0.1) + 0.13, 0.24), (0.0, kit.top(0.2) + 0.03, 0.3)],
        web, rows=2, thick=0.015)
kit.finish(sys.argv[sys.argv.index("--") + 1])
