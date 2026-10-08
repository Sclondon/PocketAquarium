"""Crested gecko (Correlophus ciliatus).

What makes it one: a fringe of soft spines like eyelashes over each eye, running on down the
neck and back in two rows (it is what "crested" means); a wide flat wedge of a head; big eyes
with no lids, and a slit pupil; broad toes with sticky pads, so it climbs anything; orange and
tan, paler along the back between the crests; a tail it can hold on with.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import lizard

kit = Kit("crested_gecko")
ORANGE, TAN, CREAM, BELLY, CREST = srgb(0.86, 0.46, 0.16), srgb(0.7, 0.42, 0.22), srgb(0.96, 0.82, 0.56), srgb(0.95, 0.88, 0.72), srgb(0.98, 0.9, 0.7)


def skin(t, up, side):
    if up < -0.4:
        return BELLY
    if up > 0.8:
        return CREAM
    return TAN if int(t * 18.0) % 4 == 0 else ORANGE


STATIONS = [(-1.2, 0.07, 0.04, 0.22), (-1.05, 0.24, 0.09, 0.24), (-0.85, 0.27, 0.12, 0.25), (-0.65, 0.13, 0.09, 0.23),
            (-0.3, 0.19, 0.12, 0.21), (0.1, 0.2, 0.12, 0.2), (0.4, 0.11, 0.08, 0.19), (0.8, 0.07, 0.06, 0.16), (1.25, 0.03, 0.03, 0.2)]
lizard(kit, STATIONS, skin, ORANGE, CREAM, srgb(0.8, 0.6, 0.3), eye=0.1, eye_z=-0.95, shoulders=-0.5, hips=0.15, reach=0.36)
# the crests: a row of small spines over each eye and on down each side of the back
for sx in (-1.0, 1.0):
    root, rim = [], []
    for i in range(12):
        z = -1.05 + i * 0.12
        hw, hh, yc = kit.ring(z)
        root.append((sx * hw * 0.72, yc + hh * 0.75, z))
        rim.append((sx * (hw * 0.72 + 0.06), yc + hh * 0.75 + (0.09 if i % 2 == 0 else 0.03) * (1.4 if i < 3 else 1.0), z + 0.02))
    kit.fin(root, rim, lambda u, v: CREST, rows=1, thick=0.02, line=0.5)
kit.finish(sys.argv[sys.argv.index("--") + 1])
