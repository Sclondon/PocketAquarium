extends Node
## The save: one JSON file holding the shelf of tanks, the fish-dex and (outside the arcade) the
## practice wallet. `--no-save` starts from a new tank and writes nothing, for tests.
##
## The file carries a `version`. The first game that was published wrote none, in two shapes
## (one `tank`, or later a `tanks` list of three): a file like that is version 1. Before a
## file older than this is touched it is copied, once, to BACKUP, so nothing an update does to it
## can lose what was in it. `upgrade` then brings it up to date.

const PATH := "user://aquarium.json"
const BACKUP := "user://aquarium.v1.json"
const VERSION := 3

var data := {}
var enabled := true


func _ready() -> void:
	if "--no-save" in OS.get_cmdline_user_args():
		enabled = false
		data = {"version": VERSION}
		return
	if not FileAccess.file_exists(PATH):
		data = {"version": VERSION}
		return
	var text := FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	if int(parsed.get("version", 1)) < VERSION and not FileAccess.file_exists(BACKUP):
		var copy := FileAccess.open(BACKUP, FileAccess.WRITE)
		if copy != null:
			copy.store_string(text)
	data = upgrade(parsed)


## Brings a save of any older version up to this one, and returns it. (It is the dictionary it
## was given, changed: nothing else has read it yet.)
static func upgrade(old: Dictionary) -> Dictionary:
	var from := int(old.get("version", 1))
	if from < 2:
		# version 1 kept one tank, for the middle shelf, before it kept three
		if not old.has("tanks"):
			old["tanks"] = [null, old.get("tank", {}), null]
		old.erase("tank")
		# the update changes how the tanks look and nothing about how they are kept, so the
		# time away is caught up on as it always was
	if from < 3:
		# version 2 had three shelves, and now there are five: the three are the middle three
		var three: Array = old.get("tanks", [])
		three.resize(3)
		old["tanks"] = [null, three[0], three[1], three[2], null]
	old["version"] = VERSION
	return old


func write() -> void:
	if not enabled:
		return
	data["version"] = VERSION
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


## Throws the tanks away (the wallet is kept).
func reset() -> void:
	data.erase("tanks")
	write()
