#!/usr/bin/env bash
set -euo pipefail

INTERNAL_REPO="$HOME/Projects/jup"
MIRRORS=(
  "$HOME/Projects/jup-mirror-github"
  "$HOME/Projects/jup-mirror-opencode"
)

EXCLUDES=(
  --exclude='.git/'
  --exclude='.gitlab-ci.yml'
  --include='.env.example'
  --exclude='.env'
  --exclude='.env.*'
  --exclude='fastlane/'
  --exclude='CLAUDE.md'
  --exclude='.claude/'
)

# --- Read-only Sanity-Checks ---
[[ -d "$INTERNAL_REPO/.git" ]] || { echo "ERROR: $INTERNAL_REPO ist kein git-Repo." >&2; exit 1; }
for mirror in "${MIRRORS[@]}"; do
  [[ -d "$mirror/.git" ]] || { echo "ERROR: $mirror ist kein git-Repo." >&2; exit 1; }
done

# --- Sync (nur lokale Tree-Änderungen in den Mirrors) ---
for mirror in "${MIRRORS[@]}"; do
  echo "→ Mirror-Tree neu aufbauen in $mirror"
  cd "$mirror"
  find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
  rsync -av "${EXCLUDES[@]}" "$INTERNAL_REPO/" "$mirror/"
done

echo ""
echo "✓ Sync fertig. Lokale Änderungen liegen in:"
for mirror in "${MIRRORS[@]}"; do
  echo "  - $mirror"
done
echo ""
echo "Es wurde NICHTS gestaged, committed oder gepusht."
echo "Bitte pro Mirror manuell prüfen (git status / git diff) und selbst entscheiden, wie weiter."
