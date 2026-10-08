"""Whole animals that more than one species is a variation on: a plain fish, a snail, a shrimp, a
frog, a lizard. Each species' script calls one of these with what makes it that species (its
proportions, its colours, what it has that the others do not) and then `kit.finish`.

Everything is in the game's own space, like fishkit.py: x to the animal's left, y up, z from
nose (negative) to tail, about 2 long. An animal that walks stands with its feet at y = 0.
"""
import math

from fishkit import srgb


def one(colour):
    """A colouring that is one colour all over."""
    return lambda *a: colour


def fork_tail(kit, z, y, half, reach, fork, colour_at, n=11, rows=3):
    """A tail fin at the end of a body: `half` is half its root, `reach` how long, `fork` how
    deeply it is cut (0 a fan, 1 nearly to the root)."""
    root, rim = [], []
    for i in range(n):
        u = i / (n - 1)
        a = (0.5 - u) * 2.2
        root.append((0.0, y + math.sin(a) * half, z))
        r = reach * (1.0 - fork * (1.0 - abs(2.0 * u - 1.0)) ** 1.4)
        rim.append((0.0, y + math.sin(a) * r * 1.05, z + math.cos(a) * r))
    kit.fin(root, rim, colour_at, rows=rows, thick=0.02)


def plain_fish(kit, stations, skin, fin, edge, iris, eye=0.07, eye_at=-0.82, tail=(0.45, 0.6), dorsal=(0.0, 0.4, 0.22),
               anal=(0.25, 0.6, 0.16), pectoral=0.2, eyes=True, around=16, rows=31):
    """An ordinary fish: a body, a forked tail, one dorsal and one anal fin, a pair of pectorals
    and a pair of pelvics, and eyes. `dorsal` and `anal` are (where it starts, where it ends,
    how tall); `tail` is (how long, how forked)."""
    kit.body(stations, around, skin, rows=rows)
    web = lambda u, v: edge if v > 0.75 else fin
    z1 = stations[-1][0]
    hw, hh, yc = kit.ring(z1)
    fork_tail(kit, z1 - 0.02, yc, hh * 0.9, tail[0], tail[1], web)
    for which, (a, b, tall) in (("top", dorsal), ("bottom", anal)):
        if tall <= 0.0:
            continue
        root, rim = [], []
        for i in range(6):
            u = i / 5.0
            z = a + (b - a) * u
            if which == "top":
                root.append((0.0, kit.top(z) - 0.02, z))
                rim.append((0.0, kit.top(z) + tall * math.sin(math.pi * (0.2 + 0.7 * u)) ** 0.7, z + 0.12 + 0.1 * u))
            else:
                root.append((0.0, kit.bottom(z) + 0.02, z))
                rim.append((0.0, kit.bottom(z) - tall * math.sin(math.pi * (0.2 + 0.7 * u)) ** 0.7, z + 0.1 + 0.08 * u))
        kit.fin(root, rim, web, rows=3, thick=0.02)
    for sx in (-1.0, 1.0):
        z = eye_at + 0.22
        at = (kit.side(z, sx), kit.ring(z)[2] - kit.ring(z)[1] * 0.2, z)
        root = [(at[0], at[1] + dy, at[2]) for dy in (-0.04, 0.0, 0.04)]
        rim = [(at[0] + sx * pectoral * 0.6, at[1] - pectoral * 0.6, at[2] + pectoral * 0.7),
               (at[0] + sx * pectoral * 0.9, at[1] - pectoral * 0.1, at[2] + pectoral),
               (at[0] + sx * pectoral * 0.6, at[1] + pectoral * 0.3, at[2] + pectoral * 0.8)]
        kit.fin(root, rim, web, rows=2, thick=0.015)
        pz = eye_at + 0.6
        root = [(sx * 0.03, kit.bottom(pz) + 0.02, pz - 0.04), (sx * 0.03, kit.bottom(pz) + 0.02, pz + 0.04)]
        rim = [(sx * 0.1, kit.bottom(pz) - 0.14, pz + 0.1), (sx * 0.1, kit.bottom(pz) - 0.1, pz + 0.18)]
        kit.fin(root, rim, web, rows=2, thick=0.015)
        if eyes:
            ehw, ehh, eyc = kit.ring(eye_at)
            kit.eye((sx * ehw * 0.94, eyc + ehh * 0.25, eye_at), (sx, 0.12, -0.2), eye, iris)


