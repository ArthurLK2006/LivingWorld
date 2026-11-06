#!/bin/sh
# LW-044: o tools/check_input_keys reprova tecla escrita direto no código (e aponta arquivo e linha) e aprova o que não é tecla.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/lw044.XXXXXX")
trap 'rm -r "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/src/app"
checker="$project_dir/tools/check_input_keys"
violations=0
passes=0
expect_violation() {
    label=$1
    content=$2
    printf '%s\n' "$content" > "$fixture/src/app/violation.gd"
    if "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label não foi detectada"; cat "$fixture/output"; exit 1
    fi
    if ! grep -F 'violation.gd:1:' "$fixture/output" >/dev/null; then
        echo "FALHA: $label sem arquivo e linha"; cat "$fixture/output"; exit 1
    fi
    violations=$((violations + 1))
}
expect_pass() {
    label=$1
    content=$2
    printf '%s\n' "$content" > "$fixture/src/app/clean.gd"
    if ! "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label deveria passar"; cat "$fixture/output"; exit 1
    fi
    passes=$((passes + 1))
}
expect_pass 'projeto sem teclas' 'func ok() -> bool: return Input.is_action_pressed(&"move_forward")'
expect_violation 'tipo Key com KEY_SPACE' 'var pause_key: Key = KEY_SPACE'
expect_violation 'keycode comparado' 'func f(e): return e.keycode == KEY_W'
expect_violation 'physical_keycode' 'func f(e): return e.physical_keycode'
expect_violation 'InputEventKey' 'var e = InputEventKey.new()'
expect_violation 'cast para InputEventKey' 'var k := event as InputEventKey'
expect_violation 'is_key_pressed' 'func f(): return Input.is_key_pressed(KEY_A)'
expect_violation 'is_physical_key_pressed' 'func f(): return Input.is_physical_key_pressed(KEY_A)'
expect_violation 'KEY_ESCAPE solta' 'const QUIT = KEY_ESCAPE'
expect_violation 'KEY_F5' 'func f(e): return e == KEY_F5'
expect_violation 'retorno do tipo Key' 'func which() -> Key: return 0'
expect_violation 'lista de Key' 'var keys: Array[Key] = []'
rm -f "$fixture/src/app/violation.gd"
expect_pass 'KEY_IDS não é tecla' 'const KEY_IDS: Array[String] = ["a", "b"]'
expect_pass 'KEY_WORLD_SEED não é tecla' 'const KEY_WORLD_SEED: String = "world_seed"'
expect_pass 'KEY_TOTAL_MINUTES não é tecla' 'const KEY_TOTAL_MINUTES: String = "total_minutes"'
expect_pass 'comentário com keycode' '## Não usa keycode nem InputEventKey (KEY_SPACE).'
expect_pass 'comentário com cerquilha' '# if event.keycode == KEY_W'
expect_pass 'ação de entrada' 'func f(e): return e.is_action_pressed(&"pause")'
expect_pass 'variável chamada key de outro tipo' 'func f(key: String) -> String: return key'
# Código com comentário no fim continua varrido.
printf 'var k: Key = KEY_W # tecla fixa\n' > "$fixture/src/app/violation.gd"
if "$checker" "$fixture" > "$fixture/output" 2>&1; then echo 'FALHA: tecla com comentário no fim não foi detectada'; exit 1; fi
violations=$((violations + 1))
rm -f "$fixture/src/app/violation.gd" "$fixture/src/app/clean.gd"
"$checker" "$project_dir" > "$fixture/output" 2>&1 || { echo 'FALHA: o código real tem tecla fixa'; cat "$fixture/output"; exit 1; }
echo "LW-044: check_input_keys: $violations violações detectadas, $passes casos aceitos e o código real sem tecla fixa."
