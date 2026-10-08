"""What every animal's Blender script builds with: a lofted body, fins that are thin closed
solids, domed eyes, flat colour by face, and the export and turnaround sheet at the end.

A model is described in the game's own space, so the numbers in a species script read the same
as the ones in the shaders: x to the animal's left, y up, z from nose (negative) to tail, the
body about 2 long. `Kit.finish` turns that into Blender's space and exports it.

The model contract (README, "Models"):
  nose at -Z, up +Y, body about 2 units long
  one colour layer, linear, flat by face, with borders along mesh edges
  first UV: x runs nose to tail (or fin root to tip); y says what it is part of:
            0 to 1 skin (back to belly), 2 a fin, 3 an eye
  second UV: x how wide the ink line is there (1 body, less on fins), y how much it glows
  smooth normals everywhere; fins have thickness, so the outline can go round them
"""
import math
import sys

import bmesh
import bpy
from mathutils import Vector

BLENDER = (4, 3)


def srgb(r, g, b):
    """A colour as picked on a screen, as the linear one the mesh stores."""
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b), 1.0)


def spline(points, t):
    """A smooth curve through `points` (numbers or tuples of numbers), t from 0 to 1."""
    n = len(points) - 1
    x = min(max(t, 0.0), 1.0) * n
    i = min(int(x), n - 1)
    f = x - i
    p0, p1, p2, p3 = points[max(i - 1, 0)], points[i], points[i + 1], points[min(i + 2, n)]

    def one(a, b, c, d):
        return 0.5 * ((2 * b) + (c - a) * f + (2 * a - 5 * b + 4 * c - d) * f * f + (3 * b - a - 3 * c + d) * f ** 3)
    if isinstance(p1, (int, float)):
        return one(p0, p1, p2, p3)
    return tuple(one(p0[k], p1[k], p2[k], p3[k]) for k in range(len(p1)))