def snail(kit, shell_at, foot, flesh, eye, round_shell=False, turns=3):
    """A snail: a foot, a head with two long feelers and the eyes at their roots, and a shell
    that coils up to a point over its back. `shell_at(t, k)` colours the shell from how far
    round the coil it is (0 the point to 1 the mouth) and which way round the tube."""
    # the foot: long and flat, its sole on the ground
    kit.blob((0.0, 0.1, 0.05), (0.3, 0.1, 0.95), lambda t, up: foot if up < -0.2 else flesh, around=12, rows=8)
    # the head, and its feelers
    kit.blob((0.0, 0.2, -0.85), (0.2, 0.15, 0.22), one(flesh), around=10, rows=6)
    for sx in (-1.0, 1.0):
        kit.tube([(sx * 0.1, 0.26, -0.98), (sx * 0.2, 0.36, -1.3), (sx * 0.24, 0.4, -1.55)], [0.035, 0.025, 0.012], one(flesh), around=5, line=0.5)
        kit.eye((sx * 0.17, 0.3, -0.98), (sx, 0.3, -0.5), 0.035, eye)
    # the shell: a tube that winds outward and down from its point, growing as it goes
    path, radii = [], []
    steps = int(9 * turns)
    squat = 0.55 if round_shell else 0.9
    for i in range(steps + 1):
        t = i / steps
        a = t * turns * 2.0 * math.pi
        r = 0.02 + 0.4 * t ** 1.5
        path.append((-math.sin(a) * r * 0.9, 1.25 * squat - t * 0.75 * squat + 0.15, 0.25 + math.cos(a) * r))
        radii.append(0.05 + 0.42 * t ** 1.3)
    kit.tube(path, radii, shell_at, around=9)


def shrimp(kit, shell_at, legs, feeler, eye, glow=0.0, size=1.0, fans=False):
    """A shrimp: a body in segments that arches and bends under at the tail, a saw-edged beak
    between stalked eyes, two long feelers and two short, five pairs of legs, a fringe of
    swimmerets under the tail, and a tail fan. `fans` gives it fans for hands (a bamboo shrimp)."""
    path, radii = [], []
    for i in range(15):
        t = i / 14.0
        z = -0.75 + 1.6 * t
        y = 0.42 + 0.14 * math.sin(math.pi * min(t / 0.55, 1.0)) - 0.5 * max(t - 0.6, 0.0) ** 1.5
        path.append((0.0, y, z))
        radii.append(size * (0.1 + 0.11 * math.sin(math.pi * (0.12 + 0.6 * t)) - 0.06 * max(t - 0.7, 0.0)))
    kit.tube(path, radii, shell_at, around=10)
    # the beak, between the eyes
    kit.tube([(0.0, 0.5, -0.78), (0.0, 0.56, -1.05), (0.0, 0.6, -1.25)], [0.045, 0.03, 0.008], lambda t, k: shell_at(0.0, k), around=5, line=0.6)
    tail_end = path[-1]
    fan_root = [(sx * 0.05, tail_end[1], tail_end[2]) for sx in (-1.0, -0.5, 0.0, 0.5, 1.0)]
    fan_rim = [(sx * 0.3, tail_end[1] - 0.12, tail_end[2] + 0.28 - abs(sx) * 0.08) for sx in (-1.0, -0.5, 0.0, 0.5, 1.0)]
    kit.fin(fan_root, fan_rim, lambda u, v: shell_at(1.0, 0), rows=2, thick=0.02)
    for sx in (-1.0, 1.0):
        # eyes on short stalks
        kit.tube([(sx * 0.08, 0.5, -0.72), (sx * 0.17, 0.56, -0.8)], [0.03, 0.03], one(legs), around=5, line=0.5)
        kit.eye((sx * 0.19, 0.57, -0.82), (sx, 0.2, -0.3), 0.05, eye)
        # feelers: one long, swept back over the body, and one short
        kit.tube([(sx * 0.06, 0.48, -0.78), (sx * 0.3, 0.7, -1.2), (sx * 0.5, 0.8, -0.4), (sx * 0.55, 0.7, 0.5)],
                 [0.018, 0.014, 0.01, 0.006], one(feeler), around=4, line=0.4)
        kit.tube([(sx * 0.04, 0.46, -0.8), (sx * 0.12, 0.5, -1.15)], [0.014, 0.006], one(feeler), around=4, line=0.4)
        # five pairs of legs, the front ones reaching forward
        for k in range(5):
            z = -0.5 + k * 0.17
            reach = -0.22 if k < 2 else 0.05 * (k - 2)
            foot = (sx * 0.24, 0.0, z + reach)
            kit.tube([(sx * 0.07, 0.33, z), (sx * 0.2, 0.2, z + reach * 0.5), foot], [0.022, 0.016, 0.008], one(legs), around=4, line=0.4)
            if fans and k < 2:
                root = [(foot[0], foot[1] + 0.02, foot[2] - 0.01), (foot[0], foot[1] + 0.02, foot[2] + 0.01)]
                rim = [(foot[0] + sx * 0.1, 0.2, foot[2] - 0.18), (foot[0] + sx * 0.16, 0.08, foot[2] - 0.2)]
                kit.fin(root, rim, one(feeler), rows=2, thick=0.012, line=0.4)
        # swimmerets, under the tail
        for k in range(4):
            z = 0.3 + k * 0.13
            y = path[9 + k][1] - radii[9 + k]
            kit.tube([(sx * 0.05, y, z), (sx * 0.08, y - 0.12, z + 0.05)], [0.02, 0.008], one(legs), around=4, line=0.4)


