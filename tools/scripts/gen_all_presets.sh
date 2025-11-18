#!/usr/bin/env bash
set -eu pipefail

echo "here we go!"
# Run from repo root. Converts every .config under ./config/examples
# using tools/scripts/config2presets.py

SCRIPT="./tools/scripts/config2presets.py"
DIR="./config/examples"

if [ ! -f "$SCRIPT" ]; then
    echo "Error: $SCRIPT not found. Run this from the wolfBoot repo root."
    exit 1
fi

if [ ! -d "$DIR" ]; then
    echo "Error: $DIR not found. Check your path."
    exit 1
fi

shopt -s nullglob
configs=("$DIR"/*.config)

if [ ${#configs[@]} -eq 0 ]; then
    echo "No .config files found in $DIR"
    exit 0
fi

for cfg in "${configs[@]}"; do
    name="$(basename "$cfg" .config)"
    echo "Converting: $cfg"
    "$SCRIPT" "$DIR/$name.config"
done

echo "Done."
