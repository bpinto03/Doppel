#!/usr/bin/env sh
# Usage: GODOT=/path/to/godot ./run_simulation.sh [--games N] [--scenarios name,name]
set -e
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s tools/simulation/simulation_runner.gd -- "$@"
