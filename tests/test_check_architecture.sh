#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/lw012.XXXXXX")
trap 'rm -r "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/src/core/rng" "$fixture/src/data" "$fixture/src/sim/world" "$fixture/src/presentation"
mkdir -p "$fixture/docs"
printf '# Eventos\n' > "$fixture/docs/events.md"
for dir in "$fixture/src/core" "$fixture/src/core/rng" "$fixture/src/data" "$fixture/src/sim" "$fixture/src/sim/world" "$fixture/src/presentation"; do
    printf 'Contrato de teste\n' > "$dir/README.md"
done
checker="$project_dir/tools/check_architecture"
printf 'func next():\n    return randi()\n' > "$fixture/src/core/rng/allowed.gd"
"$checker" "$fixture" || { echo 'FALHA: caso válido'; exit 1; }
check_violation() {
    label=$1
    expected=$2
    if "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label não foi detectada"; exit 1
    fi
    if ! grep -F "$expected" "$fixture/output" >/dev/null; then
        echo "FALHA: $label sem localização esperada"; cat "$fixture/output"; exit 1
    fi
    echo "OK: $label"
}
printf 'extends Node3D\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'simulação usa Node' 'violation.gd:1:'
printf 'func x(): return randf()\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'aleatoriedade fora de rng' 'violation.gd:1:'
printf 'func x(): return Time.get_ticks_msec()\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'tempo do sistema' 'violation.gd:1:'
printf 'static var estado = 0\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'estado estático' 'violation.gd:1:'
rm "$fixture/src/sim/world/violation.gd"
rm "$fixture/src/sim/world/README.md"
check_violation 'contrato ausente' 'world/README.md'
printf 'Contrato\n' > "$fixture/src/sim/world/README.md"
printf 'func x(): bus.publish("TestOccurred")\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'evento não catalogado' 'violation.gd:1:'
printf '| `TestOccurred` | teste |\n' >> "$fixture/docs/events.md"
"$checker" "$fixture" || { echo 'FALHA: evento catalogado'; exit 1; }
printf '[autoload]\nUnexpected="*res://unexpected.gd"\n' > "$fixture/project.godot"
check_violation 'autoload não permitido' 'project.godot:2:'
echo 'Arquitetura: casos válidos e sete violações detectadas.'
