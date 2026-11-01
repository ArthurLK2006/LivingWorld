#!/bin/sh
# LW-021: a cena principal carrega com os autoloads por 60 quadros sem erro e o smoke_test continua passando.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/Applications/Godot 2.app/Contents/MacOS/Godot}
output=$(mktemp "${TMPDIR:-/tmp}/lw021.XXXXXX")
trap 'rm -f "$output"' EXIT HUP INT TERM
if ! "$godot_bin" --headless --path "$project_dir" --quit-after 60 > "$output" 2>&1; then
    echo 'FALHA: a cena principal não terminou com código 0'; cat "$output"; exit 1
fi
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$output" >/dev/null; then
    echo 'FALHA: a cena principal registrou erros'; cat "$output"; exit 1
fi
echo 'OK: cena principal com autoloads por 60 quadros'
if ! "$godot_bin" --headless --path "$project_dir" --script res://tools/smoke_test.gd > "$output" 2>&1; then
    echo 'FALHA: smoke_test'; cat "$output"; exit 1
fi
grep -F 'SMOKE_TEST: PASS' "$output" >/dev/null || { echo 'FALHA: smoke_test sem PASS'; cat "$output"; exit 1; }
echo 'OK: smoke_test da cena'
echo 'LW-021: cena principal e smoke_test aprovados.'