def leg(kit, hip, knee, foot, thick, colour, toes=3, toe_colour=None, spread=0.09):
    """A leg from `hip` by way of `knee` to a `foot` on the ground, with toes."""
    kit.tube([hip, knee, foot], [thick, thick * 0.75, thick * 0.55], one(colour), around=6, line=0.7)
    sx = 1.0 if foot[0] >= 0.0 else -1.0
    for k in range(toes):
        a = (k - (toes - 1) / 2.0) * 0.55
        tip = (foot[0] + sx * math.cos(a) * spread * 0.6 + 0.0, 0.015, foot[2] - math.cos(a) * spread + sx * 0.0 + math.sin(a) * spread * sx)
        kit.tube([foot, tip], [thick * 0.4, thick * 0.3], one(toe_colour or colour), around=4, line=0.5)


def frog(kit, stations, skin, limb, toe, iris, eye=0.11, eye_z=-0.55, wide=1.0, around=14):
    """A frog, sitting: a squat body with no neck, eyes that stand up out of the top of its
    head, short arms and long legs folded under it."""
    kit.body(stations, around, skin, rows=21, squareness=2.0)
    ehw, ehh, eyc = kit.ring(eye_z)
    for sx in (-1.0, 1.0):
        at = (sx * ehw * 0.62, eyc + ehh * 0.92, eye_z)
        kit.blob(at, (eye * 1.15, eye * 1.1, eye * 1.2), lambda t, up: skin(0.3, 1.0, sx), around=8, rows=5)
        kit.eye((at[0] + sx * eye * 0.75, at[1] + eye * 0.25, at[2] - eye * 0.2), (sx, 0.35, -0.35), eye * 0.8, iris)
        # an arm: down and forward, the hand turned in
        sz = eye_z + 0.3
        shw, shh, syc = kit.ring(sz)
        leg(kit, (sx * shw * 0.8, syc - shh * 0.3, sz), (sx * (shw + 0.16 * wide), 0.16, sz - 0.05), (sx * (shw + 0.1 * wide), 0.02, sz - 0.3),
            0.06, limb, toes=4, toe_colour=toe)
        # a leg: thigh forward along the body, shin back, and a long foot forward again
        hz = stations[-1][0] - 0.35
        hhw, hhh, hyc = kit.ring(hz)
        knee = (sx * (hhw + 0.26 * wide), 0.24, hz - 0.5)
        ankle = (sx * (hhw + 0.3 * wide), 0.06, hz + 0.1)
        kit.tube([(sx * hhw * 0.8, hyc, hz), knee], [0.11, 0.08], one(limb), around=6, line=0.8)
        kit.tube([knee, ankle], [0.075, 0.05], one(limb), around=6, line=0.7)
        leg(kit, ankle, (ankle[0] + sx * 0.03, 0.04, ankle[2] - 0.2), (ankle[0] + sx * 0.06, 0.02, ankle[2] - 0.42), 0.045, limb, toes=4,
            toe_colour=toe, spread=0.13)


def lizard(kit, stations, skin, limb, toe, iris, eye=0.07, eye_z=-0.95, shoulders=-0.55, hips=0.15, reach=0.34, around=12, rows=41,
           pupil_slit=True):
    """A lizard: head, body and tail all of a piece, low to the ground, with four legs out to
    the sides and five toes on each."""
    kit.body(stations, around, skin, rows=rows, squareness=2.0)
    ehw, ehh, eyc = kit.ring(eye_z)
    for sx in (-1.0, 1.0):
        kit.eye((sx * ehw * 0.9, eyc + ehh * 0.45, eye_z), (sx, 0.3, -0.2), eye, iris)
        for z, fwd in ((shoulders, -0.14), (hips, 0.1)):
            hw, hh, yc = kit.ring(z)
            elbow = (sx * (hw + reach * 0.55), yc + 0.02, z + fwd * 0.4)
            foot = (sx * (hw + reach), 0.02, z + fwd)
            leg(kit, (sx * hw * 0.8, yc - hh * 0.2, z), elbow, foot, 0.06, limb, toes=5, toe_colour=toe, spread=0.1)
