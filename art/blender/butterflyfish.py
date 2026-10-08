"""African butterflyfish (Pantodon buchholzi).

What makes it one: it lives pressed up against the surface, flat-backed, looking like a dead
leaf; pectoral fins like a butterfly's wings, wide, held out flat to the sides, brown with dark
bars; pelvic fins that are long trailing threads, four a side, hanging under it like roots; a
big mouth that opens upward; mottled brown and tan, with a dark band through the eye.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import fork_tail

kit = Kit("butterflyfish")
BROWN, TAN, DARK, BELLY = srgb(0.42, 0.3, 0.18), srgb(0.72, 0.6, 0.4), srgb(0.16, 0.11, 0.08), srgb(0.86, 0.8, 0.64)
TOP = 0.14


def skin(t, up, side):
    if up < -0.4:
        return BELLY
    if 0.1 < t < 0.16:
        return DARK
    return BROWN if math.sin(t * 19.0 + up * 4.0) > 0.0 else TAN


def station(z, hw, hh):
    return (z, hw, hh, TOP - hh)


STATIONS = [station(-0.95, 0.07, 0.04), station(-0.85, 0.14, 0.11), station(-0.5, 0.18, 0.2), station(-0.1, 0.17, 0.21),
            station(0.3, 0.12, 0.16), station(0.6, 0.06, 0.09), station(0.78, 0.035, 0.06)]
kit.body(STATIONS, 14, skin, rows=29, squareness=2.4)
web = lambda u, v: DARK if int(u * 7.0) % 2 == 0 else TAN
fork_tail(kit, 0.76, TOP - 0.06, 0.05, 0.5, 0.0, web, rows=4)
# small dorsal and anal fins, far back
kit.fin([(0.0, TOP - 0.02, z) for z in (0.35, 0.45, 0.55)], [(0.0, TOP + 0.12, 0.45), (0.0, TOP + 0.16, 0.58), (0.0, TOP + 0.03, 0.62)], web, rows=2, thick=0.02)
root = [(0.0, kit.bottom(z) + 0.02, z) for z in (0.1, 0.25, 0.4, 0.55)]
rim = [(0.0, kit.bottom(0.1) - 0.14, 0.2), (0.0, kit.bottom(0.25) - 0.2, 0.38), (0.0, kit.bottom(0.4) - 0.16, 0.54), (0.0, kit.bottom(0.55) - 0.04, 0.62)]
kit.fin(root, rim, web, rows=2, thick=0.02)
for sx in (-1.0, 1.0):
    # a wing: wide and flat, out to the side from behind the head
    root, rim = [], []
    for i in range(7):
        u = i / 6.0
        z = -0.7 + 0.3 * u
        root.append((sx * kit.ring(z)[0] * 0.85, TOP - 0.07, z))
        a = (u - 0.2) * 2.4
        rim.append((sx * (kit.ring(z)[0] + 0.62 * math.cos(a * 0.7)), TOP - 0.04, z + 0.25 + 0.5 * math.sin(a)))
    kit.fin(root, rim, web, rows=4, thick=0.02)
    # the pelvic threads
    for k in range(4):
        base = (sx * 0.06, kit.bottom(-0.3) + 0.02, -0.34 + k * 0.04)
        root = [(base[0], base[1], base[2] - 0.008), (base[0], base[1], base[2] + 0.008)]
        rim = [(base[0] + sx * (0.04 + 0.05 * k), base[1] - 0.5, base[2] + 0.15 + 0.08 * k), (base[0] + sx * (0.04 + 0.05 * k), base[1] - 0.5, base[2] + 0.16 + 0.08 * k)]
        kit.fin(root, rim, lambda u, v: TAN, rows=3, thick=0.012, line=0.35)
    kit.eye((kit.side(-0.82, sx, 0.95), TOP - 0.07, -0.82), (sx, 0.3, -0.2), 0.06, srgb(0.85, 0.7, 0.35))
kit.finish(sys.argv[sys.argv.index("--") + 1])
