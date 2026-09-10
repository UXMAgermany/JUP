#!/usr/bin/env bash
# Flatten CSS <style> in the achievement badge SVGs into presentation
# attributes so flutter_svg renders their real colours (it does not apply
# internal <style> — class-based fills otherwise render as black).
#
# Re-run after any fresh designer export of assets/achievements/*.svg.
# Better long-term: have the designer export with "Presentation Attributes".
#
# Requires Node (uses `npx svgo`).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/assets/achievements"
CONFIG="$ROOT/scripts/svgo-achievements.config.mjs"

npx --yes svgo@4 --config "$CONFIG" -f "$DIR"
echo "Flattened SVGs in $DIR"
