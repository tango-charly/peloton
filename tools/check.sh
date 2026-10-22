#!/usr/bin/env bash
# Vérification CORE-001. Usage : GODOT=/chemin/Godot_v4.7.2-stable_linux.x86_64 tools/check.sh
set -euo pipefail
: "${GODOT:?Définir GODOT vers Godot 4.7.2}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Import : sous Linux, le premier import à froid se termine par un abort à la fermeture de l'éditeur
# (extension godot-sqlite, voir docs/COMPATIBILITY.md). L'import est pourtant complet : on le vérifie.
"$GODOT" --headless --path "$ROOT" --import </dev/null >/dev/null 2>&1 || true
test -f "$ROOT/.godot/extension_list.cfg" || { echo "Import Godot incomplet" >&2; exit 1; }
timeout 600 "$GODOT" --headless --path "$ROOT" --script res://tests/run_tests.gd < /dev/null
"$GODOT" --headless --path "$ROOT" --quit-after 30 | grep "\[boot\]"
