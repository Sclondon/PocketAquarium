extends RefCounted
## The animals that have a model made in Blender (art/blender/, built into models/ by
## tools/build_models.sh). Any other animal's model is built in code, by fish_mesh.gd.
##
## A Blender model keeps to the contract at the top of art/blender/fishkit.py, which differs
## from a code-built one in three ways the shaders have to be told about (`modelled`): its
## colours are stored linear, its fins have thickness, and how wide its outline is and how much
## it glows come in its second UV.

static var _cache := {}


## The model for a species, or null if it has none.
static func of(id: String) -> Mesh:
	if not _cache.has(id):
		_cache[id] = _load("res://models/%s.glb" % id)
	return _cache[id]


static func _load(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var scene: Node = (load(path) as PackedScene).instantiate()
	var found: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	scene.free()
	return mesh