class Kit:
    def __init__(self, name):
        if bpy.app.version[:2] != BLENDER:
            sys.exit("fishkit: these scripts are written for Blender %d.%d, and this is %s" % (BLENDER + (bpy.app.version_string,)))
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.name = name
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.float_color.new("Col")
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.data = self.bm.loops.layers.uv.new("data")

    # ------------------------------------------------------------------ pieces

    def vert(self, at):
        return self.bm.verts.new(Vector(at))

    def face(self, verts, out, colour, uvs, line=1.0, glow=0.0):
        """A face of `verts` facing `out`, one flat colour, with a first-UV for each corner."""
        a, b, c = verts[0].co, verts[1].co, verts[2].co
        if (b - a).cross(c - a).dot(Vector(out)) < 0.0:
            verts = list(reversed(verts))
            uvs = list(reversed(uvs))
        try:
            f = self.bm.faces.new(verts)
        except ValueError:
            return None
        f.smooth = True
        # (a colour may carry a fifth number: how much that face glows)
        if len(colour) == 5:
            glow = colour[4]
            colour = colour[:4]
        for loop, uv in zip(f.loops, uvs):
            loop[self.col] = colour
            # (glTF counts a UV's second number from the top, so the exporter turns it over)
            loop[self.uv].uv = (uv[0], 1.0 - uv[1])
            loop[self.data].uv = (line, 1.0 - glow)
        return f

    def body(self, stations, around, colour_at, rows=28, squareness=2.2):
        """The body: rings of `around` points, lofted through `stations`, each
        (z, half-width, half-height, y-centre). `colour_at(t, up, side)` gives a face's colour
        from how far along it is (0 nose to 1 tail), how high (1 back to -1 belly) and which
        side (-1 or 1). Returns `ring(z)`, the (half-width, half-height, y-centre) at any z."""
        z0, z1 = stations[0][0], stations[-1][0]

        def ring(z):
            t = (z - z0) / (z1 - z0)
            # (stations are not evenly spaced, so find the span first)
            for k in range(len(stations) - 1):
                if stations[k][0] <= z <= stations[k + 1][0]:
                    f = (z - stations[k][0]) / (stations[k + 1][0] - stations[k][0])
                    t = (k + f) / (len(stations) - 1)
                    break
            p = spline(stations, t)
            return p[1], p[2], p[3]

        grid = []
        for r in range(rows):
            z = z0 + (z1 - z0) * r / (rows - 1)
            hw, hh, yc = ring(z)
            row = []
            for i in range(around):
                a = 2 * math.pi * i / around
                # a rounded box more than an ellipse: flat-sided, as most fish are
                cx, cy = math.sin(a), math.cos(a)
                e = 2.0 / squareness
                x = math.copysign(abs(cx) ** e, cx) * hw
                y = math.copysign(abs(cy) ** e, cy) * hh
                row.append(self.vert((x, yc + y, z)))
            grid.append(row)
        for r in range(rows - 1):
            t = (r + 0.5) / (rows - 1)
            for i in range(around):
                j = (i + 1) % around
                a = 2 * math.pi * (i + 0.5) / around
                up = math.cos(a)
                quad = [grid[r][i], grid[r][j], grid[r + 1][j], grid[r + 1][i]]
                v = (1.0 - up) * 0.5
                uvs = [(r / (rows - 1), v), (r / (rows - 1), v), ((r + 1) / (rows - 1), v), ((r + 1) / (rows - 1), v)]
                self.face(quad, (math.sin(a), up, 0.0), colour_at(t, up, 1 if math.sin(a) > 0 else -1), uvs)
        hw, hh, yc = ring(z0)
        nose = self.vert((0.0, yc, z0 - hw * 0.9))
        hw, hh, yc = ring(z1)
        stump = self.vert((0.0, yc, z1 + 0.02))
        for i in range(around):
            j = (i + 1) % around
            up = math.cos(2 * math.pi * (i + 0.5) / around)
            self.face([nose, grid[0][i], grid[0][j]], (0, 0, -1), colour_at(0.0, up, 1), [(0, 0.5)] * 3)
            self.face([stump, grid[-1][i], grid[-1][j]], (0, 0, 1), colour_at(1.0, up, 1), [(1, 0.5)] * 3)
        self.ring = ring
        return ring

    def top(self, z):
        """How high the back is at z."""
        hw, hh, yc = self.ring(z)
        return yc + hh

    def bottom(self, z):
        """How low the belly is at z."""
        hw, hh, yc = self.ring(z)
        return yc - hh

    def side(self, z, sx, inset=0.93):
        """How far out the flank is at z, on the side sx (-1 or 1)."""
        hw, hh, yc = self.ring(z)
        return sx * hw * inset


    def tube(self, path, radii, colour_at, around=8, part=0.5, line=1.0, flat=1.0):
        """A round limb through the points of `path`, with a radius at each: a leg, a feeler, a
        tail, a body that bends. `colour_at(t, k)` gives a face's colour from how far along it
        is (0 to 1) and which way round (0 to `around`). `flat` squashes it top to bottom. Both
        ends are closed."""
        pts = [Vector(p) for p in path]
        rings = []
        ref = Vector((0.0, 1.0, 0.0))
        for k, p in enumerate(pts):
            along = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]).normalized()
            up = ref - along * ref.dot(along)
            if up.length < 0.05:
                up = Vector((1.0, 0.0, 0.0)) - along * along.x
            up.normalize()
            ref = up
            side = along.cross(up).normalized()
            ring = []
            for i in range(around):
                a = 2 * math.pi * i / around
                ring.append(self.vert(p + (side * math.cos(a) + up * math.sin(a) * flat) * radii[k]))
            rings.append(ring)
        n = len(pts) - 1
        for k in range(n):
            mid = (pts[k] + pts[k + 1]) * 0.5
            for i in range(around):
                j = (i + 1) % around
                quad = [rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]]
                out = (rings[k][i].co + rings[k][j].co) * 0.5 - pts[k]
                uvs = [(k / n, part)] * 2 + [((k + 1) / n, part)] * 2
                self.face(quad, out, colour_at((k + 0.5) / n, i), uvs, line)
        for end, ring, t in ((pts[0] + (pts[0] - pts[1]).normalized() * radii[0] * 0.6, rings[0], 0.0),
                             (pts[-1] + (pts[-1] - pts[-2]).normalized() * radii[-1] * 0.6, rings[-1], 1.0)):
            cap = self.vert(end)
            centre = pts[0] if t == 0.0 else pts[-1]
            for i in range(around):
                self.face([cap, ring[i], ring[(i + 1) % around]], end - centre, colour_at(t, i), [(t, part)] * 3, line)

    def blob(self, centre, radii, colour_at, around=12, rows=8, part=0.5, line=1.0):
        """A rounded lump: a ball stretched to `radii` (x, y, z) about `centre`. `colour_at(t,
        up)` gives a face's colour from how far along z it is (0 front to 1 back) and how high
        (1 top to -1 bottom)."""
        c = Vector(centre)
        rings = []
        for r in range(1, rows):
            b = math.pi * r / rows
            ring = []
            for i in range(around):
                a = 2 * math.pi * i / around
                ring.append(self.vert(c + Vector((math.sin(a) * math.sin(b) * radii[0], math.cos(a) * math.sin(b) * radii[1],
                                                  -math.cos(b) * radii[2]))))
            rings.append(ring)
        front = self.vert(c + Vector((0, 0, -radii[2])))
        back = self.vert(c + Vector((0, 0, radii[2])))
        for i in range(around):
            j = (i + 1) % around
            up = math.cos(2 * math.pi * (i + 0.5) / around)
            out = Vector((math.sin(2 * math.pi * (i + 0.5) / around), up, 0.0))
            self.face([front, rings[0][i], rings[0][j]], (0, 0, -1), colour_at(0.0, up), [(0.0, part)] * 3, line)
            self.face([back, rings[-1][i], rings[-1][j]], (0, 0, 1), colour_at(1.0, up), [(1.0, part)] * 3, line)
            for r in range(len(rings) - 1):
                t = (r + 1.5) / rows
                quad = [rings[r][i], rings[r][j], rings[r + 1][j], rings[r + 1][i]]
                self.face(quad, out, colour_at(t, up), [(t, part)] * 4, line)

    def fin(self, root, rim, colour_at, rows=6, thick=0.03, wave=0.0, line=0.6):
        """A fin: a sheet from the points of `root` (on the body) out to the matching points of
        `rim`, given thickness so it is a closed solid. `colour_at(u, v)` gives a face's colour
        from how far along the root it is and how far out (both 0 to 1). `wave` ripples it."""
        n = len(root)
        mid = []
        for i in range(n):
            u = i / (n - 1)
            line_pts = []
            for j in range(rows + 1):
                v = j / rows
                p = Vector(root[i]).lerp(Vector(rim[i]), v)
                line_pts.append((p, u, v))
            mid.append(line_pts)
        # the sheet's normal at each point, from its neighbours
        def normal(i, j):
            a = mid[min(i + 1, n - 1)][j][0] - mid[max(i - 1, 0)][j][0]
            b = mid[i][min(j + 1, rows)][0] - mid[i][max(j - 1, 0)][0]
            nrm = a.cross(b)
            return nrm.normalized() if nrm.length > 1e-9 else Vector((1, 0, 0))
        flat = normal(n // 2, rows // 2)
        sides = []
        for sign in (1.0, -1.0):
            grid = []
            for i in range(n):
                row = []
                for j in range(rows + 1):
                    p, u, v = mid[i][j]
                    nrm = normal(i, j)
                    if nrm.dot(flat) < 0.0:
                        nrm = -nrm
                    ripple = wave * math.sin(u * 7.0 + v * 4.0) * v * v
                    # (thinner toward the edge)
                    t = thick * (1.0 - 0.75 * v) * 0.5
                    row.append(self.vert(p + nrm * (ripple + sign * t)))
                grid.append(row)
            sides.append(grid)
            for i in range(n - 1):
                for j in range(rows):
                    quad = [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
                    uvs = [(j / rows, 2.0), (j / rows, 2.0), ((j + 1) / rows, 2.0), ((j + 1) / rows, 2.0)]
                    self.face(quad, flat * sign, colour_at((i + 0.5) / (n - 1), (j + 0.5) / rows), uvs, line)
        front, back = sides
        centre = sum((m[rows // 2][0] for m in mid), Vector()) / n

        def edge(a0, a1, b0, b1, u, v, at):
            self.face([a0, a1, b1, b0], at - centre, colour_at(u, v), [(v, 2.0)] * 4, line)
        for i in range(n - 1):
            edge(front[i][rows], front[i + 1][rows], back[i][rows], back[i + 1][rows], (i + 0.5) / (n - 1), 1.0, mid[i][rows][0])
            edge(front[i][0], front[i + 1][0], back[i][0], back[i + 1][0], (i + 0.5) / (n - 1), 0.0, mid[i][0][0])
        for j in range(rows):
            edge(front[0][j], front[0][j + 1], back[0][j], back[0][j + 1], 0.0, (j + 0.5) / rows, mid[0][j][0])
            edge(front[n - 1][j], front[n - 1][j + 1], back[n - 1][j], back[n - 1][j + 1], 1.0, (j + 0.5) / rows, mid[n - 1][j][0])

    def eye(self, at, out, size, iris, pupil=(0.0, 0.0, 0.0, 1.0), glint=(1.0, 1.0, 1.0, 1.0)):
        """A round eye on the side of the head, looking out along `out`: a low dome for the
        iris, a smaller one on it for the pupil, and a glint."""
        out = Vector(out).normalized()
        u = out.cross(Vector((0, 1, 0))).normalized()
        v = u.cross(out).normalized()
        for radius, lift, colour, shift in ((1.0, 0.0, iris, (0, 0)), (0.6, 0.2, pupil, (0, 0)), (0.2, 0.36, glint, (-0.3, 0.35))):
            centre = Vector(at) + out * lift * size + (u * shift[0] + v * shift[1]) * size
            top = self.vert(centre + out * size * 0.3 * radius)
            ring = []
            for i in range(12):
                a = 2 * math.pi * i / 12
                ring.append(self.vert(centre + (u * math.cos(a) + v * math.sin(a)) * size * radius))
            for i in range(12):
                self.face([top, ring[i], ring[(i + 1) % 12]], out, colour, [(0, 3.0), (1, 3.0), (1, 3.0)])

    # ------------------------------------------------------------------ the end

    def finish(self, out_dir):
        """Turns the model into Blender's space, checks it, and writes NAME.blend, NAME.glb and
        NAME.png (the turnaround sheet) into `out_dir`."""
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-6)
        for v in self.bm.verts:
            x, y, z = v.co
            v.co = Vector((x, -z, y))
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        tris = sum(len(f.verts) - 2 for f in self.bm.faces)
        self.bm.free()
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.color_attributes.active_color = mesh.color_attributes["Col"]
        mesh.color_attributes.render_color_index = 0
        length = max(v.co.y for v in mesh.vertices) - min(v.co.y for v in mesh.vertices)
        print("MODEL %s: %d triangles, %d vertices, %.2f long" % (self.name, tris, len(mesh.vertices), length))
        if tris > 4000:
            sys.exit("fishkit: %s has %d triangles; the most a model may have is 4000" % (self.name, tris))

        bpy.ops.wm.save_as_mainfile(filepath="%s/%s.blend" % (out_dir, self.name))
        bpy.ops.export_scene.gltf(filepath="%s/%s.glb" % (out_dir, self.name), export_format="GLB", export_yup=True,
                export_animations=False, export_materials="NONE", export_vertex_color="ACTIVE",
                export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True)
        self._sheet(obj, "%s/%s.png" % (out_dir, self.name))

    def _icon(self, np, px, path):
        """The side view by itself, facing left, cut close to the animal, with nothing behind it:
        what the shop and the animal's card show."""
        solid = np.argwhere(px[:, :, 3] > 0.02)
        (y0, x0), (y1, x1) = solid.min(axis=0), solid.max(axis=0)
        pad = 6
        cut = px[max(y0 - pad, 0):y1 + pad, max(x0 - pad, 0):x1 + pad, :][:, ::-1, :]
        out = bpy.data.images.new("icon", cut.shape[1], cut.shape[0], alpha=True)
        out.pixels = cut.ravel()
        out.filepath_raw = path
        out.file_format = "PNG"
        out.save()

    def _sheet(self, obj, path):
        """Side, front, top and three-quarter views in flat colour, and the side again as a
        black shape, in one picture."""
        import numpy as np
        scene = bpy.context.scene
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "FLAT"
        scene.display.shading.color_type = "VERTEX"
        scene.world = bpy.data.worlds.new("w")
        scene.world.color = (0.5, 0.5, 0.5)
        scene.view_settings.view_transform = "Standard"
        cam_data = bpy.data.cameras.new("cam")
        cam_data.type = "ORTHO"
        cam_data.ortho_scale = 4.4
        cam = bpy.data.objects.new("cam", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
        w, h = 480, 360
        scene.render.resolution_x, scene.render.resolution_y = w, h
        scene.render.film_transparent = True
        views = [("side", (6, 0, 0)), ("front", (0, 6, 0)), ("top", (0, 0, 6)), ("three-quarter", (4, 4, 2.5))]
        tiles = []
        lo = Vector([min(v.co[k] for v in obj.data.vertices) for k in range(3)])
        hi = Vector([max(v.co[k] for v in obj.data.vertices) for k in range(3)])
        for title, at in views:
            cam.location = (lo + hi) * 0.5 + Vector(at)
            cam.rotation_euler = (-Vector(at)).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = "%s.%s.png" % (path, title)
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(scene.render.filepath)
            px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
            tiles.append(px)
            if title == "side":
                self._icon(np, px, path.replace(".png", "_icon.png"))
            bpy.data.images.remove(img)
            import os
            os.remove(scene.render.filepath)
        grey = np.array([0.42, 0.42, 0.45], dtype=np.float32)

        def over(px, flat=None):
            rgb = px[:, :, :3] if flat is None else np.zeros_like(px[:, :, :3]) + flat
            a = px[:, :, 3:4]
            return rgb * a + (grey if flat is None else np.array([0.85, 0.85, 0.85], dtype=np.float32)) * (1.0 - a)
        cells = [over(t) for t in tiles] + [over(tiles[0], 0.0)]
        # (pixels run bottom row first: the top row of the sheet is the second strip)
        strip_a = np.concatenate(cells[:3], axis=1)
        pad = np.zeros((h, w, 3), dtype=np.float32) + grey
        strip_b = np.concatenate([cells[3], cells[4], pad], axis=1)
        sheet = np.concatenate([strip_b, strip_a], axis=0)
        sheet = np.concatenate([sheet, np.ones((h * 2, w * 3, 1), dtype=np.float32)], axis=2)
        out = bpy.data.images.new("sheet", w * 3, h * 2)
        out.pixels = sheet.ravel()
        out.filepath_raw = path
        out.file_format = "PNG"
        out.save()
