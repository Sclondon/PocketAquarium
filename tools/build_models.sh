#!/usr/bin/env bash
# Builds every animal's model: runs each script in art/blender/ (but fishkit.py, which they
# share) in Blender, which writes NAME.blend, NAME.glb and NAME.png (the turnaround sheet to
# review) into art/generated/. Then puts the model the game is to use in models/: the one
# from art/hand/ if somebody has reworked it by hand, and the generated one if not.
# Nothing here overwrites art/hand/. Pass names to build only those: tools/build_models.sh betta
set -e
cd "$(dirname "$0")/.."
BLENDER="${BLENDER:-C:/Program Files/Blender Foundation/Blender 4.3/blender.exe}"
mkdir -p art/generated models
for script in art/blender/*.py; do
	name="$(basename "$script" .py)"
	[ "$name" = fishkit ] && continue
	if [ $# -gt 0 ] && [[ ! " $* " =~ " $name " ]]; then continue; fi
	"$BLENDER" -b --python "$script" -- "$(pwd)/art/generated" 2>&1 | grep -E "^MODEL|fishkit:|Error|Traceback|^  File|line [0-9]+" || true
	[ -f "art/generated/$name.glb" ] || { echo "build_models: $name did not build"; exit 1; }
	if [ -f "art/hand/$name.glb" ]; then cp "art/hand/$name.glb" "models/$name.glb"; echo "  models/$name.glb (by hand)"
	else cp "art/generated/$name.glb" "models/$name.glb"; echo "  models/$name.glb"; fi
	# (its picture for the shop and its card: the side of the model, as built)
	cp "art/generated/${name}_icon.png" "models/${name}_icon.png"
done
