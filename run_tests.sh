#!/usr/bin/env sh
# Usage: GODOT=/path/to/godot ./run_tests.sh
set -e
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd
