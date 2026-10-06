extends Node
## The save: one JSON file holding the tank, the fish-dex and (outside the arcade) the practice
## wallet. `--no-save` starts from a new tank and writes nothing, for tests.

const PATH := "user://aquarium.json"

var data := {}
var enabled := true


func _ready() -> void:
	if "--no-save" in OS.get_cmdline_user_args():
		enabled = false
		return
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		data = parsed


func write() -> void:
	if not enabled:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


## Throws the tank away (the wallet is kept).
func reset() -> void:
	data.erase("tank")
	write()
