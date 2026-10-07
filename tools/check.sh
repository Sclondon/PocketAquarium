#!/usr/bin/env bash
# The checks to run before a release. Each prints PASS or FAIL; the script fails if any does.
#   smoke    months of tank time with a fixed seed, against tests/smoke_seed7.txt: the tanks
#            must go exactly as they did when that file was written. If the rules were changed
#            on purpose, read the difference and then run:  tools/check.sh --accept
#   saves    (part of the smoke run) saves from the first game load with every fish
#   models   every Blender model builds and keeps to the contract (needs Blender)
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
failed=0
out="$(mktemp)"
"$GODOT" --headless --path . -- --no-save --smoke --seed=7 2>&1 | grep -E "^smoke|SCRIPT ERROR" > "$out"
if [ "${1:-}" = "--accept" ]; then cp "$out" tests/smoke_seed7.txt; echo "smoke: accepted as the new baseline"; exit 0; fi
if diff -u tests/smoke_seed7.txt "$out"; then echo "PASS smoke"; else echo "FAIL smoke"; failed=1; fi
if grep -q "old save" "$out" && ! grep "old save" "$out" | grep -vqE ": ([0-9]+) of \1 fish"; then echo "PASS saves"; else echo "FAIL saves"; failed=1; fi
if [ "${SKIP_MODELS:-}" = 1 ]; then echo "SKIP models"; elif bash tools/build_models.sh >/dev/null; then echo "PASS models"; else echo "FAIL models"; failed=1; fi
exit $failed
